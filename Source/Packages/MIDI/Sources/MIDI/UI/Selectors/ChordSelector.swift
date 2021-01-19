////
////  ChordSelector.swift
////  Sequencer
////
////  Created by Jason Cardwell on 1/8/21.
////  Copyright © 2021 Moondeer Studios. All rights reserved.
////
//
//import Foundation
//import MoonDev
//import SwiftUI
//import Common
//#if os(iOS)
//import UIKit
//#endif
//// MARK: - ChordSelector
//
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//public struct ChordSelector: View
//{
//
//  public var body: some View
//  {
//    ChordSelectorHost()
//  }
//
//}
//
//// MARK: - ChordSelectorHost
//
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//internal final class ChordSelectorHost: UIViewRepresentable, InlinePickerDelegate
//{
//  /// The collection of `Chord.Patter.Standard` cases converted to inline picker
//  /// view items. Also includes as its first element an item for representing the
//  /// empty selection.
//  private static let labels: [InlinePickerView.Item] =
//    [.text("–")] + Chord.Pattern.Standard.allCases.map { .text($0.name) }
//
//  func makeUIView(context: Context) -> InlinePickerView
//  {
//    let selector = InlinePickerView(flat: false, frame: .zero, delegate: nil)
//    selector.font = .control
//    selector.selectedFont = .controlSelected
//    selector.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
//    selector.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
//    selector.itemHeight = 36
//    selector.itemPadding = 8
//    selector.delegate = self
//    return selector
//  }
//
//  func updateUIView(_ uiView: InlinePickerView, context: Context)
//  {
//  }
//
//  /// Returns the number of elements in `items`.
//  func numberOfItems(in inlinePickerView: InlinePickerView) -> Int
//  {
//    ChordSelectorHost.labels.count
//  }
//
//  /// Returns the element in `items` at `item`.
//  func inlinePicker(_ inlinePickerView: InlinePickerView,
//                           contentForItem item: Int) -> InlinePickerView.Item
//  {
//    ChordSelectorHost.labels[item]
//  }
//
//  /// Returns the `zero` offset.
//  func inlinePicker(inlinePickerView: InlinePickerView,
//                           contentOffsetForItem _: Int) -> UIOffset
//  {
//    .zero
//  }
//}
//
//// MARK: - ChordSelector_Previews
//
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//struct ChordSelector_Previews: PreviewProvider
//{
//  static var previews: some View
//  {
//    ChordSelector()
//  }
//}
