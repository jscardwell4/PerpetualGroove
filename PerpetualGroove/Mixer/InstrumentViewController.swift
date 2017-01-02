//
//  InstrumentViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class InstrumentViewController: UIViewController, SecondaryControllerContent {

  @IBOutlet weak var soundSetPicker: SoundFontSelector!
  @IBOutlet weak var programPicker:  ProgramSelector!
  @IBOutlet weak var channelStepper: LabeledStepper!

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    receptionist.observe(name: .didUpdateAvailableSoundSets, from: Sequencer.self) {
      [weak self] _ in self?.updateSoundSets()
    }
  }

  fileprivate func updateSoundSets() {
    soundSetPicker.refreshItems()

  }

  /// Callback for `soundSetPicker` selections.
  @IBAction func didPickSoundSet() {
    guard let instrument = instrument else { return }
    let soundFont = Sequencer.soundSets[soundSetPicker.selection]
    let preset = Instrument.Preset(soundFont: soundFont, presetHeader: soundFont[0], channel: 0)

    do {
      try instrument.loadPreset(preset)
      programPicker.selection = 0
      programPicker.soundFont = soundFont
      audition()
    } catch {
      Log.error(error)
    }
  }

  /// Callback for `programPicker` selections.
  @IBAction func didPickProgram() {
    guard let instrument = instrument else { return }
    let soundSet = instrument.soundFont
    let presetHeader = soundSet.presetHeaders[programPicker.selection]
    let preset = Instrument.Preset(soundFont: soundSet, presetHeader: presetHeader, channel: 0)
    do {
      try instrument.loadPreset(preset)
      audition()
    } catch {
      Log.error(error)
    }
  }

  /// Callback for `channelStepper` value changes.
  @IBAction func didChangeChannel() { instrument?.channel = UInt8(channelStepper.value) }

  /// Loads `initialPreset` back into `instrument`.
  func rollBackInstrument() {
    guard let instrument = instrument, let initialPreset = initialPreset else {
      return
    }
    do { try instrument.loadPreset(initialPreset) } catch { Log.error(error) }
  }

  /// The preset property value of `instrument` upon initialization.
  fileprivate(set) var initialPreset: Instrument.Preset?

  /// Instrument used by the controller to provide feedback for soundfont and program changes.
  weak var instrument: Instrument? {
    didSet {
      guard let instrument = instrument,
        let soundSetIndex = instrument.soundFont.index,
        let presetIndex = instrument.soundFont.presetHeaders.index(of: instrument.preset.presetHeader),
        isViewLoaded
      else { return }

      initialPreset = instrument.preset
      soundSetPicker.selectItem(soundSetIndex, animated: true)
      programPicker.soundFont = instrument.soundFont
      programPicker.selectItem(presetIndex, animated: true)
      channelStepper.value = Double(instrument.channel)
    }
  }

  fileprivate func audition() {
    guard let instrument = instrument else { return }
    instrument.playNote(AnyMIDIGenerator())
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    guard Sequencer.initialized else { return }
    updateSoundSets()
  }

}

