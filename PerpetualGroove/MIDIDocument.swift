//
//  MIDIDocument.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class MIDIDocument: UIDocument {

  enum SourceType: String {
    case MIDI = "midi", Groove = "groove"
    init?(_ string: String?) {
      switch string?.lowercaseString {
        case "midi", "mid", "public.midi-audio": self = .MIDI
        case "groove", "com.moondeerstudios.groove-document": self = .Groove
        default: return nil
      }
    }
  }

  var sourceType: SourceType? { return SourceType(fileType) }

  var storageLocation: MIDIDocumentManager.StorageLocation {
    var isUbiquitous: AnyObject?
    do { try fileURL.getResourceValue(&isUbiquitous, forKey: NSURLIsUbiquitousItemKey) } catch { logError(error) }
    return isUbiquitous != nil && (isUbiquitous as? NSNumber)?.boolValue == true ? .iCloud : .Local
  }

  private(set) var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }

      if let oldSequence = oldValue {
        receptionist.stopObserving(Sequence.Notification.DidUpdate, from: oldSequence)
      }

      if let sequence = sequence {
        receptionist.observe(.DidUpdate, from: sequence, callback: weakMethod(self, MIDIDocument.didUpdate))
      }
    }
  }

  private var creating = false

  override var presentedItemOperationQueue: NSOperationQueue { return MIDIDocumentManager.operationQueue }

  /**
   didUpdate:

   - parameter notification: NSNotification
  */
  private func didUpdate(notification: NSNotification) {
    logDebug("")
    updateChangeCount(.Done)
  }

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
                callback: weakMethod(self, MIDIDocument.didChangeState))
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
    guard let data = contents as? NSData, type = SourceType(typeName) else { throw Error.InvalidContentType }
    guard data.length > 0 else { sequence = Sequence(document: self); return }
    let file: SequenceDataProvider
    switch type {
      case .MIDI: file = try MIDIFile(data: data)
      case .Groove: guard let f = GrooveFile(data: data) else { throw Error.InvalidContent }; file = f
    }
    sequence = Sequence(data: file, document: self)
    logDebug("file: \(file)\nloaded into sequence: \(sequence!)")
  }

  /**
  contentsForType:

  - parameter typeName: String
  */
  override func contentsForType(typeName: String) throws -> AnyObject {
    if sequence == nil && creating {
      sequence = Sequence(document: self)
      creating = false
    }
    guard let sequence = sequence, type = SourceType(typeName) else { throw Error.MissingSequence }

    let file: DataConvertible
    switch type {
      case .MIDI:   file = MIDIFile(sequence: sequence)
      case .Groove: file = GrooveFile(sequence: sequence)
    }
    logDebug("file contents:\n\(file)")
    return file.data
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
    guard name != localizedName, let url = fileURL.URLByDeletingLastPathComponent else { return }
    saveToURL(url + "\(baseName).groove", forSaveOperation: .ForCreating, completionHandler: nil)

  }

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

}

extension MIDIDocument: Named {
  var name: String { return localizedName.isEmpty ? "unamed" : localizedName }
}

// MARK: - Error
extension MIDIDocument {

  enum Error: String, ErrorType { case InvalidContentType, InvalidContent, MissingSequence }

}
