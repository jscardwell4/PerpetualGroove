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

  @IBOutlet weak var volumeSlider: VerticalSlider! {
    didSet {
      guard let volumeSlider = volumeSlider else { return }
      volumeSlider.setThumbImage(UIImage(named: "verticalthumb2"), forState: .Normal, color: Chameleon.kelleyPearlBush)
      volumeSlider.setMinimumTrackImage(UIImage(named: "line6"), forState: .Normal, color: rgb(146, 135, 120))
      volumeSlider.setMaximumTrackImage(UIImage(named: "line6"), forState: .Normal, color: rgb(51, 50, 49))
    }
  }

  var volume: AudioUnitParameterValue {
    get { return volumeSlider.value / volumeSlider.maximumValue }
    set { volumeSlider.value = newValue * volumeSlider.maximumValue }
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize { return CGSize(width: 64, height: 300) }

}

final class MasterCell: MixerCell {

  static let Identifier = "MasterCell"

  /** refresh */
  func refresh() { do { volume = try Mixer.masterVolume() } catch { logError(error) } }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { do { try Mixer.setMasterVolume(volume) } catch { logError(error) } }

}

final class TrackCell: MixerCell, UITextFieldDelegate {

  static let Identifier = "TrackCell"

  @IBOutlet weak var labelTextField: UITextField!

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volumeSlider.value / volumeSlider.maximumValue }

  var track: Track? {
    didSet {
      guard let track = track else { return }
      MSLogDebug("track = \(track)")
      volume = track.volume
      // TODO: Update UI with pan value
      labelTextField.text = track.label
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
