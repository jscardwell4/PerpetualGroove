//
//  MixerCell.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit
import Chameleon
import CoreImage
import typealias AudioToolbox.AudioUnitParameterValue

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
  @IBOutlet var trackColor: ImageButtonView! {
    didSet { trackColor?.addGestureRecognizer(longPress) }
  }

  private lazy var longPress: UILongPressGestureRecognizer = {
    let gesture = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
    gesture.delaysTouchesBegan = true
    return gesture
  }()

  private var startLocation: CGPoint?

  @IBOutlet var removalDisplay: UIVisualEffectView!

  override var selected: Bool {
    get { return super.selected }
    set {
      trackColor.selected = newValue
      super.selected = newValue
    }
  }

  private var markedForRemoval = false {
    didSet {
      guard markedForRemoval != oldValue else { return }
      UIView.animateWithDuration(0.25) {[unowned self] in self.removalDisplay.hidden = !self.markedForRemoval }
    }
  }

  /**
  handleLongPress:

  - parameter sender: UILongPressGestureRecognizer
  */
  @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
    switch sender.state {
      case .Began:
        startLocation = sender.locationInView(controller?.collectionView)
        UIView.animateWithDuration(0.25) { [unowned self] in
          self.layer.transform = CATransform3D(sx: 1.1, sy: 1.1, sz: 1.1).translate(tx: 0, ty: 10, tz: 0)
        }

      case .Changed:
        guard let startLocation = startLocation else { break }
        let currentLocation = sender.locationInView(controller?.collectionView)

        switch (startLocation - currentLocation).unpack {
        case let (x, _) where x < -50 && !markedForRemoval:
            controller?.shiftCell(self, direction: .Right); self.startLocation = currentLocation
          case let (x, _) where x > 50 && !markedForRemoval:
            controller?.shiftCell(self, direction: .Left); self.startLocation = currentLocation
          case let (_, y) where y < -50 && !markedForRemoval:
            markedForRemoval = true
          case let (_, y) where y > -50 && markedForRemoval:
            markedForRemoval = false
          default:
            break
        }

      case .Ended where markedForRemoval:
        controller?.deleteItem(self)

      case .Cancelled, .Ended: fallthrough

      default:
        startLocation = nil
        UIView.animateWithDuration(0.25) { [unowned self] in self.layer.transform = .identity }
    }
  }

  /** solo */
  @IBAction func solo() {
    guard let track = track else { return }
    Sequencer.sequence?.toggleSoloForTrack(track)
  }

  private var muteDisengaged = false { didSet { muteButton.enabled = !muteDisengaged } }

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
      trackLabel.text = track?.name ?? ""
      trackColor.tintColor = track?.color.value
      muteButton.selected = track?.mute ?? false
      soloButton.selected = track?.solo ?? false
      receptionist = receptionistForTrack(track)
    }
  }

  private var receptionist: NotificationReceptionist?

  /**
  muteStatusChanged:

  - parameter notification: NSNotification
  */
  private func muteStatusChanged(notification: NSNotification) {
    muteButton.selected = track?.mute ?? false
  }

  /**
  soloStatusChanged:

  - parameter notification: NSNotification
  */
  private func soloStatusChanged(notification: NSNotification) { soloButton.selected = track?.solo ?? false }

  /**
  soloCountChanged:

  - parameter notification: NSNotification
  */
  private func soloCountChanged(notification: NSNotification) {
    guard let count = (notification.userInfo?[MIDISequence.Notification.Key.NewCount.rawValue] as? NSNumber)?.integerValue else {
      return
    }
    muteDisengaged = count > 0
  }

  /**
  receptionistForTrack:

  - parameter track: InstrumentTrack

  - returns: NotificationReceptionist
  */
  private func receptionistForTrack(track: InstrumentTrack?) -> NotificationReceptionist? {
    guard let track = track else { return nil }
    let queue = NSOperationQueue.mainQueue()
    let receptionist = NotificationReceptionist()
    receptionist.observe(InstrumentTrack.Notification.MuteStatusDidChange,
                    from: track,
                   queue: queue,
                callback: muteStatusChanged)
    receptionist.observe(InstrumentTrack.Notification.SoloStatusDidChange,
                    from: track,
                   queue: queue,
                callback: soloStatusChanged)
    receptionist.observe(MIDISequence.Notification.SoloCountDidChange,
                    from: Sequencer.sequence,
                   queue: queue,
                callback: soloCountChanged)
    return receptionist
  }

}

extension TrackCell: UITextFieldDelegate {

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(textField: UITextField) { track?.label = textField.text }

}