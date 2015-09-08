//
//  ViewController.swift
//  Instruments
//
//  Created by Jason Cardwell on 9/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

class ViewController: UIViewController {

  var programs: [SF2File.Preset] = []

  var soundSet = 0
  var program = 0

  @IBOutlet weak var soundSetPicker: InlinePickerView!
  @IBOutlet weak var programPicker: InlinePickerView!
  @IBOutlet weak var pitchPicker: InlinePickerView!
  @IBOutlet weak var octaveStepper: LabeledStepper!

  @IBAction func octaveDidChange(sender: LabeledStepper) {
  }

  func didPickPitch(picker: InlinePickerView, idx: Int) {
    
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    do { try AudioManager.start() } catch { logError(error) }
    soundSetPicker.labels = Sequencer.soundSets.map({$0.displayName})
    logDebug("soundSetPicker.labels = \(soundSetPicker.labels)")
    soundSetPicker.didSelectItem = didPickSoundSet
    soundSetPicker.selection = 0
    programs = Sequencer.soundSets[0].presets
    logDebug("programs = \(programs)")
    programPicker.labels = programs.map {$0.name}
    programPicker.didSelectItem = didPickProgram
    programPicker.selection = 0

    pitchPicker.didSelectItem = didPickPitch
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
    logDebug("picked sound set '\(programs[idx])'")
    program = idx
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

}

