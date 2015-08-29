//
//  TemplateViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class TemplateViewController: UIViewController {

  /**
  initWithBarButtonItem:

  - parameter barButtonItem: ImageBarButtonItem
  */
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /** loadView */
  override func loadView() {
    let formView = FormView(form: form)
    formView.labelFont                = AssetManager.labelFont
    formView.labelTextColor           = AssetManager.labelTextColor
    formView.controlFont              = AssetManager.controlFont
    formView.controlTextColor         = AssetManager.controlTextColor
    formView.controlSelectedFont      = AssetManager.controlSelectedFont
    formView.controlSelectedTextColor = AssetManager.controlSelectedTextColor
    formView.tintColor                = AssetManager.tintColor
    view = formView
    view.setNeedsUpdateConstraints()
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()
    let id = Identifier(self, "ViewWidth")
    guard view.constraintsWithIdentifier(id).count == 0 else { return }
    view.constrain(view.width ≤ (UIScreen.mainScreen().bounds.width - 10) --> id)
  }

  var textureType = MIDINode.currentTexture {
    didSet {
      guard let form = _form, textureField = form[FieldName.TextureType.rawValue] as? FormPickerField else { return }
      textureField.value = MIDINode.TextureType.allCases.indexOf(textureType) ?? 0
      MIDINode.currentTexture = textureType
    }
  }
  var note = MIDINode.currentNote {
    didSet {
      guard let form = _form,
      noteField = form[FieldName.Note.rawValue] as? FormPickerField,
      velocityField = form[FieldName.Velocity.rawValue] as? FormSliderField,
      durationField = form[FieldName.Duration.rawValue] as? FormSliderField else { return }

      noteField.value = Int(note.note.midi)
      velocityField.value = Float(note.velocity.midi)
      durationField.value = Float(note.duration.secondsWithBPM(Sequencer.tempo))

      MIDINode.currentNote = note
    }
  }

  private enum FieldName: String { case TextureType = "Type", Note, Velocity, Duration }

  private var _form: Form?
  private var form: Form {
    guard _form == nil else { return _form! }
    // FIXME: update fields
    let typeField = FormPickerField(name: FieldName.TextureType.rawValue,
                                    value: MIDINode.TextureType.allCases.indexOf(textureType) ?? 0,
                                    choices: MIDINode.TextureType.allCases.map { $0.image})

    let noteField = FormPickerField(name: FieldName.Note.rawValue,
                                    value: Int(note.note.midi),
                                    choices: NoteAttributes.Note.allCases.map({$0.rawValue}))

    let velocityField = FormSliderField(name: FieldName.Velocity.rawValue,
                                        value: Float(note.velocity.midi),
                                        max: 127,
                                        minTrack: AssetManager.sliderMinTrackImage,
                                        maxTrack: AssetManager.sliderMaxTrackImage,
                                        thumb: AssetManager.sliderThumbImage,
                                        offset: AssetManager.sliderThumbOffset)

//    let durationField = FormPickerField(name: FieldName.Duration.rawValue, value: <#T##Int#>, choices: <#T##[AnyObject]#>)
    let durationField = FormSliderField(name: FieldName.Duration.rawValue,
                                        precision: 3,
                                        value: Float(note.duration.secondsWithBPM(Sequencer.tempo)),
                                        max: 5,
                                        minTrack: AssetManager.sliderMinTrackImage,
                                        maxTrack: AssetManager.sliderMaxTrackImage,
                                        thumb: AssetManager.sliderThumbImage,
                                        offset: AssetManager.sliderThumbOffset)

    let fields = [typeField, noteField, velocityField, durationField]

    _form =  Form(fields: fields) {
      [unowned self] (form: Form, field: FormField) in

      guard let fieldName = FieldName(rawValue: field.name) else { return }

      switch fieldName {
        case .TextureType:
          if let idx = field.value as? Int where MIDINode.TextureType.allCases.indices.contains(idx) {
            let type = MIDINode.TextureType.allCases[idx]
            self.textureType = type
        }

        case .Note:
          if let midi = field.value as? Int { self.note.note = NoteAttributes.Note(midi: UInt8(midi)) }

        case .Velocity:
        assert(false)
//          if let velocity = field.value as? Float { self.note.velocity = UInt8(velocity) }

        case .Duration:
        assert(false)
//          if let duration = field.value as? Float { self.note.duration = duration }

      }

    }

    return _form!
  }

}
