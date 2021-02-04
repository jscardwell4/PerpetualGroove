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
import Sequencing
import SwiftUI

// MARK: - GrooveApp

@main
final class GrooveApp: App
{
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  @Environment(\.enableMockData) var enableMockData: Bool

  var body: some Scene
  {

    DocumentGroup(newDocument: Document(sequence: self.enableMockData ? .mock : .init()))
    {
      let sequencer = Sequencer(sequence: $0.document.sequence)
      
      ContentView()
        .environment(\.openDocument, $0) // Add `file` to the environment
        .environmentObject(sequencer) // Add the sequencer.
        .statusBar(hidden: true)
        .preferredColorScheme(.dark) // Not sure this does any good.
    }
  }

}

// MARK: - MockDataEnvironmentKey

private struct MockDataEnvironmentKey: EnvironmentKey
{
  static let defaultValue: Bool = ProcessInfo.processInfo
    .environment["ENABLE_MOCK_DATA"] == "true"
}

extension EnvironmentValues
{
  public var enableMockData: Bool
  {
    get { self[MockDataEnvironmentKey.self] }
    set { self[MockDataEnvironmentKey.self] = newValue }
  }
}
