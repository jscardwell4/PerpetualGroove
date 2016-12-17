//
//  InlinePickerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/26/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

@IBDesignable
class InlinePickerContainer: UIControl {

  override init(frame: CGRect) { super.init(frame: frame); setup() }

  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  fileprivate let picker = InlinePickerView(flat: false, frame: .zero, delegate: nil)

  @objc private func valueChanged() { sendActions(for: .valueChanged) }

  func refreshItems() { fatalError("Subclasses must override \(#function)") }

  class var contentForInterfaceBuilder: [Any] { return [] }

  class var initialSelection: Int { return 0 }

  var items: [Any] = [] { didSet { picker.reloadData() } }

  fileprivate func setColors(for picker: InlinePickerView) {
    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
  }

  fileprivate func setFonts(for picker: InlinePickerView) {
    picker.font = .largeControlFont
    picker.selectedFont = .largeControlSelectedFont
  }

  fileprivate func setMetrics(for picker: InlinePickerView) {
    picker.itemHeight = 36
    picker.itemPadding = 8
  }

  private func decorate(picker: InlinePickerView) {
    setColors(for: picker)
    setFonts(for: picker)
    setMetrics(for: picker)
  }

  private func setup() {
    picker.delegate = self
    picker.accessibilityIdentifier = accessibilityIdentifier
    picker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    decorate(picker: picker)
    addSubview(picker)
    constrain(𝗛|picker|𝗛, 𝗩|picker|𝗩)

    #if TARGET_INTERFACE_BUILDER
      items = type(of: self).contentForInterfaceBuilder
    #else
      refreshItems()
    #endif

    picker.selection = type(of: self).initialSelection
  }

  /// Forward identifier to wrapped `InlinePickerView`.
  override var accessibilityIdentifier: String? {
    didSet {
      picker.accessibilityIdentifier = accessibilityIdentifier
    }
  }

  var selection: Int { get { return picker.selection } set { picker.selection = selection } }

  func selectItem(_ item: Int, animated: Bool) { picker.selectItem(item, animated: animated) }

  override var intrinsicContentSize: CGSize { return picker.intrinsicContentSize }

  override var forLastBaselineLayout: UIView { return picker.forLastBaselineLayout }

}

extension InlinePickerContainer: InlinePickerDelegate {

  func numberOfItems(in picker: InlinePickerView) -> Int { return items.count }
  func inlinePicker(_ picker: InlinePickerView, contentForItem item: Int) -> Any { return items[item] }
  func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset { return .zero }

}

final class SoundFontSelector: InlinePickerContainer {

  override func refreshItems() {
    items = Sequencer.soundSets.map { $0.displayName }
  }

  private static let labels: [String] = [
    "Emax Volume 1",
    "Emax Volume 2",
    "Emax Volume 3",
    "Emax Volume 4",
    "Emax Volume 5",
    "Emax Volume 6",
    "SPYRO's Pure Oscillators"
  ]

  override class var contentForInterfaceBuilder: [Any] { return labels }

}

final class ProgramSelector: InlinePickerContainer {

  private static let labels: [String] = [
    "Pop Brass",
    "Trombone",
    "TromSection",
    "C Trumpet",
    "D Trumpet",
    "Trumpet"
  ]

  override class var contentForInterfaceBuilder: [Any] { return labels }

  override func refreshItems() { items = soundFont?.presetHeaders.map { $0.name } ?? [] }

  var soundFont: SoundFont? { didSet { refreshItems() } }

}

final class PitchSelector: InlinePickerContainer {

  private static let labels = Natural.allCases.map({"\($0.rawValue)"})

  override class var contentForInterfaceBuilder: [Any] { return labels }

  override func refreshItems() { items = PitchSelector.labels }

  override class var initialSelection: Int { return 2 }

}

final class PitchModifierSelector: InlinePickerContainer {

  private static let images: [UIImage] = {
    #if TARGET_INTERFACE_BUILDER
      return  ["flat", "natural", "sharp"].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

          UIImage(named: $0, in: bundle, compatibleWith: nil)
      }
    #else
      return [#imageLiteral(resourceName: "flat"), #imageLiteral(resourceName: "natural"), #imageLiteral(resourceName: "sharp")]
    #endif
  }()

  override class var initialSelection: Int { return 1 }

  override class var contentForInterfaceBuilder: [Any] { return images }

