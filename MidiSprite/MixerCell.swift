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
  func refresh() { do { volume = try Mixer.masterVolume(); pan = try Mixer.masterPan() } catch { logError(error) } }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { do { try Mixer.setMasterVolume(volume) } catch { logError(error) } }
  @IBAction func panDidChange() { do { try Mixer.setMasterPan(pan) } catch { logError(error) } }

}

final class TrackCell: MixerCell, UITextFieldDelegate {

  static let Identifier = "TrackCell"

  @IBOutlet weak var labelTextField: UITextField!

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volume }

  /** panDidChange */
  @IBAction func panDidChange() { track?.pan = pan }

  var track: Track? {
    didSet {
      guard let track = track else { return }
      volume = track.volume
      pan = track.pan
      labelTextField.text = track.label ?? "BUS \(track.bus.element)"
      tintColor = track.color.value
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
    if let track = track, label = textField.text { track.label = label }
    textField.resignFirstResponder()
    return false
  }
}
