//
//  DocumentManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class DocumentManager {

  // MARK: - Initialization

  /** initialize */
  static func initialize() {

    queue.async {

      guard state ∌ .Initialized else { return }

      receptionist.logContext = LogManager.MIDIFileContext

      receptionist.observe(notification: .iCloudStorageChanged,
                           from: SettingsManager.self,
                           callback: DocumentManager.didChangeStorage)

      receptionist.observe(name: NSMetadataQueryDidFinishGatheringNotification,
                           from: metadataQuery,
                           callback: DocumentManager.didGatherMetadataItems)

      receptionist.observe(name: NSMetadataQueryDidUpdateNotification,
                           from: metadataQuery,
                           callback: DocumentManager.didUpdateMetadataItems)

      storageLocation = SettingsManager.iCloudStorage ? .iCloud : .Local

      state ∪= [.Initialized]
    }
  }
  
  // MARK: - Queues

  /// Queue for document manipulations
  static let queue: dispatch_queue_t = concurrentQueueWithLabel("DocumentManager")

  /// Operation queue that dispatches to `queue`
  static let operationQueue: NSOperationQueue = {
    let operationQueue = NSOperationQueue(name: "DocumentManager")
    operationQueue.underlyingQueue = queue
    return operationQueue
  }()

  /// Operation queue for metadata queries
  private static let queryQueue: NSOperationQueue = {
    let queryQueue = NSOperationQueue(name: "DocumentManager.MetadataQuery")
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

  /// Updates contents of bookmark data for storage relevant setting
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

  /// Receptionist for KVO of the current document
  private static let observer = KVOReceptionist()

  static private var _currentDocument: Document? {
    willSet {
      guard _currentDocument != newValue else { return }
      dispatchToMain { Notification.WillChangeDocument.post() }
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
            DocumentManager.refreshBookmark()
          }
        }

        refreshBookmark()
        dispatchToMain { Notification.DidChangeDocument.post() }
      }
    }
  }

  /// Used as lock for synchronized access to `_currentDocument`
  static private let currentDocumentLock = NSObject()

  static private(set) var currentDocument: Document? {
    get {
      return synchronized(currentDocumentLock) { _currentDocument }
//      objc_sync_enter(currentDocumentLock)
//      defer { objc_sync_exit(currentDocumentLock) }
//      return _currentDocument
    }
    set {
      synchronized(currentDocumentLock) { _currentDocument = newValue }
//      objc_sync_enter(currentDocumentLock)
//      defer { objc_sync_exit(currentDocumentLock) }
//      _currentDocument = newValue
    }
  }

  // MARK: - Items

  /** updateStorageLocation */
