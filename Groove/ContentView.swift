//
//  ContentView.swift
//  Groove
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import Documents
import MIDI
import Sequencer
import SoundFont
import SwiftUI

// MARK: - ContentView

struct ContentView: View
{
  @Binding var document: GrooveDocument
  
  var body: some View
  {
    Text("Hello, world!")
      .padding()
  }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider
{
  static var previews: some View
  {
    ContentView(document: .constant(GrooveDocument()))
      .previewLayout(.device)
      .preferredColorScheme(.dark)
  }
}
