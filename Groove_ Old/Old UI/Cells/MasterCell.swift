//
//  MasterCell.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright (c) 2021 Moondeer Studios. All rights reserved.
//

// MARK: - MasterCell

/// `MixerCell` subclass for controlling master volume and pan.
@available(iOS 14.0, *)
public final class MasterCell: MixerCell
{
  /// Updates the knob and slider with current values retrieved from `AudioManager`.
  public func refresh()
  {
    volume = audioEngine.mixer.volume
    pan = audioEngine.mixer.pan
  }

  /// Updates `AudioManager.mixer.volume`.
  @IBAction public func volumeDidChange() { audioEngine.mixer.volume = volume }

  /// Updates `AudioManager.mixer.pan`.
  @IBAction public func panDidChange() { audioEngine.mixer.pan = pan }
}

