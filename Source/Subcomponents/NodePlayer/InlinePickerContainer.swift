//
//  InlinePickerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/26/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import UIKit
import SoundFont
import MoonKit
import MIDI

/// An abstract subclass of `UIControl` that wraps an instance of `InlinePickerView` to provide
/// application-specific customization.
@IBDesignable
public class InlinePickerContainer: UIControl, InlinePickerDelegate {

  /// Overridden to invoke `setup()`.
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /// Overridden to invoke `setup()`.
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  /// The inline picker view being wrapped.
  fileprivate let picker = InlinePickerView(flat: false, frame: .zero, delegate: nil)

  /// Sends actions for `valueChanged`. Invoked by `picker` value changes.
  @objc private func valueChanged() { sendActions(for: .valueChanged) }

  /// Updates the items displayed by `picker`. This method is abstract and must be overridden
  /// by subclasses of `InlinePickerContainer`.
  public func refreshItems() {

    fatalError("Subclasses must override \(#function)")

  }

  /// The items to give `picker` when built for interface builder.
  class var contentForInterfaceBuilder: [InlinePickerView.Item] { return [] }

  /// The index of the default item.
  class var initialSelection: Int { return 0 }

  /// The items displayed by `picker`. Setting the value of this property causes `picker` to reload.
  public var items: [InlinePickerView.Item] = [] {

    didSet {

      // Reload the picker view to keep the picker view's items in sync with `items`.
      picker.reloadData()

    }

  }

  /// Sets the item color and selected item color for `picker`.
  fileprivate func setColors(for picker: InlinePickerView) {

    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)

  }

  /// Sets the font and selected font for `picker`.
  fileprivate func setFonts(for picker: InlinePickerView) {
    picker.font = .controlFont
    picker.selectedFont = .controlSelectedFont
  }

  /// Sets the item height and item padding for `picker`.
  fileprivate func setMetrics(for picker: InlinePickerView) {
    picker.itemHeight = 36
    picker.itemPadding = 8
  }

  /// Sets the colors, fonts, and metrics for `picker`.
  private func decorate(picker: InlinePickerView) {

    setColors(for: picker)
    setFonts(for: picker)
    setMetrics(for: picker)

  }

  /// Configures the inline picker container.
  private func setup() {

    // Assign `self` as the picker view's delegate.
    picker.delegate = self

    // Assign to the picker view the accessibility identifier that was assigned to the container.
    picker.accessibilityIdentifier = accessibilityIdentifier

    // Add the target for picker view value changes.
    picker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)

    // Configure the appearance of the picker view.
    decorate(picker: picker)

    // Add the picker view as a subview.
    addSubview(picker)

    // Add constraints to keep the picker vertically and horizontally stretched across the container.
    constrain(𝗛∶|[picker]|, 𝗩∶|[picker]|)


    #if TARGET_INTERFACE_BUILDER

      // Assign the interface builder content to `items`.
      items = type(of: self).contentForInterfaceBuilder

    #else

      // Assign items via a refresh.
      refreshItems()

    #endif

    // Make the default selection.
    picker.selection = type(of: self).initialSelection

  }

  /// Overridden to update the accessibility identifier of `picker` whenever the value of this property
  /// changes.
  public override var accessibilityIdentifier: String? {

    didSet {

      // Give the picker view the same accessibility identifer.
      picker.accessibilityIdentifier = accessibilityIdentifier

    }

  }

  /// The index of the selected item in `items`. This is a derived property wrapping the property
  /// accessors of `picker.selection`.
  public var selection: Int {
    get { return picker.selection }
    set { picker.selection = newValue }
  }

  /// Selects the item at the specified index.
  /// - Parameter item: The index of the item to select.
  /// - Parameter animated: Whether to animate changes to the selection.
  public func selectItem(_ item: Int, animated: Bool) {

    picker.selectItem(item, animated: animated)

  }

  /// Overridden to return the intrinsic content size returned by `picker`.
  public override var intrinsicContentSize: CGSize { return picker.intrinsicContentSize }

  /// Overridden to return the view returned by `picker` for the same property.
  public override var forLastBaselineLayout: UIView { return picker.forLastBaselineLayout }

  /// Returns the number of elements in `items`.
  public func numberOfItems(in picker: InlinePickerView) -> Int {
    return items.count
  }

  /// Returns the element in `items` at `item`.
  public func inlinePicker(_ picker: InlinePickerView, contentForItem item: Int) -> InlinePickerView.Item {
    return items[item]
  }

  /// Returns the `zero` offset.
  public func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    return .zero
  }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the names of available sound fonts.
public final class SoundFontSelector: InlinePickerContainer {

  /// Overridden to update `items` with the names of the sequencer's sound fonts.
  public override func refreshItems() {
    fatalError("\(#function) not yet implemented.")
//    items = Sequencer.soundFonts.map { .text($0.displayName) }
  }

  /// The names to use items when built for interface builder.
  private static let labels: [InlinePickerView.Item] = [
    .text("Emax Volume 1"),
    .text("Emax Volume 2"),
    .text("Emax Volume 3"),
    .text("Emax Volume 4"),
    .text("Emax Volume 5"),
    .text("Emax Volume 6"),
    .text("SPYRO's Pure Oscillators")
  ]

  /// Overridden to return `labels`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the names of programs
/// contained by a sound font.
public final class ProgramSelector: InlinePickerContainer {

