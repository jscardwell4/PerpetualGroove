//
//  GrooveApp.swift
//  Shared
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import Documents
import MoonDev
import Sequencer
import SwiftUI

@main
final class GrooveApp: App
{
  var openDocument: FileDocumentConfiguration<GrooveDocument>?
  {
    didSet
    {
      switch (openDocument, oldValue)
      {
        case let (current?, old) where old == nil,
             let (current?, old) where old != nil
              && current.document.sequence !== old!.document.sequence:
          // A document has been opened and possible another closed.

          let name = current.fileURL!.deletingPathExtension().lastPathComponent
          let oldName = old?.fileURL?.deletingPathExtension().lastPathComponent

          current.document.name = name
          sequencer.sequence = current.document.sequence

          logi("""
          \(#fileID) \(#function) \
          \(oldName == nil ? "" : "closed '\(oldName!)' and ")opened '\(name)'
          """)

        case let (nil, old?):
          // A document has been closed.

          logi("""
          \(#fileID) \(#function) \
          closed '\(old.fileURL!.lastPathComponent)'
          """)

        default:
          break
      }
    }
  }

  var body: some Scene
  {
    DocumentGroup(newDocument: GrooveDocument(sequence: Sequence.mock))
    {
      (file: FileDocumentConfiguration<GrooveDocument>) -> ContentView in
      self.openDocument = file
      let contentView = ContentView(document: file.$document)
      return contentView
    }
  }
}
