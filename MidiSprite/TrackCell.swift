//
//  TrackCell.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

class TrackCell: UICollectionViewCell, UITextFieldDelegate {

  static let Identifier = "TrackCell"

  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var volumeSlider: VerticalSlider!
  @IBOutlet weak var panLabel: UILabel!
  @IBOutlet weak var labelTextField: UITextField!

  var track: TrackType? {
    didSet {
      guard let track = track else { return }
      MSLogDebug("track = \(track)")
      volumeSlider.value = track.volume * volumeSlider.maximumValue
      // TODO: Update UI with pan value
      labelTextField.text = track.label
      labelTextField.enabled = track is InstrumentTrackType
      tintColor = track.color.value
    }
  }

  /** volumeDidChange */
  @IBAction func volumeDidChange() { track?.volume = volumeSlider.value / volumeSlider.maximumValue }


  /**
  textFieldShouldEndEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  @objc func textFieldShouldEndEditing(textField: UITextField) -> Bool {
    return textField.text != nil && !textField.text!.isEmpty
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
    if let instrumentTrack = track as? InstrumentTrackType, label = textField.text { instrumentTrack.label = label }
    textField.resignFirstResponder()
    return false
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize {
    return CGSize(width: 64, height: 300)
  }

  /** setup */
//  private func setup() {
//    labelTextField.delegate = self
//  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
//  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
//  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }
}