  /// The names to use as items when built for interface builder.
  private static let labels: [InlinePickerView.Item] = [
    .text("Pop Brass"),
    .text("Trombone"),
    .text("TromSection"),
    .text("C Trumpet"),
    .text("D Trumpet"),
    .text("Trumpet")
  ]

  /// Overridden to return `labels`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

  /// Overridden to update `items` with the preset header names from `soundFont`.
  public override func refreshItems() { items = soundFont?.presetHeaders.map { .text($0.name) } ?? [] }

  /// The sound font from which preset header names are queried for `items`. Setting the value of
  /// this property causes `items` to refresh.
  public var soundFont: SoundFont2? { didSet { refreshItems() } }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the seven 'natural' note names
/// in western tonal music.
public final class PitchSelector: InlinePickerContainer {

  /// The collection of `Natural` cases converted to an inline picker view item.
  private static let labels: [InlinePickerView.Item] = Natural.allCases.map({.text($0.rawValue)})

  /// Overridden to return `labels`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

  /// Overridden to set the items to the elements in `labels`.
  public override func refreshItems() { items = PitchSelector.labels }

  /// Overridden to return the index for selecting 'c'.
  override class var initialSelection: Int { return 2 }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the 'flat', 'natural', and 'sharp' 
/// pitch modifiers.
public final class PitchModifierSelector: InlinePickerContainer {

  /// A collection of images for each case in the `PitchModifier` enumeration converted to inline
  /// picker view items.
  private static let images: [InlinePickerView.Item] = {

    #if TARGET_INTERFACE_BUILDER
      // The use of image literal syntax seems to crash interface builder, so we avoid it here.

      return  ["flat", "natural", "sharp"].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

        guard let image = UIImage(named: $0, in: bundle, compatibleWith: nil) else { return nil }
        return InlinePickerView.Item.image(image)
      }

    #else

      return [.image(#imageLiteral(resourceName: "flat")), .image(#imageLiteral(resourceName: "natural")), .image(#imageLiteral(resourceName: "sharp"))]

    #endif

  }()

  /// Overridden to return the index for selecting `natural`.
  override class var initialSelection: Int { return 1 }

  /// Overridden to return `images`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return images }

  /// Sets `items` to the elements in `images`.
  public override func refreshItems() { items = PitchModifierSelector.images }

  /// Overridden to slightly reduce the item height.
  fileprivate override func setMetrics(for picker: InlinePickerView) {
    picker.itemHeight = 28
    picker.itemPadding = 8
  }

  /// Overridden to adjust the vertical offset by `-1`.
  public override func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    return UIOffset(horizontal: 0, vertical: -1)
  }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the standard chord patterns.
public final class ChordSelector: InlinePickerContainer {

  /// The collection of `Chord.Patter.Standard` cases converted to inline picker view items. Also
  /// includes as its first element an item for representing the empty selection.
  private static let labels: [InlinePickerView.Item] = [.text("–")]
                             + Chord.Pattern.Standard.allCases.map {.text($0.name)}

  /// Overridden to return `labels`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return ChordSelector.labels }

  /// Overridden to set `items` to the elements in `labels`.
  public override func refreshItems() { items = ChordSelector.labels }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the enumeration `Octave`.
public final class OctaveSelector: InlinePickerContainer {

  /// The collection of `Octave` cases converted to inline picker view items.
  private static let labels: [InlinePickerView.Item] = Octave.allCases.map({.text("\($0.rawValue)")})

  /// Overridden to return the index for selecting `four`.
  override class var initialSelection: Int { return 5 }

  /// Overridden to return `labels`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return labels }

  /// Overridden to set `items` to the elements in `labels`.
  public override func refreshItems() { items = OctaveSelector.labels }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the enumeration `Duration`.
public final class DurationSelector: InlinePickerContainer {

  /// A collection of images for each case in the `Duration` enumeration converted to inline picker
  /// view items.
  private static let images: [InlinePickerView.Item] = {

    #if TARGET_INTERFACE_BUILDER
      // The use of image literal syntax seems to crash interface builder, so we avoid it here.

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

  /// Overridden to return `images`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return images }

  /// Overridden to return the index for selecting `quarter`.
  override class var initialSelection: Int { return 6 }

  /// Overridden to set `items` to the elements in `images`.
  public override func refreshItems() { items = DurationSelector.images }

}

/// Subclass of `InlinePickerContainer` whose selectable items are the enumeration `Velocity`.
public final class VelocitySelector: InlinePickerContainer {

  /// A collection of images for each case in the `Velocity` enumeration converted to inline picker
  /// view items.
  private static let images: [InlinePickerView.Item] = {

    #if TARGET_INTERFACE_BUILDER
      // The use of image literal syntax seems to crash interface builder, so we avoid it here.

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

  /// Overridden to return `images`.
  override class var contentForInterfaceBuilder: [InlinePickerView.Item] { return images }

  /// Overridden to return the index for selecting `𝑚𝑓`
  override class var initialSelection: Int { return 4 }

  /// Overridden to set `items` to the elements in `images`.
  public override func refreshItems() { items = VelocitySelector.images }

  /// Overridden to adjust the vertical offset by `1` for items containing the character '𝑝'.
  public override func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    switch item {
      case 0...3: return UIOffset(horizontal: 0, vertical: 1)
      default: return UIOffset(horizontal: 0, vertical: 0)
    }
  }

}
