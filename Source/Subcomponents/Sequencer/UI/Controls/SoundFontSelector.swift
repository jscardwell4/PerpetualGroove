//
//  SoundFontSelector.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/8/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev
import SoundFont

// MARK: - SoundFontSelector

/// Subclass of `Picker` whose selectable items are the names of available sound fonts.
public final class SoundFontSelector: Picker
{
  /// Overridden to update `items` with the names of the sequencer's sound fonts.
  override public func refreshItems()
  {
    items = AnySoundFont.bundledFonts.map { .text($0.displayName) }
  }
  
  /// The names to use items when built for interface builder.
  private static let labels: [InlinePickerView.Item] = [
    .text("Emax Volume 1"),
    .text("Emax Volume 2"),
    .text("Emax Volume 3"),
    .text("Emax Volume 4"),
    .text("Emax Volume 5"),
    .text("Emax Volume 6"),
    .text("SPYRO's Pure Oscillators"),
  ]
  
  /// Overridden to return `labels`.
  override public class var contentForInterfaceBuilder: [InlinePickerView.Item] { labels }
}
