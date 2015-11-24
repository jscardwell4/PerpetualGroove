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
  @IBOutlet weak var modifierPicker: InlinePickerView!
  @IBOutlet weak var chordPicker: InlinePickerView! {
    didSet {
      chordPicker?.labels = ["–"] + Chord.ChordPattern.StandardChordPattern.allCases.map {$0.name}
    }
  }

  /**
  indexForModifier:

  - parameter modifier: PitchModifier?

  - returns: Int
  */
  private func indexForModifier(modifier: PitchModifier?) -> Int {
    switch modifier {
      case .Flat?:  return 0
      case .Sharp?: return 2
      default:     return 1
    }
  }

  /** refresh */
  private func refresh() {
    pitchPicker.selection    = noteGenerator.root.natural.index
    modifierPicker.selection = indexForModifier(noteGenerator.root.modifier)
    octavePicker.selection   = noteGenerator.octave.index
    durationPicker.selection = noteGenerator.duration.index
    velocityPicker.selection = noteGenerator.velocity.index
    switch noteGenerator {
      case _ as NoteGenerator: chordPicker.selection = 0
      case let generator as ChordGenerator:
        if let pattern = Chord.ChordPattern.StandardChordPattern(rawValue: generator.chord.pattern.rawValue) {
          chordPicker.selection = pattern.index
        } else {
          chordPicker.selection = 0
        }
      default: break
    }
  }

  private var noteGenerator: MIDINoteGenerator = Sequencer.currentNote {
    didSet {
      Sequencer.currentNote = noteGenerator
    }
  }

  /** didPickPitch */
  @IBAction func didPickPitch() {
    noteGenerator.root.natural = Natural.allCases[pitchPicker.selection]
    audition()
  }

  /** didPickOctave */
  @IBAction func didPickOctave() {
    noteGenerator.octave = Octave.allCases[octavePicker.selection]
    audition()
  }

  /** didPickModifier */
  @IBAction func didPickModifier() {
    switch modifierPicker.selection {
      case 0: noteGenerator.root.modifier = .Flat
      case 2: noteGenerator.root.modifier = .Sharp
      default: noteGenerator.root.modifier = nil
    }
    audition()
  }

  /** didPickChord */
  @IBAction func didPickChord() {
    let newValue: Chord.ChordPattern.StandardChordPattern?
    switch chordPicker.selection {
      case 0: newValue = nil
      case let idx: newValue = Chord.ChordPattern.StandardChordPattern.allCases[idx - 1]
    }
    switch (noteGenerator, newValue) {
      case let (generator as NoteGenerator, newValue?):
        noteGenerator = ChordGenerator(pattern: newValue.pattern, generator: generator)
      case (var generator as ChordGenerator, let newValue?):
        generator.chord.pattern = newValue.pattern; noteGenerator = generator
      case (let generator as ChordGenerator, nil):
        noteGenerator = NoteGenerator(generator: generator)
      default:
        break
    }
    audition()
  }

  /** didPickDuration */
  @IBAction func didPickDuration() {
    noteGenerator.duration = Duration.allCases[durationPicker.selection]
    audition()
  }

  /** didPickVelocity */
  @IBAction func didPickVelocity() {
    noteGenerator.velocity = Velocity.allCases[velocityPicker.selection]
    audition()
  }

  /** audition */
  private func audition() { Sequencer.soundSetSelectionTarget.playNote(noteGenerator) }
  
  /** viewDidLoad */
  override func viewDidLoad() { super.viewDidLoad(); refresh() }
  
 }
