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
  didChangeState:

  - parameter notification: NSNotification
  */
  private func didChangeState(notification: NSNotification) {
    guard documentState ∋ .InConflict, let versions = NSFileVersion.unresolvedConflictVersionsOfItemAtURL(fileURL) else { return }
    logDebug("versions: \(versions)")
    // TODO: resolve conflict
  }

  /**
  init:

  - parameter url: NSURL
  */
  override init(fileURL url: NSURL) {
    super.init(fileURL: url)
    receptionist.logContext = LogManager.MIDIFileContext
    let callback: (NSNotification) -> Void = {[weak self] _ in self?.updateChangeCount(.Done)}
    let queue = NSOperationQueue.mainQueue()
    receptionist.observe(UIDocumentStateChangedNotification, from: self, queue: queue) { [weak self] in self?.didChangeState($0) }
    receptionist.observe(MIDISequence.Notification.DidAddTrack, from: sequence, queue: queue, callback: callback)
    receptionist.observe(MIDISequence.Notification.DidRemoveTrack, from: sequence, queue: queue, callback: callback)
  }

  private let receptionist = NotificationReceptionist()

  /**
  loadFromContents:ofType:

  - parameter contents: AnyObject
  - parameter typeName: String?
  */
  override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
    guard let data = contents as? NSData else { throw Error.InvalidContentType }
    sequence.file = try MIDIFile(data: data)
    logDebug("file loaded into sequence: \(sequence)")
  }

  /**
  contentsForType:

  - parameter typeName: String
  */
  override func contentsForType(typeName: String) throws -> AnyObject {
    let file = sequence.file
    logDebug("saving file:\n\(file)")
    let bytes = file.bytes
    return NSData(bytes: sequence.file.bytes, length: bytes.count)
  }

  /**
  handleError:userInteractionPermitted:

  - parameter error: NSError
  - parameter userInteractionPermitted: Bool
  */
  override func handleError(error: NSError, userInteractionPermitted: Bool) {
    logError(error)
    super.handleError(error, userInteractionPermitted: userInteractionPermitted)
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

//  override func disableEditing() {}
//  override func enableEditing() {}

  /**
  autosaveWithCompletionHandler:

  - parameter completionHandler: ((Bool) -> Void
  */
  override func autosaveWithCompletionHandler(completionHandler: ((Bool) -> Void)?) {
    logDebug("unsaved changes? \(hasUnsavedChanges())")
    super.autosaveWithCompletionHandler(completionHandler)
  }

}
