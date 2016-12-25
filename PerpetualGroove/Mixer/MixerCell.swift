//
//  MixerCell.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

// TODO: Review file
import Chameleon
import CoreImage
import typealias AudioToolbox.AudioUnitParameterValue

final class AddTrackCell: UICollectionViewCell {

  static let Identifier = "AddTrackCell"
  @IBOutlet weak var mockTrackBackground: UIImageView!
  @IBOutlet weak var addTrackButton: ImageButtonView!

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
  
  func refresh() {
    volume = AudioManager.mixer.volume
    pan = AudioManager.mixer.pan
  }

  @IBAction func volumeDidChange() {
    AudioManager.mixer.volume = volume
  }

  @IBAction func panDidChange() {
    AudioManager.mixer.pan = pan
  }

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

  private var startLocation: CGPoint?

  @IBOutlet var removalDisplay: UIVisualEffectView!

  override var isSelected: Bool {
    get { return super.isSelected }
    set { trackColor.isSelected = newValue; super.isSelected = newValue }
  }

  @IBAction func instrument() {
    if controller?.soundFontTarget === self {
      controller?.soundFontTarget = nil
    } else {
      controller?.soundFontTarget = self
    }
  }

  @IBAction func solo() { track?.solo.toggle() }

  private var muteDisengaged = false { didSet { muteButton.isEnabled = !muteDisengaged } }

  @IBAction func mute() { track?.mute.toggle() }

  @IBAction func volumeDidChange() { track?.volume = volume }

  @IBAction func panDidChange() { track?.pan = pan }

  weak var track: InstrumentTrack? {
    didSet {
      guard track != oldValue else { return }
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      soundSetImage.image = track?.instrument.soundFont.image
      trackLabel.text = track?.displayName ?? ""
      trackColor.normalTintColor = track?.color.value
      muteButton.isSelected = track?.isMuted ?? false
      soloButton.isSelected = track?.solo ?? false
      receptionist = receptionistForTrack(track)
    }
  }

  private var receptionist: NotificationReceptionist?

  private func receptionistForTrack(_ track: InstrumentTrack?) -> NotificationReceptionist? {

    guard let track = track else { return nil }
    
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.SequencerContext
    
    receptionist.observe(name: .muteStatusDidChange, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.muteButton.isSelected = track.isMuted
    }
    
    receptionist.observe(name: .forceMuteStatusDidChange, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.muteDisengaged = track.forceMute || track.solo
    }

    receptionist.observe(name: .soloStatusDidChange, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.soloButton.isSelected = track.solo
      self?.muteDisengaged = track.forceMute || track.solo
    }

    receptionist.observe(name: .didChangeName, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.trackLabel.text = track.displayName
    }

    receptionist.observe(name: .soundFontDidChange, from: track.instrument) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.soundSetImage.image = track.instrument.soundFont.image
      self?.trackLabel.text = track.displayName
    }

    receptionist.observe(name: .programDidChange, from: track.instrument) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.trackLabel.text = track.displayName
    }

    return receptionist
  }

}

extension TrackCell: UITextFieldDelegate {

  func textFieldDidEndEditing(_ textField: UITextField) {
    if let text = textField.text {
      track?.name = text
    }
  }

}
