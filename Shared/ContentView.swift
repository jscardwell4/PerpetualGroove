//
//  ContentView.swift
//  Shared
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Documents
import MIDI
import MoonDev
import Sequencing
import SoundFont
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - ContentView

/// The main content.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ContentView: View
{
  /// The shared sequencer instance loaded into the environment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The file configuration for the open document loaded into the
  /// environment by `GrooveApp`.
  @Environment(\.openDocument) var openDocument: FileDocumentConfiguration<Document>?


  private func topStack(_ geometry: GeometryProxy) -> some View
  {
    HStack
    {
      MixerView()
        .environmentObject(Mixer(sequence: sequencer.sequence)) // Create the mixer.
        .padding()
      Spacer()

      VStack(alignment: .center)
      {
        HStack { Spacer(); DocumentNameField() } .fixedSize(horizontal: false, vertical: true)
        Spacer()
        PlayerView()
          .environmentObject(sequencer.player) // Add the player.
      }
    }
    .frame(height: geometry.size.height - 200)
  }

  private var backButton: some View
  {
    VStack
    {
      Spacer()
      Button(action: goBack) { Image(systemName: "chevron.left") }
      .accentColor(.primaryColor1)
    }
  }

  private func bottomStack(_ geometry: GeometryProxy) -> some View
  {
    HStack
    {
      backButton
      Spacer()
      TransportView()
        .environmentObject(sequencer.transport) // Add the transport.
    }
    .frame(height: 200)
  }

  var body: some View
  {
    GeometryReader
    {
      geometry in

      let _ = logi("<\(#fileID) \(#function)> geometry.size: \(geometry.size)")

        VStack
        {
          topStack(geometry)
          bottomStack(geometry)
        }
        .background(Color.backgroundColor1)
        .statusBar(hidden: true)
    //    .padding()
    //    .navigationTitle("")
    //    .navigationBarHidden(true)
    //    .navigationBarBackButtonHidden(true)
    //    .edgesIgnoringSafeArea(.bottom)
    //    .softwareKeyboardAdaptive()
  }
  }

  private func goBack()
  {
    #if canImport(UIKit)
    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true) {}
    #endif
  }
}
