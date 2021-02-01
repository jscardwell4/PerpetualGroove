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
  let isEditing: Bool

  func body(content: Content) -> some View
  {
    content
      .allowsTightening(true)
      .triumpFont(family: .rock, volume: .two, size: 14)
      .foregroundColor(isEditing ? .busLabelActive : .busLabel)
  }
}

extension View
{
  /// Decorates the view to appear like one of the mixer's bus labels.
  /// - Returns: The modified content.
  func busLabel(isEditing: Bool = false) -> some View
  {
    modifier(BusLabel(isEditing: isEditing))
  }
}

extension Color
{
  static let busLabel = Color("mixerLabel", bundle: .module)
  static let busLabelActive = Color("tint", bundle: .module)
}

#if canImport(UIKit)
extension UIColor
{
  static let busLabel = UIColor(named: "mixerLabel", in: .module, compatibleWith: nil)!
  static let busLabelActive = UIColor(named: "tint", in: .module, compatibleWith: nil)!
}
#endif
