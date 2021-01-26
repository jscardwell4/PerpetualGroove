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
  @AppStorage("lastLoadedFile") var lastLoadedFile = Data()

  var openDocument: FileDocumentConfiguration<GrooveDocument>?
  {
    didSet
    {
      switch (openDocument, oldValue)
      {
        case let (currentDocument?, oldDocument) where oldDocument == nil,
             let (currentDocument?, oldDocument) where oldDocument != nil
               && currentDocument.document.sequence !== oldDocument!.document.sequence:
          // A document has been opened and possibly another has been closed.

          let currentFileURL = currentDocument.fileURL!
          let name = currentFileURL.deletingPathExtension().lastPathComponent
          do
          {
            lastLoadedFile = try currentFileURL
              .bookmarkData(options: .suitableForBookmarkFile)
          }
          catch
          {
            logw("<\(#fileID) \(#function)> Failed to generate bookmark for \(name).")
          }

          let oldName = oldDocument?.fileURL?.deletingPathExtension().lastPathComponent

          currentDocument.document.name = name
          sequencer.sequence = currentDocument.document.sequence

          logi("""
          <\(#fileID) \(#function)> \
          \(oldName == nil ? "" : "closed '\(oldName!)' and ")opened '\(name)'
          """)

        case let (nil, old?):
          // A document has been closed.

          logi("""
          <\(#fileID) \(#function)> \
          closed '\(old.fileURL!.lastPathComponent)'
          """)

        default:
          break
      }
    }
  }

  private func newDocument() -> GrooveDocument
  {
    .init(sequence: ProcessInfo.processInfo.environment["ENABLE_MOCK_DATA"] == "true"
      ? Sequence.mock
      : Sequence())
  }

  private func contentView(_ file: FileDocumentConfiguration<GrooveDocument>) -> some View
  {
    openDocument = file
    return ContentView()
      .environmentObject(file.document)
      .environmentObject(file.document.sequence)
  }

  var body: some Scene
  {
    DocumentGroup(newDocument: self.newDocument(), editor: contentView)
  }
}
