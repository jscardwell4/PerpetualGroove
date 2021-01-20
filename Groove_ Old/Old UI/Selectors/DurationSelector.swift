////
////  DurationSelector.swift
////  Sequencer
////
////  Created by Jason Cardwell on 1/8/21.
////  Copyright © 2021 Moondeer Studios. All rights reserved.
////
//import Foundation
//import MoonDev
//
//// MARK: - DurationSelector
//
///// Subclass of `Picker` whose selectable items are the enumeration `Duration`.
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//internal final class DurationSelector: InlineSelector
//{
//  /// A collection of images for each case in the `Duration` enumeration converted
//  /// to inline picker view items.
//  private static let images: [InlinePickerView.Item] = [
//    .image(#imageLiteral(resourceName: "DoubleWhole")), .image(#imageLiteral(resourceName: "DottedWhole")), .image(#imageLiteral(resourceName: "Whole")), .image(#imageLiteral(resourceName: "DottedHalf")), .image(#imageLiteral(resourceName: "Half")),
//    .image(#imageLiteral(resourceName: "DottedQuarter")), .image(#imageLiteral(resourceName: "Quarter")), .image(#imageLiteral(resourceName: "DottedEighth")), .image(#imageLiteral(resourceName: "Eighth")),
//    .image(#imageLiteral(resourceName: "DottedSixteenth")), .image(#imageLiteral(resourceName: "Sixteenth")), .image(#imageLiteral(resourceName: "DottedThirtySecond")), .image(#imageLiteral(resourceName: "ThirtySecond")),
//    .image(#imageLiteral(resourceName: "DottedSixtyFourth")), .image(#imageLiteral(resourceName: "SixtyFourth")), .image(#imageLiteral(resourceName: "DottedHundredTwentyEighth")),
//    .image(#imageLiteral(resourceName: "HundredTwentyEighth")), .image(#imageLiteral(resourceName: "DottedTwoHundredFiftySixth")), .image(#imageLiteral(resourceName: "TwoHundredFiftySixth")),
//  ]
//
//  /// Overridden to return the index for selecting `quarter`.
//  override public class var initialSelection: Int { 6 }
//
//  /// Overridden to set `items` to the elements in `images`.
//  override public func refreshItems() { items = DurationSelector.images }
//}
