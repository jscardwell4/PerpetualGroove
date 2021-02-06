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
        .environmentObject(sequencer) // Add the sequencer.
        .statusBar(hidden: true)
        .preferredColorScheme(.dark) // Not sure this does any good.
    }
  }

}

