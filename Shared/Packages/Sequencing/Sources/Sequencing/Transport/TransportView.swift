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
import AVFoundation

// MARK: - TransportView

/// A view for controlling the sequencer's transport.
@available(iOS 14.0, *)
public struct TransportView: View
{
  @Environment(\.currentTransport) var currentTransport: Transport

  @Environment(\.audioEngine) var audioEngine: AudioEngine

  private var metronome: Metronome
  {
    let metronome = Metronome(sampler: AVAudioUnitSampler())
    audioEngine.attach(node: metronome.sampler)
    return metronome
  }

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
            MetronomeToggle()
              .environmentObject(metronome)
              .frame(width: 44)
            HorizontalSlider(value: Binding<UInt16>(get: {currentTransport.tempo},
                                                    set: {currentTransport.tempo = $0}))
              .frame(minWidth: 150, idealWidth: 250, maxWidth: 350, alignment: .leading)
            Spacer()
          }
          .frame(height: 44)
          Clock()
            .environmentObject(currentTransport.time)
        }
        .frame(width: half_available, height: 𝘩)

        Spacer()
        Wheel { logi("<\(#fileID) \(#function)> revolutions (radians): \($0)") }
        Spacer()

        TransportButtons()
          .frame(width: half_available, height: min(64, max(𝘩 * 0.5, 44)))
      }
      .frame(width: 𝘸, height: 𝘩)
    }
  }

  public init() {}
}
