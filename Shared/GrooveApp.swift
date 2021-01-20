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
import SwiftUI

@main
final class GrooveApp: App
{
  var openDocument: FileDocumentConfiguration<GrooveDocument>?
  {
    didSet
    {
      logi("""
        \(#fileID) \(#function) \
        openDocument: \(openDocument?.fileURL?.absoluteString ?? "nil")
        """)
    }
  }

  var body: some Scene
  {
    DocumentGroup(newDocument: GrooveDocument())
    {
      (file: FileDocumentConfiguration<GrooveDocument>) -> ContentView in
      self.openDocument = file
      return ContentView(document: file.$document)
    }
  }
}
