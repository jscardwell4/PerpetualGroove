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
      switch string?.lowercaseString {
        case "midi", "mid", "public.midi-audio": self = .MIDI
        case "groove", "com.moondeerstudios.groove-document": self = .Groove
        default: return nil
      }
    }
  }

  var sourceType: SourceType? { return SourceType(fileType) }

  var storageLocation: DocumentManager.StorageLocation {
    return NSFileManager.withDefaultManager({$0.isUbiquitousItemAtURL(fileURL)}) ? .iCloud : .Local
//    let fileManager = NSFileManager.defaultManager()
//    var isUbiquitous: AnyObject?
//    do { try fileURL.getResourceValue(&isUbiquitous, forKey: NSURLIsUbiquitousItemKey) } catch { logError(error) }
//    return isUbiquitous != nil && (isUbiquitous as? NSNumber)?.boolValue == true ? .iCloud : .Local
  }

  private(set) var sequence: Sequence? {
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

  private var creating = false

  override var presentedItemOperationQueue: NSOperationQueue { return DocumentManager.operationQueue }

  /**
   didUpdate:

   - parameter notification: NSNotification
  */
  private func didUpdate(notification: NSNotification) {
    logDebug("")
    updateChangeCount(.Done)
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

    receptionist.observe(name: UIDocumentStateChangedNotification,
                    from: self,
                callback: weakMethod(self, Document.didChangeState))
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: DocumentManager.operationQueue)
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
  func renameTo(newName: String) {
    DocumentManager.queue.async {
      [weak self] in

      guard let weakself = self else { return }

      guard newName != weakself.localizedName,
        let directoryURL = weakself.fileURL.URLByDeletingLastPathComponent else { return }

      let oldName = weakself.localizedName
      let oldURL = weakself.fileURL

      let newURL = directoryURL + "\(newName).groove"

      weakself.logDebug("renaming document '\(oldName)' ⟹ '\(newName)'")

      let fileCoordinator = NSFileCoordinator(filePresenter: nil)
      var error: NSError?
      fileCoordinator.coordinateWritingItemAtURL(oldURL,
                                                 options: .ForMoving,
                                                 writingItemAtURL: newURL,
                                                 options: .ForReplacing,
                                                 error: &error)
      {
        [weak self] oldURL, newURL in

        fileCoordinator.itemAtURL(oldURL, willMoveToURL: newURL)
        do {
          try NSFileManager.withDefaultManager { try $0.moveItemAtURL(oldURL, toURL: newURL) }
          fileCoordinator.itemAtURL(oldURL, didMoveToURL: newURL)
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
  override func saveToURL(url: NSURL,
         forSaveOperation saveOperation: UIDocumentSaveOperation,
        completionHandler: ((Bool) -> Void)?)
  {
    creating = saveOperation == .ForCreating
    logDebug("(\(creating ? "saving" : "overwriting"))  '\(url.path!)'")
    super.saveToURL(url, forSaveOperation: saveOperation, completionHandler: completionHandler)
  }

  override func presentedItemDidMoveToURL(newURL: NSURL) {
    super.presentedItemDidMoveToURL(newURL)
    guard let newName = newURL.pathBaseName else {
      fatalError("Failed to get base name from new url")
    }
    Notification.DidRenameDocument.post(object: self, userInfo: [.NewName: newName])
  }
}

extension Document: NotificationDispatchType {
  enum Notification: String, NotificationType, NotificationNameType {
    case DidRenameDocument

    enum Key: String, NotificationKeyType { case NewName }
  }
}

extension NSNotification {
  var newDocumentName: String? {
    return userInfo?[Document.Notification.Key.NewName.key] as? String
  }
}

extension Document: Named {
  var name: String { return localizedName.isEmpty ? "unamed" : localizedName }
}

// MARK: - Error
extension Document {

  enum Error: String, ErrorType { case InvalidContentType, InvalidContent, MissingSequence }

}
