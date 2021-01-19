////
////  PitchSelector.swift
////  Sequencer
////
////  Created by Jason Cardwell on 1/8/21.
////  Copyright © 2021 Moondeer Studios. All rights reserved.
////
//import Foundation
//import MoonDev
//
//// MARK: - PitchSelector
//
///// Subclass of `Picker` whose selectable items are the seven 'natural' note names
///// in western tonal music.
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//internal final class PitchSelector: InlineSelector
//{
//  /// The collection of `Natural` cases converted to an inline picker view item.
//  private static let labels: [InlinePickerView.Item] =
//    Natural.allCases.map { .text($0.rawValue) }
//
//  /// Overridden to return `labels`.
//  override public class var contentForInterfaceBuilder: [InlinePickerView.Item] { labels }
//
//  /// Overridden to set the items to the elements in `labels`.
//  override public func refreshItems() { items = PitchSelector.labels }
//
//  /// Overridden to return the index for selecting 'c'.
//  override public class var initialSelection: Int { 2 }
//}
