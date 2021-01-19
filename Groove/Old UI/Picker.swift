//
//  Picker.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/26/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonDev
import SoundFont
import UIKit

// MARK: - Picker

/// An abstract subclass of `UIControl` that wraps an instance of `InlinePickerView`
/// to provide application-specific customization.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public class Picker: UIControl, InlinePickerDelegate
{
  // MARK: Stored Properties

  /// Overridden to invoke `setup()`.
  /// The inline picker view being wrapped.
  fileprivate let picker = InlinePickerView(flat: false, frame: .zero, delegate: nil)

  /// The items displayed by `picker`. Setting the value of this property causes
  /// `picker` to reload.
  public var items: [InlinePickerView.Item] = []
  {
    didSet
    {
      // Reload the picker view to keep the picker view's items in sync with `items`.
      picker.reloadData()
    }
  }

  // MARK: Initializing

  override public init(frame: CGRect) { super.init(frame: frame); setup() }

  /// Overridden to invoke `setup()`.
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  /// Configures the inline picker container.
  private func setup()
  {
    // Assign `self` as the picker view's delegate.
    picker.delegate = self

    // Assign to the picker view the accessibility identifier that was assigned to
    // the container.
    picker.accessibilityIdentifier = accessibilityIdentifier

    // Add the target for picker view value changes.
    picker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)

    // Configure the appearance of the picker view.
    decorate(picker: picker)

    // Add the picker view as a subview.
    addSubview(picker)

    // Add constraints to keep the picker vertically and horizontally stretched
    // across the container.
    constrain(𝗛∶|[picker]|, 𝗩∶|[picker]|)

    // Assign items via a refresh.
    refreshItems()

    // Make the default selection.
    picker.selection = type(of: self).initialSelection
  }

  /// Sets the colors, fonts, and metrics for `picker`.
  private func decorate(picker: InlinePickerView)
  {
    setColors(for: picker)
    setFonts(for: picker)
    setMetrics(for: picker)
  }

  /// Sets the item color and selected item color for `picker`.
  func setColors(for picker: InlinePickerView)
  {
    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
  }

  /// Sets the font and selected font for `picker`.
  func setFonts(for picker: InlinePickerView)
  {
    picker.font = .control
    picker.selectedFont = .controlSelected
  }

  /// Sets the item height and item padding for `picker`.
  func setMetrics(for picker: InlinePickerView)
  {
    picker.itemHeight = 36
    picker.itemPadding = 8
  }

  // MARK: Actions

  /// Sends actions for `valueChanged`. Invoked by `picker` value changes.
  @objc private func valueChanged() { sendActions(for: .valueChanged) }

  // MARK: Items

  /// Updates the items displayed by `picker`. This method is abstract and must
  /// be overridden by subclasses of `Picker`.
  public func refreshItems() { fatalError("Subclasses must override \(#function)") }

  /// The items to give `picker` when built for interface builder.
  public class var contentForInterfaceBuilder: [InlinePickerView.Item] { [] }

  /// The index of the default item.
  public class var initialSelection: Int { 0 }

  /// Overridden to update the accessibility identifier of `picker` whenever the
  /// value of this property changes.
  override public var accessibilityIdentifier: String?
  {
    didSet
    {
      // Give the picker view the same accessibility identifer.
      picker.accessibilityIdentifier = accessibilityIdentifier
    }
  }

  /// The index of the selected item in `items`. This is a derived property
  /// wrapping the property accessors of `picker.selection`.
  public var selection: Int
  {
    get { picker.selection }
    set { picker.selection = newValue }
  }

  /// Selects the item at the specified index.
  /// - Parameter item: The index of the item to select.
  /// - Parameter animated: Whether to animate changes to the selection.
  public func selectItem(_ item: Int, animated: Bool)
  {
    picker.selectItem(item, animated: animated)
  }
  
  /// Overridden to return the intrinsic content size returned by `picker`.
  override public var intrinsicContentSize: CGSize { picker.intrinsicContentSize }

  /// Overridden to return the view returned by `picker` for the same property.
  override public var forLastBaselineLayout: UIView { picker.forLastBaselineLayout }

  /// Returns the number of elements in `items`.
  public func numberOfItems(in inlinePickerView: InlinePickerView) -> Int
  {
    items.count
  }

  /// Returns the element in `items` at `item`.
  public func inlinePicker(_ inlinePickerView: InlinePickerView,
                           contentForItem item: Int) -> InlinePickerView.Item
  {
    items[item]
  }

  /// Returns the `zero` offset.
  public func inlinePicker(inlinePickerView: InlinePickerView,
                           contentOffsetForItem _: Int) -> UIOffset
  {
    .zero
  }
}
