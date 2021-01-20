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
import MoonDev
import SwiftUI

// MARK: - TransportView

/// A view for controlling the sequencer's transport.
@available(iOS 14.0, *)
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
        .frame(width: 44)
      JogWheel()
      Spacer()
        .frame(width: 88)
      VStack
      {
        Clock()
          .fixedSize()
        HStack
        {
          MetronomeToggle()
          TempoSlider()
        }
        .offset(x: 0, y: -20)
      }
    }
  }

  public init() {}
  
}

// MARK: - TransportView_Previews

@available(iOS 14.0, *)
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
