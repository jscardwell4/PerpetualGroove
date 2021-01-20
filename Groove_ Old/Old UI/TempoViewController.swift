//
//  TempoViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import MoonDev
import UIKit

/// A simple view controller presenting a tempo slider and a metronome toggle.
@available(iOS 14.0, *)
public final class TempoViewController: UIViewController
{
  /// The slider for setting the sequencer's tempo.
  @IBOutlet public var tempoSlider: Slider!
  
  /// The button for toggling the audio manager's metronome on and off.
  @IBOutlet public var metronomeButton: ImageButtonView!
  
  /// Handles `tempoSlider` value changes by updating `Sequencer.tempo`
  /// with the new slider value.
  @IBAction private func tempoSliderValueDidChange()
  {
    sequencer.tempo = Double(tempoSlider.value)
  }
  
  /// Handles presses of the `metronomeButton` by toggling `AudioManager.metronome.isOn`.
  @IBAction private func toggleMetronome() { metronome.isOn.toggle() }
  
  /// Overridden to update `tempoSlider.value` and `metronomeButton.isSelected`
  /// with current values.
  override public func viewDidLoad()
  {
    super.viewDidLoad()
    
    // Set the slider's value to the current tempo.
    tempoSlider.value = Float(sequencer.tempo)
    
    // Set the selected state of the button to match whether the metronome is on.
    metronomeButton.isSelected = metronome.isOn
  }
}
