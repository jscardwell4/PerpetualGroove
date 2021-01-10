//
//  TrackCell.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright (c) 2021 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonKit
import Combine

// MARK: - TrackCell

/// `MixerCell` subclass for controlling property values for an individual track.
public final class TrackCell: MixerCell
{
  /// Button for toggling track solo status.
  @IBOutlet public var soloButton: LabelButton!

  /// Button for toggling track muting.
  @IBOutlet public var muteButton: LabelButton!

  /// Button for toggling an instrument editor for the track.
  @IBOutlet public var soundSetImage: ImageButtonView!

  /// A text field for displaying/editing the name of the track.
  @IBOutlet public var trackLabel: MarqueeField!

  /// A button for displaying the track's color and setting the current track.
  @IBOutlet public var trackColor: ImageButtonView!

  /// A blurred view that blocks access to track controls and indicates
  /// that the track is slated to be deleted.
  @IBOutlet public var removalDisplay: UIVisualEffectView!

  /// Overridden to keep `trackColor.isSelected` in sync with `isSelected`.
  override public var isSelected: Bool { didSet { trackColor.isSelected = isSelected } }

  /// The action attached to `soloButton`. Toggles `track.solo`.
  @IBAction public func solo() { track?.solo.toggle() }

  /// Flag indicating whether the mute button has been disabled.
  private var muteDisengaged = false
  {
    didSet { muteButton.isEnabled = !muteDisengaged }
  }

  /// Action attached to `muteButton`. Toggles `track.mute`.
  @IBAction public func mute() { track?.mute.toggle() }

  /// Action attached to `volumeSlider`. Updates `track.volume` using `volume`.
  @IBAction public func volumeDidChange() { track?.volume = volume }

  /// Action attached to `panKnob`. Updates `track.pan` using `pan`.
  @IBAction public func panDidChange() { track?.pan = pan }

  /// The track for which the cell provides an interface.
  public weak var track: InstrumentTrack?
  {
    willSet
    {
      muteStatusSubscription?.cancel()
      forceMuteStatusSubscription?.cancel()
      soloStatusSubscription?.cancel()
      nameChangeSubscription?.cancel()
      soundFontChangeSubscription?.cancel()
      programChangeSubscription?.cancel()
    }
    didSet
    {
      guard track != oldValue else { return }
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      soundSetImage.image = track?.instrument.soundFont.image
      trackLabel.text = track?.displayName ?? ""
      trackColor.normalTintColor = track?.color.value
      muteButton.isSelected = track?.isMuted ?? false
      soloButton.isSelected = track?.solo ?? false

      if let track = track
      {
        muteStatusSubscription = track.$isMuted.sink { self.muteButton.isSelected = $0 }
        forceMuteStatusSubscription = track.$forceMute.sink
        {
          self.muteDisengaged = $0 || (self.track?.solo == true)
        }
        soloStatusSubscription = track.$solo.sink
        {
          self.soloButton.isSelected = $0
          self.muteDisengaged = $0 || (self.track?.forceMute == true)
        }
        nameChangeSubscription = NotificationCenter.default
          .publisher(for: .trackDidChangeName, object: track)
          .sink { _ in self.trackLabel.text = self.track?.displayName ?? "" }
        soundFontChangeSubscription = NotificationCenter.default
          .publisher(for: .instrumentSoundFontDidChange, object: track.instrument)
          .sink
          {
            _ in guard let track = self.track else { return }
            self.soundSetImage.image = track.instrument.soundFont.image
            self.trackLabel.text = track.displayName
          }
        programChangeSubscription = NotificationCenter.default
          .publisher(for: .instrumentProgramDidChange, object: track.instrument)
          .sink { _ in self.trackLabel.text = self.track?.displayName ?? "" }
      }
    }
  }

  /// Subscription for mute status changes.
  private var muteStatusSubscription: Cancellable?

  /// Subscription for force mute status changes.
  private var forceMuteStatusSubscription: Cancellable?

  /// Subscription for solo status changes.
  private var soloStatusSubscription: Cancellable?

  /// Subscription for name changes.
  private var nameChangeSubscription: Cancellable?

  /// Subscription for sound font changes.
  private var soundFontChangeSubscription: Cancellable?

  /// Subscription for program changes.
  private var programChangeSubscription: Cancellable?
}

// MARK: - TrackCell + UITextFieldDelegate

extension TrackCell: UITextFieldDelegate
{
  /// Updates `track.name` when `textField` holds a non-empty string.
  public func textFieldDidEndEditing(_ textField: UITextField)
  {
    if let text = textField.text { track?.name = text }
  }
}

