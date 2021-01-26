//
//  ControlLabel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/26/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - ControlLabel

/// A view modifier for decorating text to appear like one of the mixer's bus labels.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ControlLabel: ViewModifier
{
  func body(content: Content) -> some View
  {
    content
      .evelethFont(family: .normal, weigth: .regular, size: 12)
      .foregroundColor(.controlLabel)
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension View
{
  /// Decorates the view to appear like one of the mixer's bus labels.
  /// - Returns: The modified content.
  func controlLabel() -> some View { modifier(ControlLabel()) }
}

extension Color
{
  static let controlLabel = Color("mixerLabel", bundle: .module)
}
