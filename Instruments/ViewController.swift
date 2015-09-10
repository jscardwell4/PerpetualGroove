//
//  ViewController.swift
//  Instruments
//
//  Created by Jason Cardwell on 9/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import AVFoundation
import MoonKit

class ViewController: UIViewController {

  var programs: [SF2File.Preset] = []

  var noteAttributes = NoteAttributes()
  var soundSet = 0
  var program = 0
  var instrument: Instrument?

  @IBOutlet weak var soundSetPicker: InlinePickerView!
  @IBOutlet weak var programPicker: InlinePickerView!
  @IBOutlet weak var notePicker: InlinePickerView!
  @IBOutlet weak var durationPicker: InlinePickerView!
  @IBOutlet weak var velocityPicker: InlinePickerView!

  @IBAction func playNote() {
    guard let instrument = instrument else {
      logError("cannot play note when instrument is nil")
      return
    }
    instrument.playNoteWithAttributes(noteAttributes)
  }

  @IBAction func didPickSoundSet(picker: InlinePickerView) {
    let idx = picker.selection
    logDebug("picked sound set '\(Sequencer.soundSets[idx])'")
    programs = Sequencer.soundSets[idx].presets
    programPicker.labels = programs.map {$0.name}
    soundSet = idx
    program = 0
    programPicker.selectItem(0, animated: true)
    do {
      try instrument?.loadSoundSet(Sequencer.soundSets[soundSet], program: UInt8(programs[program].program))
    } catch {
      logError(error)
    }
  }

  @IBAction func didPickProgram(picker: InlinePickerView) {
    let idx = picker.selection
    logDebug("picked program '\(programs[idx])'")
    program = idx
    do {
      try instrument?.loadSoundSet(Sequencer.soundSets[soundSet], program: UInt8(programs[program].program))
    } catch {
      logError(error)
    }
  }

  @IBAction func didPickNote(picker: InlinePickerView) {
    let idx = picker.selection
    let note = NoteAttributes.Note.allCases[idx]
    logDebug("picked note '\(note.rawValue)'")
    noteAttributes.note = note
  }

  @IBAction func didPickDuration(picker: InlinePickerView) {
    let idx = picker.selection
    let duration = NoteAttributes.Duration.allCases[idx]
    logDebug("picked duration '\(duration)'")
    noteAttributes.duration = duration
  }

  @IBAction func didPickVelocity(picker: InlinePickerView) {
    let idx = picker.selection
    let velocity = NoteAttributes.Velocity.allCases[idx]
    logDebug("picked velocity '\(velocity)'")
    noteAttributes.velocity = velocity
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    programs = Sequencer.soundSets[0].presets
    program = max(programPicker.selection, 0)
    soundSet = max(soundSetPicker.selection, 0)
    noteAttributes.note = NoteAttributes.Note.allCases[notePicker.selection]
    noteAttributes.duration = NoteAttributes.Duration.allCases[durationPicker.selection]
    noteAttributes.velocity = NoteAttributes.Velocity.allCases[velocityPicker.selection]

    do {
      try AudioManager.start()
      instrument = try Instrument(soundSet: Sequencer.soundSets[soundSet], program: UInt8(programs[program].program))
    } catch {
      logError(error)
    }

  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

}

