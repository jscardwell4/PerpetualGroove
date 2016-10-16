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

  @IBOutlet weak var soundSetPicker: InlinePickerView!
  @IBOutlet weak var programPicker:  InlinePickerView!
  @IBOutlet weak var channelStepper: LabeledStepper!

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
//    receptionist.observe(name: Sequencer.NotificationName.soundSetSelectionTargetDidChange.rawValue, from: Sequencer.self) {
//      [weak self] in self?.instrument = $0.newSoundSetSelectionTarget
//    }
    receptionist.observe(name: Sequencer.NotificationName.didUpdateAvailableSoundSets.rawValue,
                         from: Sequencer.self,
                         callback: weakMethod(self, InstrumentViewController.updateSoundSets))
  }

  fileprivate func updateSoundSets(_ notification: Notification) { updateSoundSets() }

  fileprivate func updateSoundSets() {
    soundSetPicker.labels = Sequencer.soundSets.map { $0.displayName }
//    instrument = Sequencer.soundSetSelectionTarget
  }


  @IBAction func didPickSoundSet() {
    guard let instrument = instrument else { return }
    let soundSet = Sequencer.soundSets[soundSetPicker.selection]
    let preset = Instrument.Preset(soundFont: soundSet, presetHeader: soundSet[0], channel: 0)

    do {
      try instrument.loadPreset(preset)
      programPicker.selection = 0
      programPicker.labels = soundSet.presetHeaders.map({$0.name})
      audition()
    } catch {
      logError(error)
    }
  }

  @IBAction func didPickProgram() {
    guard let instrument = instrument else { return }
    let soundSet = instrument.soundFont
    let presetHeader = soundSet.presetHeaders[programPicker.selection]
    let preset = Instrument.Preset(soundFont: soundSet, presetHeader: presetHeader, channel: 0)
    do {
      try instrument.loadPreset(preset)
      audition()
    } catch {
      logError(error)
    }
  }

  @IBAction func didChangeChannel() { instrument?.channel = UInt8(channelStepper.value) }


  func rollBackInstrument() {
    guard let instrument = instrument, let initialPreset = initialPreset else {
      return
    }
    do { try instrument.loadPreset(initialPreset) } catch { logError(error) }
  }

  fileprivate(set) var initialPreset: Instrument.Preset?

  weak var instrument: Instrument? {
    didSet {
      guard let instrument = instrument,
        let soundSetIndex = instrument.soundFont.index,
        let presetIndex = instrument.soundFont.presetHeaders.index(of: instrument.preset.presetHeader) ,
        isViewLoaded
      else { return }

      initialPreset = instrument.preset
      soundSetPicker.selectItem(soundSetIndex, animated: true)
      programPicker.labels = instrument.soundFont.presetHeaders.map({$0.name})
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
