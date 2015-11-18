//
//  NoteViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class NoteViewController: UIViewController {

  @IBOutlet weak var pitchPicker:    InlinePickerView!
  @IBOutlet weak var octavePicker:   InlinePickerView!
  @IBOutlet weak var durationPicker: InlinePickerView!
  @IBOutlet weak var velocityPicker: InlinePickerView!

  typealias Tone     = Note.Tone
//  typealias Pitch    = Note.Pitch
//  typealias Octave   = Note.Octave
  typealias Duration = Note.Duration
  typealias Velocity = Note.Velocity

  var currentNote: Note = Note() {
    didSet {
      pitchPicker.selection    = currentNote.note.pitch.index
      octavePicker.selection   = currentNote.note.octave.index
      durationPicker.selection = currentNote.duration.index
      velocityPicker.selection = currentNote.velocity.index

      Sequencer.currentNote = currentNote
    }
  }

  /** didPickPitch */
  @IBAction func didPickPitch() { currentNote.note.pitch = Note.Tone.Pitch.allCases[pitchPicker.selection] }

  /** didPickOctave */
  @IBAction func didPickOctave() { currentNote.note.octave = Note.Tone.Octave.allCases[octavePicker.selection] }

  /** didPickDuration */
  @IBAction func didPickDuration() { currentNote.duration = Duration.allCases[durationPicker.selection] }

  /** didPickVelocity */
  @IBAction func didPickVelocity() { currentNote.velocity = Velocity.allCases[velocityPicker.selection] }

  /** auditionValues */
  @IBAction func auditionValues() { Sequencer.auditionCurrentNote() }
  
  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    currentNote = Sequencer.currentNote
  }
 }
