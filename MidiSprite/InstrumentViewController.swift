//
//  InstrumentViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class InstrumentViewController: FormPopoverViewController {

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  /** init */
  init() {
    super.init(nibName: nil, bundle: nil)
    InstrumentViewController.currentInstance = self
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    InstrumentViewController.currentInstance = self
  }

  private static weak var currentInstance: InstrumentViewController?
  private static var _soundSet = SoundSet.PureOscillators
  private static var _program = Program(0)
  private static var _channel = Channel(0)

  static var soundSet: SoundSet {
    get { return _soundSet }
    set {
      guard _soundSet != newValue else { return }
      _soundSet = newValue
      guard let form = currentInstance?._form,
                field = form[FieldName.SoundSet.rawValue] as? FormPickerField else { return }
      field.value = SoundSet.allCases.indexOf(_soundSet) ?? 0
      _program = 0
    }
  }

  static var program: Program {
    get { return _program }
    set {
      guard _program != newValue else { return }
      _program = newValue
      guard let form = currentInstance?._form,
                field = form[FieldName.Program.rawValue] as? FormPickerField else { return }
      field.choices = _soundSet.programs
      field.value = Int(_program)
    }
  }

  static var channel: Channel {
    get { return _channel }
    set {
      guard _channel != newValue else { return }
      _channel = newValue
      guard let form = currentInstance?._form,
                field = form[FieldName.Channel.rawValue] as? FormStepperField else { return }
      field.value = Double(_channel)
    }
  }


  private enum FieldName: String { case SoundSet = "Sound Set", Program, Channel }

  private var _form: Form?
  override var form: Form {
    guard _form == nil else { return _form! }

    let soundSetField = FormPickerField(name: FieldName.SoundSet.rawValue,
                                        value: SoundSet.allCases.indexOf(InstrumentViewController._soundSet) ?? 0,
                                        choices: SoundSet.allCases.map({$0.baseName}))

    let programField = FormPickerField(name: FieldName.Program.rawValue,
                                       value: Int(InstrumentViewController._program),
                                       choices: InstrumentViewController._soundSet.programs)

    let channelField = FormStepperField(name: FieldName.Channel.rawValue,
                                        value: Double(InstrumentViewController._channel),
                                        minimumValue: 0,
                                        maximumValue: 15,
                                        stepValue: 1)
    channelField.backgroundImage = UIImage()
    channelField.dividerImage = UIImage()
    channelField.incrementImage = UIImage(named: "up")
    channelField.decrementImage = UIImage(named: "down")


    let fields = [soundSetField, programField, channelField]

    _form =  Form(fields: fields) {
      (form: Form, field: FormField) in

      guard let fieldName = FieldName(rawValue: field.name) else { return }

      switch fieldName {
        case .SoundSet:
          if let idx = field.value as? Int where SoundSet.allCases.indices.contains(idx) {
            let soundSet = SoundSet.allCases[idx]
            guard InstrumentViewController._soundSet != soundSet else { break }
            InstrumentViewController._soundSet = soundSet
            InstrumentViewController._program = 0
            programField.choices = InstrumentViewController._soundSet.programs
            programField.value = programField.choices.count > 0 ? 0 : -1
          }

        case .Program:
          if let idx = field.value as? Int where InstrumentViewController._soundSet.programs.indices.contains(idx) {
            InstrumentViewController._program = UInt8(idx)
          }

        case .Channel:
          if let channel = field.value as? Double { InstrumentViewController._channel = Channel(channel) }

      }

    }

    return _form!
  }

}
