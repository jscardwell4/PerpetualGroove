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

  private(set) var sequence: MIDISequence? {
    didSet {
      let stopObserving: (MIDISequence) -> Void = {
        self.receptionist.stopObserving(MIDISequence.Notification.DidUpdate, from: $0)
      }
      let observe: (MIDISequence) -> Void = {
        self.receptionist.observe(MIDISequence.Notification.DidUpdate, from: $0) {
          [weak self] _ in
          self?.logDebug("notification received that sequence has been updated")
          self?.updateChangeCount(.Done)
        }
      }
      switch (oldValue, sequence) {
        case let (oldValue?, newValue?): stopObserving(oldValue); observe(newValue)
        case let (nil, newValue?):       observe(newValue)
        case let (oldValue?, nil):       stopObserving(oldValue)
        case (nil, nil):                 break
      }
    }
  }

  private var creating = false

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

    receptionist.observe(UIDocumentStateChangedNotification,
                    from: self,
                callback: weakMethod(self, method: MIDIDocument.didChangeState))
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: MIDIDocumentManager.operationQueue)
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  /**
  loadFromContents:ofType:

  - parameter contents: AnyObject
  - parameter typeName: String?
  */
  override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
    guard let data = contents as? NSData else { throw Error.InvalidContentType }
    sequence = MIDISequence(file: try MIDIFile(data: data), document: self)
    logDebug("file loaded into sequence: \(sequence!)")
  }

  /**
  contentsForType:

  - parameter typeName: String
  */
  override func contentsForType(typeName: String) throws -> AnyObject {
    if sequence == nil && creating {
      sequence = MIDISequence(file: MIDIFile.emptyFile, document: self)
      creating = false
    }
    guard let file = sequence?.file else { throw Error.MissingSequence }
    logDebug("file contents:\n\(file)")
    let bytes = file.bytes
    return NSData(bytes: bytes, length: bytes.count)
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

  // MARK: - Saving

  /**
  saveToURL:forSaveOperation:completionHandler:

  - parameter url: NSURL
  - parameter saveOperation: UIDocumentSaveOperation
  - parameter completionHandler: ((Bool) -> Void
  */
  override func saveToURL(url: NSURL,
         forSaveOperation saveOperation: UIDocumentSaveOperation,
        completionHandler: ((Bool) -> Void)?)
  {
    creating = saveOperation == .ForCreating
    logDebug("(\(creating ? "saving" : "overwriting"))  '\(String(CString:url.fileSystemRepresentation, encoding: NSUTF8StringEncoding)!)'")
    super.saveToURL(url, forSaveOperation: saveOperation, completionHandler: completionHandler)
  }

  /**
  autosaveWithCompletionHandler:

  - parameter completionHandler: ((Bool) -> Void
  */
  override func autosaveWithCompletionHandler(completionHandler: ((Bool) -> Void)?) {
    logDebug("unsaved changes? \(hasUnsavedChanges())")
    super.autosaveWithCompletionHandler(completionHandler)
  }

}

extension MIDIDocument: Named {
  var name: String { return localizedName.isEmpty ? "unamed" : localizedName }
}

// MARK: - Error
extension MIDIDocument {

  enum Error: String, ErrorType { case InvalidContentType, MissingSequence }

}
