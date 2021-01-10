//
//  DocumentManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Foundation
import MoonKit
import os
import Sequencer

// MARK: - Shorthand

/// The singleton instance of `DocumentManager`.
public let documentManager = DocumentManager()

// MARK: - Logging

/// A logger for internal use by the `Documents` framework.
internal let log = os.Logger(subsystem: "com.moondeerstudios.groove.documents",
                             category: "Documents")

// MARK: - DocumentManager

/// A Singleton whose job is to coordinate all file/document operations.
public final class DocumentManager
{
  // MARK: Stored Properties

  /// Concurrent queue for manipulating documents and the underlying queue
  /// for `operationQueue`.
  internal let queue = DispatchQueue(label: "com.groove.documents",
                                     attributes: .concurrent)

  /// `OperationQueue` wrapper for `queue`.
  internal let operationQueue: OperationQueue

  /// Holds state information such as whether a document is being opened
  /// or metadata items are being gathered.
  private var state: State = []
  {
    didSet
    {
      logi("\(String(describing: oldValue)) ➞ \(String(describing: self.state))")

      // Check that the `openingDocument` flag has changed.
      guard state ∆ oldValue ∋ .openingDocument else { return }

      // Post an appopriate notification.
      postNotification(name: isOpeningDocument
                        ? .managerWillOpenDocument
                        : .managerDidOpenDocument,
                       object: self)
    }
  }

  /// Holds subscription to published `fileURL` changes of `_currentDocument`.
  private var fileURLSubscription: Cancellable?

  /// The document to which the active sequence belongs.
  @Published public var currentDocument: Document?
  {
    didSet
    {
      guard oldValue != currentDocument else { return }

      queue.async
      { [self] in

        logi("currentDocument: \(currentDocument?.localizedName ?? "nil")")

        if let oldValue = oldValue
        {
          logi("closing document '\(oldValue.localizedName)'")
          oldValue.close(completionHandler: nil)
          fileURLSubscription = nil
        }

        if let currentDocument = currentDocument
        {
          // Observe the new document and update the bookmark data in settings.
          fileURLSubscription = currentDocument.publisher(for: \.fileURL)
            .sink
            {
              [weak currentDocument] (_: URL) in
              logi("observed change to file URL of current document")
              currentDocument?.storageLocation.currentDocument = currentDocument!
            }

          currentDocument.storageLocation.currentDocument = currentDocument
        }
      }
    }
  }

  /// The location from which files are retrieved, created, and saved.
  public private(set) var activeStorageLocation: StorageLocation = .local
  {
    didSet
    {
      switch activeStorageLocation
      {
        case .iCloud
              where state ∌ .gatheringMetadataItems && directoryMonitor.isMonitoring:
          directoryMonitor.stopMonitoring()
          fallthrough

        case .iCloud where state ∌ .gatheringMetadataItems:

          state ∪= .gatheringMetadataItems
          metadataQuery.operationQueue?.addOperation { [self] in metadataQuery.start() }

        case .local
              where state ∋ .gatheringMetadataItems && !directoryMonitor.isMonitoring:
          metadataQuery.operationQueue?.addOperation { [self] in metadataQuery.stop() }
          fallthrough

        case .local where !directoryMonitor.isMonitoring:
          refreshLocalItems()
          do
          {
            try directoryMonitor.startMonitoring()
          }
          catch
          {
            loge("\(error as NSObject)")
            fatalError("Failed to begin monitoring local directory")
          }

        default: break
      }
    }
  }

  /// Cache of the previous set of items for which a notification was posted.
  private var updateNotificationItems: OrderedSet<DocumentItem> = []

  /// Monitor for observing changes to local files.
  private let directoryMonitor: DirectoryMonitor

  /// Query for iCloud file discovery.
  private let metadataQuery: NSMetadataQuery

  /// Collection of `DocumentItem` instances for available iCloud documents
  public private(set) var metadataItems: OrderedSet<DocumentItem> = []

