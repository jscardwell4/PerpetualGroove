////
////  PitchModifierSelector.swift
////  Sequencer
////
////  Created by Jason Cardwell on 1/8/21.
////  Copyright © 2021 Moondeer Studios. All rights reserved.
////
//import Foundation
//import MoonDev
//import UIKit
//
//// MARK: - PitchModifierSelector
//
///// Subclass of `Picker` whose selectable items are the 'flat', 'natural',
///// and 'sharp' pitch modifiers.
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//internal final class PitchModifierSelector: InlineSelector
//{
//  /// A collection of images for each case in the `PitchModifier`
//  /// enumeration converted to inline picker view items.
//  private static let images: [InlinePickerView.Item] = [.image(#imageLiteral(resourceName: "flat")),
//                                                        .image(#imageLiteral(resourceName: "natural")),
//                                                        .image(#imageLiteral(resourceName: "sharp"))]
//  
//  /// Overridden to return the index for selecting `natural`.
//  override public class var initialSelection: Int { 1 }
//  
//  /// Overridden to return `images`.
//  override public class var contentForInterfaceBuilder: [InlinePickerView.Item] { images }
//  
//  /// Sets `items` to the elements in `images`.
//  override public func refreshItems() { items = PitchModifierSelector.images }
//  
//  /// Overridden to slightly reduce the item height.
//  override internal func setMetrics(for picker: InlinePickerView)
//  {
//    picker.itemHeight = 28
//    picker.itemPadding = 8
//  }
//  
//  /// Overridden to adjust the vertical offset by `-1`.
//  override public func inlinePicker(inlinePickerView: InlinePickerView,
//                                    contentOffsetForItem _: Int) -> UIOffset
//  {
//    UIOffset(horizontal: 0, vertical: -1)
//  }
//}
