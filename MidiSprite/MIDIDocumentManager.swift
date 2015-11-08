//
//  MIDIDocumentManager.swift
//  MidiSprite
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

      receptionist.observe(SettingsManager.Notification.Name.iCloudStorageChanged, from: SettingsManager.self) {
        _ in iCloudStorage = SettingsManager.iCloudStorage
      }

      receptionist.observe(NSMetadataQueryDidFinishGatheringNotification,
                      from: metadataQuery,
                  callback: MIDIDocumentManager.didGatherMetadataItems)

      receptionist.observe(NSMetadataQueryDidUpdateNotification,
                      from: metadataQuery,
                  callback: MIDIDocumentManager.didUpdateMetadataItems)

      if let data = SettingsManager.currentDocument {
        do {
          let url = try NSURL(byResolvingBookmarkData: data, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: nil)
          logDebug("opening bookmarked file at path '\(String(CString: url.fileSystemRepresentation, encoding: NSUTF8StringEncoding)!)'")
          openURL(url)
        } catch {
          logError(error, message: "Failed to resolve bookmark data into a valid file url")
          SettingsManager.currentDocument = nil
        }
      } else {
        createNewDocument()
      }

      if let fileWrappers = directoryMonitor.directoryWrapper.fileWrappers?.values {
        let directory = directoryMonitor.directoryURL
        localItems = fileWrappers.flatMap({
          guard let name = $0.preferredFilename else { return nil }
          return try? LocalDocumentItem(directory + name)
        })
      }

      if iCloudStorage {
        metadataQuery.startQuery()
        state ∪= [.Initialized, .GatheringMetadataItems]
      } else {
        directoryMonitor.startMonitoring()
        state ∪= [.Initialized]
      }
      logDebug("files: \(directoryMonitor.directoryWrapper.fileWrappers!.map({$1.preferredFilename!}))")
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
  private static var state: State = [] { didSet { logDebug("\(oldValue) ➞ \(state)") } }

  static var openingDocument: Bool { return state ∋ .OpeningDocument }
  static var gatheringMetadataItems: Bool { return state ∋ .GatheringMetadataItems }

  // MARK: - The currently open document

  /** refreshBookmark */
  static private func refreshBookmark() {
    queue.async {
      guard let currentDocument = currentDocument else { return }
        do {
          SettingsManager.currentDocument = try currentDocument.fileURL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                                                 includingResourceValuesForKeys: nil,
                                                                                  relativeToURL: nil)
          logDebug("bookmark refreshed for '\(currentDocument.localizedName)'")
        } catch {
          logError(error, message: "Failed to generate bookmark data for storage")
        }
    }
  }

  private static let observer = KVOReceptionist()

  static private var _currentDocument: MIDIDocument? {
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

  private static var iCloudStorage = SettingsManager.iCloudStorage {
    didSet {
      guard oldValue != iCloudStorage else { return }
      logDebug("iCloudStorage: \(iCloudStorage)")
      switch iCloudStorage {
        case true:
          metadataQuery.startQuery()
          directoryMonitor.stopMonitoring()
        case false:
          metadataQuery.stopQuery()
          directoryMonitor.startMonitoring()
      }
      items = currentItems()
    }
  }

  /**
  currentItems

  - returns: [DocumentItem]
  */
  static private func currentItems() -> [DocumentItem] {
    return iCloudStorage ? metadataItems.map({DocumentItem($0)}) : localItems.map({DocumentItem($0)})
  }

  static private(set) var items: [DocumentItem] = [] {
    didSet {
      guard oldValue != items else { return }

      let removed = oldValue ∖ items
      let added = items ∖ oldValue

      logDebug("removed: \(removed); added: \(added)")

      var userInfo: [Notification.Key:AnyObject?] = [:]
      if removed.count > 0 { userInfo[Notification.Key.Removed] = removed.map({$0.data}) }
      if added.count > 0 { userInfo[Notification.Key.Added] = added.map({$0.data}) }

      guard userInfo.count > 0 else { return }

      logDebug("posting 'DidUpdateItems'")
      dispatchToMain { Notification.DidUpdateItems.post(object: self, userInfo: userInfo) }
    }
  }

  private static let directoryMonitor: DirectoryMonitor = {
    let monitor = try! DirectoryMonitor(directoryURL: documentsURL,
                                        callback: MIDIDocumentManager.directoryContentsChanged)
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

  static private(set) var metadataItems: [NSMetadataItem] = [] {
    didSet { items = currentItems() }
  }

  static private(set) var localItems: [LocalDocumentItem] = [] {
    didSet { items = currentItems() }
  }

  static private var metadataItemsDescription: String {
    return "metadataItems:\n\("\n\n".join(metadataItems.map({$0.attributesDescription.indentedBy(4)})))"
  }

  // MARK: - Receiving notifications

  private static let receptionist = NotificationReceptionist(callbackQueue: MIDIDocumentManager.operationQueue)

  /**
  directoryContentsChanged:

  - parameter monitor: DirectoryMonitor
  */
  private static func directoryContentsChanged(added: [String], removed: [String]) {
    logDebug("\n".join(
      "files: \(directoryMonitor.directoryWrapper.fileWrappers!.map({$1.preferredFilename!}))",
      "added: \(added)",
      "removed: \(removed)"
      ))
    if let fileWrappers = directoryMonitor.directoryWrapper.fileWrappers?.values {
      let directory = directoryMonitor.directoryURL
      localItems = fileWrappers.flatMap({
        guard let name = $0.preferredFilename else { return nil }
        return try? LocalDocumentItem(directory + name)
      })
    }
  }

  /**
  didUpdateMetadataItems:

  - parameter notification: NSNotification
  */
  private static func didUpdateMetadataItems(notification: NSNotification) {
    var items = metadataItems
    if let removed = notification.removedMetadataItems { items ∖= removed }
    if let added = notification.addedMetadataItems { items += added }
    guard items.count != metadataItems.count else { return }
    metadataItems = items
  }

  /**
  didGatherMetadataItems:

  - parameter notificaiton: NSNotification
  */
  private static func didGatherMetadataItems(notification: NSNotification) {
    guard state ∋ .GatheringMetadataItems else {
      logWarning("received gathering notification but state does not contain gathering flag")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = metadataQuery.results as! [NSMetadataItem]
    metadataQuery.enableUpdates()
    logDebug(metadataItemsDescription)
    state ⊻= .GatheringMetadataItems
  }

  // MARK: - Creating new documents

  private static let DefaultDocumentName = "AwesomeSauce"

  /** createNewFile */
  static func createNewDocument() {

    queue.async {

      let url: NSURL

      switch SettingsManager.iCloudStorage {

        case true:
          guard let baseURL = NSFileManager().URLForUbiquityContainerIdentifier(nil) else {
            fatalError("createNewDocument() requires that the iCloud drive is available when the iCloud storage flag is set")
          }
          url = baseURL + "Documents"

        case false:
          url = documentsURL

      }

      guard let fileName = noncollidingFileName(DefaultDocumentName) else { return }
      let fileURL = url + ["\(fileName).midi"]
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
    if extʹ.isEmpty { extʹ = "midi" }


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
      baseNameʹ = "\(baseName)\(i++)"
    }

    return "\(baseNameʹ)" + (ext.isEmpty ? "" : ".\(ext)")
  }

  // MARK: - Opening documents

  /**
  openDocument:

  - parameter document: MIDIDocument
  */
  static func openDocument(document: MIDIDocument) {
    queue.async {
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
  }

  /**
  openURL:

  - parameter url: NSURL
  */
  static func openURL(url: NSURL) { openDocument(MIDIDocument(fileURL: url)) }

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

// MARK: - Error
extension MIDIDocumentManager {

  enum Error: String, ErrorType {
    case iCloudUnavailable
  }

}

// MARK: - Notification
extension MIDIDocumentManager {

  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateItems, DidChangeDocument, DidCreateDocument
    enum Key: String, NotificationKeyType { case Changed, Added, Removed, FilePath }
    var object: AnyObject? { return MIDIDocumentManager.self }
  }
  
}

extension NSNotification {
  var addedItems: [DocumentItem]? {
    guard let dataSet = userInfo?[MIDIDocumentManager.Notification.Key.Added.key] as? [NSData] else { return nil }
    return dataSet.map({DocumentItem($0)!})
  }
  var removedItems: [DocumentItem]? {
    guard let dataSet = userInfo?[MIDIDocumentManager.Notification.Key.Removed.key] as? [NSData] else { return nil }
    return dataSet.map({DocumentItem($0)!})
  }
}