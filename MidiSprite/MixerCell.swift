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

class TrackCell: MixerCell, UITextFieldDelegate {

  class var Identifier: String { return "TrackCell" }

  @IBOutlet var soloButton: LabelButton!
  @IBOutlet var muteButton: LabelButton!
  @IBOutlet var volumeLabel: UILabel!
  @IBOutlet var panLabel: UILabel!
  @IBOutlet var labelTextField: UITextField!


  /** solo */
  @IBAction func solo() {
    logDebug()
  }

  /** mute */
  @IBAction func mute() {
    logDebug()
  }


//  override var selected: Bool {
//    didSet {
//      switch selected {
//      case true:
//        volumeLabel?.textColor = .secondaryColor2
//        panLabel?.textColor = .secondaryColor2
//        labelTextField?.textColor = .secondaryColor2
//        panKnob?.knobColor = .secondaryColor2
//        panKnob?.indicatorColor = .primaryColor2
//        volumeSlider?.trackMinColor = .secondaryColor2
//        volumeSlider?.trackMaxColor = .tertiaryColor2
//        volumeSlider?.thumbColor = .primaryColor2
//        soloButton?.textColor = .tertiaryColor2
//        muteButton?.textColor = .tertiaryColor2
//
//      case false:
//        volumeLabel?.textColor = .secondaryColor
//        panLabel?.textColor = .secondaryColor
//        labelTextField?.textColor = .secondaryColor
//        panKnob?.knobColor = .secondaryColor
//        panKnob?.indicatorColor = .primaryColor
//        volumeSlider?.trackMinColor = .secondaryColor
//        volumeSlider?.trackMaxColor = .tertiaryColor
//        volumeSlider?.thumbColor = .primaryColor
//        soloButton?.textColor = .tertiaryColor
//        muteButton?.textColor = .tertiaryColor
//      }
//    }
//  }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volume }

  /** panDidChange */
  @IBAction func panDidChange() { track?.pan = pan }

  weak var track: InstrumentTrack? {
    didSet {
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      labelTextField.text = track?.name
      tintColor = track?.color.value ?? .blackColor()
    }
  }

  /**
  textFieldShouldEndEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  @objc func textFieldShouldEndEditing(textField: UITextField) -> Bool {
    guard let text = textField.text else { return false }
    return !text.isEmpty
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
    if let label = textField.text { track?.label = label }
    textField.resignFirstResponder()
    return false
  }
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

