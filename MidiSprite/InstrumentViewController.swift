//
//  InstrumentViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class InstrumentViewController: UIViewController {

  @IBOutlet weak var soundSetPicker: InlinePickerView!
  @IBOutlet weak var programPicker:  InlinePickerView!
  @IBOutlet weak var channelStepper: LabeledStepper!

  /** didPickSoundSet */
  @IBAction func didPickSoundSet() {
    let soundSet = Sequencer.soundSets[soundSetPicker.selection]
    do {
      try instrument?.loadPreset(soundSet.presets[0])
      programPicker.selection = 0
      programPicker.labels = soundSet.presets.map({$0.name})
    } catch {
      logError(error)
    }
  }

  /** didPickProgram */
  @IBAction func didPickProgram() {
    let soundSet = Sequencer.auditionInstrument.soundSet
    do {
      try instrument?.loadPreset(soundSet.presets[programPicker.selection])
    } catch {
      logError(error)
    }
  }

  /** didChangeChannel */
  @IBAction func didChangeChannel() { Sequencer.auditionInstrument.channel = UInt8(channelStepper.value) }

  /** auditionValues */
  @IBAction func auditionValues() { Sequencer.auditionCurrentNote() }

  var instrument: Instrument? {
    didSet {
      guard let instrument = instrument,
             soundSetIndex = Sequencer.soundSets.indexOf(instrument.soundSet),
              presetIndex = instrument.soundSet.presets.indexOf(instrument.preset)
      else { return }
      soundSetPicker.selection = soundSetIndex
      programPicker.labels = instrument.soundSet.presets.map({$0.name})
      programPicker.selection = presetIndex
      channelStepper.value = Double(instrument.channel)
    }
  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    soundSetPicker.labels = Sequencer.soundSets.map { $0.displayName }
    instrument = Sequencer.auditionInstrument
  }

}
