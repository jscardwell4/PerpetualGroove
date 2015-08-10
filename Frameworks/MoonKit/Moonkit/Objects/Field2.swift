//
//  Field2.swift
//  Remote
//
//  Created by Jason Cardwell on 5/18/15.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

public enum FieldTemplate {
  case Text     (value: String, placeholder: String?, validation: ((String?) -> Bool)?)
  case Switch   (value: Bool)
  case Slider   (value: Float, min: Float, max: Float)
  case Stepper  (value: Double, min: Double, max: Double, step: Double)
  case Picker   (value: Int, choices: [String])
  case Checkbox (value: Bool)
}

public class Field: NSObject {

  func valueDidChange(sender: AnyObject) {

  }

  public static func fieldWithTemplate(template: FieldTemplate) -> Field {
    switch template {
      case let .Text(value, placeholder, validation):
        return TextField(value: value, placeholder: placeholder, validation: validation)
      case let .Switch(value):
        return SwitchField(value: value)
      case let .Slider(value, min, max):
        return SliderField(value: value, min: min, max: max)
      case let .Stepper(value, min, max, step):
        return StepperField(value: value, min: min, max: max, step: step)
      case let .Picker(value, choices):
        return PickerField(value: value, choices: choices)
      case let .Checkbox(value):
        return CheckboxField(value: value)
    }
  }

  private class TextField: Field, UITextFieldDelegate {
    var value: String = ""
    var placeholder: String?
    var validation: ((String?) -> Bool)?

    init(value: String, placeholder: String?, validation: ((String?) -> Bool)?) {
      self.value = value; self.placeholder = placeholder; self.validation = validation; super.init()
    }
    weak var _control: UITextField?
    func control() -> UIView {
      let control = UITextField.newForAutolayout()
      control.textAlignment = .Right
      control.returnKeyType = .Done
      control.layer.shadowColor = UIColor.redColor().CGColor
      control.delegate = self
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      control.text = value
      control.placeholder = placeholder
      _control = control
      return control
    }
    @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      return false
    }
 }

  private class SwitchField: Field {
    var value = false
    init(value: Bool) { self.value = value; super.init()  }
    weak var _control: UISwitch?
    func control() -> UIView {
      let control = UISwitch.newForAutolayout()
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      control.on = value
      _control = control
      return control
    }
  }

  private class SliderField: Field {
    var value: Float = 0
    var min: Float = 0
    var max: Float = 1
    init(value: Float, min: Float, max: Float) {
      self.value = value; self.min = min; self.max = max; super.init()
    }
    weak var _control: UISlider?
    func control() -> UIView {
      let control = UISlider.newForAutolayout()
      control.value = value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

  private class StepperField: Field {
    var value = 0.0
    var min = 0.0
    var max = 100.0
    var step = 1.0

    init(value: Double, min: Double, max: Double, step: Double) {
      self.value = value; self.min = min; self.max = max; self.step = step; super.init()
    }
    weak var _control: UIStepper?
    func control() -> UIView {
      let control = UIStepper.newForAutolayout()
      control.value = value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

  private class PickerField: Field, AKPickerViewDelegate, AKPickerViewDataSource {
    var value = 0
    var choices: [String] = []

    init(value: Int, choices: [String]) {
      self.value = value; self.choices = choices; super.init()
    }

    weak var _control: AKPickerView?
    func control() -> UIView {
      let control = AKPickerView.newForAutolayout()
      control.delegate = self
      control.dataSource = self
      control.selectItem(value)
      control.interitemSpacing = 20.0
      _control = control
      return control
    }

    @objc func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
      return choices.count
    }

    @objc func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
      return choices[item]
    }

    @objc func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
      value = item
      valueDidChange(self)
    }
  }

  private class CheckboxField: Field {
    var value = false

    init(value: Bool) { self.value = value; super.init() }

    weak var _control: Checkbox?
    func control() -> UIView {
      let control = Checkbox.newForAutolayout()
      control.checked = value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }


}