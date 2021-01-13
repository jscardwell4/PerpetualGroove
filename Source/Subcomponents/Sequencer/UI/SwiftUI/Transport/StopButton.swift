//
//  StopButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

struct StopButton: View
{
  @Binding var isEnabled: Bool

  var body: some View
  {
    Button(action: {})
    {
      Image("stop", bundle: bundle)
    }
    .disabled(!isEnabled)
    .accentColor(isEnabled ? .primaryColor1 : .disabledColor)
  }
}
