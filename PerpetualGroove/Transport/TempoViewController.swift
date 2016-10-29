//
//  TempoViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class TempoViewController: UIViewController {

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var metronomeButton: ImageButtonView!

  @IBAction fileprivate func tempoSliderValueDidChange() { Sequencer.tempo = Double(tempoSlider.value) }

  @IBAction fileprivate func toggleMetronome() { AudioManager.metronome.on = !AudioManager.metronome.on }

  override func viewDidLoad() {
    super.viewDidLoad()
    tempoSlider.value = Float(Sequencer.tempo)
    metronomeButton.isSelected = AudioManager.metronome?.on ?? false
  }

}
