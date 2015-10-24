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

  enum Error: String, ErrorType {
    case iCloudUnavailable
  }

  private static var initialized = false
  private static let DefaultDocumentName = "AwesomeSauce"
  private(set) static var openingDocument = false

  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateMetadataItems, DidChangeDocument
    enum Key: String, NotificationKeyType { case Changed, Added, Removed }
    var object: AnyObject? { return MIDIDocumentManager.self }
  }

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

      if let oldValue = oldValue {
        observer.stopObserving(oldValue, forChangesTo: "fileURL")
        oldValue.updateChangeCount(.Done)
        oldValue.closeWithCompletionHandler(nil)
      }

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
    queue.maxConcurrentOperationCount = 1
    return queue
  }()

  /** enabledUpdates */
  static func enabledUpdates() { metadataQuery.enableUpdates() }

  /** disableUpdates */
  static func disableUpdates() { metadataQuery.disableUpdates() }

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
    logDebug("metadata item count: \(results.count)")
    return results
  }


  /**
  didFinishGatheringNotification:

  - parameter notification: NSNotification
  */
  private static func didFinishGathering(notification: NSNotification) {
    Notification.DidUpdateMetadataItems.post()
  }

  /**
  didRenameFile:

  - parameter notification: NSNotification
  */
  private static func didRenameFile(notification: NSNotification) {
    guard let currentDocument = currentDocument,
              object = notification.object as? MIDIDocument where currentDocument == object else { return }
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
    logDebug({
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
        guard $0 else { return }; MIDIDocumentManager.openDocument(document)
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
  static func openURL(url: NSURL) {
    openDocument(MIDIDocument(fileURL: url))
  }

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
    receptionist.observe(NSMetadataQueryDidFinishGatheringNotification,
                    from: metadataQuery,
                   queue: queue,
                callback: MIDIDocumentManager.didFinishGathering)
    receptionist.observe(NSMetadataQueryDidUpdateNotification,
                    from: metadataQuery,
                   queue: queue,
                callback: MIDIDocumentManager.didUpdate)
    receptionist.observe(MIDIDocument.Notification.DidRenameFile, queue: queue, callback: MIDIDocumentManager.didRenameFile)
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