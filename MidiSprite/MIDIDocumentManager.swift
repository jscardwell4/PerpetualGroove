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

  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateFileURLs
    var object: AnyObject? { return MIDIDocumentManager.self }
  }

  private static let queue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.MoondeerStudios.MIDISprite.documentmanager"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()

  private static let metadataQuery: NSMetadataQuery = {
    let query = NSMetadataQuery()
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                          NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.operationQueue = MIDIDocumentManager.queue
    return query
  }()

  private static var queryResults: [NSMetadataItem] {
    metadataQuery.disableUpdates()
    let results = metadataQuery.results as! [NSMetadataItem]
    metadataQuery.enableUpdates()
    return results
  }

  private(set) static var fileURLs: [NSURL] = [] {
    didSet {
      Notification.DidUpdateFileURLs.post()
    }
  }

  /** refreshFileURLs */
  private static func refreshFileURLs() {
    fileURLs = queryResults.flatMap { $0.valueForAttribute(NSMetadataItemURLKey) as? NSURL }
  }

  /**
  didFinishGatheringNotification:

  - parameter notification: NSNotification
  */
  private static func didFinishGathering(notification: NSNotification) { refreshFileURLs() }

  /**
  didUpdate:

  - parameter notification: NSNotification
  */
  private static func didUpdate(notification: NSNotification) {
    let changed = notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]
    let removed = notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]
    let added   = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey]   as? [NSMetadataItem]
    logDebug("changed: \(changed)\nremoved: \(removed)\nadded: \(added)")
    refreshFileURLs()
  }

  /** createNewFile */
  static func createNewFile() {
    queue.addOperationWithBlock {
      let fileManager = NSFileManager()
      guard let baseURL = fileManager.URLForUbiquityContainerIdentifier(nil) else {
        logDebug("Need to present an alert prompting to enabled iCloud Drive")
        return
      }

      var fileURL = baseURL + ["Documents", "AwesomeSauce.midi"]
      var i = 2

      while fileURL.checkPromisedItemIsReachableAndReturnError(nil) {
        fileURL = baseURL + ["Documents", "AwesomeSauce\(i++).midi"]
      }

      let document = MIDIDocument(fileURL: fileURL)
      document.saveToURL(fileURL, forSaveOperation: .ForCreating, completionHandler: {
        guard $0 else { return }
        Sequencer.currentDocument = document
      })

    }

  }

  /**
  openFileAtURL:

  - parameter url: NSURL
  */
  static func openFileAtURL(url: NSURL) {

  }

  private static let notificationReceptionist: NotificationReceptionist = {
    let metadataQuery = MIDIDocumentManager.metadataQuery
    let queue = MIDIDocumentManager.queue
    typealias Callback = NotificationReceptionist.Callback
    let finishGatheringCallback: Callback = (metadataQuery, queue, MIDIDocumentManager.didFinishGathering)
    let updateCallback: Callback          = (metadataQuery, queue, MIDIDocumentManager.didUpdate)
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

    initialized = true
  }
  
}