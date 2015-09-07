//
//  TemplateViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class TemplateViewController: FormPopoverViewController {

  private typealias TextureType = MIDINode.TextureType
  private typealias Duration = NoteAttributes.Duration
  private typealias Velocity = NoteAttributes.Velocity
  private typealias Note = NoteAttributes.Note

  var textureType = Sequencer.currentTexture {
    didSet {
      guard let form = _form, textureField = form[FieldName.TextureType.rawValue] as? FormPickerField else { return }
      textureField.value = textureType.index
      Sequencer.currentTexture = textureType
    }
  }
  var note = Sequencer.currentNote {
    didSet {
      guard let form = _form,
      noteField = form[FieldName.Note.rawValue] as? FormPickerField,
      velocityField = form[FieldName.Velocity.rawValue] as? FormPickerField,
      durationField = form[FieldName.Duration.rawValue] as? FormPickerField else { return }

      noteField.value = Int(note.note.MIDIValue)
      velocityField.value = Float(note.velocity.index)
      durationField.value = Float(note.duration.index)

      Sequencer.currentNote = note
    }
  }

  private enum FieldName: String { case TextureType = "Type", Note, Velocity, Duration }

  private var _form: Form?
  override var form: Form {
    guard _form == nil else { return _form! }

    // FIXME: update fields
    let typeField = FormPickerField(
      name: FieldName.TextureType.rawValue,
      value: textureType.index,
      choices: TextureType.allImages
    )

    let noteField = FormPickerField(
      name: FieldName.Note.rawValue,
      value: Int(note.note.MIDIValue),
      choices: Note.allCases.map({$0.rawValue})
    )

    let velocityField = FormPickerField(
      name: FieldName.Velocity.rawValue,
      value: note.velocity.index,
      choices: Velocity.allImages
    )

    let durationField = FormPickerField(
      name: FieldName.Duration.rawValue,
      value: note.duration.index,
      choices: Duration.allImages
    )

    let fields = [typeField, noteField, velocityField, durationField]

    _form =  Form(fields: fields) {
      [unowned self] (form: Form, field: FormField) in

      guard let fieldName = FieldName(rawValue: field.name) else { return }

      switch fieldName {
        case .TextureType: if let idx = field.value as? Int { self.textureType = TextureType(index: idx) }
        case .Note: if let midi = field.value as? Int { self.note.note = Note(MIDIValue: UInt8(midi)) }
        case .Velocity: if let idx = field.value as? Int { self.note.velocity = Velocity(index: idx) }
        case .Duration: if let idx = field.value as? Int { self.note.duration = Duration(index: idx) }
      }

    }

    return _form!
  }

}
