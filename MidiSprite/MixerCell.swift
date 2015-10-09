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
import typealias AudioToolbox.AudioUnitParameterValue

class MixerCell: UICollectionViewCell {

  @IBOutlet weak var volumeSlider: Slider!
  @IBOutlet weak var panKnob: Knob!
  @IBOutlet weak var stackView: UIStackView!

  var volume: AudioUnitParameterValue {
    get { return volumeSlider.value / volumeSlider.maximumValue }
    set { volumeSlider.value = newValue * volumeSlider.maximumValue }
  }

  var pan: AudioUnitParameterValue {
    get { return panKnob.value }
    set { panKnob.value = newValue }
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize { return CGSize(width: 100, height: 400) }

}

final class MasterCell: MixerCell {

  static let Identifier = "MasterCell"
  
  /** refresh */
  func refresh() { volume = AudioManager.mixer.volume; pan = AudioManager.mixer.pan }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { AudioManager.mixer.volume = volume }
  @IBAction func panDidChange() { AudioManager.mixer.pan = pan }

}

class TrackCell: MixerCell, TrackLabelDelegate {

  class var Identifier: String { return "TrackCell" }

  @IBOutlet var soloButton: LabelButton!
  @IBOutlet var muteButton: LabelButton!
  @IBOutlet var volumeLabel: Label!
  @IBOutlet var panLabel: Label!
  @IBOutlet var trackLabel: TrackLabel!
  
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
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volume }

  /** panDidChange */
  @IBAction func panDidChange() { track?.pan = pan }

  weak var track: InstrumentTrack? {
    didSet {
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      trackLabel.text = track?.name ?? ""
    }
  }

  /**
  trackLabelDidChange:

  - parameter trackLabel: TrackLabel
  */
  func trackLabelDidChange(trackLabel: TrackLabel) { track?.label = trackLabel.text }
}

final class AddTrackCell: TrackCell {

  override static var Identifier: String { return "AddTrackCell" }

  @IBOutlet weak var addTrackImageButton: ImageButtonView!

  /** didDraw */
  func generateBackdrop() {

    stackView.hidden = false
    addTrackImageButton.hidden = true

    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

    for view in stackView.subviews {
      view.drawViewHierarchyInRect(view.frame.offsetBy(stackView.frame.origin), afterScreenUpdates: false)
    }
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    let blurredImage = image.applyBlurWithRadius(3, tintColor: UIColor.backgroundColor.colorWithAlpha(0.95), saturationDeltaFactor: 0, maskImage: nil)

    stackView.hidden = true
    addTrackImageButton.hidden = false
    let imageView = UIImageView(image: blurredImage)
    imageView.contentMode = .Center
    backgroundView = imageView

  }
}

