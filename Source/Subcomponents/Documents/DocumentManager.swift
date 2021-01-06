//
//  DocumentManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import Common
import Sequencer

/// A Singleton whose job is to coordinate all file/document operations within the application.
public final class DocumentManager: NotificationDispatching {

  /// Asynchronously registers for notifications and updates `storageLocation`.
  public static func initialize() {

    queue.async {

      guard state ∌ .initialized else { return }

//      receptionist.observe(name: .iCloudStorageChanged, from: SettingsManager.self,
//                           callback: DocumentManager.didChangeStorage)
//
//      receptionist.observe(name: .didFinishGathering, from: metadataQuery,
//                           callback: DocumentManager.didGatherMetadataItems)
//
//      receptionist.observe(name: .didUpdate, from: metadataQuery,
//                           callback: DocumentManager.didUpdateMetadataItems)

      activeStorageLocation = preferredStorageLocation
      openCurrentDocument(for: activeStorageLocation)

      state ∪= [.initialized]

    }

  }

  /// Queue for manipulating documents and the underlying queue for `operationQueue`.
  public static let queue = DispatchQueue(label: "com.groove.documentmanager", attributes: .concurrent)

  /// `OperationQueue` wrapper for `queue`.
  public static let operationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.name = "com.groove.documentmanager"
    operationQueue.underlyingQueue = queue
    return operationQueue
  }()

  /// Indicates whether `DocumentManager` has been intialized, a document is being opened 
  /// or metadata items are being gathered.
  private static var state: State = [] {
    didSet {
      logi("\(oldValue) ➞ \(state)")

      // Check that the `openingDocument` flag has changed.
      guard state ∆ oldValue ∋ .openingDocument else { return }

      // Post an appopriate notification.
      dispatchToMain {
        postNotification(name: isOpeningDocument ? .willOpenDocument : .didOpenDocument, object: self)
      }
    }
  }

  /// Whether a document is currently being opened.
  public static var isOpeningDocument: Bool { return state ∋ .openingDocument }

  /// Whether metadata items are currently being gathered.
  public static var isGatheringMetadataItems: Bool { return state ∋ .gatheringMetadataItems }

  /// Receptionist for KVO of the current document
  private static let observer = KVOReceptionist()

  /// The document to which the active sequence belongs.
  static private var _currentDocument: Document? {

    willSet {

      guard _currentDocument != newValue else { return }

      dispatchToMain { postNotification(name: .willChangeDocument, object: self) }

    }

    didSet {

      queue.async {

        logi("currentDocument: \(_currentDocument == nil ? "nil" : _currentDocument!.localizedName)")

        guard oldValue != _currentDocument else { return }

        let keyPath = #keyPath(Document.fileURL)

        if let oldValue = oldValue {
          // Stop observing and close the old document

          logi("closing document '\(oldValue.localizedName)'")

          observer.stopObserving(object: oldValue, forChangesTo: keyPath)

          oldValue.close(completionHandler: nil)

        }

        if let currentDocument = _currentDocument {
          // Observe the new document and update the bookmark data in settings.

          observer.observe(object: currentDocument, forChangesTo: keyPath, queue: operationQueue) {
            _, object, _ in

            guard let document = object as? Document else {
              fatalError("Expected object to be of type `Document`.")
            }

            logi("observed change to file URL of current document")

            document.storageLocation.currentDocument = document

          }

          currentDocument.storageLocation.currentDocument = currentDocument

        }

        dispatchToMain { postNotification(name: .didChangeDocument, object: self) }

      }

    }

  }

  /// Used as lock for synchronized access to `_currentDocument`
  static private let currentDocumentLock = NSObject()

  /// Exposed accessors for `_currentDocument`.
  static private(set) var currentDocument: Document? {
    get {
      objc_sync_enter(currentDocumentLock)
      defer { objc_sync_exit(currentDocumentLock) }
      return _currentDocument
    }
    set {
      objc_sync_enter(currentDocumentLock)
      _currentDocument = newValue
      objc_sync_exit(currentDocumentLock)
    }
  }

  /// Opens the document bookmarked as current for `location` when non-nil.
  static private func openCurrentDocument(for location: StorageLocation) {

//    guard Sequencer.isInitialized else {
//      // Proceed once `Sequencer` has initialized.
//
//      receptionist.observeOnce(name: .didUpdateAvailableSoundFonts, from: Sequencer.self) {
//        _ in openCurrentDocument(for: location)
//      }
//
//      return
//
//    }

    // Ensure there is a document to open.
    guard let document = location.currentDocument else { return }

    open(document: document)

  }

  /// The location from which files are retrieved, created, and saved.
  static public private(set) var activeStorageLocation: StorageLocation = .local {

    didSet {

      switch activeStorageLocation {

        case .iCloud where state ∌ .gatheringMetadataItems && directoryMonitor.isMonitoring:
          directoryMonitor.stopMonitoring()
          fallthrough

        case .iCloud where state ∌ .gatheringMetadataItems:

          state ∪= .gatheringMetadataItems
          metadataQuery.operationQueue?.addOperation { metadataQuery.start() }

        case .local where state ∋ .gatheringMetadataItems && !directoryMonitor.isMonitoring:
          metadataQuery.operationQueue?.addOperation { metadataQuery.stop() }
          fallthrough

        case .local where !directoryMonitor.isMonitoring:
          refreshLocalItems()
          do {
            try directoryMonitor.startMonitoring()
          } catch {
            loge("\(error)")
            fatalError("Failed to begin monitoring local directory")
          }

          default: break

      }

    }

  }

  /// The location to use as specified in user preferences.
  public static var preferredStorageLocation: StorageLocation {
    return SettingsManager.shared.iCloudStorage ? .iCloud : .local
  }

  /// Handler for changes to the preferred storage location.
  private static func didChangeStorage(_ notification: Notification) {

    logi("observed notification of iCloud storage setting change")

    guard preferredStorageLocation != activeStorageLocation else { return }

    activeStorageLocation = preferredStorageLocation

    openCurrentDocument(for: activeStorageLocation)

  }

  /// Accessor for the current collection of document items: `metadataItems` 
  /// when `activeStorageLocation == .iCloud` and `localItems` otherwise.
  public static var items: OrderedSet<DocumentItem> {
    return activeStorageLocation == .iCloud ? metadataItems : localItems
  }

  /// Cache of the previous set of items for which a notification was posted.
  static private var updateNotificationItems: OrderedSet<DocumentItem> = []

  /// Monitor for observing changes to local files.
  private static let directoryMonitor: DirectoryMonitor = {

    guard let url = StorageLocation.local.root else {
      fatalError("Failed to obtain local root directory")
    }

    do {

      let monitor = try DirectoryMonitor(directoryURL: url, callback: didUpdateLocalItems)
      monitor.callbackQueue = operationQueue

      return monitor

    } catch {

      loge("\(error)")
      fatalError("Failed to initialize monitor for local directory.")

    }

  }()

  /// Query for iCloud file discovery.
  private static let metadataQuery: NSMetadataQuery = {

    let query = NSMetadataQuery()

    query.notificationBatchingInterval = 1

    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]

    query.operationQueue = {
      let queue = OperationQueue()
      queue.name = "come.groove.documentmanager.metadataquery"
      queue.maxConcurrentOperationCount = 1
      return queue
    }()

    return query

  }()

  /// Handler for metadata query notifications. Runs on `metadataQuery.operationQueue`.
  private static func didGatherMetadataItems(_ notification: Notification) {

    logi("observed notification metadata query has finished gathering")

    guard state ∋ .gatheringMetadataItems else {
      logw("received gathering notification but state does not contain gathering flag")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = OrderedSet(metadataQuery.results.flatMap(as: NSMetadataItem.self, DocumentItem.metaData))
    metadataQuery.enableUpdates()

    state ∆= .gatheringMetadataItems

  }

  /// Callback for `NSMetadataQueryDidUpdateNotification`
  private static func didUpdateMetadataItems(_ notification: Notification) {

    logi("observed metadata query update notification")

    var itemsDidChange = false

    if let removed = notification.removedMetadataItems?.compactMap(DocumentItem.metaData) {

      metadataItems ∖= removed
      itemsDidChange = true

    }

    if let added = notification.addedMetadataItems?.compactMap(DocumentItem.metaData) {

      metadataItems ∪= added
      itemsDidChange = true

    }

    guard itemsDidChange else { return }

    postUpdateNotification(for: metadataItems)

  }

  /// Overwrites `localItems` content with items derived from the local directory's current contents.
  static private func refreshLocalItems() {

    localItems = OrderedSet((directoryMonitor.directoryWrapper.fileWrappers ?? [:] ).values.compactMap({
      [directory = directoryMonitor.directoryURL] in
      guard let name = $0.preferredFilename else { return nil }
      return try? LocalDocumentItem(url: directory + name)
    }).map(DocumentItem.local))

  }

  /// Handler for callbacks invoked by `directoryMonitor`.
  static private func didUpdateLocalItems(added: [FileWrapper], removed: [FileWrapper]) {

    logi("updating local items from directory '\(directoryMonitor.directoryWrapper.filename ?? "nil")")

    // Check we actually have some kind of change.
    guard !(added.isEmpty && removed.isEmpty) else { return }

    for wrapper in removed {

      guard let matchingItem = localItems.first(where: {
            guard case .local(let localItem) = $0 else { return false }
            return (localItem.displayName == wrapper.preferredFilename) == true
          })
        else
      {
        continue
      }

      localItems.remove(matchingItem)

    }

    for item in added.compactMap({try? LocalDocumentItem($0)}).map(DocumentItem.local) {
      localItems.insert(item)
    }

    postUpdateNotification(for: localItems)

  }

  /// Collection of `DocumentItem` instances for available iCloud documents
  static public private(set) var metadataItems: OrderedSet<DocumentItem> = []

  /// Collection of `DocumentItem` instances for available local documents
  static public private(set) var localItems: OrderedSet<DocumentItem> = []

  /// Posts a notification with changes obtained via comparison to `updateNotificationItems`.
  static private func postUpdateNotification(for items: OrderedSet<DocumentItem>) {

    defer { updateNotificationItems = items }

    logi("items: \(items.map(({$0.name})))")

    guard updateNotificationItems != items else {
      logi("no change…")
      return
    }

    let removed = updateNotificationItems ∖ items
    let added = items ∖ updateNotificationItems

    logi({
      guard removed.count + added.count > 0 else { return "" }
      var string = ""
      if removed.count > 0 { string += "removed: \(removed)" }
      if added.count > 0 { if !string.isEmpty { string += "\n" }; string += "added: \(added)" }
      return string
      }())

    var userInfo: [String:Any] = [:]

    if removed.count > 0 { userInfo["removed"] = removed }

    if added.count > 0 { userInfo["added"] = added }

    guard userInfo.count > 0 else { return }

    logi("posting 'didUpdateItems'")

    dispatchToMain {

      postNotification(name: .didUpdateItems, object: self, userInfo: userInfo)

    }

  }

  /// Receptionist for receiving settings and metadata query related updates.
  private static let receptionist = NotificationReceptionist(callbackQueue: operationQueue)

  /// Document name to use when a name has not been specified.
  private static let defaultDocumentName = "AwesomeSauce"

  /// Creates a new document, optionally with the specified `name`. If `name` is unavailable, it will be
  /// used to derive an available file name.
  public static func createNewDocument(name: String? = nil) {

    queue.async {

      let name = noncollidingFileName(for: name ?? defaultDocumentName)

      guard let fileURL = activeStorageLocation.root + "\(name).groove" else { return }

      logi("creating a new document at path '\(fileURL.path)'")

      let document = Document(fileURL: fileURL)

      document.save(to: fileURL, for: .forCreating) {
        success in

        guard success else { return }

        dispatchToMain {

          postNotification(name: .didCreateDocument, object: self, userInfo: ["filePath": fileURL.path])

          DocumentManager.open(document: document)

        }

      }
      
    }

  }

  /// Returns an available file name based on `fileName`.
  public static func noncollidingFileName(for fileName: String) -> String {

    var (baseName, ext) = fileName.baseNameExt

    if ext.isEmpty { ext = "groove" }

    // Check that there is a collision.
    guard let directoryURL = activeStorageLocation.root,
          (try? (directoryURL + "\(baseName).\(ext)").checkResourceIsReachable()) == true
      else
    {
      return fileName
    }

    // Iterate through file names formed by appending an integer to the original until a non-colliding name
    // is found.
    var i = 2
    while (try? (directoryURL + "\(baseName)\(i).\(ext)").checkPromisedItemIsReachable()) == true {
      i += 1
    }

    return "\(baseName)\(i).\(ext)"

  }

  /// Performs the actual opening of `document`.
  private static func _open(document: Document) {

    // Check that a document is not already in the process of being opened.
    guard state ∌ .openingDocument else { logw("already opening a document"); return }

    logi("opening document '\(document.fileURL.path)'")

    // Update flag.
    state ∆= .openingDocument

    // Open the document.
    document.open {
      success in

      guard success else { loge("failed to open document: \(document)"); return }

      guard state ∋ .openingDocument else {
        loge("internal inconsistency, expected state to contain `openingDocument`")
        return
      }

      currentDocument = document

      state ∆= .openingDocument

    }

  }

  /// If the sequencer has already initialized, the document is opened; otherwise, the document will be
  /// opened after notification has been received that the sequencer has initialized.
  public static func open(document: Document) {

    // Make sure sequencer has been initialized before opening the document.
//    guard Sequencer.isInitialized else {
//
//      receptionist.observeOnce(name: .didUpdateAvailableSoundFonts, from: Sequencer.self) {
//        _ in queue.async(execute: {_open(document: document)})
//      }
//
//      return
//    }

    queue.async(execute: {_open(document: document)})

  }

  /// Initializes a new `Document` instance using the url resolved from `data`.
  static private func resolveBookmarkData(_ data: Data) throws -> (document: Document, isStale: Bool) {

    guard let name = URL.resourceValues(forKeys: [.localizedNameKey],
                                        fromBookmarkData: data)?.localizedName
      else
    {
      logw("Unable to retrieve localized name from bookmark data, ignoring open request…")
      throw Error.invalidBookmarkData
    }

    var isStale = false
    let url = try URL(resolvingBookmarkData: data,
                      options: .withoutUI,
                      relativeTo: nil,
                      bookmarkDataIsStale: &isStale)

    logi("resolved bookmark data for '\(name)'")

    return (document: Document(fileURL: url), isStale: isStale)

  }

  /// Asynchronously deletes the document at `item.url`.
  public static func delete(item: DocumentItem) {

    queue.async {

      let itemURL = item.url

      // Does this create race condition with closing of file?
      if currentDocument?.fileURL.isEqualToFileURL(itemURL) == true { currentDocument = nil }

      logi("removing item '\(item.name)'")

      let coordinator = NSFileCoordinator(filePresenter: nil)

      coordinator.coordinate(writingItemAt: itemURL as URL, options: .forDeleting, error: nil) {
        url in

        do {

          try FileManager.default.removeItem(at: url)

        } catch {

          // Simply log the error since we cannot throw.
          loge("\(error)")

        }

      }

    }

  }

  /// Structure for storing `DocumentManager` state.
  private struct State: OptionSet, CustomStringConvertible {

    let rawValue: Int

    static let initialized            = State(rawValue: 0b0001)
    static let openingDocument        = State(rawValue: 0b0010)
    static let gatheringMetadataItems = State(rawValue: 0b0100)

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

  /// Type for specifying whether files are retrieved/saved from/to local disk or iCloud.
  public enum StorageLocation {

    case iCloud, local

    /// Initialize by deriving the value according to the ubiquity of the item at `url`.
    public init(url: URL) {
      self = FileManager.default.isUbiquitousItem(at: url) ? .iCloud : .local
    }

    /// Current document setting associated with the storage location.
    public var bookmarkData: Data? {
      switch self {
        case .iCloud: return SettingsManager.shared.currentDocumentiCloud
        case .local:  return SettingsManager.shared.currentDocumentLocal
      }
    }

    /// The root directory for stored document files.
    public var root: URL? {

      switch self {

        case .iCloud:
          return FileManager.default.url(forUbiquityContainerIdentifier: nil) + "Documents"

        case .local:
          return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
          
      }

    }

    /// Accessors for the document pointed to by the bookmark stored by the location's setting.
    public var currentDocument: Document? {

      get {
        fatalError("\(#function) not yet implemented.")
//        guard let data = bookmarkData else { return nil }
//
//        do {
//
//          let (document, isStale) = try DocumentManager.resolveBookmarkData(data)
//
//          if isStale { setting.value = document.bookmarkData }
//
//          return document
//
//        } catch {
//
//          loge("\(error)")
//          setting.value = nil
//
//          return nil
//
//        }

      }

      nonmutating set {
        fatalError("\(#function) not yet implemented.")
//        setting.value = newValue?.bookmarkData

      }

    }

  }  

  /// Enumeration of the possible errors thrown by `DocumentManager`.
  public enum Error: String, Swift.Error {
    case iCloudUnavailable, invalidBookmarkData
  }

  /// Enumeration for the names of notifications posted by `DocumentManager`.
  public enum NotificationName: String, LosslessStringConvertible {
    case didUpdateItems
    case didCreateDocument
    case willChangeDocument, didChangeDocument
    case willOpenDocument, didOpenDocument

    public var description: String { return rawValue }

    public init?(_ description: String) { self.init(rawValue: description) }

  }
  
}

extension NSMetadataQuery: NotificationDispatching {

  /// Enumeration shadowing the metadata query related values of type `NSNotification.Name`.
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

  /// The document items added for a `DocumentManager` `didUpdateItems` notification or `nil`.
  public var addedItems: OrderedSet<DocumentItem>? { return userInfo?["added"] as? OrderedSet<DocumentItem> }

  /// The document items removed for a `DocumentManager` `didUpdateItems` notification or `nil`.
  public var removedItems: OrderedSet<DocumentItem>? { return userInfo?["removed"] as? OrderedSet<DocumentItem> }

}
