//
//  MixerCell.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright (c) 2021 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonKit
import typealias AudioToolbox.AudioUnitParameterValue

// MARK: - MixerCell

/// Abstract base for a cell with a label and volume/pan controls.
public class MixerCell: UICollectionViewCell
{
  /// Controls the volume output for a connection.
  @IBOutlet public var volumeSlider: Slider!

  /// Controls panning for a connection.
  @IBOutlet public var panKnob: Knob!

  /// Accessors for a normalized `volumeSlider.value`.
  public var volume: AudioUnitParameterValue
  {
    get { volumeSlider.value / volumeSlider.maximumValue }
    set { volumeSlider.value = newValue * volumeSlider.maximumValue }
  }

  /// Accessors for `panKnob.value`.
  public var pan: AudioUnitParameterValue
  {
    get { return panKnob.value }
    set { panKnob.value = newValue }
  }
}

