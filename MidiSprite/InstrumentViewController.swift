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
    let program = UInt8(soundSet.presets[0].program)
    do { try instrument?.loadSoundSet(soundSet, program: program) } catch { logError(error) }
    programPicker.labels = soundSet.presets.map({$0.name})
  }

  /** didPickProgram */
  @IBAction func didPickProgram() {
    let soundSet = Sequencer.auditionInstrument.soundSet
    let program = UInt8(soundSet.presets[programPicker.selection].program)
    do { try instrument?.loadSoundSet(soundSet, program: program) } catch { logError(error) }
  }

  /** didChangeChannel */
  @IBAction func didChangeChannel() { Sequencer.auditionInstrument.channel = UInt8(channelStepper.value) }

  /** auditionValues */
  @IBAction func auditionValues() { Sequencer.auditionCurrentNote() }

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  var instrument: Instrument? {
    didSet {
      guard let instrument = instrument,
             soundSetIndex = Sequencer.soundSets.indexOf(instrument.soundSet),
              programIndex = instrument.soundSet.presets.map({UInt8($0.program)}).indexOf(instrument.program)
      else { return }
      soundSetPicker.selection = soundSetIndex
      programPicker.labels = instrument.soundSet.presets.map({$0.name})
      programPicker.selection = programIndex
      channelStepper.value = Double(instrument.channel)
    }
  }

//  override func updateViewConstraints() {
//    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)
//    super.updateViewConstraints()
//  }


  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
//    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)
    soundSetPicker.labels = Sequencer.soundSets.map { $0.displayName }
    instrument = Sequencer.auditionInstrument
    logDebug(view.viewTreeDescription, asynchronous: false)
  }

}
