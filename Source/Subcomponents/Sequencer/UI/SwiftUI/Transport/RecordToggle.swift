//
//  RecordToggle.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

struct RecordToggle: View
{
  @Binding var isRecording: Bool

  var body: some View
  {
    Button(action: { self.isRecording.toggle() })
    {
      Image("record", bundle: bundle)
    }
    .accentColor(isRecording ? .highlightColor : .primaryColor1)
  }
}
