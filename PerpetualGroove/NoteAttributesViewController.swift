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

  var currentNote: MIDINote = MIDINote() {
    didSet {
      pitchPicker.selection    = MIDINote.Tone.indexForNote(currentNote.note.pitch)
      octavePicker.selection   = currentNote.note.octave.index
      durationPicker.selection = currentNote.duration.index
      velocityPicker.selection = currentNote.velocity.index

      Sequencer.currentNote = currentNote
    }
  }

  /** didPickPitch */
  @IBAction func didPickPitch() {
    currentNote.note.pitch = MIDINote.Tone.noteForIndex(pitchPicker.selection)!
    audition()
  }

  /** didPickOctave */
  @IBAction func didPickOctave() {
    currentNote.note.octave = Octave.allCases[octavePicker.selection]
    audition()
  }

  /** didPickDuration */
  @IBAction func didPickDuration() {
    currentNote.duration = Duration.allCases[durationPicker.selection]
    audition()
  }

  /** didPickVelocity */
  @IBAction func didPickVelocity() {
    currentNote.velocity = Velocity.allCases[velocityPicker.selection]
    audition()
  }

  /** audition */
  private func audition() { Sequencer.soundSetSelectionTarget.playNote(currentNote) }
  
  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    switch Sequencer.currentNote {
      case let note as MIDINote: currentNote = note
//      case let chord as Chord: currentNote = chord.rootNote
      default: break
    }
  }
  
 }
