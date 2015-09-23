//
//  TempoViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class TempoViewController: UIViewController {

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var metronomeButton: ImageButtonView!

  override func updateViewConstraints() {
    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)
    super.updateViewConstraints()
  }

  /** tempoSliderValueDidChange */
  @IBAction private func tempoSliderValueDidChange() { logDebug(""); Sequencer.tempo = Double(tempoSlider.value) }

  /** toggleMetronome */
  @IBAction private func toggleMetronome() { logDebug(""); AudioManager.metronome.on = !AudioManager.metronome.on }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    tempoSlider.value = Float(Sequencer.tempo)
    metronomeButton.selected = AudioManager.metronome.on
    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)
  }

}
