//
//  TempoSlider.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import SwiftUI

// MARK: - TempoSlider

/// A view wrapping a hosted instance of `MoonDev.Slider` for controlling the
/// transport's tempo setting.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct TempoSlider: View
{
  /// The transport being controlled by the slider.
  @EnvironmentObject private var transport: Transport

  /// The view's body is composed of the slider host constrained to 330w x 44h.
  var body: some View
  {
    HorizontalSlider(value: $transport.tempo)
      .frame(width: 300)
  }

}
