//
//  TemplateViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit
import Eveleth
import Chameleon

final class TemplateViewController: UIViewController {

  var barButtonItem: ImageBarButtonItem?

  /**
  initWithBarButtonItem:

  - parameter barButtonItem: ImageBarButtonItem
  */
  init(barButtonItem item: ImageBarButtonItem?) {
    super.init(nibName: nil, bundle: nil)
    barButtonItem = item
  }

  /** updateViewConstraints */
//  override func updateViewConstraints() {
//    super.updateViewConstraints()
//    let id = Identifier(self, "View")
//    guard view.constraintsWithIdentifier(id).count == 0 else { return }
//    view.constrain(view.width ≥ 300 --> id)
//  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /** loadView */
  override func loadView() {
    let formView = FormView(form: form)
    formView.labelFont                = Eveleth.lightFontWithSize(14)
    formView.labelTextColor           = Chameleon.kelleyPearlBush
    formView.controlFont              = Eveleth.thinFontWithSize(14)
    formView.controlTextColor         = Chameleon.quietLightLobLollyDark
    formView.controlSelectedFont      = Eveleth.regularFontWithSize(14)
    formView.controlSelectedTextColor = Chameleon.quietLightLobLolly
    formView.tintColor                = Chameleon.quietLightLilyWhiteDark
    view = formView
    view.setNeedsUpdateConstraints()
  }

  var textureType = MIDINode.templateTextureType {
    didSet {
      guard let form = _form, textureField = form[FieldName.TextureType.rawValue] as? FormPickerField else { return }
      textureField.value = MIDINode.TextureType.allCases.indexOf(textureType) ?? 0
      MIDINode.templateTextureType = textureType
    }
  }
  var note = MIDINode.templateNote {
    didSet {
      guard let form = _form,
      noteField = form[FieldName.Note.rawValue] as? FormPickerField,
      velocityField = form[FieldName.Velocity.rawValue] as? FormSliderField,
      durationField = form[FieldName.Duration.rawValue] as? FormSliderField else { return }

      noteField.value = Int(note.value.midi)
      velocityField.value = Float(note.velocity)
      durationField.value = Float(note.duration)

      MIDINode.templateNote = note
    }
  }

  private enum FieldName: String { case TextureType = "Type", Note, Velocity, Duration }

  private var _form: Form?
  private var form: Form {
    guard _form == nil else { return _form! }

    let typeField = FormPickerField(name: FieldName.TextureType.rawValue,
                                    value: MIDINode.TextureType.allCases.indexOf(textureType) ?? 0,
                                    choices: MIDINode.TextureType.allCases.map { $0.image})

    let noteField = FormPickerField(name: FieldName.Note.rawValue,
                                    value: Int(note.value.midi),
                                    choices: MIDINote.allCases.map({$0.rawValue}))

    let velocityField = FormSliderField(name: FieldName.Velocity.rawValue,
                                        value: Float(note.velocity),
                                        max: 127,
                                        minTrack: AssetManager.sliderMinTrackImage,
                                        maxTrack: AssetManager.sliderMaxTrackImage,
                                        thumb: AssetManager.sliderThumbImage,
                                        offset: AssetManager.sliderThumbOffset)

    let durationField = FormSliderField(name: FieldName.Duration.rawValue,
                                        precision: 3,
                                        value: Float(note.duration),
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
            let image = type.image
            self.barButtonItem?.image = image
            self.barButtonItem?.highlightedImage = image.imageWithBackgroundColor(.whiteColor()).inverted.maskToAlpha
        }

        case .Note:
          if let midi = field.value as? Int { self.note.value = MIDINote(midi: UInt8(midi)) }

        case .Velocity:
          if let velocity = field.value as? Float { self.note.velocity = UInt8(velocity) }

        case .Duration:
          if let duration = field.value as? Float { self.note.duration = Double(duration) }

      }

    }

    return _form!
  }

}