  /// Collection of `DocumentItem` instances for available local documents
  public private(set) var localItems: OrderedSet<DocumentItem> = []

  /// Document name to use when a name has not been specified.
  private static let defaultDocumentName = "AwesomeSauce"

  // MARK: Initializing

  /// Subscription for `iCloudStorageChanged` notifications.
  private var iCloudStorageChangedNotificationSubscription: Cancellable?
  /// Subscription for `didFinishGathering` notifications.
  private var didFinishGatheringNotificationSubscription: Cancellable?
  /// Subscription for `didUpdate` notifications.
  private var didUpdateNotificationSubscription: Cancellable?

  /// The default initializer.
  fileprivate init()
  {
    let operationQueue = OperationQueue()
    operationQueue.name = "com.groove.documentmanager"
    operationQueue.underlyingQueue = queue

    self.operationQueue = operationQueue

    guard let url = StorageLocation.local.root
    else
    {
      fatalError("Failed to obtain local root directory")
    }

    do
    {
      let monitor = try DirectoryMonitor(directoryURL: url)
      {
        documentManager.didUpdateLocalItems(added: $0, removed: $1)
      }
      monitor.callbackQueue = operationQueue

      directoryMonitor = monitor
    }
    catch
    {
      loge("\(error as NSObject)")
      fatalError("Failed to initialize monitor for local directory.")
    }

    let query = NSMetadataQuery()
    query.notificationBatchingInterval = 1
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]

    let queryQueue = OperationQueue()
    queryQueue.name = "come.groove.documentmanager.metadataquery"
    queryQueue.maxConcurrentOperationCount = 1
    query.operationQueue = queryQueue

    metadataQuery = query

    didFinishGatheringNotificationSubscription = NotificationCenter.default
      .publisher(for: .NSMetadataQueryDidFinishGathering, object: metadataQuery)
      .sink { self.didGatherMetadataItems(notification: $0) }

    didUpdateNotificationSubscription = NotificationCenter.default
      .publisher(for: .NSMetadataQueryDidUpdate, object: metadataQuery)
      .sink { self.didUpdateMetadataItems(notification: $0) }

    iCloudStorageChangedNotificationSubscription = UserDefaults.standard
      .publisher(for: \.iCloudStorage)
      .sink
      {
        [self] preferCloud in
        logi("observed notification of iCloud storage setting change")

        guard (activeStorageLocation == .iCloud) ^ preferCloud else { return }

        activeStorageLocation = preferredStorageLocation

        openCurrentDocument(for: activeStorageLocation)
      }

