//
//  Document.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class Document: UIDocument {

  enum SourceType: String {
    case MIDI = "midi", Groove = "groove"
    init?(_ string: String?) {
      switch string?.lowercased() {
        case "midi", "mid", "public.midi-audio": self = .MIDI
        case "groove", "com.moondeerstudios.groove-document": self = .Groove
        default: return nil
      }
    }
  }

  var sourceType: SourceType? { return SourceType(fileType) }

  var storageLocation: DocumentManager.StorageLocation {
    return FileManager.withDefaultManager({$0.isUbiquitousItem(at: fileURL)}) ? .iCloud : .local
//    let fileManager = NSFileManager.defaultManager()
//    var isUbiquitous: AnyObject?
//    do { try fileURL.getResourceValue(&isUbiquitous, forKey: NSURLIsUbiquitousItemKey) } catch { logError(error) }
//    return isUbiquitous != nil && (isUbiquitous as? NSNumber)?.boolValue == true ? .iCloud : .Local
  }

  fileprivate(set) var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }

      if let oldSequence = oldValue {
        receptionist.stopObserving(notification: .DidUpdate, from: oldSequence)
      }

      if let sequence = sequence {
        receptionist.observe(notification: .DidUpdate, from: sequence, callback: weakMethod(self, Document.didUpdate))
      }
    }
  }

  fileprivate var creating = false

  override var presentedItemOperationQueue: OperationQueue { return DocumentManager.operationQueue }

  /**
   didUpdate:

   - parameter notification: NSNotification
  */
  fileprivate func didUpdate(_ notification: Foundation.Notification) {
    logDebug("")
    updateChangeCount(.done)
  }

  override func disableEditing() {
    logDebug("")
    super.disableEditing()
  }

  override func enableEditing() {
    logDebug("")
    super.enableEditing()
  }

  /**
  didChangeState:

  - parameter notification: NSNotification
  */
  fileprivate func didChangeState(_ notification: Foundation.Notification) {
    
    guard documentState ∋ .inConflict, let versions = NSFileVersion.unresolvedConflictVersionsOfItem(at: fileURL) else { return }
    logDebug("versions: \(versions)")
    // TODO: resolve conflict
  }

  /**
  init:

  - parameter url: NSURL
  */
  override init(fileURL url: URL) {
    super.init(fileURL: url)

    receptionist.observe(name: NSNotification.Name.UIDocumentStateChanged.rawValue,
                    from: self,
                callback: weakMethod(self, Document.didChangeState))
  }

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: DocumentManager.operationQueue)
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  /**
  loadFromContents:ofType:

  - parameter contents: AnyObject
  - parameter typeName: String?
  */
  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    guard let data = contents as? Data, let type = SourceType(typeName) else { throw Error.InvalidContentType }
    guard data.count > 0 else { sequence = Sequence(document: self); return }
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
  override func contents(forType typeName: String) throws -> Any {
    if sequence == nil && creating {
      sequence = Sequence(document: self)
      creating = false
    }
    guard let sequence = sequence, let type = SourceType(typeName) else { throw Error.MissingSequence }

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
  override func handleError(_ error: Swift.Error, userInteractionPermitted: Bool) {
    logError(error)
    super.handleError(error, userInteractionPermitted: userInteractionPermitted)
  }

  /**
  renameTo:

  - parameter name: String
  */
  func renameTo(_ newName: String) {
    DocumentManager.queue.async {
      [weak self] in

      guard let weakself = self else { return }

      guard newName != weakself.localizedName else { return }

      let directoryURL = weakself.fileURL.deletingLastPathComponent()

      let oldName = weakself.localizedName
      let oldURL = weakself.fileURL

      let newURL = directoryURL + "\(newName).groove"

      weakself.logDebug("renaming document '\(oldName)' ⟹ '\(newName)'")

      let fileCoordinator = NSFileCoordinator(filePresenter: nil)
      var error: NSError?
      fileCoordinator.coordinate(writingItemAt: oldURL,
                                 options: .forMoving,
                                 writingItemAt: newURL,
                                                 options: .forReplacing,
                                                 error: &error)
      {
        [weak self] oldURL, newURL in

        fileCoordinator.item(at: oldURL, willMoveTo: newURL)
        do {
          try FileManager.withDefaultManager { try $0.moveItem(at: oldURL, to: newURL) }
          fileCoordinator.item(at: oldURL, didMoveTo: newURL)
        } catch {
          self?.logError(error)
        }
      }

      if let error = error { weakself.logError(error) }
    }
  }

  // MARK: - Saving

  /**
  saveToURL:forSaveOperation:completionHandler:

  - parameter url: NSURL
  - parameter saveOperation: UIDocumentSaveOperation
  - parameter completionHandler: ((Bool) -> Void
  */
  override func save(to url: URL,
         for saveOperation: UIDocumentSaveOperation,
        completionHandler: ((Bool) -> Void)?)
  {
    creating = saveOperation == .forCreating
    logDebug("(\(creating ? "saving" : "overwriting"))  '\(url.path)'")
    super.save(to: url, for: saveOperation, completionHandler: completionHandler)
  }

  override func presentedItemDidMove(to newURL: URL) {
    super.presentedItemDidMove(to: newURL)
    guard let newName = newURL.pathBaseName else {
      fatalError("Failed to get base name from new url")
    }
    Notification.DidRenameDocument.post(object: self, userInfo: [.NewName: newName])
  }
}

extension Document: NotificationDispatching {
  enum NotificationName: String, LosslessStringConvertible {
    case didRenameDocument
  }
}

extension Notification {
  var newDocumentName: String? {
    return userInfo?["newName"] as? String
  }
}

extension Document: Named {
  var name: String { return localizedName.isEmpty ? "unamed" : localizedName }
}

// MARK: - Error
extension Document {

  enum Error: String, Swift.Error { case InvalidContentType, InvalidContent, MissingSequence }

}
