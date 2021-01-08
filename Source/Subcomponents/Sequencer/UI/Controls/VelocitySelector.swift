//
//  VelocitySelector.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/8/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonKit
import UIKit

// MARK: - VelocitySelector

/// Subclass of `Picker` whose selectable items are the enumeration `Velocity`.
public final class VelocitySelector: Picker
{
  /// A collection of images for each case in the `Velocity` enumeration
  /// converted to inline picker view items.
  private static let images: [InlinePickerView.Item] = [
    .image(#imageLiteral(resourceName: "𝑝𝑝𝑝")), .image(#imageLiteral(resourceName: "𝑝𝑝")), .image(#imageLiteral(resourceName: "𝑝")), .image(#imageLiteral(resourceName: "𝑚𝑝")),
    .image(#imageLiteral(resourceName: "𝑚𝑓")), .image(#imageLiteral(resourceName: "𝑓")), .image(#imageLiteral(resourceName: "𝑓𝑓")), .image(#imageLiteral(resourceName: "𝑓𝑓𝑓")),
  ]

  /// Overridden to return `images`.
  override public class var contentForInterfaceBuilder: [InlinePickerView.Item] { images }

  /// Overridden to return the index for selecting `𝑚𝑓`
  override public class var initialSelection: Int { 4 }

  /// Overridden to set `items` to the elements in `images`.
  override public func refreshItems() { items = VelocitySelector.images }

  /// Overridden to adjust the vertical offset by `1` for items containing
  /// the character '𝑝'.
  override public func inlinePicker(inlinePickerView: InlinePickerView,
                                    contentOffsetForItem item: Int) -> UIOffset
  {
    UIOffset(horizontal: 0, vertical: item ∈ (0 ... 3) ? 1 : 0)
  }
}
