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

  @IBOutlet var trackLabel: TrackLabel!
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

  private var markedForRemoval = false {
    didSet {
      guard markedForRemoval != oldValue else { return }
      logDebug("markedForRemoval: \(markedForRemoval)")
      UIView.animateWithDuration(0.25) {[unowned self] in self.removalDisplay.alpha = self.markedForRemoval ? 1 : 0 }
    }
  }

  /**
  handleLongPress:

  - parameter sender: UILongPressGestureRecognizer
  */
  @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
    switch sender.state {
      case .Began:
        logDebug("Began")
        startLocation = sender.locationInView(controller?.collectionView)
        UIView.animateWithDuration(0.25) { [unowned self] in
          self.layer.transform = CATransform3D(sx: 1.1, sy: 1.1, sz: 1.1).translate(tx: 0, ty: 10, tz: 0)
        }
        controller?.movingCell = self

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
        logDebug("Ended")
        startLocation = nil
        controller?.movingCell = nil
        UIView.animateWithDuration(0.25) { [unowned self] in self.layer.transform = .identity }
    }
  }

  /** solo */
  @IBAction func solo() {
    logDebug()
  }

  /** mute */
  @IBAction func mute() {
    logDebug()
  }

  /** setup */
  private func setup() {
    let view = UIView()
    view.backgroundColor = .clearColor()
    backgroundView = view
    selectedBackgroundView = view
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volume }

  /** panDidChange */
  @IBAction func panDidChange() { track?.pan = pan }

  weak var track: InstrumentTrack? {
    didSet {
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      trackLabel.text = track?.name ?? ""
      trackColor.tintColor = track?.color.value
    }
  }

}

extension TrackCell: TrackLabelDelegate {

  /**
  trackLabelDidChange:

  - parameter trackLabel: TrackLabel
  */
  func trackLabelDidChange(trackLabel: TrackLabel) { track?.label = trackLabel.text }

}