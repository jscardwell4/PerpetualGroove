////
////  OctaveSelector.swift
////  Sequencer
////
////  Created by Jason Cardwell on 1/8/21.
////  Copyright © 2021 Moondeer Studios. All rights reserved.
////
//import Foundation
//import MoonDev
//
//// MARK: - OctaveSelector
//
///// Subclass of `Picker` whose selectable items are the enumeration `Octave`.
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//internal final class OctaveSelector: InlineSelector
//{
//  /// The collection of `Octave` cases converted to inline picker view items.
//  private static let labels: [InlinePickerView.Item] = Octave.allCases.map
//  {
//    .text("\($0.rawValue)")
//  }
//  
//  /// Overridden to return the index for selecting `four`.
//  override public class var initialSelection: Int { 5 }
//  
//  /// Overridden to return `labels`.
//  override public class var contentForInterfaceBuilder: [InlinePickerView.Item] { labels }
//  
//  /// Overridden to set `items` to the elements in `labels`.
//  override public func refreshItems() { items = OctaveSelector.labels }
//}
