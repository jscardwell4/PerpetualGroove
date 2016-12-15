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

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  class var font: UIFont {
    return .controlFont
  }

  class var selectedFont: UIFont {
    return .controlSelectedFont
  }

  class var flat: Bool {
    return false
  }

  private var picker: InlinePickerView!

  @objc private func valueChanged() {
    sendActions(for: .valueChanged)
  }

  func refreshItems() {
    fatalError("Subclasses must override \(#function)")
  }

  class var contentForInterfaceBuilder: [Any] {
    return []
  }

  class var initialSelection: Int { return 0 }

  var items: [Any] = [] {
    didSet {
      picker.reloadData()
    }
  }

  private func setup() {
    flat = type(of: self).flat
    picker = InlinePickerView(flat: flat, frame: .zero, delegate: self)
    picker.accessibilityIdentifier = accessibilityIdentifier
    picker.font = type(of: self).font
    picker.selectedFont = type(of: self).selectedFont
    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.itemHeight = itemHeight
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
    picker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)

    addSubview(picker)
    constrain(𝗛|picker|𝗛, 𝗩|picker|𝗩)

    #if TARGET_INTERFACE_BUILDER
      items = type(of: self).contentForInterfaceBuilder
    #else
      refreshItems()
    #endif

    selection = type(of: self).initialSelection
  }

  /// Forward identifier to wrapped `InlinePickerView`.
  override var accessibilityIdentifier: String? {
    didSet {
      picker?.accessibilityIdentifier = accessibilityIdentifier
    }
  }

//  override func prepareForInterfaceBuilder() {
//    
//    super.prepareForInterfaceBuilder()
//    picker.reloadData()
//  }

  var selection: Int = -1 {
    didSet {
      picker?.selection = selection
    }
  }

  var flat: Bool = false {
    didSet {
      picker?.flat = flat
    }
  }

  func selectItem(_ item: Int, animated: Bool) {
    
    picker?.selectItem(item, animated: animated)
  }

  var itemHeight: CGFloat = 36 {
    didSet {
      picker?.itemHeight = itemHeight
    }
  }

  override var intrinsicContentSize: CGSize {
    return picker.intrinsicContentSize
  }

  override var forLastBaselineLayout: UIView {
    return picker.forLastBaselineLayout
  }

}

extension InlinePickerContainer: InlinePickerDelegate {

  func numberOfItems(in picker: InlinePickerView) -> Int {
    return items.count
  }

  func inlinePicker(_ picker: InlinePickerView, contentForItem item: Int) -> Any {
    return items[item]
  }

}
