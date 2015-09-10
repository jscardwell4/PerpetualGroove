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

  @IBAction func didPickSoundSet() {
  }

  @IBAction func didPickProgram() {
  }

  @IBAction func didChangeChannel() {
  }

  @IBAction func auditionValues() {
  }
  
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


  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let soundSetPicker = soundSetPicker else { fatalError("wtf") }
    soundSetPicker.labels = Sequencer.soundSets.map { $0.displayName }
    instrument = Sequencer.currentTrack.instrument
  }

}
