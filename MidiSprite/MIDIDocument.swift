//
//  MIDIDocument.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class MIDIDocument: UIDocument {

  typealias SequenceNotification = MIDISequence.Notification

  enum Error: String, ErrorType {
    case InvalidContentType
  }

  let sequence = MIDISequence()

  /**
  didAddTrack:

  - parameter notification: NSNotification
  */
  private func didAddTrack(notification: NSNotification) {
    guard let track = notification.userInfo?[SequenceNotification.Key.Track.rawValue] as? InstrumentTrack else { return }
    notificationReceptionist.observe(MIDITrackNotification.DidUpdateEvents, from: track, callback: didUpdateTrack)
    updateChangeCount(.Done)
  }

  /**
  didRemoveTrack:

  - parameter notification: NSNotification
  */
  private func didRemoveTrack(notification: NSNotification) {
    guard let track = notification.userInfo?[SequenceNotification.Key.OldTrack.rawValue] as? InstrumentTrack else { return }
    notificationReceptionist.stopObserving(MIDITrackNotification.DidUpdateEvents, from: track)
    updateChangeCount(.Done)
  }

  /**
  didUpdateTrack:

  - parameter notification: NSNotification
  */
  private func didUpdateTrack(notification: NSNotification) {
    updateChangeCount(.Done)
  }

  /**
  init:

  - parameter url: NSURL
  */
  override init(fileURL url: NSURL) {
    super.init(fileURL: url)
    notificationReceptionist.observe(SequenceNotification.DidAddTrack, from: sequence, callback: didAddTrack)
    notificationReceptionist.observe(SequenceNotification.DidRemoveTrack, from: sequence, callback: didRemoveTrack)
  }

  private let notificationReceptionist = NotificationReceptionist()

  /**
  loadFromContents:ofType:

  - parameter contents: AnyObject
  - parameter typeName: String?
  */
  override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
    guard let data = contents as? NSData else { throw Error.InvalidContentType }
    sequence.file = try MIDIFile(data: data)
  }

  /**
  contentsForType:

  - parameter typeName: String
  */
  override func contentsForType(typeName: String) throws -> AnyObject {
    let bytes = sequence.file.bytes
    return NSData(bytes: bytes, length: bytes.count)
  }

  /**
  fileAttributesToWriteToURL:forSaveOperation:

  - parameter url: NSURL
  - parameter saveOperation: UIDocumentSaveOperation
  */
  override func fileAttributesToWriteToURL(url: NSURL,
                          forSaveOperation saveOperation: UIDocumentSaveOperation) throws -> [NSObject: AnyObject]
  {

    // TODO: Generate thumbnail
    let image = UIImage()

    return [NSURLHasHiddenExtensionKey: true, NSURLThumbnailDictionaryKey: [NSThumbnail1024x1024SizeKey: image]]
  }


}
