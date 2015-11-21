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
  @IBAction func didPickPitch() {
    currentNote.note.pitch = Note.Tone.Pitch.allCases[pitchPicker.selection]
    audition()
  }

  /** didPickOctave */
  @IBAction func didPickOctave() {
    currentNote.note.octave = Note.Tone.Octave.allCases[octavePicker.selection]
    audition()
  }

  /** didPickDuration */
  @IBAction func didPickDuration() {
    currentNote.duration = Note.Duration.allCases[durationPicker.selection]
    audition()
  }

  /** didPickVelocity */
  @IBAction func didPickVelocity() {
    currentNote.velocity = Note.Velocity.allCases[velocityPicker.selection]
    audition()
  }

  /** audition */
  private func audition() { Sequencer.soundSetSelectionTarget.playNote(currentNote) }
  
  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    switch Sequencer.currentNote {
      case let note as Note: currentNote = note
      case let chord as Chord: currentNote = chord.rootNote
      default: break
    }
  }
  
 }
