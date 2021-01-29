//
//  BusLabel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - BusLabel

/// A view modifier for decorating text to appear like one of the mixer's bus labels.
struct BusLabel: ViewModifier
{
  func body(content: Content) -> some View
  {
    content
      .allowsTightening(true)
      .triumpFont(family: .rock, volume: .two, size: 14)
      .foregroundColor(.busLabel)
  }
}

extension View
{
  /// Decorates the view to appear like one of the mixer's bus labels.
  /// - Returns: The modified content.
  func busLabel() -> some View { modifier(BusLabel()) }
}

extension Color
{
  static let busLabel = Color("mixerLabel", bundle: .module)
}