  override func refreshItems() { items = PitchModifierSelector.images }

  fileprivate override func setMetrics(for picker: InlinePickerView) {
    picker.itemHeight = 28
    picker.itemPadding = 8
  }


  override func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    return UIOffset(horizontal: 0, vertical: -1)
  }

}

final class ChordSelector: InlinePickerContainer {

  private static let labels = ["–"] + Chord.Pattern.Standard.allCases.map {$0.name}

  override class var contentForInterfaceBuilder: [Any] { return ChordSelector.labels }

  override func refreshItems() { items = ChordSelector.labels }

}

final class OctaveSelector: InlinePickerContainer {

  private static let labels = Octave.allCases.map({"\($0.rawValue)"})

  override class var initialSelection: Int { return 5 }

  override class var contentForInterfaceBuilder: [Any] { return labels }

  override func refreshItems() { items = OctaveSelector.labels }

}

final class DurationSelector: InlinePickerContainer {

  private static let images: [UIImage] = {
    #if TARGET_INTERFACE_BUILDER
     return  [
        "DoubleWhole", "DottedWhole", "Whole", "DottedHalf", "Half", "DottedQuarter",
        "Quarter", "DottedEighth", "Eighth", "DottedSixteenth", "Sixteenth",
        "DottedThirtySecond", "ThirtySecond", "DottedSixtyFourth", "SixtyFourth",
        "DottedHundredTwentyEighth", "HundredTwentyEighth", "DottedTwoHundredFiftySixth",
        "TwoHundredFiftySixth"
        ].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

          UIImage(named: $0, in: bundle, compatibleWith: nil)
      }
    #else
      return [
        #imageLiteral(resourceName: "DoubleWhole"), #imageLiteral(resourceName: "DottedWhole"), #imageLiteral(resourceName: "Whole"), #imageLiteral(resourceName: "DottedHalf"), #imageLiteral(resourceName: "Half"), #imageLiteral(resourceName: "DottedQuarter"),
        #imageLiteral(resourceName: "Quarter"), #imageLiteral(resourceName: "DottedEighth"), #imageLiteral(resourceName: "Eighth"), #imageLiteral(resourceName: "DottedSixteenth"), #imageLiteral(resourceName: "Sixteenth"),
        #imageLiteral(resourceName: "DottedThirtySecond"), #imageLiteral(resourceName: "ThirtySecond"), #imageLiteral(resourceName: "DottedSixtyFourth"), #imageLiteral(resourceName: "SixtyFourth"),
        #imageLiteral(resourceName: "DottedHundredTwentyEighth"), #imageLiteral(resourceName: "HundredTwentyEighth"), #imageLiteral(resourceName: "DottedTwoHundredFiftySixth"),
        #imageLiteral(resourceName: "TwoHundredFiftySixth")
      ]
    #endif
  }()

  override class var contentForInterfaceBuilder: [Any] { return images }
  override class var initialSelection: Int { return 6 }

  override func refreshItems() { items = DurationSelector.images }

}

final class VelocitySelector: InlinePickerContainer {

  private static let images: [UIImage] = {
    #if TARGET_INTERFACE_BUILDER
      return  ["𝑝𝑝𝑝", "𝑝𝑝", "𝑝", "𝑚𝑝", "𝑚𝑓", "𝑓", "𝑓𝑓", "𝑓𝑓𝑓"].flatMap {
        [bundle = Bundle(for: DurationSelector.self)] in

        UIImage(named: $0, in: bundle, compatibleWith: nil)
      }
    #else
      return [#imageLiteral(resourceName:"𝑝𝑝𝑝"), #imageLiteral(resourceName:"𝑝𝑝"), #imageLiteral(resourceName:"𝑝"), #imageLiteral(resourceName:"𝑚𝑝"), #imageLiteral(resourceName:"𝑚𝑓"), #imageLiteral(resourceName:"𝑓"), #imageLiteral(resourceName:"𝑓𝑓"), #imageLiteral(resourceName:"𝑓𝑓𝑓")]
    #endif
  }()

  override class var contentForInterfaceBuilder: [Any] { return images }
  override class var initialSelection: Int { return 4 }

  override func refreshItems() { items = VelocitySelector.images }

  override func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    switch item {
      case 0...3: return UIOffset(horizontal: 0, vertical: 1)
      default: return UIOffset(horizontal: 0, vertical: 0)
    }
  }

}