    activeStorageLocation = preferredStorageLocation
    openCurrentDocument(for: activeStorageLocation)
  }

  // MARK: Computed Properties

  /// Whether a document is currently being opened.
  public var isOpeningDocument: Bool { state ∋ .openingDocument }

  /// Whether metadata items are currently being gathered.
  public var isGatheringMetadataItems: Bool { state ∋ .gatheringMetadataItems }

  /// The location to use as specified in user preferences.
  public var preferredStorageLocation: StorageLocation
  {
    settings.iCloudStorage ? .iCloud : .local
  }

  /// Accessor for the current collection of document items: `metadataItems`
  /// when `activeStorageLocation == .iCloud` and `localItems` otherwise.
  public var items: OrderedSet<DocumentItem>
  {
    activeStorageLocation == .iCloud ? metadataItems : localItems
  }

  // MARK: Creating Documents

  /// Creates a new document, optionally with the specified `name`. If `name`
  /// is unavailable, it will be used to derive an available file name.
  public func createNewDocument(name: String? = nil)
  {
    queue.async
    { [self] in
      let name = noncollidingFileName(for: name ?? DocumentManager.defaultDocumentName)

      guard let fileURL = activeStorageLocation.root + "\(name).groove" else { return }

      logi("creating a new document at path '\(fileURL.path)'")

      let document = Document(fileURL: fileURL)

      document.save(to: fileURL, for: .forCreating)
      {
        success in

        guard success else { return }

        postNotification(name: .managerDidCreateDocument,
                         object: self,
                         userInfo: ["filePath": fileURL.path])
        dispatchToMain { self.open(document: document) }
      }
    }
  }

  /// Returns an available file name based on `fileName`.
  public func noncollidingFileName(for fileName: String) -> String
  {
    var (baseName, ext) = fileName.baseNameExt

    if ext.isEmpty { ext = "groove" }

    // Check that there is a collision.
    guard let directoryURL = activeStorageLocation.root,
          (try? (directoryURL + "\(baseName).\(ext)").checkResourceIsReachable()) == true
    else
    {
      return fileName
    }

    // Iterate through file names formed by appending an integer to the original
    // until a non-colliding name is found.
    var i = 2
    while (try? (directoryURL + "\(baseName)\(i).\(ext)")
            .checkPromisedItemIsReachable()) == true
    {
      i += 1
    }

    return "\(baseName)\(i).\(ext)"
  }

  // MARK: Deleting Documents

  /// Asynchronously deletes the document at `item.url`.
  public func delete(item: DocumentItem)
  {
    queue.async
    { [self] in
      let itemURL = item.url

      // Does this create race condition with closing of file?
      if currentDocument?.fileURL.isEqualToFileURL(itemURL) == true
      {
        currentDocument = nil
      }

      logi("removing item '\(item.name)'")

      let coordinator = NSFileCoordinator(filePresenter: nil)

      coordinator.coordinate(writingItemAt: itemURL as URL,
                             options: .forDeleting,
                             error: nil)
      {
        url in

        do
        {
          try FileManager.default.removeItem(at: url)
        }
        catch
        {
          // Simply log the error since we cannot throw.
          loge("\(error as NSObject)")
        }
      }
    }
  }

  // MARK: Opening Documents

  /// Performs the actual opening of `document`.
  private func _open(document: Document)
  {
    // Check that a document is not already in the process of being opened.
    guard state ∌ .openingDocument
    else
    {
      logw("already opening a document")
      return
    }

    logi("opening document '\(document.fileURL.path)'")

    // Update flag.
    state ∆= .openingDocument

    // Open the document.
    document.open
    { [self]
      success in

      guard success else { loge("failed to open document: \(document)"); return }

      guard state ∋ .openingDocument
      else
      {
        loge("internal inconsistency, expected state to contain `openingDocument`")
        return
      }

      currentDocument = document

      state ∆= .openingDocument
    }
  }

  /// If the sequencer has already initialized, the document is opened; otherwise,
  /// the document will be opened after notification has been received that the
  /// sequencer has initialized.
  public func open(document: Document)
  {
    queue.async { [self] in _open(document: document) }
  }

  /// Initializes a new `Document` instance using the url resolved from `data`.
  private func resolveBookmarkData(_ data: Data) throws -> (document: Document,
                                                            isStale: Bool)
  {
    guard let name = URL.resourceValues(forKeys: [.localizedNameKey],
                                        fromBookmarkData: data)?.localizedName
    else
    {
      logw("Unable to retrieve localized name from bookmark data…")
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

  /// Opens the document bookmarked as current for `location` when non-nil.
  private func openCurrentDocument(for location: StorageLocation)
  {
    // Ensure there is a document to open.
    guard let document = location.currentDocument else { return }

    open(document: document)
  }

  // MARK: Storage

  //  /// Handler for changes to the preferred storage location.
  //  ///
  //  /// - Parameter preferCloud: Whether settings indicate iCloud is preferred location.
  //  private func didChangeStorage(preferCloud: Bool)
  //  {
  //    logi("observed notification of iCloud storage setting change")
  //
  //    guard (activeStorageLocation == .iCloud) ^ preferCloud else { return }
  //
  //    activeStorageLocation = preferredStorageLocation
  //
  //    openCurrentDocument(for: activeStorageLocation)
  //  }

  // MARK: Metadata Items

  /// Handler for metadata query notifications. Runs on `metadataQuery.operationQueue`.
  private func didGatherMetadataItems(notification: Notification)
  {
    logi("observed notification metadata query has finished gathering")

    guard state ∋ .gatheringMetadataItems
    else
    {
      logw("received gathering notification but flag is not set.")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = OrderedSet(metadataQuery.results.flatMap(as: NSMetadataItem.self,
                                                             DocumentItem.metaData))
    metadataQuery.enableUpdates()

    state ∆= .gatheringMetadataItems
  }

  /// Callback for `NSMetadataQueryDidUpdateNotification`
  private func didUpdateMetadataItems(notification: Notification)
  {
    logi("observed metadata query update notification")

    var itemsDidChange = false

    if let removed = notification.removedMetadataItems?.compactMap(DocumentItem.metaData)
    {
      metadataItems ∖= removed
      itemsDidChange = true
    }

    if let added = notification.addedMetadataItems?.compactMap(DocumentItem.metaData)
    {
      metadataItems ∪= added
      itemsDidChange = true
    }

    guard itemsDidChange else { return }

    postUpdateNotification(for: metadataItems)
  }

  /// Overwrites `localItems` content with items derived from the local
  /// directory's current contents.
  private func refreshLocalItems()
  {
    localItems = OrderedSet((directoryMonitor.directoryWrapper.fileWrappers ?? [:]).values
                              .compactMap
                              {
                                [directory = directoryMonitor.directoryURL] in
                                guard let name = $0.preferredFilename else { return nil }
                                return try? LocalDocumentItem(url: directory + name)
                              }.map(DocumentItem.local))
  }

  /// Handler for callbacks invoked by `directoryMonitor`.
  private func didUpdateLocalItems(added: [FileWrapper], removed: [FileWrapper])
  {
    logi("""
    updating local items directory \
    '\(self.directoryMonitor.directoryWrapper.filename ?? "nil")
    """)

    // Check we actually have some kind of change.
    guard !(added.isEmpty && removed.isEmpty) else { return }

    for wrapper in removed
    {
      guard let matchingItem = localItems.first(where: {
        guard case let .local(localItem) = $0 else { return false }
        return (localItem.displayName == wrapper.preferredFilename) == true
      })
      else
      {
        continue
      }

      localItems.remove(matchingItem)
    }

    for item in added.compactMap({ try? LocalDocumentItem($0) }).map(DocumentItem.local)
    {
      localItems.insert(item)
    }

    postUpdateNotification(for: localItems)
  }

  // MARK: Notification Posting

  /// Posts a notification with changes obtained via comparison to
  /// `updateNotificationItems`.
  private func postUpdateNotification(for items: OrderedSet<DocumentItem>)
  {
    defer { updateNotificationItems = items }

    logi("items: \(items.map(({ $0.name })))")

    guard updateNotificationItems != items
    else
    {
      logi("no change…")
      return
    }

    let removed = updateNotificationItems ∖ items
    let added = items ∖ updateNotificationItems

    logi("""
    \(!removed.isEmpty ? "removed: \(removed)" : "")\
    \(!added.isEmpty ? (!removed.isEmpty ? "\nadded: \(added)" : "added: \(added)") : "")
    """)

    var userInfo: [String: Any] = [:]

    if !removed.isEmpty { userInfo["removed"] = removed }

    if !added.isEmpty { userInfo["added"] = added }

    guard !userInfo.isEmpty else { return }

    logi("posting 'didUpdateItems'")

    postNotification(name: .managerDidUpdateItems,
                     object: self,
                     userInfo: userInfo)
  }
}

// MARK: - Manager.State

public extension DocumentManager
{
  /// Structure for storing `Manager` state.
  struct State: OptionSet
  {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Set while the manager is opening a document.
    public static let openingDocument = State(rawValue: 0b0010)

    /// Set while the manager is querying for iCloud documents.
    public static let gatheringMetadataItems = State(rawValue: 0b0100)
  }
}

// MARK: - Manager.StorageLocation

public extension DocumentManager
{
  /// An enumeration for working with local and cloud-based document storage locations.
  enum StorageLocation
  {
    /// The document is cloud-based.
    case iCloud

    /// The document is located on the local disk.
    case local

    /// Initialize according to the ubiquity of the item at a specified location.
    ///
    /// - Parameter url: The storage location.
    public init(url: URL)
    {
      self = FileManager.default.isUbiquitousItem(at: url) ? .iCloud : .local
    }

    /// Accessor for the bookmark data associated with the storage location.
    public var bookmarkData: Data?
    {
      self == .iCloud ? settings.currentDocumentiCloud : settings.currentDocumentLocal
    }

    /// The root directory for stored document files.
    public var root: URL?
    {
      switch self
      {
        case .iCloud:
          return FileManager.default.url(forUbiquityContainerIdentifier: nil) + "Documents"

        case .local:
          return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      }
    }

    /// Accessors for the document pointed to by the bookmark stored by
    /// the location's setting.
    public var currentDocument: Document?
    {
      get
      {
        guard let data = bookmarkData else { return nil }

        do
        {
          let (document, isStale) = try documentManager.resolveBookmarkData(data)

          if isStale
          {
            switch self
            {
              case .iCloud:
                settings.currentDocumentiCloud = document.bookmarkData
              case .local:
                settings.currentDocumentLocal = document.bookmarkData
            }
          }

          return document
        }
        catch
        {
          loge("\(error as NSObject)")
          switch self
          {
            case .iCloud:
              settings.currentDocumentiCloud = nil
            case .local:
              settings.currentDocumentLocal = nil
          }

          return nil
        }
      }

      nonmutating set
      {
        switch self
        {
          case .iCloud:
            settings.currentDocumentiCloud = newValue?.bookmarkData
          case .local:
            settings.currentDocumentLocal = newValue?.bookmarkData
        }
      }
    }
  }
}

// MARK: - Manager.Error

public extension DocumentManager
{
  /// Enumeration of the possible errors thrown by `Manager`.
  enum Error: String, Swift.Error
  {
    /// Thrown when attempting to use iCloud but it is unavailable.
    case iCloudUnavailable

    /// Thrown when provided with invalid bookmark data.
    case invalidBookmarkData
  }
}

// MARK: NotificationDispatching

extension DocumentManager: NotificationDispatching
{
  public static let didUpdateItemsNotification =
    Notification.Name("didUpdateItems")

  public static let didCreateDocumentNotification =
    Notification.Name("didCreateDocument")

  public static let willChangeDocumentNotification =
    Notification.Name("willChangeDocument")

  public static let didChangeDocumentNotification =
    Notification.Name("didChangeDocument")

  public static let willOpenDocumentNotification =
    Notification.Name("willOpenDocument")

  public static let didOpenDocumentNotification =
    Notification.Name("didOpenDocument")
}

public extension Notification.Name
{
  static let managerDidUpdateItems = DocumentManager.didUpdateItemsNotification
  static let managerDidCreateDocument = DocumentManager.didCreateDocumentNotification
  static let managerWillChangeDocument = DocumentManager.willChangeDocumentNotification
  static let managerDidChangeDocument = DocumentManager.didChangeDocumentNotification
  static let managerWillOpenDocument = DocumentManager.willOpenDocumentNotification
  static let managerDidOpenDocument = DocumentManager.didOpenDocumentNotification
}

public extension Notification
{
  /// The document items added for a `Manager` `didUpdateItems` notification or `nil`.
  var addedItems: OrderedSet<DocumentItem>?
  {
    userInfo?["added"] as? OrderedSet<DocumentItem>
  }

  /// The document items removed for a `Manager` `didUpdateItems` notification or `nil`.
  var removedItems: OrderedSet<DocumentItem>?
  {
    userInfo?["removed"] as? OrderedSet<DocumentItem>
  }
}
