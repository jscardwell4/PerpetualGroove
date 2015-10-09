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

  @IBInspectable var textColor: UIColor = .blackColor() {
    didSet {
      marquee.textColor = textColor
      textField.textColor = textColor
      setNeedsDisplay()
    }
  }
  
  var font: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline) {
    didSet {
      marquee.font = font
      textField.font = font
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

  /** setup */
  private func setup() {
    let id = Identifier(self, "Internal")

    marquee.font = .compressedControlFont
    marquee.textColor = .secondaryColor
    addSubview(marquee)
    constrain([𝗩|marquee|𝗩, 𝗛|marquee|𝗛] --> id)

    textField.font = .compressedControlFont
    textField.textColor = .secondaryColor
    textField.backgroundColor = .clearColor()
    textField.enablesReturnKeyAutomatically = true
    textField.returnKeyType = .Done
    textField.delegate = self
    textField.hidden = true
    addSubview(textField)
    constrain([𝗩|textField|𝗩, 𝗛|textField|𝗛] --> id)

    tapGesture.addTarget(self, action: "handleTap:")
    tapGesture.delaysTouchesBegan = true
    addGestureRecognizer(tapGesture)
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize { return marquee.intrinsicContentSize() }

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