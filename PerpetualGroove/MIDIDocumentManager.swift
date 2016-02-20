//
//  MIDIDocumentManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class MIDIDocumentManager {

  // MARK: - Initialization

  /** initialize */
  static func initialize() {

    queue.async {

      guard state ∌ .Initialized else { return }

      receptionist.logContext = LogManager.MIDIFileContext

      receptionist.observe(SettingsManager.Notification.Name.iCloudStorageChanged,
                      from: SettingsManager.self)
      {
        _ in
        logDebug("observed notification of iCloud storage setting change")
        updateStorageLocation()
      }

      receptionist.observe(NSMetadataQueryDidFinishGatheringNotification, from: metadataQuery) {
        _ in

        logDebug("observed notification metadata query has finished gathering")
        guard state ∋ .GatheringMetadataItems else {
          logWarning("received gathering notification but state does not contain gathering flag")
          return
        }

        metadataQuery.disableUpdates()
        metadataItems = (metadataQuery.results as! [NSMetadataItem]).map(DocumentItem.init)
        metadataQuery.enableUpdates()
        state ⊻= .GatheringMetadataItems
      }

      receptionist.observe(NSMetadataQueryDidUpdateNotification, from: metadataQuery) {
        logDebug("observed metadata query update notification")
        var items = metadataItems
        if let removed = $0.removedMetadataItems?.map(DocumentItem.init) { items ∖= removed }
        if let added   = $0.addedMetadataItems?.map(DocumentItem.init)   { items += added   }
        metadataItems = items 
      }

      updateStorageLocation()

      state ∪= [.Initialized]
    }
  }
  
  // MARK: - Queues

  static let queue: dispatch_queue_t = concurrentQueueWithLabel("MIDIDocumentManager")
  static let operationQueue: NSOperationQueue = {
    let operationQueue = NSOperationQueue(name: "MIDIDocumentManager")
    operationQueue.underlyingQueue = queue
    return operationQueue
  }()

  private static let queryQueue: NSOperationQueue = {
    let queryQueue = NSOperationQueue(name: "MIDIDocumentManager.MetadataQuery")
    queryQueue.maxConcurrentOperationCount = 1
    return queryQueue
  }()


  // MARK: - Tracking state
  private static var state: State = [] {
    didSet {
      logDebug("\(oldValue) ➞ \(state)")

      let modifiedState = state ⊻ oldValue

      if modifiedState ∋ .OpeningDocument {
        dispatchToMain {
          (openingDocument ? Notification.WillOpenDocument : Notification.DidOpenDocument).post(object: self)
        }
      }
    }
  }

  static var openingDocument: Bool { return state ∋ .OpeningDocument }
  static var gatheringMetadataItems: Bool { return state ∋ .GatheringMetadataItems }

  // MARK: - The currently open document

  /** refreshBookmark */
  static private func refreshBookmark() {
    queue.async {
      guard let currentDocument = currentDocument else { return }
        do {
          let bookmark = try currentDocument.fileURL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                              includingResourceValuesForKeys: nil,
                                                               relativeToURL: nil)
          switch currentDocument.storageLocation {
            case .iCloud: SettingsManager.currentDocumentiCloud = bookmark
            case .Local: SettingsManager.currentDocumentLocal = bookmark
          }
          logDebug("bookmark refreshed for '\(currentDocument.localizedName)'")
        } catch {
          logError(error, message: "Failed to generate bookmark data for storage")
        }
    }
  }

  private static let observer = KVOReceptionist()

  static private var _currentDocument: MIDIDocument? {
    willSet {
      guard _currentDocument != newValue else { return }
      Notification.WillChangeDocument.post()
    }
    didSet {
      queue.async {
        logDebug("currentDocument: \(_currentDocument == nil ? "nil" : _currentDocument!.localizedName)")

        guard oldValue != _currentDocument else { return }

        if let oldValue = oldValue {
          logDebug("closing document '\(oldValue.localizedName)'")
          observer.stopObserving(oldValue, forChangesTo: "fileURL")
          oldValue.closeWithCompletionHandler(nil)
        }

        if let currentDocument = _currentDocument {
          observer.observe(currentDocument, forChangesTo: "fileURL", queue: operationQueue) {
            _, _, _ in
            logDebug("observed change to file URL of current document")
            MIDIDocumentManager.refreshBookmark()
          }
        }

        refreshBookmark()
        dispatchToMain { Notification.DidChangeDocument.post() }
      }
    }
  }

  static private let currentDocumentLock = NSObject()

  static private(set) var currentDocument: MIDIDocument? {
    get {
      objc_sync_enter(currentDocumentLock)
      defer { objc_sync_exit(currentDocumentLock) }
      return _currentDocument
    }
    set {
      objc_sync_enter(currentDocumentLock)
      defer { objc_sync_exit(currentDocumentLock) }
      _currentDocument = newValue
    }
  }

  // MARK: - Items

  /** updateStorageLocation */
  static private func updateStorageLocation() {
    let bookmarkData: NSData?
    switch (SettingsManager.iCloudStorage, storageLocation) {
      case (true, .Local), (true, .iCloud) where state ∌ .Initialized:
        storageLocation = .iCloud
        state ∪= [.GatheringMetadataItems]
        metadataQuery.startQuery()
        directoryMonitor.stopMonitoring()
        bookmarkData = SettingsManager.currentDocumentiCloud
      case (false, .iCloud), (false, .Local) where state ∌ .Initialized:
        storageLocation = .Local
        metadataQuery.stopQuery()
        refreshLocalItems()
        directoryMonitor.startMonitoring()
        bookmarkData = SettingsManager.currentDocumentLocal
      default:
        bookmarkData = nil
    }

    switch (bookmarkData, Sequencer.initialized) {
      case (nil, _): return
      case (let data?, true):
        do { try openBookmarkedDocument(data) }
        catch { logError(error, message: "Failed to resolve bookmark data into a valid file url") }
      case (let data?, false):
        receptionist.observe(Sequencer.Notification.DidUpdateAvailableSoundSets, from: Sequencer.self) {
          _ in
          receptionist.stopObserving(Sequencer.Notification.DidUpdateAvailableSoundSets)
          queue.async {
            do {
              try openBookmarkedDocument(data)
            } catch {
              logError(error, message: "Failed to resolve bookmark data into a valid file url")
            }
          }
        }
    }
  }

  static private(set) var storageLocation: StorageLocation = SettingsManager.iCloudStorage ? .iCloud: .Local

  /**
  currentItems

  - returns: [DocumentItem]
  */
  static private func currentItems() -> [DocumentItem] {
    switch storageLocation {
      case .iCloud: return metadataItems
      case .Local:  return localItems
    }
  }

  static var items: [DocumentItem] { return storageLocation == .iCloud ? metadataItems : localItems }

  private static let directoryMonitor: DirectoryMonitor = {
    let monitor = try! DirectoryMonitor(directoryURL: documentsURL) {
      _, _ in MIDIDocumentManager.refreshLocalItems()
    }
    monitor.callbackQueue = operationQueue
    return monitor
  }()

  private static let metadataQuery: NSMetadataQuery = {
    let query = NSMetadataQuery()
    query.notificationBatchingInterval = 1
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.operationQueue = queryQueue
    return query
  }()

  static private(set) var metadataItems: [DocumentItem] = [] {
    didSet {
      guard storageLocation == .iCloud else { return }
      postItemUpdateNotification(metadataItems)
    }
  }

  static private(set) var localItems: [DocumentItem] = [] {
    didSet {
      guard storageLocation == .Local else { return }
      postItemUpdateNotification(localItems)
    }
  }

  static private var oldItems: [DocumentItem] = []


  /**
  postItemNotificationWithItems:oldItems:

  - parameter items: [DocumentItem]
  - parameter oldItems: [DocumentItem]
  */
  static private func postItemUpdateNotification(items: [DocumentItem]) {
    defer { oldItems = items }

    logDebug("items: \(items.map(({$0.displayName})))")
    guard oldItems != items else { logDebug("no change…"); return }

    let removed = oldItems ∖ items
    let added = items ∖ oldItems

    logDebug({
      guard removed.count + added.count > 0 else { return "" }
      var string = ""
      if removed.count > 0 { string += "removed: \(removed)" }
      if added.count > 0 { if !string.isEmpty { string += "\n" }; string += "added: \(added)" }
      return string
      }())

    var userInfo: [Notification.Key:AnyObject?] = [:]
    if removed.count > 0 { userInfo[Notification.Key.Removed] = removed.map({$0.data}) }
    if added.count > 0 { userInfo[Notification.Key.Added] = added.map({$0.data}) }

    guard userInfo.count > 0 else { return }

    logDebug("posting 'DidUpdateItems'")
    dispatchToMain { Notification.DidUpdateItems.post(object: self, userInfo: userInfo) }

  }

  /** refreshLocalItems */
  static private func refreshLocalItems() {
    guard let fileWrappers = directoryMonitor.directoryWrapper.fileWrappers?.values else { return }
    let localDocumentItems: [LocalDocumentItem] = fileWrappers.flatMap({[directory = directoryMonitor.directoryURL] in
      guard let name = $0.preferredFilename else { return nil }
      return try? LocalDocumentItem(directory + name)
      })
    localItems = localDocumentItems.map(DocumentItem.init)
  }

  // MARK: - Receiving notifications

  private static let receptionist = NotificationReceptionist(callbackQueue: MIDIDocumentManager.operationQueue)

  // MARK: - Creating new documents

  private static let DefaultDocumentName = "AwesomeSauce"

  /** createNewFile */
  static func createNewDocument(name: String? = nil) {

    queue.async {

      let url: NSURL

      switch storageLocation {

        case .iCloud:
          guard let baseURL = NSFileManager().URLForUbiquityContainerIdentifier(nil) else {
            fatalError("createNewDocument() requires that the iCloud drive is available when the iCloud storage flag is set")
          }
          url = baseURL + "Documents"

        case .Local:
          url = documentsURL

      }

      guard let fileName = noncollidingFileName(name ?? DefaultDocumentName) else { return }
      let fileURL = url + ["\(fileName).groove"]
      logDebug("creating a new document at path '\(fileURL.path!)'")
      let document = MIDIDocument(fileURL: fileURL)
      document.saveToURL(fileURL, forSaveOperation: .ForCreating, completionHandler: {
        guard $0 else { return }
        dispatchToMain {
          Notification.DidCreateDocument.post(userInfo: [Notification.Key.FilePath: fileURL.path!])
          MIDIDocumentManager.openDocument(document)
        }
      })
    }

  }

  /**
  noncollidingFileName:

  - parameter fileName: String?

  - returns: String
  */
  static func noncollidingFileName(fileName: String?) -> String? {
    guard let (baseName, ext) = fileName?.baseNameExt else { return nil }

    var extʹ = ext
    if extʹ.isEmpty { extʹ = "groove" }


    let url: NSURL

    switch SettingsManager.iCloudStorage {

      case true:
        guard let baseURL = NSFileManager().URLForUbiquityContainerIdentifier(nil) else {
          logError("Use iCloud setting is true but failed to get ubiquity container")
          return nil
        }
        url = baseURL + "Documents"

      case false:
        url = documentsURL

    }

    var baseNameʹ = baseName
    var i = 2
    while (url + "\(baseNameʹ).\(extʹ)").checkPromisedItemIsReachableAndReturnError(nil) {
      baseNameʹ = "\(baseName)\(i)"
      i += 1
    }

    return "\(baseNameʹ)" + (ext.isEmpty ? "" : ".\(ext)")
  }

  // MARK: - Opening documents

  /**
  openDocument:

  - parameter document: MIDIDocument
  */
  static func openDocument(document: MIDIDocument) {
    let openBlock = {
      guard state ∌ .OpeningDocument else { logWarning("already opening a document"); return }
      logDebug("opening document '\(document.fileURL.path ?? "???")'")
      state ⊻= .OpeningDocument
      document.openWithCompletionHandler {
        guard $0  else {
          logError("failed to open document: \(document)")
          return
        }
        guard state ∋ .OpeningDocument else {
          logError("internal inconsistency, expected state to contain `OpeningDocument`")
          return
        }
        currentDocument = document
        state ⊻= .OpeningDocument
      }
    }
    if Sequencer.soundSets.count > 0 { queue.async(openBlock) }
    else {
      receptionist.observe(Sequencer.Notification.DidUpdateAvailableSoundSets, from: Sequencer.self, queue: operationQueue) {
        _ in
        receptionist.stopObserving(Sequencer.Notification.DidUpdateAvailableSoundSets, from: Sequencer.self)
        openBlock()
      }
    }
  }

  /**
  openURL:

  - parameter url: NSURL
  */
  static func openURL(url: NSURL) { openDocument(MIDIDocument(fileURL: url)) }

  /**
  openBookmarkedDocument:

  - parameter data: NSData?
  */
  static private func openBookmarkedDocument(data: NSData) throws {
    let url = try NSURL(byResolvingBookmarkData: data, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: nil)
    logDebug("opening bookmarked file at path '\(url.path!)'")
    openURL(url)

  }

  /**
  openItem:

  - parameter item: DocumentItemType
  */
  static func openItem(item: DocumentItem) { openURL(item.URL) }

  /**
  deleteItem:

  - parameter item: DocumentItemType
  */
  static func deleteItem(item: DocumentItem) {

    queue.async {

      // Does this create race condition with closing of file?
      if currentDocument?.fileURL == item.URL { currentDocument = nil }

      logDebug("removing item '\(item.URL.path!)'")
      NSFileCoordinator(filePresenter: nil).coordinateWritingItemAtURL(item.URL, options: .ForDeleting, error: nil) {
        do { try NSFileManager().removeItemAtURL($0) }
        catch { logError(error) }
      }
    }
  }

}

