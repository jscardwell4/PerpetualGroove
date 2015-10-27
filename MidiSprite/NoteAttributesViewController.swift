//
//  NoteAttributesViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class NoteAttributesViewController: UIViewController {

  @IBOutlet weak var pitchPicker:    InlinePickerView!
  @IBOutlet weak var octavePicker:   InlinePickerView!
  @IBOutlet weak var durationPicker: InlinePickerView!
  @IBOutlet weak var velocityPicker: InlinePickerView!

  typealias Note     = NoteAttributes.Note
  typealias Pitch    = Note.Pitch
  typealias Octave   = Note.Octave
  typealias Duration = NoteAttributes.Duration
  typealias Velocity = NoteAttributes.Velocity

  var currentNote: NoteAttributes = NoteAttributes() {
    didSet {
      pitchPicker.selection    = currentNote.note.pitch.index
      octavePicker.selection   = currentNote.note.octave.index
      durationPicker.selection = currentNote.duration.index
      velocityPicker.selection = currentNote.velocity.index

      Sequencer.currentNoteAttributes = currentNote
    }
  }

  /** didPickPitch */
  @IBAction func didPickPitch() { currentNote.note.pitch = Pitch.allCases[pitchPicker.selection] }

  /** didPickOctave */
  @IBAction func didPickOctave() { currentNote.note.octave = Octave.allCases[octavePicker.selection] }

  /** didPickDuration */
  @IBAction func didPickDuration() { currentNote.duration = Duration.allCases[durationPicker.selection] }

  /** didPickVelocity */
  @IBAction func didPickVelocity() { currentNote.velocity = Velocity.allCases[velocityPicker.selection] }

  /** auditionValues */
  @IBAction func auditionValues() { Sequencer.auditionCurrentNote() }
  
  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    currentNote = Sequencer.currentNoteAttributes
  }
 }
