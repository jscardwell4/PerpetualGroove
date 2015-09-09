//
//  ViewController.swift
//  Instruments
//
//  Created by Jason Cardwell on 9/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit
import AudioToolbox


class ViewController: UIViewController {

  var programs: [SF2File.Preset] = []

  var soundSet = 0
  var program = 0
  var noteAttributes = NoteAttributes()
  var instrument: Instrument?

  @IBOutlet weak var soundSetPicker: InlinePickerView!
  @IBOutlet weak var programPicker: InlinePickerView!
  @IBOutlet weak var pitchPicker: InlinePickerView!
  @IBOutlet weak var octaveStepper: LabeledStepper!
  @IBOutlet weak var durationPicker: InlinePickerView!

  @IBAction func playNote() {
    guard let instrument = instrument else { return }
//    instrument.node.sendMIDIEvent(0x90, data1: 0x36, data2: 0x40)
    instrument.playNoteWithAttributes(noteAttributes)
//    instrument.node.startNote(note, withVelocity: velocity, onChannel: 0)
//    delayedDispatch(attributes.duration.seconds, dispatch_get_main_queue()) {
//      instrument.node.stopNote(note, onChannel: 0)
//    }

  }

  @IBAction func octaveDidChange(stepper: LabeledStepper) {
    let rawPitch = pitchPicker.labels[pitchPicker.selection]
    let octave = stepper.value
    guard let note = NoteAttributes.Note(rawValue: "\(rawPitch)\(Int(octave))") else { return }
    noteAttributes.note = note
  }
  func didPickPitch(picker: InlinePickerView, idx: Int) {
    let rawPitch = picker.labels[idx]
    let octave = Int(octaveStepper.value)
    guard let note = NoteAttributes.Note(rawValue: "\(rawPitch)\(octave)") else { return }
    noteAttributes.note = note
  }

  func didPickDuration(picker: InlinePickerView, idx: Int) {
    noteAttributes.duration = NoteAttributes.Duration.allCases[idx]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    soundSetPicker.labels = Sequencer.soundSets.map({$0.displayName})
    soundSetPicker.didSelectItem = didPickSoundSet
    soundSetPicker.selection = 0
    programs = Sequencer.soundSets[0].presets
    programPicker.labels = programs.map {$0.name}
    programPicker.didSelectItem = didPickProgram
    programPicker.selection = 0
    pitchPicker.didSelectItem = didPickPitch
    durationPicker.didSelectItem = didPickDuration

    do {
      instrument = try Instrument(soundSet: Sequencer.soundSets[0], program: 0)
      try AudioManager.start()
    } catch {
      logError(error)
    }
  }

  func didPickSoundSet(picker: InlinePickerView, idx: Int) {
    logDebug("picked sound set '\(Sequencer.soundSets[idx])'")
    programs = Sequencer.soundSets[idx].presets
    programPicker.labels = programs.map {$0.name}
    soundSet = idx
    program = 0
    programPicker.selectItem(0, animated: true)

  }

  func didPickProgram(picker: InlinePickerView, idx: Int) {
    logDebug("picked program '\(programs[idx])'")
    program = idx
    instrument?.node.sendProgramChange(UInt8(programs[idx].program), bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: UInt8(kAUSampler_DefaultBankLSB), onChannel: 0)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

}

