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

      guard state ∌ .initialized else { return }

      receptionist.observe(name: .iCloudStorageChanged,
                           from: SettingsManager.self,
                           callback: DocumentManager.didChangeStorage)

      receptionist.observe(name: .didFinishGathering,
                           from: metadataQuery,
                           queue: queryQueue,
                           callback: DocumentManager.didGatherMetadataItems)

      receptionist.observe(name: .didUpdate,
                           from: metadataQuery,
                           queue: queryQueue,
                           callback: DocumentManager.didUpdateMetadataItems)

      storageLocation = SettingsManager.iCloudStorage ? .iCloud : .local

      state ∪= [.initialized]

    }

  }
  
  // MARK: - Queues

  /// Queue for document manipulations
  static let queue = DispatchQueue(label: "com.groove.documentmanager", attributes: .concurrent)

  /// Operation queue that dispatches to `queue`
  static let operationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.name = "com.groove.documentmanager"
    operationQueue.underlyingQueue = queue
    return operationQueue
  }()

  /// Operation queue for metadata queries
  fileprivate static let queryQueue: OperationQueue = {
    let queryQueue = OperationQueue()
    queryQueue.name = "come.groove.documentmanager.metadataquery"
    queryQueue.maxConcurrentOperationCount = 1
    return queryQueue
  }()


  // MARK: - Tracking state
  fileprivate static var state: State = [] {
    didSet {
      Log.debug("\(oldValue) ➞ \(state)")

      guard state.symmetricDifference(oldValue) ∋ .openingDocument else { return }
      dispatchToMain {
        postNotification(name: openingDocument ? .willOpenDocument : .didOpenDocument,
                         object: self,
                         userInfo: nil)
      }
    }
  }

  static var openingDocument: Bool { return state ∋ .openingDocument }
  static var gatheringMetadataItems: Bool { return state ∋ .gatheringMetadataItems }

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
          Log.debug("bookmark refreshed for '\(currentDocument.localizedName)'")
        } catch {
          Log.error(error, message: "Failed to generate bookmark data for storage")
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
        Log.debug("currentDocument: \(_currentDocument == nil ? "nil" : _currentDocument!.localizedName)")

        guard oldValue != _currentDocument else { return }

        if let oldValue = oldValue {
          Log.debug("closing document '\(oldValue.localizedName)'")
          observer.stopObserving(oldValue, forChangesTo: "fileURL")
          oldValue.close(completionHandler: nil)
        }

        if let currentDocument = _currentDocument {
          observer.observe(currentDocument, forChangesTo: "fileURL", queue: operationQueue) {
            _, _, _ in
            Log.debug("observed change to file URL of current document")
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
          state ∪= [.gatheringMetadataItems]
          queryQueue.addOperation { metadataQuery.start() }
          directoryMonitor.stopMonitoring()
          bookmarkData = SettingsManager.currentDocumentiCloud as Data?

        case .local:
          queryQueue.addOperation { metadataQuery.stop() }
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
              Log.error(error, message: "Failed to resolve bookmark data into a valid file url")
              switch storageLocation {
                case .iCloud: SettingsManager.currentDocumentiCloud = nil
                case .local: SettingsManager.currentDocumentLocal = nil
              }
            }
          }
      }

      switch (bookmarkData, Sequencer.initialized) {

        case (nil, _):
          // Nothing to do.
          return

        case (let data?, true):
          // Open the data.
          openData(data)

        case (let data?, false):
          // Open the data once `Sequencer` has initialized.
          receptionist.observeOnce(name: .didUpdateAvailableSoundSets, from: Sequencer.self) {
            _ in openData(data)

        }

      }

    }

  }

  fileprivate static func didChangeStorage(_ notification: Notification) {
    Log.debug("observed notification of iCloud storage setting change")
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
    Log.debug("observed notification metadata query has finished gathering")

    guard state ∋ .gatheringMetadataItems else {
      Log.warning("received gathering notification but state does not contain gathering flag")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = OrderedSet(metadataQuery.results.flatMap(as: NSMetadataItem.self, DocumentItem.metaData))
    metadataQuery.enableUpdates()
    state ∆= .gatheringMetadataItems
  }

  /// Callback for `NSMetadataQueryDidUpdateNotification`
  private static func didUpdateMetadataItems(_ notification: Notification) {
    Log.debug("observed metadata query update notification")

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

  /// Collection of `DocumentItem` instances for available local documents
  static fileprivate(set) var localItems: OrderedSet<DocumentItem> = [] {
    didSet {
      guard storageLocation == .local && localItems.elementsEqual(oldValue) else { return }
      postUpdateNotification(for: localItems)
    }
  }

  static fileprivate func postUpdateNotification(for items: OrderedSet<DocumentItem>) {

    defer { updateNotificationItems = items }

    Log.debug("items: \(items.map(({$0.displayName})))")
    guard updateNotificationItems != items else { Log.debug("no change…"); return }

    let removed = updateNotificationItems ∖ items
    let added = items ∖ updateNotificationItems

    Log.debug({
      guard removed.count + added.count > 0 else { return "" }
      var string = ""
      if removed.count > 0 { string += "removed: \(removed)" }
      if added.count > 0 { if !string.isEmpty { string += "\n" }; string += "added: \(added)" }
      return string
      }())

    var userInfo: [String:Any] = [:]

    if removed.count > 0 {
      userInfo["removed"] = removed.map({$0.data})
    }

    if added.count > 0 {
      userInfo["added"] = added.map({$0.data})
    }

    guard userInfo.count > 0 else { return }

    Log.debug("posting 'didUpdateItems'")

    dispatchToMain { postNotification(name: .didUpdateItems, object: self, userInfo: userInfo) }

  }

  /// Updates `localItems` from `directoryMonitor.directoryWrapper`.
  static fileprivate func refreshLocalItems() {

    Log.debug("updating local items from directory '\(directoryMonitor.directoryWrapper.filename ?? "nil")")

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

  fileprivate static let receptionist = NotificationReceptionist(callbackQueue: operationQueue)

  /// Document name to use when a name has not been specified.
  fileprivate static let defaultDocumentName = "AwesomeSauce"

  /// Creates a new document, optionally with the specified `name`.
  static func createNewDocument(name: String? = nil) {

    guard let storageLocation = storageLocation else {
      Log.warning("Cannot create a new document without a valid storage location")
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

      let fileName = noncollidingFileName(for: name ?? defaultDocumentName)
      let fileURL = url + ["\(fileName).groove"]
      Log.debug("creating a new document at path '\(fileURL.path)'")
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

  private static func _open(document: Document) {

    guard state ∌ .openingDocument else {
      Log.warning("already opening a document")
      return
    }

    Log.debug("opening document '\(document.fileURL.path)'")

    state.formSymmetricDifference(.openingDocument)

    document.open {
      success in

      guard success else {
        Log.error("failed to open document: \(document)")
        return
      }

      guard state ∋ .openingDocument else {
        Log.error("internal inconsistency, expected state to contain `openingDocument`")
        return
      }

      currentDocument = document

      state.formSymmetricDifference(.openingDocument)

    }

  }

  /// Opens the specified document.
  static func open(document: Document) {
    if Sequencer.soundSets.count > 0 {
      queue.async(execute: {_open(document: document)})
    } else {
      receptionist.observe(name: .didUpdateAvailableSoundSets, from: Sequencer.self, queue: operationQueue) {
        _ in
        receptionist.stopObserving(name: .didUpdateAvailableSoundSets, from: Sequencer.self)
        queue.async(execute: {_open(document: document)})
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
    Log.debug("opening bookmarked file at path '\(url.path)'")
    open(url: url)

  }

  /// Opens the document specified by `item`.
  static func open(item: DocumentItem) { open(url: item.url) }


  /// Deletes th document specified by `item`.
  static func delete(item: DocumentItem) {

    queue.async {

      let itemURL = item.url

      // Does this create race condition with closing of file?
      if currentDocument?.fileURL.isEqualToFileURL(itemURL) == true { currentDocument = nil }

      Log.debug("removing item '\(item.displayName)'")

      let coordinator = NSFileCoordinator(filePresenter: nil)

      coordinator.coordinate(writingItemAt: itemURL as URL, options: .forDeleting, error: nil) {
        url in
        do {
          try FileManager.default.removeItem(at: url)
        } catch {
          Log.error(error)
        }
      }

    }

  }

}

extension DocumentManager {

  fileprivate struct State: OptionSet {
    let rawValue: Int

    static let initialized            = State(rawValue: 0b0001)
    static let openingDocument        = State(rawValue: 0b0010)
    static let gatheringMetadataItems = State(rawValue: 0b0100)
  }

}

extension DocumentManager.State: CustomStringConvertible {

  var description: String {
    var result = "["
    var flagStrings: [String] = []
    if contains(.initialized)            { flagStrings.append("initialized")            }
    if contains(.openingDocument)        { flagStrings.append("openingDocument")        }
    if contains(.gatheringMetadataItems) { flagStrings.append("gatheringMetadataItems") }
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

extension NSMetadataQuery: NotificationDispatching {

  public enum NotificationName: LosslessStringConvertible {

    case didStartGathering, gatheringProgress, didFinishGathering, didUpdate

    public init?(_ description: String) {
      switch description {
      case NSNotification.Name.NSMetadataQueryDidStartGathering.rawValue:
        self = .didStartGathering
      case NSNotification.Name.NSMetadataQueryGatheringProgress.rawValue:
        self = .gatheringProgress
      case NSNotification.Name.NSMetadataQueryDidFinishGathering.rawValue:
        self = .didFinishGathering
      case NSNotification.Name.NSMetadataQueryDidUpdate.rawValue:
        self = .didUpdate
      default:
        return nil
      }
    }

    public var description: String {
      switch self {
        case .didStartGathering:
          return NSNotification.Name.NSMetadataQueryDidStartGathering.rawValue
        case .gatheringProgress:
          return NSNotification.Name.NSMetadataQueryGatheringProgress.rawValue
        case .didFinishGathering:
          return NSNotification.Name.NSMetadataQueryDidFinishGathering.rawValue
        case .didUpdate:
          return NSNotification.Name.NSMetadataQueryDidUpdate.rawValue
      }
    }

  }

}

extension Notification {

  var addedItemsData: [Any]? { return userInfo?["added"] as? [Any] }
  var removedItemsData: [Any]? { return userInfo?["removed"] as? [Any] }

  var addedItems: [DocumentItem]?   { return addedItemsData?.flatMap(DocumentItem.init)   }
  var removedItems: [DocumentItem]? { return removedItemsData?.flatMap(DocumentItem.init) }

}
