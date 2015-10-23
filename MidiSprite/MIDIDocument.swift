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

  enum Notification: String, NotificationType, NotificationNameType {
    case DidRenameFile
    enum Key: String, KeyType { case OldName, NewName }
  }

  enum Error: String, ErrorType { case InvalidContentType }

  let sequence = MIDISequence()

  /**
  Callback for `DidAddTrack` notifications from `sequence`. Updates `receptionist` to observe `DidUpdateEvents` notificaton from
  the new track.

  - parameter notification: NSNotification
  */
  private func didAddTrack(notification: NSNotification) {
    guard let track = notification.userInfo?[MIDISequence.Notification.Key.Track.rawValue] as? InstrumentTrack else { return }
    receptionist.observe(MIDITrackNotification.DidUpdateEvents, from: track, callback: didUpdateTrack)
    updateChangeCount(.Done)
  }

  /**
  Callback for `DidRemoveTrack` notifications from `sequence`. Updates `receptionist` to stop observing the removed track.

  - parameter notification: NSNotification
  */
  private func didRemoveTrack(notification: NSNotification) {
    guard let track = notification.userInfo?[MIDISequence.Notification.Key.Track.rawValue] as? InstrumentTrack else { return }
    receptionist.stopObserving(MIDITrackNotification.DidUpdateEvents, from: track)
    updateChangeCount(.Done)
  }

  /**
  Callback for `DidUpdateEvents` notifications from the tracks of `sequence`.

  - parameter notification: NSNotification
  */
  private func didUpdateTrack(notification: NSNotification) { updateChangeCount(.Done) }

  /**
  init:

  - parameter url: NSURL
  */
  override init(fileURL url: NSURL) {
    super.init(fileURL: url)
    receptionist.observe(MIDISequence.Notification.DidAddTrack,    from: sequence, callback: didAddTrack)
    receptionist.observe(MIDISequence.Notification.DidRemoveTrack, from: sequence, callback: didRemoveTrack)
  }

  private let receptionist = NotificationReceptionist()

  /**
  loadFromContents:ofType:

  - parameter contents: AnyObject
  - parameter typeName: String?
  */
  override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
    guard let data = contents as? NSData else { throw Error.InvalidContentType }
    let file = try MIDIFile(data: data)
    logDebug("parsed data into midi file:\n\(file)")
    sequence.file = file
    logDebug("file loaded into sequence: \(sequence)")
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
    return [NSURLHasHiddenExtensionKey: true]
  }

  /**
  renameTo:

  - parameter name: String
  */
  func renameTo(name: String) {
    let (baseName, _) = name.baseNameExt
    logDebug("renaming document '\(localizedName)' ⟹ '\(baseName)'")
    guard let url = fileURL.URLByDeletingLastPathComponent else { return }
    saveToURL(url + "\(baseName).midi", forSaveOperation: .ForCreating, completionHandler: nil)

  }

}
