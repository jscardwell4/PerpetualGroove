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
  @EnvironmentObject var sequencer: Sequencer
  @EnvironmentObject var transport: Transport

  /// The view's body.
  public var body: some View
  {
    GeometryReader
    {
      proxy in

      let 𝘸 = proxy.size.width
      let 𝘩 = proxy.size.height

      let 𝘸_wheel: CGFloat = 150
      let pad_min: CGFloat = 44
      let available = 𝘸 - 𝘸_wheel - pad_min * 2
      let half_available = available / 2

      HStack
      {
        VStack
        {
          HStack
          {
            Spacer()
            MetronomeToggle().environmentObject(sequencer.metronome)
              .frame(width: 44)
            HorizontalSlider(value: $transport.tempo)
              .frame(minWidth: 150, idealWidth: 250, maxWidth: 350, alignment: .leading)
            Spacer()
          }
          .frame(height: 44)
          Clock().environmentObject(transport.time)
        }
        .frame(width: half_available, height: 𝘩)

        Spacer()
        Wheel { logi("<\(#fileID) \(#function)> revolutions (radians): \($0)") }
        Spacer()

        HStack(spacing: 20) { RecordToggle(); PlayButton(); StopButton() }
          .frame(width: half_available, height: min(64, max(𝘩 * 0.5, 44)))
      }
      .frame(width: 𝘸, height: 𝘩)
    }
  }

  public init() {}
}
