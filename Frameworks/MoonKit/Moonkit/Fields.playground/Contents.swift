//: Playground - noun: a place where people can play

import UIKit
import class MoonKit.UIView
import class MoonKit.AKPickerView
import protocol MoonKit.AKPickerViewDelegate
import protocol MoonKit.AKPickerViewDataSource
import class MoonKit.Checkbox
import struct MoonKit.OrderedDictionary

public enum FieldTemplate {
  case Text     (value: String, placeholder: String?, validation: ((String?) -> Bool)?)
  case Switch   (value: Bool)
  case Slider   (value: Float, min: Float, max: Float)
  case Stepper  (value: Double, min: Double, max: Double, step: Double)
  case Picker   (value: Int, choices: [String])
  case Checkbox (value: Bool)
}

public class Field: NSObject {
  public enum Type { case Undefined, Text, Switch, Slider, Stepper, Picker, Checkbox }

  var control: UIView { return UIView() }
  public var value: Any?
  public var valid: Bool { return true }
  public var type: Type { return .Undefined }
  public var changeHandler: ((Field) -> Void)?

  func valueDidChange(sender: AnyObject) { changeHandler?(self) }

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
    var _value: String = ""
    override var type: Type { return .Text }
    override var value: Any? { get { return _value } set { if let v = newValue as? String { _value = v } } }
    override var valid: Bool { return validation?(_value) ?? true }
    var placeholder: String?
    var validation: ((String?) -> Bool)?

    init(value: String, placeholder: String?, validation: ((String?) -> Bool)?) {
      _value = value; self.placeholder = placeholder; self.validation = validation; super.init()
    }
    weak var _control: UITextField?
    override var control: UIView {
      let control = UITextField.newForAutolayout()
      control.textAlignment = .Right
      control.returnKeyType = .Done
      control.layer.shadowColor = UIColor.redColor().CGColor
      control.delegate = self
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      control.text = _value
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
    var _value = false
    override var type: Type { return .Switch }
    override var value: Any? { get { return _value } set { if let v = newValue as? Bool { _value = v } } }
    init(value: Bool) { _value = value; super.init()  }
    weak var _control: UISwitch?
    override var control: UIView {
      let control = UISwitch.newForAutolayout()
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      control.on = _value
      _control = control
      return control
    }
  }

  private class SliderField: Field {
    var _value: Float = 0
    override var type: Type { return .Slider }
    override var value: Any? { get { return _value } set { if let v = newValue as? Float { _value = v } } }
    var min: Float = 0
    var max: Float = 1
    init(value: Float, min: Float, max: Float) {
      _value = value; self.min = min; self.max = max; super.init()
    }
    weak var _control: UISlider?
    override var control: UIView {
      let control = UISlider.newForAutolayout()
      control.value = _value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

  private class StepperField: Field {
    var _value = 0.0
    override var type: Type { return .Stepper }
    override var value: Any? { get { return _value } set { if let v = newValue as? Double { _value = v } } }
    var min = 0.0
    var max = 100.0
    var step = 1.0

    init(value: Double, min: Double, max: Double, step: Double) {
      _value = value; self.min = min; self.max = max; self.step = step; super.init()
    }
    weak var _control: UIStepper?
    override var control: UIView {
      let control = UIStepper.newForAutolayout()
      control.value = _value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

  private class PickerField: Field, AKPickerViewDelegate, AKPickerViewDataSource {
    var _value = 0
    override var type: Type { return .Picker }
    override var value: Any? { get { return _value } set { if let v = newValue as? Int { _value = v } } }
    var choices: [String] = []

    init(value: Int, choices: [String]) {
      _value = value; self.choices = choices; super.init()
    }

    weak var _control: AKPickerView?
    override var control: UIView {
      let control = AKPickerView.newForAutolayout()
      control.delegate = self
      control.dataSource = self
      control.selectItem(_value)
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
      _value = item
      valueDidChange(self)
    }
  }

  private class CheckboxField: Field {
    var _value = false
    override var type: Type { return .Checkbox }
    override var value: Any? { get { return _value } set { if let v = newValue as? Bool { _value = v } } }

    init(value: Bool) { _value = value; super.init() }

    weak var _control: Checkbox?
    override var control: UIView {
      let control = Checkbox.newForAutolayout()
      control.checked = _value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }
  
}

public class Form {

  public var fields: OrderedDictionary<String, Field>
  public var changeHandler: ((Form, Field, String) -> Void)?

  public init(templates: OrderedDictionary<String, FieldTemplate>) {
    fields = templates.map {Field.fieldWithTemplate($0)}
    apply(fields) {$2.changeHandler = self.didChangeField}
  }

  func didChangeField(field: Field) { if let name = nameForField(field) { changeHandler?(self, field, name) } }

  func nameForField(field: Field) -> String? {
    if let idx = find(fields.values, field) { return fields.keys[idx] } else { return nil }
  }

}

