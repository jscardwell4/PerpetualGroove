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

  static func initialize() {

    queue.async {

      guard state ∌ .Initialized else { return }

      receptionist.logContext = LogManager.MIDIFileContext

      receptionist.observe(name: SettingsManager.NotificationName.iCloudStorageChanged.rawValue,
                           from: SettingsManager.self,
                           callback: DocumentManager.didChangeStorage)

      receptionist.observe(name: NSNotification.Name.NSMetadataQueryDidFinishGathering.rawValue,
                           from: metadataQuery,
                           callback: DocumentManager.didGatherMetadataItems)

      receptionist.observe(name: NSNotification.Name.NSMetadataQueryDidUpdate.rawValue,
                           from: metadataQuery,
                           callback: DocumentManager.didUpdateMetadataItems)

      storageLocation = SettingsManager.iCloudStorage ? .iCloud : .local

      state ∪= [.Initialized]

    }

  }
  
  // MARK: - Queues

  /// Queue for document manipulations
  static let queue = DispatchQueue(label: "DocumentManager", attributes: .concurrent)

  /// Operation queue that dispatches to `queue`
  static let operationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.name = "DocumentManager"
    operationQueue.underlyingQueue = queue
    return operationQueue
  }()

  /// Operation queue for metadata queries
  fileprivate static let queryQueue: OperationQueue = {
    let queryQueue = OperationQueue()
    queryQueue.name = "DocumentManager.MetadataQuery"
    queryQueue.maxConcurrentOperationCount = 1
    return queryQueue
  }()


  // MARK: - Tracking state
  fileprivate static var state: State = [] {
    didSet {
      logDebug("\(oldValue) ➞ \(state)")

      guard state.symmetricDifference(oldValue) ∋ .OpeningDocument else { return }
      dispatchToMain {
        postNotification(name: openingDocument ? .willOpenDocument : .didOpenDocument,
                         object: self,
                         userInfo: nil)
      }
    }
  }

  static var openingDocument: Bool { return state ∋ .OpeningDocument }
  static var gatheringMetadataItems: Bool { return state ∋ .GatheringMetadataItems }

  // MARK: - The currently open document

  /// Updates contents of bookmark data for storage relevant setting
  static fileprivate func refreshBookmark() {
    queue.async {
      guard let currentDocument = currentDocument else { return }
        do {
          let bookmark = try currentDocument.fileURL.bookmarkData(options: .suitableForBookmarkFile,
                                                                  includingResourceValuesForKeys: nil,
                                                                  relativeTo: nil)
          switch currentDocument.storageLocation {
            case .iCloud: SettingsManager.currentDocumentiCloud = bookmark
            case .local: SettingsManager.currentDocumentLocal = bookmark
          }
          logDebug("bookmark refreshed for '\(currentDocument.localizedName)'")
        } catch {
          logError(error, message: "Failed to generate bookmark data for storage")
        }
    }
  }

  /// Receptionist for KVO of the current document
  fileprivate static let observer = KVOReceptionist()

  static fileprivate var _currentDocument: Document? {

    willSet {
      guard _currentDocument != newValue else { return }
      dispatchToMain { postNotification(name: .willChangeDocument, object: self, userInfo: nil) }
    }

    didSet {
      queue.async {
        logDebug("currentDocument: \(_currentDocument == nil ? "nil" : _currentDocument!.localizedName)")

        guard oldValue != _currentDocument else { return }

        if let oldValue = oldValue {
          logDebug("closing document '\(oldValue.localizedName)'")
          observer.stopObserving(oldValue, forChangesTo: "fileURL")
          oldValue.close(completionHandler: nil)
        }

        if let currentDocument = _currentDocument {
          observer.observe(currentDocument, forChangesTo: "fileURL", queue: operationQueue) {
            _, _, _ in
            logDebug("observed change to file URL of current document")
            DocumentManager.refreshBookmark()
          }
        }

        refreshBookmark()
        dispatchToMain { postNotification(name: .didChangeDocument, object: self, userInfo: nil) }
      }

    }

  }

  /// Used as lock for synchronized access to `_currentDocument`
  static fileprivate let currentDocumentLock = NSObject()

  static fileprivate(set) var currentDocument: Document? {
    get { return synchronized(currentDocumentLock) { _currentDocument } }
    set { synchronized(currentDocumentLock) { _currentDocument = newValue } }
  }

  // MARK: - Items

  static fileprivate(set) var storageLocation: StorageLocation! {
    didSet {
      guard let storageLocation = storageLocation , storageLocation != oldValue else { return }

      let bookmarkData: Data?

      switch storageLocation {
        case .iCloud:
          state ∪= [.GatheringMetadataItems]
          metadataQuery.start()
          directoryMonitor.stopMonitoring()
          bookmarkData = SettingsManager.currentDocumentiCloud as Data?

        case .local:
          metadataQuery.stop()
          refreshLocalItems()
          directoryMonitor.startMonitoring()
          bookmarkData = SettingsManager.currentDocumentLocal as Data?

      }

      let openData = {
        (data: Data) -> Void in
          queue.async {
            do {
              try openBookmarkedDocument(data)
            } catch {
              logError(error, message: "Failed to resolve bookmark data into a valid file url")
              switch storageLocation {
                case .iCloud: SettingsManager.currentDocumentiCloud = nil
                case .local: SettingsManager.currentDocumentLocal = nil
              }
            }
          }
      }

      switch (bookmarkData, Sequencer.initialized) {
        case (nil, _): return
        case (let data?, true):
          openData(data)
        case (let data?, false):
          receptionist.observeOnce(name: Sequencer.NotificationName.didUpdateAvailableSoundSets.rawValue,
                                   from: Sequencer.self) { _ in openData(data) }
      }
    }
  }

  fileprivate static func didChangeStorage(_ notification: Foundation.Notification) {
    logDebug("observed notification of iCloud storage setting change")
    storageLocation = SettingsManager.iCloudStorage ? .iCloud : .local
  }

  /// Accessor for the current collection of document items
  static var items: OrderedSet<DocumentItem> {
    guard let storageLocation = storageLocation else { return [] }
    return storageLocation == .iCloud ? metadataItems : localItems
  }

  static fileprivate var updateNotificationItems: OrderedSet<DocumentItem> = []

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
  private static func didGatherMetadataItems(_ notification: Notification) {
    logDebug("observed notification metadata query has finished gathering")

    guard state ∋ .GatheringMetadataItems else {
      logWarning("received gathering notification but state does not contain gathering flag")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = OrderedSet(metadataQuery.results.flatMap(as: NSMetadataItem.self, DocumentItem.metaData))
    metadataQuery.enableUpdates()
    state ∆= .GatheringMetadataItems
  }

  /// Callback for `NSMetadataQueryDidUpdateNotification`
  private static func didUpdateMetadataItems(_ notification: Notification) {
    logDebug("observed metadata query update notification")

    var itemsDidChange = false

    if let removed = notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem] {
      metadataItems ∖= removed.flatMap(DocumentItem.metaData)
      itemsDidChange = true
    }

    if let added = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem] {
      metadataItems ∪= added.flatMap(DocumentItem.metaData)
      itemsDidChange = true
    }

    guard itemsDidChange else { return }

    postUpdateNotification(for: metadataItems)
  }

  /// Collection of `DocumentItem` instances for available iCloud documents
  static fileprivate(set) var metadataItems: OrderedSet<DocumentItem> = []
