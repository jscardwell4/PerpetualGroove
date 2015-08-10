//
//  FormStepperField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class FormStepperField: FormField {

  private var _value = 0.0

  override public var value: Any? {
    get { return _value }
    set { guard let v = newValue as? Double else { return }; _value = v; stepper?.value = v }
  }

  public var minimumValue = 0.0 { didSet { stepper?.minimumValue = minimumValue } }
  public var maximumValue = 100.0 { didSet { stepper?.maximumValue = maximumValue } }
  public var stepValue = 1.0 { didSet { stepper?.stepValue = stepValue } }
  public var autorepeat = false { didSet { stepper?.autorepeat = autorepeat } }
  public var wraps = true { didSet { stepper?.wraps = wraps } }

  public init(name: String,
              value: Double = 0,
              minimumValue: Double = 0,
              maximumValue: Double = 100,
              stepValue: Double = 1,
              autorepeat: Bool = false,
              wraps: Bool = true)
  {
    _value = value
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
    self.stepValue = stepValue
    self.autorepeat = autorepeat
    self.wraps = wraps
    super.init(name: name)
  }

  private weak var stepper: LabeledStepper? { didSet { _control = stepper } }

  override var control: UIView {
    guard stepper == nil else { return stepper! }

    let control = LabeledStepper(autolayout: true)
    control.nametag = "stepper"
    control.userInteractionEnabled = editable
    control.value = _value
    control.minimumValue = minimumValue
    control.maximumValue = maximumValue
    control.stepValue = stepValue
    control.wraps = wraps
    control.autorepeat = autorepeat

    if let font = font { control.font = font }
    if let color = color { control.textColor = color }
    control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
    stepper = control
    return control
  }

  func valueDidChange(stepper: UIStepper) { _value = stepper.value; changeHandler?(self) }
  override public var font: UIFont? { didSet { guard let font = font else { return }; stepper?.font = font } }
  override public var color: UIColor? { didSet { guard let color = color else { return }; stepper?.textColor = color } }
}
