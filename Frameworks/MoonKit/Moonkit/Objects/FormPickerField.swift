//
//  FormPickerField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class FormPickerField: FormField {

  private var _value = -1

  override public var value: Any? {
    get { return (0 ..< choices.count).contains(_value) ? _value : nil }
    set {
      guard let idx = newValue as? Int where (0 ..< choices.count).contains(idx) else { return }
      _value = idx
      picker?.selectItem(idx, animated: picker?.superview != nil)
    }
  }

  public var choices: [AnyObject] = [] {
    didSet {
      if let labels = choices as? [String] { picker?.labels = labels }
      else if let images = choices as? [UIImage] { picker?.images = images }
    }
  }

  public init(name: String, value: Int, choices: [AnyObject]) {
    _value = value
    self.choices = choices
    super.init(name: name)
  }

  override public var font: UIFont? { didSet { if let font = font { picker?.font = font } } }
  override public var selectedFont: UIFont? { didSet { if let font = selectedFont { picker?.selectedFont = font } } }
  override public var color: UIColor? {
    didSet { if let color = color { picker?.itemColor = color } }
  }
  override public var selectedColor: UIColor? {
    didSet { if let color = selectedColor { picker?.selectedItemColor = color } }
  }

  private weak var picker: InlinePickerView? { didSet { _control = picker } }

  override public var editable: Bool { didSet { picker?.editing = editable; } }

  override var control: UIView {
    guard picker == nil else { return picker! }
    let control: InlinePickerView
    if let labels = choices as? [String] { control = InlinePickerView(labels: labels) }
    else if let images = choices as? [UIImage] { control = InlinePickerView(images: images) }
    else { fatalError("choices must be an array of String or UIImage objects") }

    control.identifier = "picker"
    control.editing = editable
    control.didSelectItem = { [unowned self] _, idx in self._value = idx; self.changeHandler?(self) }

    if let font = font { control.font = font }
    if let color = color { control.itemColor = color }
    if let font = selectedFont { control.selectedFont = font }
    if let color = selectedColor { control.selectedItemColor = color }
    if (0 ..< choices.count).contains(_value) { control.selectItem(_value, animated: false) }
    picker = control
    
    return control
  }
}

