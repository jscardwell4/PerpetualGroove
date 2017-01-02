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

// TODO: Review file

@IBDesignable
class InlinePickerContainer: UIControl {

  override init(frame: CGRect) { super.init(frame: frame); setup() }

  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  fileprivate let picker = InlinePickerView(flat: false, frame: .zero, delegate: nil)

  @objc private func valueChanged() { sendActions(for: .valueChanged) }

  func refreshItems() { fatalError("Subclasses must override \(#function)") }

  class var contentForInterfaceBuilder: [InlinePickerView.Item] { return [] }

  class var initialSelection: Int { return 0 }

  var items: [InlinePickerView.Item] = [] { didSet { picker.reloadData() } }

  fileprivate func setColors(for picker: InlinePickerView) {
    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
  }

  fileprivate func setFonts(for picker: InlinePickerView) {
    picker.font = .controlFont
    picker.selectedFont = .controlSelectedFont
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
    constrain(𝗛∶|[picker]|, 𝗩∶|[picker]|)

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

  func inlinePicker(_ picker: InlinePickerView, contentForItem item: Int) -> InlinePickerView.Item {
    return items[item]
  }

  func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    return .zero
  }

}

final class SoundFontSelector: InlinePickerContainer {

  override func refreshItems() {
    items = Sequencer.soundSets.map { .text($0.displayName) }
  }

  private static let labels: [InlinePickerView.Item] = [
    .text("Emax Volume 1"),
    .text("Emax Volume 2"),
    .text("Emax Volume 3"),
    .text("Emax Volume 4"),
    .text("Emax Volume 5"),
    .text("Emax Volume 6"),
    .text("SPYRO's Pure Oscillators")
  ]

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

}

final class ProgramSelector: InlinePickerContainer {

  private static let labels: [InlinePickerView.Item] = [
    .text("Pop Brass"),
    .text("Trombone"),
    .text("TromSection"),
    .text("C Trumpet"),
    .text("D Trumpet"),
    .text("Trumpet")
  ]

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

  override func refreshItems() { items = soundFont?.presetHeaders.map { .text($0.name) } ?? [] }

  var soundFont: SoundFont? { didSet { refreshItems() } }

}

final class PitchSelector: InlinePickerContainer {

  private static let labels: [InlinePickerView.Item] = Natural.allCases.map({.text($0.rawValue)})

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

  override func refreshItems() { items = PitchSelector.labels }

  override class var initialSelection: Int { return 2 }

}

final class PitchModifierSelector: InlinePickerContainer {

  private static let images: [InlinePickerView.Item] = {
    #if TARGET_INTERFACE_BUILDER
      return  ["flat", "natural", "sharp"].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

        guard let image = UIImage(named: $0, in: bundle, compatibleWith: nil) else { return nil }
        return InlinePickerView.Item.image(image)
      }
    #else
      return [.image(#imageLiteral(resourceName: "flat")), .image(#imageLiteral(resourceName: "natural")), .image(#imageLiteral(resourceName: "sharp"))]
    #endif
  }()

  override class var initialSelection: Int { return 1 }

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return images }

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

  private static let labels: [InlinePickerView.Item] = [.text("–")]
                             + Chord.Pattern.Standard.allCases.map {.text($0.name)}

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return ChordSelector.labels }

  override func refreshItems() { items = ChordSelector.labels }

}

final class OctaveSelector: InlinePickerContainer {

  private static let labels: [InlinePickerView.Item] = Octave.allCases.map({.text("\($0.rawValue)")})

  override class var initialSelection: Int { return 5 }

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

  override func refreshItems() { items = OctaveSelector.labels }

}

final class DurationSelector: InlinePickerContainer {

  private static let images: [InlinePickerView.Item] = {
    #if TARGET_INTERFACE_BUILDER
     return  [
        "DoubleWhole", "DottedWhole", "Whole", "DottedHalf", "Half", "DottedQuarter",
        "Quarter", "DottedEighth", "Eighth", "DottedSixteenth", "Sixteenth",
        "DottedThirtySecond", "ThirtySecond", "DottedSixtyFourth", "SixtyFourth",
        "DottedHundredTwentyEighth", "HundredTwentyEighth", "DottedTwoHundredFiftySixth",
        "TwoHundredFiftySixth"
        ].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

          guard let image = UIImage(named: $0, in: bundle, compatibleWith: nil) else { return nil }
          return InlinePickerView.Item.image(image)
      }
    #else
      return [
        .image(#imageLiteral(resourceName: "DoubleWhole")), .image(#imageLiteral(resourceName: "DottedWhole")), .image(#imageLiteral(resourceName: "Whole")), .image(#imageLiteral(resourceName: "DottedHalf")), .image(#imageLiteral(resourceName: "Half")),
        .image(#imageLiteral(resourceName: "DottedQuarter")), .image(#imageLiteral(resourceName: "Quarter")), .image(#imageLiteral(resourceName: "DottedEighth")), .image(#imageLiteral(resourceName: "Eighth")),
        .image(#imageLiteral(resourceName: "DottedSixteenth")), .image(#imageLiteral(resourceName: "Sixteenth")), .image(#imageLiteral(resourceName: "DottedThirtySecond")), .image(#imageLiteral(resourceName: "ThirtySecond")),
        .image(#imageLiteral(resourceName: "DottedSixtyFourth")), .image(#imageLiteral(resourceName: "SixtyFourth")), .image(#imageLiteral(resourceName: "DottedHundredTwentyEighth")),
        .image(#imageLiteral(resourceName: "HundredTwentyEighth")), .image(#imageLiteral(resourceName: "DottedTwoHundredFiftySixth")), .image(#imageLiteral(resourceName: "TwoHundredFiftySixth"))
      ]
    #endif
  }()

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return images }
  override class var initialSelection: Int { return 6 }

  override func refreshItems() { items = DurationSelector.images }

}

final class VelocitySelector: InlinePickerContainer {

  private static let images: [InlinePickerView.Item] = {
    #if TARGET_INTERFACE_BUILDER
      return  ["𝑝𝑝𝑝", "𝑝𝑝", "𝑝", "𝑚𝑝", "𝑚𝑓", "𝑓", "𝑓𝑓", "𝑓𝑓𝑓"].flatMap {
        [bundle = Bundle(for: DurationSelector.self)] in

        guard let image = UIImage(named: $0, in: bundle, compatibleWith: nil) else { return nil }
        return InlinePickerView.Item.image(image)
      }
    #else
      return [
        .image(#imageLiteral(resourceName:"𝑝𝑝𝑝")), .image(#imageLiteral(resourceName:"𝑝𝑝")), .image(#imageLiteral(resourceName:"𝑝")), .image(#imageLiteral(resourceName:"𝑚𝑝")),
        .image(#imageLiteral(resourceName:"𝑚𝑓")), .image(#imageLiteral(resourceName:"𝑓")), .image(#imageLiteral(resourceName:"𝑓𝑓")), .image(#imageLiteral(resourceName:"𝑓𝑓𝑓"))
      ]
    #endif
  }()

  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return images }
  override class var initialSelection: Int { return 4 }

  override func refreshItems() { items = VelocitySelector.images }

  override func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    switch item {
      case 0...3: return UIOffset(horizontal: 0, vertical: 1)
      default: return UIOffset(horizontal: 0, vertical: 0)
    }
  }

}
