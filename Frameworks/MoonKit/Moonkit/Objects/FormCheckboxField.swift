//
//  FormCheckboxField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class FormCheckboxField: FormField {

  private var _value = false

  override public var value: Any? {
    get { return _value }
    set { guard let v = newValue as? Bool else { return }; _value = v; checkbox?.checked = v }
  }

  public init(name: String, value: Bool = false) { _value = value; super.init(name: name) }

  private weak var checkbox: Checkbox? { didSet { _control = checkbox } }

  override var control: UIView {
    guard checkbox == nil else { return checkbox! }

    let control = Checkbox(autolayout: true)
    control.nametag = "checkbox"
    control.userInteractionEnabled = editable
    control.checked = _value
    control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
    checkbox = control
    return control
  }

  func valueDidChange(checkbox: Checkbox) { _value = checkbox.checked; changeHandler?(self) }
}