//  static private func updateStorageLocation() {
//    let bookmarkData: NSData?
//    switch (SettingsManager.iCloudStorage, storageLocation) {
//      case (true, .Local), (true, .iCloud) where state ∌ .Initialized:
//        storageLocation = .iCloud
//        state ∪= [.GatheringMetadataItems]
//        metadataQuery.startQuery()
//        directoryMonitor.stopMonitoring()
//        bookmarkData = SettingsManager.currentDocumentiCloud
//      case (false, .iCloud), (false, .Local) where state ∌ .Initialized:
//        storageLocation = .Local
//        metadataQuery.stopQuery()
//        refreshLocalItems()
//        directoryMonitor.startMonitoring()
//        bookmarkData = SettingsManager.currentDocumentLocal
//      default:
//        bookmarkData = nil
//    }
//
//    switch (bookmarkData, Sequencer.initialized) {
//      case (nil, _): return
//      case (let data?, true):
//        do { try openBookmarkedDocument(data) }
//        catch { logError(error, message: "Failed to resolve bookmark data into a valid file url") }
//      case (let data?, false):
//        receptionist.observe(notification: .DidUpdateAvailableSoundSets, from: Sequencer.self) {
//          _ in
//          receptionist.stopObserving(notification: .DidUpdateAvailableSoundSets, from: Sequencer.self)
//          queue.async {
//            do {
//              try openBookmarkedDocument(data)
//            } catch {
//              logError(error, message: "Failed to resolve bookmark data into a valid file url")
//            }
//          }
//        }
//    }
//  }

  static private(set) var storageLocation: StorageLocation! {
    didSet {
      guard let storageLocation = storageLocation where storageLocation != oldValue else { return }

      let bookmarkData: NSData?

      switch storageLocation {
        case .iCloud:
          state ∪= [.GatheringMetadataItems]
          metadataQuery.startQuery()
          directoryMonitor.stopMonitoring()
          bookmarkData = SettingsManager.currentDocumentiCloud

        case .Local:
          metadataQuery.stopQuery()
          refreshLocalItems()
          directoryMonitor.startMonitoring()
          bookmarkData = SettingsManager.currentDocumentLocal

      }

      let openData = {
        (data: NSData) -> Void in
          queue.async {
            do {
              try openBookmarkedDocument(data)
            } catch {
              logError(error, message: "Failed to resolve bookmark data into a valid file url")
              switch storageLocation {
                case .iCloud: SettingsManager.currentDocumentiCloud = nil
                case .Local: SettingsManager.currentDocumentLocal = nil
              }
            }
          }
      }

      switch (bookmarkData, Sequencer.initialized) {
        case (nil, _): return
        case (let data?, true):
          openData(data)
        case (let data?, false):
          receptionist.observeOnce(notification: .DidUpdateAvailableSoundSets, from: Sequencer.self) {
            _ in openData(data)
          }
      }
    }
  }

  private static func didChangeStorage(notification: NSNotification) {
    logDebug("observed notification of iCloud storage setting change")
    storageLocation = SettingsManager.iCloudStorage ? .iCloud : .Local
  }

  /// Accessor for the current collection of document items
  static var items: [DocumentItem] {
    guard let storageLocation = storageLocation else { return [] }
    return storageLocation == .iCloud ? metadataItems : localItems
  }

  static private var updateNotificationItems: [DocumentItem] = []

  /// Monitor for observing changes to local files
  private static let directoryMonitor: DirectoryMonitor = {
    let monitor = try! DirectoryMonitor(directoryURL: documentsURL) {
      _, _ in DocumentManager.refreshLocalItems()
    }
    monitor.callbackQueue = operationQueue
    return monitor
  }()

  /// Query for iCloud file discovery
  private static let metadataQuery: NSMetadataQuery = {
    let query = NSMetadataQuery()
    query.notificationBatchingInterval = 1
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.operationQueue = queryQueue
    return query
  }()

  /// Callback for `NSMetadataQueryDidFinishGatheringNotification`
  private static func didGatherMetadataItems(notification: NSNotification) {
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

  /// Callback for `NSMetadataQueryDidUpdateNotification`
  private static func didUpdateMetadataItems(notification: NSNotification) {
    logDebug("observed metadata query update notification")
    var items = metadataItems
    if let removed = notification.removedMetadataItems?.map(DocumentItem.init) { items ∖= removed }
    if let added   = notification.addedMetadataItems?.map(DocumentItem.init)   { items += added   }
    metadataItems = items
  }

  /// Collection of `DocumentItem` instances for available iCloud documents
  static private(set) var metadataItems: [DocumentItem] = [] {
    didSet {
      guard storageLocation == .iCloud else { return }
      postItemUpdateNotification(metadataItems)
    }
  }

  /// Collection of `DocumentItem` instances for available local documents
  static private(set) var localItems: [DocumentItem] = [] {
    didSet {
      guard storageLocation == .Local && localItems.elementsEqual(oldValue) else { return }
      postItemUpdateNotification(localItems)
    }
  }

  /**
  postItemNotificationWithItems:oldItems:

  - parameter items: [DocumentItem]
  - parameter oldItems: [DocumentItem]
  */
  static private func postItemUpdateNotification(items: [DocumentItem]) {
    defer { updateNotificationItems = items }

    logDebug("items: \(items.map(({$0.displayName})))")
    guard updateNotificationItems != items else { logDebug("no change…"); return }

    let removed = updateNotificationItems ∖ items
    let added = items ∖ updateNotificationItems

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

  private static let receptionist = NotificationReceptionist(callbackQueue: DocumentManager.operationQueue)

  // MARK: - Creating new documents

  private static let DefaultDocumentName = "AwesomeSauce"

  /** createNewFile */
  static func createNewDocument(name: String? = nil) {
    guard let storageLocation = storageLocation else {
      logWarning("Cannot create a new document without a valid storage location")
      return
    }

    queue.async {

      let url: NSURL

      switch storageLocation {

        case .iCloud:
          guard let baseURL = NSFileManager().URLForUbiquityContainerIdentifier(nil) else {
            fatalError("\(#function) requires that the iCloud drive is available to use iCloud storage")
          }
          url = baseURL + "Documents"

        case .Local:
          url = documentsURL

      }

      guard let fileName = noncollidingFileName(name ?? DefaultDocumentName) else { return }
      let fileURL = url + ["\(fileName).groove"]
      logDebug("creating a new document at path '\(fileURL.path!)'")
      let document = Document(fileURL: fileURL)
      document.saveToURL(fileURL, forSaveOperation: .ForCreating, completionHandler: {
        guard $0 else { return }
        dispatchToMain {
          Notification.DidCreateDocument.post(userInfo: [Notification.Key.FilePath: fileURL.path!])
          DocumentManager.openDocument(document)
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

  - parameter document: Document
  */
  static func openDocument(document: Document) {
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
      receptionist.observe(notification: .DidUpdateAvailableSoundSets, from: Sequencer.self, queue: operationQueue) {
        _ in
        receptionist.stopObserving(notification: .DidUpdateAvailableSoundSets, from: Sequencer.self)
        openBlock()
      }
    }
  }

  /**
  openURL:

  - parameter url: NSURL
  */
  static func openURL(url: NSURL) { openDocument(Document(fileURL: url)) }

  /**
  openBookmarkedDocument:

  - parameter data: NSData?
  */
  static private func openBookmarkedDocument(data: NSData) throws {
    let url = try NSURL(byResolvingBookmarkData: data,
                        options: .WithoutUI,
                        relativeToURL: nil,
                        bookmarkDataIsStale: nil)
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
      let coordinator = NSFileCoordinator(filePresenter: nil)
      coordinator.coordinateWritingItemAtURL(item.URL, options: .ForDeleting, error: nil) {
        do { try NSFileManager().removeItemAtURL($0) }
        catch { logError(error) }
      }
    }
  }

}

extension DocumentManager {
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

extension DocumentManager {
  enum StorageLocation { case iCloud, Local }
}

// MARK: - Error
extension DocumentManager {

  enum Error: String, ErrorType {
    case iCloudUnavailable
  }

}

// MARK: - Notification
extension DocumentManager: NotificationDispatchType {

  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateItems, WillChangeDocument, DidChangeDocument, DidCreateDocument
    case WillOpenDocument, DidOpenDocument
    enum Key: String, NotificationKeyType { case Changed, Added, Removed, FilePath }
    var object: AnyObject? { return DocumentManager.self }
  }
  
}

extension NSNotification {
  var addedItemsData: [NSData]? {
    return userInfo?[DocumentManager.Notification.Key.Added.key] as? [NSData]
  }
  var removedItemsData: [NSData]? {
    return userInfo?[DocumentManager.Notification.Key.Removed.key] as? [NSData]
  }
  var addedItems: [DocumentItem]?   { return addedItemsData?.flatMap(DocumentItem.init)   }
  var removedItems: [DocumentItem]? { return removedItemsData?.flatMap(DocumentItem.init) }
}