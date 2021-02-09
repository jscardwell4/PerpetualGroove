//
//  ContentView_Previews.swift
//  Groove
//
//  Created by Jason Cardwell on 2/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import Documents
import Sequencing
import Common
import MoonDev
import SoundFont
import MIDI

struct ContentView_Previews: PreviewProvider
{
  @State static var document = Document(sequence: Sequence.mock)

  static var previews: some View
  {
    ContentView()
      .environment(\.currentDocument, document)
      .previewLayout(.device)
      .previewDevice("iPad Pro (11-inch) (2nd generation)")
      .preferredColorScheme(.dark)
  }
}
