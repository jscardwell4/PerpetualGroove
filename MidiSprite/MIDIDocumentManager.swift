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

  private static var initialized = false
  private static let DefaultDocumentName = "AwesomeSauce"
  private(set) static var openingDocument = false

  /** refreshBookmark */
  static private func refreshBookmark() {
      do {
        SettingsManager.currentDocument = try currentDocument?.fileURL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                                                includingResourceValuesForKeys: nil,
                                                                                 relativeToURL: nil)
      } catch {
        logError(error, message: "Failed to generate bookmark data for storage")
      }
  }

  static private(set) var currentDocument: MIDIDocument? {
    didSet {
      logDebug("currentDocument: \(currentDocument == nil ? "nil" : currentDocument!.localizedName)")

      guard oldValue != currentDocument else { return }

      if let oldValue = oldValue { observer.stopObserving(oldValue, forChangesTo: "fileURL") }

      if let currentDocument = currentDocument {
        observer.observe(currentDocument, forChangesTo: "fileURL", queue: queue) {
          _, _, _ in MIDIDocumentManager.refreshBookmark()
        }
      }

      refreshBookmark()
      Notification.DidChangeDocument.post()
    }
  }

  private static let queue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.moondeerstudios.perpetualgroove.documentmanager"
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    return queue
  }()

  private static let metadataQuery: NSMetadataQuery = {
    let query = NSMetadataQuery()
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.operationQueue = MIDIDocumentManager.queue
    return query
  }()

  static var metadataItems: [NSMetadataItem] {
    metadataQuery.disableUpdates()
    let results = metadataQuery.results as! [NSMetadataItem]
    metadataQuery.enableUpdates()
    return results
  }

  /**
  didRenameFile:

  - parameter notification: NSNotification
  */
  private static func didRenameFile(notification: NSNotification) {
    guard notification.object as? MIDIDocument == currentDocument else { return }
    refreshBookmark()
  }

  /**
  didUpdate:

  - parameter notification: NSNotification
  */
  private static func didUpdate(notification: NSNotification) {
    let changed = notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] ?? []
    let removed = notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem] ?? []
    let added   = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey]   as? [NSMetadataItem] ?? []
    logVerbose({
      [changedCount = changed.count, removedCount = removed.count, addedCount = added.count] in
        guard changedCount > 0 || removedCount > 0 || addedCount > 0 else { return "no changes" }
        var results: [String] = []
        if changedCount > 0 { results.append("changed: \(changedCount)") }
        if removedCount > 0 { results.append("removed: \(removedCount)") }
        if addedCount > 0   { results.append("added: \(addedCount)") }
        return "  ".join(results)
      }()
    )
    Notification.DidUpdateMetadataItems.post(userInfo: [Notification.Key.Changed: changed,
                                                        Notification.Key.Removed: removed,
                                                        Notification.Key.Added: added])
  }

  /** createNewFile */
  static func createNewDocument() throws {

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

    queue.addOperationWithBlock {
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
    logDebug("opening document '\(document.fileURL.path ?? "???")'")
    openingDocument = true
    document.openWithCompletionHandler {
      guard $0 else { logError("failed to open document: \(document)"); return }
      MIDIDocumentManager.currentDocument = document
      MIDIDocumentManager.openingDocument = false
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
    backgroundDispatch {
      [url = item.URL] in

      logDebug("removing item '\(url.path!)'")
      NSFileCoordinator(filePresenter: nil).coordinateWritingItemAtURL(url, options: .ForDeleting, error: nil) {
          do { try NSFileManager().removeItemAtURL($0) }
          catch { logError(error) }
        }
    }

    guard currentDocument?.fileURL == item.URL else { return }
    currentDocument = nil
  }

  private static let observer = KVOReceptionist()

  private static let receptionist: NotificationReceptionist = {
    let metadataQuery = MIDIDocumentManager.metadataQuery
    let queue = MIDIDocumentManager.queue

    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.MIDIFileContext

    receptionist.observe(NSMetadataQueryDidFinishGatheringNotification, from: metadataQuery, queue: queue) {
      _ in Notification.DidGatherMetadataItems.post()
    }

    receptionist.observe(NSMetadataQueryDidUpdateNotification, from: metadataQuery, queue: queue) {
      let changed = $0.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] ?? []
      let removed = $0.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem] ?? []
      let added   = $0.userInfo?[NSMetadataQueryUpdateAddedItemsKey]   as? [NSMetadataItem] ?? []
      logVerbose({
        [changedCount = changed.count, removedCount = removed.count, addedCount = added.count] in
        guard changedCount > 0 || removedCount > 0 || addedCount > 0 else { return "no changes" }
        var results: [String] = []
        if changedCount > 0 { results.append("changed: \(changedCount)") }
        if removedCount > 0 { results.append("removed: \(removedCount)") }
        if addedCount > 0   { results.append("added: \(addedCount)") }
        return "  ".join(results)
        }()
      )

      Notification.DidUpdateMetadataItems.post(userInfo:
        [Notification.Key.Changed: changed, Notification.Key.Removed: removed, Notification.Key.Added: added]
      )
    }

    metadataQuery.startQuery()

    return receptionist
  }()

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    let _ = receptionist

    if let data = SettingsManager.currentDocument {
      do {
        var isStale: ObjCBool = false
        let url = try NSURL(byResolvingBookmarkData: data, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: &isStale)
        openURL(url)
      } catch {
        logError(error, message: "Failed to resolve bookmark data into a valid file url")
        SettingsManager.currentDocument = nil
      }
    }
    initialized = true
    logDebug("MIDIDocumentManager initialized")
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
    case DidUpdateMetadataItems, DidChangeDocument, DidGatherMetadataItems, DidCreateDocument
    enum Key: String, NotificationKeyType { case Changed, Added, Removed, FilePath }
    var object: AnyObject? { return MIDIDocumentManager.self }
  }
  
}