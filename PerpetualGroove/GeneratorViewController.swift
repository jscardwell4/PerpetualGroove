//
//  GeneratorViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class GeneratorViewController: UIViewController {

  @IBOutlet weak var pitchPicker:    InlinePickerView!
  @IBOutlet weak var octavePicker:   InlinePickerView!
  @IBOutlet weak var durationPicker: InlinePickerView!
  @IBOutlet weak var velocityPicker: InlinePickerView!
  @IBOutlet weak var modifierPicker: InlinePickerView!
  @IBOutlet weak var chordPicker:    InlinePickerView! {
    didSet {
      chordPicker?.labels = ["–"] + Chord.ChordPattern.StandardChordPattern.allCases.map {$0.name}
    }
  }

  var didChangeGenerator: ((MIDINoteGenerator) -> Void)?

  /** refresh */
  private func refresh() {
    guard isViewLoaded() else { return }
    pitchPicker.selection    = noteGenerator.root.natural.index
    switch noteGenerator.root.modifier {
      case .Flat?:  modifierPicker.selection = 0
      case .Sharp?: modifierPicker.selection = 2
      default:      modifierPicker.selection = 1
    }
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

  private var loading = false
  func loadGenerator(generator: MIDINoteGenerator) {
    loading = true
    noteGenerator = generator
    loading = false
  }

  private var noteGenerator: MIDINoteGenerator = NoteGenerator() {
    didSet {
      guard !loading else { return }
      didChangeGenerator?(noteGenerator)
      Sequencer.soundSetSelectionTarget.playNote(noteGenerator)
    }
  }

  /** didPickPitch */
  @IBAction func didPickPitch() {
    noteGenerator.root.natural = Natural.allCases[pitchPicker.selection]
  }

  /** didPickOctave */
  @IBAction func didPickOctave() {
    noteGenerator.octave = Octave.allCases[octavePicker.selection]
  }

  /** didPickModifier */
  @IBAction func didPickModifier() {
    switch modifierPicker.selection {
      case 0: noteGenerator.root.modifier = .Flat
      case 2: noteGenerator.root.modifier = .Sharp
      default: noteGenerator.root.modifier = nil
    }
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
  }

  /** didPickDuration */
  @IBAction func didPickDuration() {
    noteGenerator.duration = Duration.allCases[durationPicker.selection]
  }

  /** didPickVelocity */
  @IBAction func didPickVelocity() {
    noteGenerator.velocity = Velocity.allCases[velocityPicker.selection]
  }

  /** viewDidLoad */
  override func viewDidAppear(animated: Bool) { super.viewDidAppear(animated); refresh() }
  
 }
