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

  private static var state: State = [] { didSet { logDebug("\(oldValue) ➞ \(state)") } }

  static var openingDocument: Bool {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    return state ∋ .OpeningDocument
  }
  static var gatheringMetadataItems: Bool {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    return state ∋ .GatheringMetadataItems
  }

  private static let DefaultDocumentName = "AwesomeSauce"

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
        Notification.DidChangeDocument.post()
      }
    }
  }
  static private(set) var currentDocument: MIDIDocument? {
    get {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      return _currentDocument
    }
    set {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      _currentDocument = newValue
    }
  }

  static let queue: dispatch_queue_t = concurrentQueueWithLabel("MIDIDocumentManager")
  static let operationQueue: NSOperationQueue = {
    let operationQueue = NSOperationQueue(name: "MIDIDocumentManager")
    operationQueue.underlyingQueue = queue
    return operationQueue
  }()

  private static let metadataQuery: NSMetadataQuery = {
    let query = NSMetadataQuery()
    query.notificationBatchingInterval = 4
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.operationQueue = operationQueue
    return query
  }()

  static private(set) var metadataItems: OrderedSet<NSMetadataItem> = [] {
    didSet {
      logDebug("metadataItems: \(", ".join(metadataItems.map({$0.displayName})))")
    }
  }

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
        Notification.DidCreateDocument.post(userInfo: [Notification.Key.FilePath: fileURL.path!])
        MIDIDocumentManager.openDocument(document)
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
  static func openItem(item: DocumentItemType) { openURL(item.URL) }

  /**
  deleteItem:

  - parameter item: DocumentItemType
  */
  static func deleteItem(item: DocumentItemType) {

    queue.async {

      if currentDocument?.fileURL == item.URL { currentDocument = nil }

      logDebug("removing item '\(item.URL.path!)'")
      NSFileCoordinator(filePresenter: nil).coordinateWritingItemAtURL(item.URL, options: .ForDeleting, error: nil) {
        do { try NSFileManager().removeItemAtURL($0) }
        catch { logError(error) }
      }
    }
  }

  private static let observer = KVOReceptionist()

  /**
  didUpdateMetadataItems:

  - parameter notification: NSNotification
  */
  private static func didUpdateMetadataItems(notification: NSNotification) {
    var userInfo: [Notification.Key:AnyObject?] = [:]
    if let removed = notification.removedMetadataItems where !removed.isEmpty && removed ⊆ metadataItems {
      metadataItems ∖= removed
      userInfo[Notification.Key.Removed] = removed
    }

    if let changed = notification.changedMetadataItems where !changed.isEmpty && changed ⊆ metadataItems {
      userInfo[Notification.Key.Changed] = changed
    }

    if let added = notification.addedMetadataItems where !added.isEmpty && added ⊈ metadataItems {
      metadataItems ∪= added
      userInfo[Notification.Key.Added] = added
    }

    guard !userInfo.isEmpty else { return }

    logDebug(
      "".join(
        "posting notification with user info:",
        {
          guard let removed = userInfo[Notification.Key.Removed] as? [NSMetadataItem] else { return "" }
          return "\n\tremoved: \(", ".join(removed.map({$0.displayName})))"
        }(),
        {
          guard let changed = userInfo[Notification.Key.Changed] as? [NSMetadataItem] else { return "" }
          return "\n\tchanged: \(", ".join(changed.map({$0.displayName})))"
        }(),
        {
          guard let added = userInfo[Notification.Key.Added] as? [NSMetadataItem] else { return "" }
          return "\n\tadded: \(", ".join(added.map({$0.displayName})))"
        }()
      )
    )
    Notification.DidUpdateMetadataItems.post(userInfo: userInfo)
  }

  /**
  didGatherMetadataItems:

  - parameter notificaiton: NSNotification
  */
  private static func didGatherMetadataItems(notificaiton: NSNotification) {
    guard state ∋ .GatheringMetadataItems else {
      logWarning("received gathering notification but state does not contain gathering flag")
      return
    }

    metadataQuery.disableUpdates()
    metadataItems = OrderedSet(metadataQuery.results as! [NSMetadataItem])
    metadataQuery.enableUpdates()

    state ⊻= .GatheringMetadataItems

    guard metadataItems.count > 0 else { return }
    Notification.DidUpdateMetadataItems.post(userInfo: [Notification.Key.Added:metadataItems.array])
  }

  private static let receptionist = NotificationReceptionist(callbackQueue: MIDIDocumentManager.operationQueue)

  /** initialize */
  static func initialize() {
    queue.asyncBarrier {

      guard state ∌ .Initialized else { return }

      receptionist.logContext = LogManager.MIDIFileContext

      receptionist.observe(NSMetadataQueryDidFinishGatheringNotification,
                      from: metadataQuery,
                  callback: MIDIDocumentManager.didGatherMetadataItems)

      receptionist.observe(NSMetadataQueryDidUpdateNotification,
                      from: metadataQuery,
                  callback: MIDIDocumentManager.didUpdateMetadataItems)

      if let data = SettingsManager.currentDocument {
        do {
          let url = try NSURL(byResolvingBookmarkData: data, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: nil)
          logDebug("opening bookmarked file at path '\(url.fileSystemRepresentation)'")
          openURL(url)
        } catch {
          logError(error, message: "Failed to resolve bookmark data into a valid file url")
          SettingsManager.currentDocument = nil
        }
      }

      metadataQuery.startQuery()

      state ∪= [.Initialized, .GatheringMetadataItems]
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
    case DidUpdateMetadataItems, DidChangeDocument, DidCreateDocument
    enum Key: String, NotificationKeyType { case Changed, Added, Removed, FilePath }
    var object: AnyObject? { return MIDIDocumentManager.self }
  }
  
}