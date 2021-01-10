//
//  ChordSelector.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/8/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonKit

// MARK: - ChordSelector

/// Subclass of `Picker` whose selectable items are the standard chord patterns.
public final class ChordSelector: Picker
{
  /// The collection of `Chord.Patter.Standard` cases converted to inline picker
  /// view items. Also includes as its first element an item for representing the
  /// empty selection.
  private static let labels: [InlinePickerView.Item] =
    [.text("–")] + Chord.Pattern.Standard.allCases.map { .text($0.name) }
  
  /// Overridden to return `labels`.
  override public class var contentForInterfaceBuilder: [InlinePickerView.Item]
  {
    ChordSelector.labels
  }
  
  /// Overridden to set `items` to the elements in `labels`.
  override public func refreshItems() { items = ChordSelector.labels }
}
