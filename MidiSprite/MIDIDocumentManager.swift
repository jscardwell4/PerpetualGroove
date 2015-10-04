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
  private static let CurrentDocumentKey = "MIDIDocumentManager.currentDocument"
  private(set) static var openingDocument = false

  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateMetadataItems, DidChangeCurrentDocument
    var object: AnyObject? { return MIDIDocumentManager.self }
  }

  static private(set) var currentDocument: MIDIDocument? {
    didSet {
      logDebug("currentDocument = \(MIDIDocumentManager.currentDocument!)")
      guard oldValue != currentDocument else { return }
      do {

        let data = try currentDocument?.fileURL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                         includingResourceValuesForKeys: nil,
                                                          relativeToURL: nil)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: CurrentDocumentKey)
      } catch {
        logError(error, message: "Failed to generate bookmark data for storage")
      }
      Notification.DidChangeCurrentDocument.post()
    }
  }

  private static let queue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.MoondeerStudios.MIDISprite.documentmanager"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()

  /** enabledUpdates */
  static func enabledUpdates() { metadataQuery.enableUpdates() }

  /** disableUpdates */
  static func disableUpdates() { metadataQuery.disableUpdates() }

  private static let metadataQuery: NSMetadataQuery = {
    let query = NSMetadataQuery()
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.operationQueue = MIDIDocumentManager.queue
    return query
  }()

  static var metadataItems: [NSMetadataItem] {
    metadataQuery.disableUpdates()
    let results = metadataQuery.results as! [NSMetadataItem]
    metadataQuery.enableUpdates()
    logDebug("metadataItems: \(results)")
    return results
  }


  /**
  didFinishGatheringNotification:

  - parameter notification: NSNotification
  */
  private static func didFinishGathering(notification: NSNotification) {
    logDebug()
    Notification.DidUpdateMetadataItems.post()
  }

  /**
  didUpdate:

  - parameter notification: NSNotification
  */
  private static func didUpdate(notification: NSNotification) {
    let changed = notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]
    let removed = notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]
    let added   = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey]   as? [NSMetadataItem]
    logDebug("changed: \(changed)\nremoved: \(removed)\nadded: \(added)")
    Notification.DidUpdateMetadataItems.post()
  }

  /** createNewFile */
  static func createNewDocument() throws {

    let fileManager = NSFileManager()
    let url: NSURL

    switch NSUserDefaults.standardUserDefaults().boolForKey("iCloudStorage") {

      case true:
        guard let baseURL = fileManager.URLForUbiquityContainerIdentifier(nil) else {
          logDebug("Need to present an alert prompting to enabled iCloud Drive")
          return
        }
        url = baseURL + "Documents"

      case false:
        url = documentsURL

    }

    queue.addOperationWithBlock {
      var fileURL = url + "AwesomeSauce.midi"
      var i = 2

      while fileURL.checkPromisedItemIsReachableAndReturnError(nil) {
        fileURL = url + "AwesomeSauce\(i++).midi"
      }

      let document = MIDIDocument(fileURL: fileURL)
      document.saveToURL(fileURL, forSaveOperation: .ForCreating, completionHandler: {
        guard $0 else { return }; MIDIDocumentManager.openDocument(document)
      })
    }

  }

  /**
  openDocument:

  - parameter document: MIDIDocument
  */
  static func openDocument(document: MIDIDocument) {
    logDebug("document = \(document)")
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
    logDebug("url = \(url)")
    openDocument(MIDIDocument(fileURL: url))
  }

  /**
  openFileAtURL:

  - parameter url: NSURL
  */
//  static func openItem(item: NSMetadataItem) {
//    logDebug("item = \(item.attributesDescription)")
//    openDocument(MIDIDocument(fileURL: item.URL))
//  }

  static func openItem(item: DocumentItemType) { openURL(item.URL) }

  private static let notificationReceptionist: NotificationReceptionist = {
    let metadataQuery = MIDIDocumentManager.metadataQuery
    let queue = MIDIDocumentManager.queue
    typealias Callback = NotificationReceptionist.Callback
    let finishGatheringCallback: Callback = (metadataQuery, queue, MIDIDocumentManager.didFinishGathering)
    let updateCallback         : Callback = (metadataQuery, queue, MIDIDocumentManager.didUpdate)
    let receptionist = NotificationReceptionist(callbacks: [
      NSMetadataQueryDidFinishGatheringNotification: finishGatheringCallback,
      NSMetadataQueryDidUpdateNotification: updateCallback
      ])
    metadataQuery.startQuery()
    return receptionist
  }()

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    NSUserDefaults.standardUserDefaults().registerDefaults(["iCloudStorage": true])

    let _ = notificationReceptionist

    if let data = NSUserDefaults.standardUserDefaults().objectForKey(CurrentDocumentKey) as? NSData {
      do {
        var isStale: ObjCBool = false
        let url = try NSURL(byResolvingBookmarkData: data, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: &isStale)
        openURL(url)
      } catch {
        logError(error, message: "Failed to resolve bookmark data into a valid file url")
      }
    }
    initialized = true
    logDebug("MIDIDocumentManager initialized")
  }
  
}