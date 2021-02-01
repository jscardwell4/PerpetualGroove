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
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private func newDocument() -> Document
  {
    .init(sequence: ProcessInfo.processInfo.environment["ENABLE_MOCK_DATA"] == "true"
      ? Sequence.mock
      : Sequence())
  }

  private func contentView(_ file: FileDocumentConfiguration<Document>) -> some View
  {
    ContentView()
      .environment(\.openDocument, file)
      .environmentObject(sequencer)
      .environmentObject(file.document.sequence)
  }

  var body: some Scene
  {
    DocumentGroup(newDocument: self.newDocument(), editor: contentView)
  }
}
