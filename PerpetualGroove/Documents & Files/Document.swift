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

  var sourceType: SourceType? { return SourceType(fileType) }

  var storageLocation: DocumentManager.StorageLocation {
    return FileManager.withDefaultManager({$0.isUbiquitousItem(at: fileURL)}) ? .iCloud : .local
  }

  fileprivate(set) var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }

      if let oldSequence = oldValue {
        receptionist.stopObserving(name: Sequence.NotificationName.didUpdate.rawValue,
                                   from: oldSequence)
      }

      if let sequence = sequence {
        receptionist.observe(name: Sequence.NotificationName.didUpdate.rawValue,
                             from: sequence,
                             callback: weakMethod(self, Document.didUpdate))
      }

    }

  }

  fileprivate var creating = false

  override var presentedItemOperationQueue: OperationQueue { return DocumentManager.operationQueue }

  fileprivate func didUpdate(_ notification: Foundation.Notification) {
    Log.debug("")
    updateChangeCount(.done)
  }

  fileprivate func didChangeState(_ notification: Foundation.Notification) {
    
    guard documentState ∋ .inConflict,
      let versions = NSFileVersion.unresolvedConflictVersionsOfItem(at: fileURL) else {
        return
    }

    // TODO: resolve conflict
    Log.debug("versions: \(versions)")

  }

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

  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    
    guard let data = contents as? Data else { throw Error.invalidContent }
    guard let type = SourceType(typeName) else { throw Error.invalidContentType }

    guard data.count > 0 else { sequence = Sequence(document: self); return }

    let dataProvider: SequenceDataProvider

    switch type {

      case .midi:
        dataProvider = try MIDIFile(data: data)

      case .groove:
        guard let file = GrooveFile(data: data) else { throw Error.invalidContent }
        dataProvider = file

    }
    
    sequence = Sequence(data: dataProvider, document: self)

    Log.debug("file: \(dataProvider)\nloaded into sequence: \(sequence!)")

  }

  override func contents(forType typeName: String) throws -> Any {

    if sequence == nil && creating {
      sequence = Sequence(document: self)
      creating = false
    }

    guard let sequence = sequence else { throw Error.missingSequence }
    guard let type = SourceType(typeName) else { throw Error.invalidContentType }

    let file: DataConvertible
    switch type {
      case .midi:   file = MIDIFile(sequence: sequence)
      case .groove: file = GrooveFile(sequence: sequence, source: fileURL)
    }

    Log.debug("file contents:\n\(file)")

    return file.data

  }

  override func handleError(_ error: Swift.Error, userInteractionPermitted: Bool) {
    Log.error(error)
    super.handleError(error, userInteractionPermitted: userInteractionPermitted)
  }

  func rename(to newName: String) {

    DocumentManager.queue.async {
      [weak self] in

      guard let weakself = self else { return }

      guard newName != weakself.localizedName else { return }

      let directoryURL = weakself.fileURL.deletingLastPathComponent()

      let oldName = weakself.localizedName
      let oldURL = weakself.fileURL

      let newURL = directoryURL + "\(newName).groove"

      Log.debug("renaming document '\(oldName)' ⟹ '\(newName)'")

      let fileCoordinator = NSFileCoordinator(filePresenter: nil)
      var error: NSError?
      fileCoordinator.coordinate(writingItemAt: oldURL,
                                 options: .forMoving,
                                 writingItemAt: newURL,
                                 options: .forReplacing,
                                 error: &error)
      {
        oldURL, newURL in

        fileCoordinator.item(at: oldURL, willMoveTo: newURL)
        do {
          try FileManager.withDefaultManager { try $0.moveItem(at: oldURL, to: newURL) }
          fileCoordinator.item(at: oldURL, didMoveTo: newURL)
        } catch {
          Log.error(error)
        }
      }

      if let error = error { Log.error(error) }

    }

  }

  // MARK: - Saving

  override func save(to url: URL,
                     for saveOperation: UIDocumentSaveOperation,
                     completionHandler: ((Bool) -> Void)?)
  {
    creating = saveOperation == .forCreating
    Log.debug("(\(creating ? "saving" : "overwriting"))  '\(url.path)'")
    super.save(to: url, for: saveOperation, completionHandler: completionHandler)
  }

  override func presentedItemDidMove(to newURL: URL) {
    super.presentedItemDidMove(to: newURL)

    guard let newName = newURL.pathBaseName else {
      fatalError("Failed to get base name from new url")
    }

    postNotification(name: .didRenameDocument, object: self, userInfo: ["newName": newName])

  }

}

extension Document {

  enum SourceType: String {
    case midi = "midi", groove = "groove"

    init?(_ string: String?) {

      switch string?.lowercased() {

        case "midi", "mid", "public.midi-audio":
          self = .midi

        case "groove", "com.moondeerstudios.groove-document":
          self = .groove

        default:
          return nil

      }

    }

  }

}

extension Document: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didRenameDocument

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }

}

extension Notification {

  var newDocumentName: String? { return userInfo?["newName"] as? String }

}

extension Document: Named {

  var name: String { return localizedName.isEmpty ? "unamed" : localizedName }

}

extension Document {

  enum Error: String, Swift.Error {
    case invalidContentType, invalidContent, missingSequence
  }

}