extension MIDIDocumentManager {
  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Initialized            = State(rawValue: 0b0001)
    static let OpeningDocument        = State(rawValue: 0b0010)
    static let GatheringMetadataItems = State(rawValue: 0b0100)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if contains(.Initialized)            { flagStrings.append("Initialized")            }
      if contains(.OpeningDocument)        { flagStrings.append("OpeningDocument")        }
      if contains(.GatheringMetadataItems) { flagStrings.append("GatheringMetadataItems") }
      result += ", ".join(flagStrings)
      result += "]"
      return result
    }
  }
}

// MARK: - StorageLocation

extension MIDIDocumentManager {
  enum StorageLocation { case iCloud, Local }
}

// MARK: - Error
extension MIDIDocumentManager {

  enum Error: String, ErrorType {
    case iCloudUnavailable
  }

}

// MARK: - Notification
extension MIDIDocumentManager: NotificationDispatchType {

  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateItems, WillChangeDocument, DidChangeDocument, DidCreateDocument
    case WillOpenDocument, DidOpenDocument
    enum Key: String, NotificationKeyType { case Changed, Added, Removed, FilePath }
    var object: AnyObject? { return MIDIDocumentManager.self }
  }
  
}

extension NSNotification {
  var addedItemsData: [NSData]? {
    return userInfo?[MIDIDocumentManager.Notification.Key.Added.key] as? [NSData]
  }
  var removedItemsData: [NSData]? {
    return userInfo?[MIDIDocumentManager.Notification.Key.Removed.key] as? [NSData]
  }
  var addedItems: [DocumentItem]?   { return addedItemsData?.flatMap(DocumentItem.init)   }
  var removedItems: [DocumentItem]? { return removedItemsData?.flatMap(DocumentItem.init) }
}