//
//  Manager.swift
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

internal let log = os.Logger(subsystem: "com.moondeerstudios.groove.documents",
                             category: "Documents")

// MARK: - Manager

/// A Singleton whose job is to coordinate all file/document operations.
public final class Manager: NotificationDispatching
{
  // MARK: Stored Properties

  /// The shared singleton instance of `Manager`.
  public static let shared = Manager()

  /// Concurrent queue for manipulating documents and the underlying queue
  /// for `operationQueue`.
  public let queue = DispatchQueue(label: "com.groove.documents",
                                   attributes: .concurrent)

  /// `OperationQueue` wrapper for `queue`.
  public let operationQueue: OperationQueue

  /// Holds state information such as whether a document is being opened
  /// or metadata items are being gathered.
  private var state: State = []
  {
    didSet
    {
      log.info("\(oldValue) ➞ \(self.state)")

      // Check that the `openingDocument` flag has changed.
      guard state ∆ oldValue ∋ .openingDocument else { return }

      // Post an appopriate notification.
      postNotification(name: isOpeningDocument ? .willOpenDocument : .didOpenDocument,
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

        log.info("currentDocument: \(currentDocument?.localizedName ?? "nil")")

        if let oldValue = oldValue
        {
          log.info("closing document '\(oldValue.localizedName)'")
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
              log.info("observed change to file URL of current document")
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

        case .local where state ∋ .gatheringMetadataItems && !directoryMonitor.isMonitoring:
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
            log.error("\(error as NSObject)")
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

  /// Receptionist for receiving settings and metadata query related updates.
  private let receptionist: NotificationReceptionist

  /// Document name to use when a name has not been specified.
  private static let defaultDocumentName = "AwesomeSauce"

  // MARK: Initializing

  // TODO: Reimplement setting and query notification monitoring.

  /// The default initializer.
  private init()
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
        Manager.shared.didUpdateLocalItems(added: $0, removed: $1)
      }
      monitor.callbackQueue = operationQueue

      directoryMonitor = monitor
    }
    catch
    {
      log.error("\(error as NSObject)")
      fatalError("Failed to initialize monitor for local directory.")
    }

    receptionist = NotificationReceptionist(callbackQueue: operationQueue)

    let query = NSMetadataQuery()

    query.notificationBatchingInterval = 1

    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]

    let queryQueue = OperationQueue()
    queryQueue.name = "come.groove.documentmanager.metadataquery"
    queryQueue.maxConcurrentOperationCount = 1
    query.operationQueue = queryQueue

    metadataQuery = query

    //      receptionist.observe(name: .iCloudStorageChanged, from: SettingsManager.self,
    //                           callback: Manager.didChangeStorage)
    //
    //      receptionist.observe(name: .didFinishGathering, from: metadataQuery,
    //                           callback: Manager.didGatherMetadataItems)
    //
    //      receptionist.observe(name: .didUpdate, from: metadataQuery,
    //                           callback: Manager.didUpdateMetadataItems)

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
    SettingsManager.shared.iCloudStorage ? .iCloud : .local
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
      let name = noncollidingFileName(for: name ?? Manager.defaultDocumentName)

      guard let fileURL = activeStorageLocation.root + "\(name).groove" else { return }

      log.info("creating a new document at path '\(fileURL.path)'")

      let document = Document(fileURL: fileURL)

      document.save(to: fileURL, for: .forCreating)
      {
        success in

        guard success else { return }

        dispatchToMain
        { [self] in
          postNotification(name: .didCreateDocument,
                           object: self,
                           userInfo: ["filePath": fileURL.path])

          open(document: document)
        }
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

      log.info("removing item '\(item.name)'")

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
          log.error("\(error as NSObject)")
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
      log.warning("already opening a document")
      return
    }

    log.info("opening document '\(document.fileURL.path)'")

    // Update flag.
    state ∆= .openingDocument

    // Open the document.
    document.open
    { [self]
      success in

      guard success else { log.error("failed to open document: \(document)"); return }

      guard state ∋ .openingDocument
      else
      {
        log.error("internal inconsistency, expected state to contain `openingDocument`")
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
      log.warning("Unable to retrieve localized name from bookmark data…")
      throw Error.invalidBookmarkData
    }

    var isStale = false
    let url = try URL(resolvingBookmarkData: data,
                      options: .withoutUI,
                      relativeTo: nil,
                      bookmarkDataIsStale: &isStale)

    log.info("resolved bookmark data for '\(name)'")

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

  /// Handler for changes to the preferred storage location.
  private func didChangeStorage(_: Notification)
  {
    log.info("observed notification of iCloud storage setting change")

    guard preferredStorageLocation != activeStorageLocation else { return }

    activeStorageLocation = preferredStorageLocation

    openCurrentDocument(for: activeStorageLocation)
  }

  // MARK: Metadata Items

  /// Handler for metadata query notifications. Runs on `metadataQuery.operationQueue`.
  private func didGatherMetadataItems(_: Notification)
  {
    log.info("observed notification metadata query has finished gathering")

    guard state ∋ .gatheringMetadataItems
    else
    {
      log.warning("received gathering notification but flag is not set.")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = OrderedSet(metadataQuery.results.flatMap(as: NSMetadataItem.self,
                                                             DocumentItem.metaData))
    metadataQuery.enableUpdates()

    state ∆= .gatheringMetadataItems
  }

  /// Callback for `NSMetadataQueryDidUpdateNotification`
  private func didUpdateMetadataItems(_ notification: Notification)
  {
    log.info("observed metadata query update notification")

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

  /// Overwrites `localItems` content with items derived from the local directory's current contents.
  private func refreshLocalItems()
  {
    localItems = OrderedSet((directoryMonitor.directoryWrapper.fileWrappers ?? [:]).values.compactMap
    {
      [directory = directoryMonitor.directoryURL] in
      guard let name = $0.preferredFilename else { return nil }
      return try? LocalDocumentItem(url: directory + name)
    }.map(DocumentItem.local))
  }

  /// Handler for callbacks invoked by `directoryMonitor`.
  private func didUpdateLocalItems(added: [FileWrapper], removed: [FileWrapper])
  {
    log.info("""
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

  /// Posts a notification with changes obtained via comparison to `updateNotificationItems`.
  private func postUpdateNotification(for items: OrderedSet<DocumentItem>)
  {
    defer { updateNotificationItems = items }

    log.info("items: \(items.map(({ $0.name })))")

    guard updateNotificationItems != items
    else
    {
      log.info("no change…")
      return
    }

    let removed = updateNotificationItems ∖ items
    let added = items ∖ updateNotificationItems

    log.info("""
      \(!removed.isEmpty ? "removed: \(removed)" : "")\
      \(!added.isEmpty ? (!removed.isEmpty ? "\nadded: \(added)" : "added: \(added)") : "")
      """
    )

    var userInfo: [String: Any] = [:]

    if !removed.isEmpty { userInfo["removed"] = removed }

    if !added.isEmpty { userInfo["added"] = added }

    guard !userInfo.isEmpty else { return }

    log.info("posting 'didUpdateItems'")

    dispatchToMain
    { [self] in
      postNotification(name: .didUpdateItems, object: self, userInfo: userInfo)
    }
  }

  /// Structure for storing `Manager` state.
  private struct State: OptionSet, CustomStringConvertible
  {
    let rawValue: Int

    static let openingDocument = State(rawValue: 0b0010)
    static let gatheringMetadataItems = State(rawValue: 0b0100)

    var description: String
    {
      var result = "["

      var flagStrings: [String] = []

      if contains(.openingDocument)
      {
        flagStrings.append("openingDocument")
      }
      if contains(.gatheringMetadataItems)
      {
        flagStrings.append("gatheringMetadataItems")
      }

      result += ", ".join(flagStrings)
      result += "]"

      return result
    }
  }

  /// Type for specifying whether files are retrieved/saved from/to local disk or iCloud.
  public enum StorageLocation
  {
    case iCloud, local

    /// Initialize by deriving the value according to the ubiquity of the item at `url`.
    public init(url: URL)
    {
      self = FileManager.default.isUbiquitousItem(at: url) ? .iCloud : .local
    }

    /// Current document setting associated with the storage location.
    public var bookmarkData: Data?
    {
      switch self
      {
        case .iCloud: return SettingsManager.shared.currentDocumentiCloud
        case .local: return SettingsManager.shared.currentDocumentLocal
      }
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

    /// Accessors for the document pointed to by the bookmark stored by the location's setting.
    public var currentDocument: Document?
    {
      get
      {
        guard let data = bookmarkData else { return nil }

        do
        {
          let (document, isStale) = try Manager.shared.resolveBookmarkData(data)

          if isStale
          {
            switch self
            {
              case .iCloud:
                SettingsManager.shared.currentDocumentiCloud = document.bookmarkData
              case .local:
                SettingsManager.shared.currentDocumentLocal = document.bookmarkData
            }
          }

          return document
        }
        catch
        {
          log.error("\(error as NSObject)")
          switch self
          {
            case .iCloud:
              SettingsManager.shared.currentDocumentiCloud = nil
            case .local:
              SettingsManager.shared.currentDocumentLocal = nil
          }

          return nil
        }
      }

      nonmutating set
      {
        switch self
        {
          case .iCloud:
            SettingsManager.shared.currentDocumentiCloud = newValue?.bookmarkData
          case .local:
            SettingsManager.shared.currentDocumentLocal = newValue?.bookmarkData
        }
      }
    }
  }

  /// Enumeration of the possible errors thrown by `Manager`.
  public enum Error: String, Swift.Error
  {
    case iCloudUnavailable, invalidBookmarkData
  }

  /// Enumeration for the names of notifications posted by `Manager`.
  public enum NotificationName: String, LosslessStringConvertible
  {
    case didUpdateItems
    case didCreateDocument
    case willChangeDocument, didChangeDocument
    case willOpenDocument, didOpenDocument

    public var description: String { rawValue }

    public init?(_ description: String) { self.init(rawValue: description) }
  }
}

// MARK: - NSMetadataQuery + NotificationDispatching

extension NSMetadataQuery: NotificationDispatching
{
  /// Enumeration shadowing the metadata query related values of type `NSNotification.Name`.
  public enum NotificationName: LosslessStringConvertible
  {
    case didStartGathering, gatheringProgress, didFinishGathering, didUpdate

    public init?(_ description: String)
    {
      switch description
      {
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

    public var description: String
    {
      switch self
      {
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
