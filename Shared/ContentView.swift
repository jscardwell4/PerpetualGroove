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
  @Environment(\.currentDocument) var currentDocument: Document?
  @Environment(\.player) var player: Player

  private func playerView(_ layout: LayoutPreference) -> some View
  {
    player.sceneSize = layout.playerSize
    return PlayerView().frame(preference: layout[.player])
  }

  var body: some View
  {
    if let document = currentDocument
    {
      GeometryReader
      {
        let layout = LayoutPreference(geometry: $0)
        let sequencer = Sequencer(sequence: document.sequence)
        let sequence = sequencer.sequence
        let mixer = Mixer(sequence: sequence)

        VStack
        {
          HStack
          {
            MixerView()
              .environmentObject(mixer)
              .frame(preference: layout[.mixer])
              .softwareKeyboardAdaptive()
            Spacer()
            playerView(layout)
          }
          .frame(preference: layout[.topStack])

          HStack
          {
            TransportView()
              .environmentObject(sequencer)
              .frame(preference: layout[.transport])
          }
          .frame(preference: layout[.bottomStack])
        }
        .background(Color.backgroundColor1.edgesIgnoringSafeArea(.all))
        .frame(preference: layout[.rootStack])
        .navigationBarItems(
          leading: HStack
          {
            Button(action: dismiss)
            {
              Image(systemName: "chevron.left")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(minHeight: 14, idealHeight: 14, maxHeight: 14)
            }
            .accentColor(.primaryColor1)
            .contentShape(Rectangle())
            .frame(preference: layout[.backButton])
            HStack
            {
              Spacer()
              NameField()
                .environmentObject(sequence)
              Spacer()
            }
            .frame(preference: layout[.nameField])
          }
          .frame(preference: layout[.leadingItem]),
          trailing: HStack
          {
            Toolbar()
              .environmentObject(sequence)
              .environmentObject(player)
              .frame(preference: layout[.toolbar])
          }
          .frame(preference: layout[.trailingItem])
        )
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
      }
    }
    else
    {
      EmptyView()
    }
  }

  private func dismiss()
  {
    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true) {}
  }
}
