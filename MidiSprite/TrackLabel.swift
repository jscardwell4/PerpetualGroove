//
//  TrackLabel.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/9/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

@objc protocol TrackLabelDelegate: NSObjectProtocol {
  func trackLabelDidChange(trackLabel: TrackLabel)
}

@IBDesignable final class TrackLabel: UIView {

  private let marquee = Marquee(autolayout: true)
  private let textField = UITextField(autolayout: true)
  private let tapGesture = UITapGestureRecognizer()

  @IBOutlet var delegate: TrackLabelDelegate?

  @IBInspectable var text: String = "" {
    didSet {
      guard text != oldValue else { return }
      marquee.text = text
      textField.text = text
      setNeedsDisplay()
      invalidateIntrinsicContentSize()
    }
  }

  @IBInspectable var textColor: UIColor = .primaryColor {
    didSet {
      marquee.textColor = textColor
      textField.textColor = textColor
      setNeedsDisplay()
    }
  }
  
  var font: UIFont = .compressedControlFont {
    didSet {
      marquee.font = font
      setNeedsDisplay()
      invalidateIntrinsicContentSize()
    }
  }

  @IBInspectable var fontName: String {
    get { return font.fontName }
    set { if let font = UIFont(name: newValue, size: font.pointSize) { self.font = font } }
  }

  @IBInspectable var fontSize: CGFloat {
    get { return font.pointSize }
    set { font = font.fontWithSize(newValue) }
  }

  @IBInspectable var editingFontName: String {
    get { return editingFont.fontName }
    set { if let font = UIFont(name: newValue, size: editingFont.pointSize) { self.editingFont = font } }
  }

  @IBInspectable var editingFontSize: CGFloat {
    get { return editingFont.pointSize }
    set { editingFont = editingFont.fontWithSize(newValue) }
  }

  var editingFont: UIFont = .compressedControlFontEditing {
    didSet {
      textField.font = editingFont
      setNeedsDisplay()
      invalidateIntrinsicContentSize()
    }
  }

  @IBInspectable var textFieldHidden: Bool = true { didSet { textField.hidden = textFieldHidden } }
  @IBInspectable var marqueeHidden: Bool = false { didSet { marquee.hidden = marqueeHidden } }


  /** Overridden to force subviews to display the proper font and text color */
  override func layoutSubviews() {
    marquee.font = font
    textField.font = editingFont
    marquee.textColor = textColor
    textField.textColor = textColor
    super.layoutSubviews()
  }

  /** setup */
  private func setup() {
    let id = Identifier(self, "Internal")

    marquee.font = font
    marquee.textColor = textColor
    marquee.verticalAlignment = .Top
    addSubview(marquee)
    constrain([[𝗩|marquee], 𝗛|marquee|𝗛] --> id)

    textField.font = editingFont
    textField.textColor = textColor
    textField.textAlignment = .Center
    textField.backgroundColor = .clearColor()
    textField.enablesReturnKeyAutomatically = true
    textField.returnKeyType = .Done
    textField.delegate = self
    textField.hidden = true
    addSubview(textField)
    constrain([[𝗩|textField], 𝗛|textField|𝗛] --> id)

    tapGesture.addTarget(self, action: "handleTap:")
    tapGesture.delaysTouchesBegan = true
    addGestureRecognizer(tapGesture)
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize { return max(marquee.intrinsicContentSize(), textField.intrinsicContentSize()) }

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

  /**
  handleTap:

  - parameter gesture: UITapGestureRecognizer
  */
  @objc private func handleTap(gesture: UITapGestureRecognizer) {
    guard gesture == tapGesture && gesture.state == .Recognized else { return }
    UIView.transitionFromView(marquee, toView: textField, duration: 0.25, options: [.ShowHideTransitionViews]) {
      [unowned self] in
      guard $0 else { return }
      self.tapGesture.enabled = false
      self.textField.becomeFirstResponder()
    }
  }

}

extension TrackLabel: UITextFieldDelegate {

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(textField: UITextField) {
    UIView.transitionFromView(textField, toView: marquee, duration: 0.25, options: [.ShowHideTransitionViews]) {
      [unowned self] in
      guard $0 else { return }
      self.tapGesture.enabled = true
    }
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if let label = textField.text {
      text = label
      delegate?.trackLabelDidChange(self)
    }
    textField.resignFirstResponder()
    return false
  }

}