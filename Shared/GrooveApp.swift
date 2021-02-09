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
      ContentView()
        .environment(\.currentDocument, $0.document)
        .statusBar(hidden: true)
        .preferredColorScheme(.dark) // Not sure this does any good.
    }
  }

}

private struct CurrentDocumentEnvironmentKey: EnvironmentKey
{
  static let defaultValue: Document? = nil
}

extension EnvironmentValues
{
  public var currentDocument: Document?
  {
    get { self[CurrentDocumentEnvironmentKey.self] }
    set { self[CurrentDocumentEnvironmentKey.self] = newValue }
  }
}

