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
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class SoundFontSelector: Picker
{
  /// Overridden to update `items` with the names of the sequencer's sound fonts.
  override public func refreshItems()
  {
    items = SoundFont.bundledFonts.map { .text($0.displayName) }
  }
}
