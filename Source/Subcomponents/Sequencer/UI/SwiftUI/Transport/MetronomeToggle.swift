//
//  MetronomeToggle.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

struct MetronomeToggle: View
{
  @Binding var isOn: Bool
  
  var body: some View
  {
    Button(action: { self.isOn.toggle() })
    {
      Image("metronome", bundle: bundle)
    }
    .accentColor(isOn ? .highlightColor : .primaryColor1)
  }
}
