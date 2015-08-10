//
//  FormTextField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class FormTextField: FormField, UITextFieldDelegate {

  private var _value: String?

  override public var value: Any? {
    get { return _value }
    set { guard let v = newValue as? String else { return }; _value = v; textField?.text = v }
  }

  override public var valid: Bool { return validation?(_value) ?? true }

  public var placeholder: String?
  public var validation: ((String?) -> Bool)?

  override public var font: UIFont? { didSet { if let font = font { textField?.font = font } } }
  override public var color: UIColor? { didSet { if let color = color { textField?.textColor = color } } }

  public init(name: String, value: String? = nil, placeholder: String? = nil, validation: ((String?) -> Bool)? = nil) {
    _value = value
    self.placeholder = placeholder
    self.validation = validation
    super.init(name: name)
  }

  private weak var textField: UITextField? { didSet { _control = textField } }

  override var control: UIView {
    guard textField == nil else { return textField! }

    let control = UITextField(autolayout: true)
    control.nametag = "textField"
    control.userInteractionEnabled = editable
    control.textAlignment = .Right
    control.adjustsFontSizeToFitWidth = true
    control.minimumFontSize = 10
    control.returnKeyType = .Done
    control.layer.shadowColor = UIColor.redColor().CGColor
    control.delegate = self
    control.text = _value
    if let font = font { control.font = font }
    if let color = color { control.textColor = color }
    control.placeholder = placeholder
    textField = control
    return control
  }

  @objc public func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    _value = textField.text
    changeHandler?(self)
    return false
  }
}