//    {
//    didSet {
//      guard storageLocation == .iCloud else { return }
//      postUpdateNotification(for: metadataItems)
//    }
//  }

  /// Collection of `DocumentItem` instances for available local documents
  static fileprivate(set) var localItems: OrderedSet<DocumentItem> = [] {
    didSet {
      guard storageLocation == .local && localItems.elementsEqual(oldValue) else { return }
      postUpdateNotification(for: localItems)
    }
  }

  static fileprivate func postUpdateNotification(for items: OrderedSet<DocumentItem>) {
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

    var userInfo: [String:Any] = [:]
    if removed.count > 0 { userInfo["removed"] = removed.map({$0.data}) }
    if added.count > 0 { userInfo["added"] = added.map({$0.data}) }

    guard userInfo.count > 0 else { return }

    logDebug("posting 'DidUpdateItems'")
    dispatchToMain { postNotification(name: .didUpdateItems, object: self, userInfo: userInfo) }

  }

  static fileprivate func refreshLocalItems() {
    guard let fileWrappers = directoryMonitor.directoryWrapper.fileWrappers?.values else {
      return
    }
    let localDocumentItems: [LocalDocumentItem] = fileWrappers.flatMap {
      [directory = directoryMonitor.directoryURL] in
        guard let name = $0.preferredFilename else { return nil }
        return try? LocalDocumentItem(url: directory + name)
      }
    localItems = OrderedSet(localDocumentItems.map(DocumentItem.local))
  }

  fileprivate static let receptionist = NotificationReceptionist(callbackQueue: DocumentManager.operationQueue)

  /// Document name to use when a name has not been specified.
  fileprivate static let DefaultDocumentName = "AwesomeSauce"

  /// Creates a new document, optionally with the specified `name`.
  static func createNewDocument(name: String? = nil) {

    guard let storageLocation = storageLocation else {
      logWarning("Cannot create a new document without a valid storage location")
      return
    }

    queue.async {

      let url: URL

      switch storageLocation {

        case .iCloud:
          guard let baseURL = FileManager().url(forUbiquityContainerIdentifier: nil) else {
            fatalError("\(#function) requires that the iCloud drive is available to use iCloud storage")
          }
          url = baseURL + "Documents"

        case .local:
          url = documentsURL

      }

      let fileName = noncollidingFileName(for: name ?? DefaultDocumentName)
      let fileURL = url + ["\(fileName).groove"]
      logDebug("creating a new document at path '\(fileURL.path)'")
      let document = Document(fileURL: fileURL)
      document.save(to: fileURL, for: .forCreating) {
        guard $0 else { return }
        dispatchToMain {
          postNotification(name: .didCreateDocument, object: self, userInfo: ["filePath": fileURL.path])
          DocumentManager.open(document: document)
        }
      }
    }

  }

  /// Returns an available file name based on `fileName`.
  static func noncollidingFileName(for fileName: String) -> String {

    var (baseName, ext) = fileName.baseNameExt

    if ext.isEmpty { ext = "groove" }


    let url: URL

    switch SettingsManager.iCloudStorage {

      case true:
        guard let baseURL = FileManager().url(forUbiquityContainerIdentifier: nil) else {
          fatalError("Use iCloud setting is true but failed to get ubiquity container")
        }
        url = baseURL + "Documents"

      case false:
        url = documentsURL

    }

    guard (try? (url + "\(baseName).\(ext)").checkResourceIsReachable()) == true else {
      return fileName
    }


    var i = 2
    while (try? (url + "\(baseName)\(i).\(ext)").checkPromisedItemIsReachable()) == true {
      i += 1
    }

    return "\(baseName)\(i).\(ext)"
  }

  // MARK: - Opening documents

  /// Opens the specified document.
  static func open(document: Document) {
    let openBlock = {
      guard state ∌ .OpeningDocument else { logWarning("already opening a document"); return }
      logDebug("opening document '\(document.fileURL.path)'")
      state.formSymmetricDifference(.OpeningDocument)
      document.open {
        guard $0  else {
          logError("failed to open document: \(document)")
          return
        }
        guard state ∋ .OpeningDocument else {
          logError("internal inconsistency, expected state to contain `OpeningDocument`")
          return
        }
        currentDocument = document
        state.formSymmetricDifference(.OpeningDocument)
      }
    }
    if Sequencer.soundSets.count > 0 { queue.async(execute: openBlock) }
    else {
      receptionist.observe(name: Sequencer.NotificationName.didUpdateAvailableSoundSets.rawValue,
                           from: Sequencer.self,
                           queue: operationQueue)
      {
        _ in
        receptionist.stopObserving(name: Sequencer.NotificationName.didUpdateAvailableSoundSets.rawValue,
                                   from: Sequencer.self)
        openBlock()
      }
    }
  }

  /// Opens the document pointed to by `url`.
  static func open(url: URL) { open(document: Document(fileURL: url)) }

  /// Opens the document referenced by a bookmark.
  static fileprivate func openBookmarkedDocument(_ data: Data) throws {
    let url = try (NSURL(resolvingBookmarkData: data,
                        options: .withoutUI,
                        relativeTo: nil,
                        bookmarkDataIsStale: nil) as URL)
    logDebug("opening bookmarked file at path '\(url.path)'")
    open(url: url)

  }

  /// Opens the document specified by `item`.
  static func open(item: DocumentItem) { open(url: item.url) }


  /// Deletes th document specified by `item`.
  static func delete(item: DocumentItem) {

    queue.async {

      let itemURL = item.url

      // Does this create race condition with closing of file?
      if currentDocument?.fileURL.isEqualToFileURL(itemURL as URL) == true { currentDocument = nil }

      logDebug("removing item '\(item.displayName)'")
      let coordinator = NSFileCoordinator(filePresenter: nil)
      coordinator.coordinate(writingItemAt: itemURL as URL, options: .forDeleting, error: nil) {
        url in
        do { try FileManager.withDefaultManager { try $0.removeItem(at: url) } }
        catch { logError(error) }
      }
    }
  }

}

extension DocumentManager {

  fileprivate struct State: OptionSet {
    let rawValue: Int

    static let Initialized            = State(rawValue: 0b0001)
    static let OpeningDocument        = State(rawValue: 0b0010)
    static let GatheringMetadataItems = State(rawValue: 0b0100)
  }

}

extension DocumentManager.State: CustomStringConvertible {

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

// MARK: - StorageLocation

extension DocumentManager {

  enum StorageLocation {
    case iCloud, local
  }

}

// MARK: - Error
extension DocumentManager {

  enum Error: String, Swift.Error {
    case iCloudUnavailable
  }

}

// MARK: - Notification
extension DocumentManager: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didUpdateItems, willChangeDocument, didChangeDocument, didCreateDocument
    case willOpenDocument, didOpenDocument

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }
  
}

extension Notification {

  var addedItemsData: [AnyObject]? { return userInfo?["added"] as? [AnyObject] }
  var removedItemsData: [AnyObject]? { return userInfo?["removed"] as? [AnyObject] }
  var addedItems: [DocumentItem]?   { return addedItemsData?.flatMap(DocumentItem.init)   }
  var removedItems: [DocumentItem]? { return removedItemsData?.flatMap(DocumentItem.init) }

}
