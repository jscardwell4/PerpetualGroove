//
//  MixerCell.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit
import Chameleon
import CoreImage
import typealias AudioToolbox.AudioUnitParameterValue

final class AddTrackCell: UICollectionViewCell {

  static let Identifier = "AddTrackCell"
  @IBOutlet weak var mockTrackBackground: UIImageView!
  @IBOutlet weak var addTrackButton: ImageButtonView!

  /** prepareForReuse */
  override func prepareForReuse() {
    super.prepareForReuse()
    addTrackButton.isSelected = false
    addTrackButton.isHighlighted = false
  }

}

class MixerCell: UICollectionViewCell {

  @IBOutlet weak var volumeSlider: Slider!
  @IBOutlet weak var panKnob:      Knob!
  @IBOutlet weak var stackView:    UIStackView!

  var volume: AudioUnitParameterValue {
    get { return volumeSlider.value / volumeSlider.maximumValue }
    set { volumeSlider.value = newValue * volumeSlider.maximumValue }
  }

  var pan: AudioUnitParameterValue {
    get { return panKnob.value }
    set { panKnob.value = newValue }
  }

}

final class MasterCell: MixerCell {

  static let Identifier = "MasterCell"
  
  /** refresh */
  func refresh() { volume = AudioManager.mixer.volume; pan = AudioManager.mixer.pan }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { AudioManager.mixer.volume = volume }
  @IBAction func panDidChange() { AudioManager.mixer.pan = pan }

}

final class TrackCell: MixerCell {

  class var Identifier: String { return "TrackCell" }

  @IBOutlet weak var controller: MixerViewController?

  @IBOutlet var soloButton: LabelButton!
  @IBOutlet var muteButton: LabelButton!

  @IBOutlet var volumeLabel: Label!
  @IBOutlet var panLabel:    Label!

  @IBOutlet var soundSetImage: ImageButtonView!

  @IBOutlet var trackLabel: MarqueeField!
  @IBOutlet var trackColor: ImageButtonView!

  fileprivate var startLocation: CGPoint?

  @IBOutlet var removalDisplay: UIVisualEffectView!

  override var isSelected: Bool {
    get { return super.isSelected }
    set { trackColor.isSelected = newValue; super.isSelected = newValue }
  }

  /** instrument */
  @IBAction func instrument() { controller?.registerCellForSoundSetSelection(self) }

  /** solo */
  @IBAction func solo() { track?.solo.toggle() }

  fileprivate var muteDisengaged = false { didSet { muteButton.isEnabled = !muteDisengaged } }

  /** mute */
  @IBAction func mute() { track?.mute.toggle() }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volume }

  /** panDidChange */
  @IBAction func panDidChange() { track?.pan = pan }

  weak var track: InstrumentTrack? {
    didSet {
      guard track != oldValue else { return }
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      soundSetImage.image = track?.instrument.soundSet.image
      trackLabel.text = track?.displayName ?? ""
      trackColor.normalTintColor = track?.color.value
      muteButton.isSelected = track?.isMuted ?? false
      soloButton.isSelected = track?.solo ?? false
      receptionist = receptionistForTrack(track)
    }
  }

  fileprivate var receptionist: NotificationReceptionist?

  /**
  receptionistForTrack:

  - parameter track: InstrumentTrack

  - returns: NotificationReceptionist
  */
  fileprivate func receptionistForTrack(_ track: InstrumentTrack?) -> NotificationReceptionist? {

    
    guard let track = track else { return nil }
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.SequencerContext
    
    receptionist.observe(name: Track.NotificationName.muteStatusDidChange.rawValue, from: track) {
      [weak self] _ in
      guard let weakself = self, let track = weakself.track else { return }
      weakself.muteButton.isSelected = track.isMuted
    }
    receptionist.observe(name: Track.NotificationName.forceMuteStatusDidChange.rawValue, from: track) {
      [weak self] _ in
      guard let weakself = self, let track = weakself.track else { return }
      weakself.muteDisengaged = track.forceMute || track.solo
    }
    receptionist.observe(name: Track.NotificationName.soloStatusDidChange.rawValue, from: track) {
      [weak self] _ in
      guard let weakself = self, let track = weakself.track else { return }
      weakself.soloButton.isSelected = track.solo
      weakself.muteDisengaged = track.forceMute || track.solo
    }
    receptionist.observe(name: Track.NotificationName.didChangeName.rawValue, from: track) {
      [weak self] _ in
      guard let weakself = self, let track = weakself.track else { return }
      weakself.trackLabel.text = track.displayName
    }
    receptionist.observe(name: Instrument.NotificationName.soundSetDidChange.rawValue, from: track.instrument) {
      [weak self] _ in
      guard let weakself = self, let track = weakself.track else { return }
      weakself.soundSetImage.image = track.instrument.soundSet.image
      weakself.trackLabel.text = track.displayName
    }
    receptionist.observe(name: Instrument.NotificationName.presetDidChange.rawValue, from: track.instrument) {
      [weak self] _ in
      guard let weakself = self, let track = weakself.track else { return }
      weakself.trackLabel.text = track.displayName
    }
    return receptionist
  }

}

extension TrackCell: UITextFieldDelegate {

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(_ textField: UITextField) { if let text = textField.text { track?.name = text } }

}
