//
//  TransportView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import MIDI
import MoonKit
import SwiftUI

// MARK: - TransportView

/// A view for controlling the sequencer's transport.
public struct TransportView: View
{
  /// The view's body.
  public var body: some View
  {
    HStack
    {
      Group
      {
        RecordToggle()
        PlayButton()
        StopButton()
      }
      Spacer()
      JogWheel()
      Spacer()
      VStack
      {
        Clock()
        HStack
        {
          MetronomeToggle()
          TempoSlider()
        }
      }
    }
  }
}

// MARK: - TransportView_Previews

struct TransportView_Previews: PreviewProvider
{
  static var previews: some View
  {
    TransportView()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
