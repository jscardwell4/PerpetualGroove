//
//  FormSwitchField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class FormSwitchField: FormField {

  private var _value = false

  override public var value: Any? {
    get { return _value }
    set { guard let v = newValue as? Bool else { return }; _value = v; `switch`?.on = v }
  }

  public init(name: String, value: Bool) { _value = value; super.init(name: name)  }

  private weak var `switch`: UISwitch? { didSet { _control = `switch` } }

  override var control: UIView {
    guard `switch` == nil else { return `switch`! }

    let control = UISwitch(autolayout: true)
    control.nametag = "switch"
    control.userInteractionEnabled = editable
    control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
    control.on = _value
    `switch` = control

    return control
  }
}
