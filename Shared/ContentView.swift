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
import Sequencer
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
  @EnvironmentObject var sequence: Sequence
  @EnvironmentObject var sequencer: Controller

  @Environment(\.openDocument) var openDocument: FileDocumentConfiguration<Document>?

  private var subscriptions: Set<AnyCancellable> = []

  var body: some View
  {
    VStack
    {
      HStack
      {
        MixerView().padding()
        Spacer()
        VStack(alignment: .trailing)
        {
          DocumentNameField()
          PlayerView()
        }
        .padding()
      }

      HStack
      {
        VStack
        {
          Spacer()
          Button(action: goBack)
          {
            Image(systemName: "chevron.left")
          }
          .accentColor(.primaryColor1)
        }
        Spacer()
        TransportView().environmentObject(sequencer.transport)
      }
      .padding()
    }
    .padding()
    .background(Color.backgroundColor1)
    .navigationTitle("")
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .statusBar(hidden: true)
    .edgesIgnoringSafeArea(.bottom)
    .softwareKeyboardAdaptive()
    .onAppear
    {
      guard let file = openDocument,
            let name = file.fileURL?.deletingPathExtension().lastPathComponent,
            file.document.sequence.name.isEmpty
      else
      {
        return
      }
      file.document.sequence.name = name
      file.document = file.document.modified
      logi("<\(#fileID) \(#function)> empty name has been set to '\(name)'")
    }
  }

  private func goBack()
  {
    #if canImport(UIKit)
    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true) {}
    #endif
  }
}

// MARK: - ContentView_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ContentView_Previews: PreviewProvider
{
  @State static var document = Document(sequence: Sequence.mock)

  static var previews: some View
  {
    ContentView()
      .environmentObject(sequencer)
      .environmentObject(document.sequence)
      .previewLayout(.fixed(width: 2_732 / 2, height: 2_048 / 2))
      .preferredColorScheme(.dark)
  }
}
