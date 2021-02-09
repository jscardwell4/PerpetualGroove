////
////  ProgramSelector.swift
////  Sequencer
////
////  Created by Jason Cardwell on 1/8/21.
////  Copyright © 2021 Moondeer Studios. All rights reserved.
////
//import Foundation
//import MoonDev
//import SoundFont
//
//// MARK: - ProgramSelector
//
///// Subclass of `Picker` whose selectable items are the names of programs
///// contained by a sound font.
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//internal final class ProgramSelector: InlineSelector
//{
//  /// The names to use as items when built for interface builder.
//  private static let labels: [InlinePickerView.Item] = [
//    .text("Pop Brass"),
//    .text("Trombone"),
//    .text("TromSection"),
//    .text("C Trumpet"),
//    .text("D Trumpet"),
//    .text("Trumpet"),
//  ]
//  
//  /// Overridden to return `labels`.
//  override public class var contentForInterfaceBuilder: [InlinePickerView.Item] { labels }
//  
//  /// Overridden to update `items` with the preset header names from `soundFont`.
//  override public func refreshItems()
//  {
//    items = soundFont?.presetHeaders.map { .text($0.name) } ?? []
//  }
//  
//  /// The sound font from which preset header names are queried for `items`.
//  /// Setting the value of this property causes `items` to refresh.
//  public var soundFont: SoundFont2? { didSet { refreshItems() } }
//}
