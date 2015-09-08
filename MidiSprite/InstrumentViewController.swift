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

  var soundSet: SoundSet {
    get { return Sequencer.currentSoundSet }
    set {
      guard Sequencer.currentSoundSet != newValue else { return }
      Sequencer.currentSoundSet = newValue
      Sequencer.currentProgram = 0
//      guard let form = _form,
//                field = form[FieldName.SoundSet.rawValue] as? FormPickerField else { return }
//      field.value = Sequencer.currentSoundSet.index
    }
  }

  var program: Program {
    get { return Sequencer.currentProgram }
    set {
      guard Sequencer.currentProgram != newValue else { return }
      Sequencer.currentProgram = newValue
//      guard let form = _form,
//                field = form[FieldName.Program.rawValue] as? FormPickerField else { return }
//      field.choices = Sequencer.currentSoundSet.programs
//      field.value = Int(Sequencer.currentProgram)
    }
  }

  var channel: Channel {
    get { return Sequencer.currentChannel }
    set {
      guard Sequencer.currentChannel != newValue else { return }
      Sequencer.currentChannel = newValue
//      guard let form = _form,
//                field = form[FieldName.Channel.rawValue] as? FormStepperField else { return }
//      field.value = Double(Sequencer.currentChannel)
    }
  }


  private enum FieldName: String { case SoundSet = "Sound Set", Program, Channel }

  private var _form: Form?
  override var form: Form {
    guard _form == nil else { return _form! }

    let soundSetField = FormPickerField(name: FieldName.SoundSet.rawValue,
                                        value: soundSet.index,
                                        choices: Sequencer.soundSets.map({$0.displayName}))

    let programField = FormPickerField(name: FieldName.Program.rawValue,
                                       value: Int(program),
                                       choices: soundSet.presets.map ({$0.name}))

    let channelField = FormStepperField(name: FieldName.Channel.rawValue,
                                        value: Double(channel),
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
          if let idx = field.value as? Int where Sequencer.soundSets.indices.contains(idx) {
            var soundSet = Sequencer.soundSets[idx]
            guard self.soundSet != soundSet else { break }
            self.soundSet = soundSet
            self.program = UInt8(soundSet.presets[0].program)
            programField.choices = self.soundSet.presets.map({$0.name})
            programField.value = programField.choices.count > 0 ? 0 : -1
          }

        case .Program:
          if let idx = field.value as? Int where self.soundSet.presets.indices.contains(idx) {
            self.program = UInt8(self.soundSet.presets[idx].program)
          }

        case .Channel:
          if let channel = field.value as? Double { self.channel = Channel(channel) }

      }

    }

    return _form!
  }

}
