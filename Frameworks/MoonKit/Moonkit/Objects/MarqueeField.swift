//
//  MarqueeField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/20/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class MarqueeField: TintColorControl {

  private let marquee: Marquee
  private let textField: TextField

  public var verticalAlignment: VerticalAlignment = .Center {
    didSet {
      guard verticalAlignment != oldValue else { return }
      marquee.verticalAlignment = verticalAlignment
      setNeedsDisplay()
    }
  }

  @IBInspectable public var verticalAlignmentString: String {
    get { return verticalAlignment.rawValue }
    set { verticalAlignment = VerticalAlignment(rawValue: newValue) ?? .Center }
  }
  
  public static let defaultFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
  public var font: UIFont = MarqueeField.defaultFont {
    didSet {
      guard font != oldValue else { return }
      marquee.font = font
      invalidateIntrinsicContentSize()
      if textField.hidden { setNeedsDisplay() }
    }
  }

  @IBInspectable public var fontName: String = Marquee.defaultFont.fontName {
    didSet { if let font = UIFont(name: fontName, size: font.pointSize) { self.font = font } }
  }

  @IBInspectable public var fontSize: CGFloat = Marquee.defaultFont.pointSize {
    didSet { font = font.fontWithSize(fontSize) }
  }

  @IBOutlet weak var delegate: UITextFieldDelegate?

  @IBInspectable public var editingFontName: String {
    get { return editingFont.fontName }
    set { if let font = UIFont(name: newValue, size: editingFont.pointSize) { self.editingFont = font } }
  }

  @IBInspectable public var editingFontSize: CGFloat {
    get { return editingFont.pointSize }
    set { editingFont = editingFont.fontWithSize(newValue) }
  }

  public var editingFont: UIFont = MarqueeField.defaultFont {
    didSet {
      textField.font = editingFont
      invalidateIntrinsicContentSize()
      if !textField.hidden { setNeedsDisplay() }
    }
  }


  @IBInspectable public var text: String = "" {
    didSet {
      guard text != oldValue else { return }
      marquee.text = text
      textField.text = text
      invalidateIntrinsicContentSize()
      setNeedsDisplay()
    }
  }

  @IBInspectable var textFieldHidden: Bool = true { didSet { textField.hidden = textFieldHidden } }
  @IBInspectable var marqueeHidden: Bool = false { didSet { marquee.hidden = marqueeHidden } }

  /** Overridden to force subviews to display the proper font and text color */
   // override public func layoutSubviews() {
   //  refresh()
   //  super.layoutSubviews()
   // }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    return max(marquee.intrinsicContentSize(), textField.intrinsicContentSize())
  }

  /** refresh */
  public override func refresh() {
    super.refresh()
    let color = tintColor
    marquee.textColor = color
    marquee.font = font
    textField.textColor = color
    textField.font = editingFont
  }

  /** How fast to scroll text in characters per second */
  @IBInspectable public var scrollSpeed: Double {
    get { return marquee.scrollSpeed }
    set { marquee.scrollSpeed = newValue }
  }

  /** Whether the text should scroll when it does not all fit */
  @IBInspectable public var scrollEnabled: Bool {
    get { return marquee.scrollEnabled }
    set { marquee.scrollEnabled = newValue }
  }

  /** prepareForInterfaceBuilder */
  override public func prepareForInterfaceBuilder() {
    marquee.setNeedsDisplay()
    textField.setNeedsDisplay()
  }

  /** setup */
  private func setup() {
    addSubview(marquee)
    addSubview(textField)
    constrain([𝗩|marquee, 𝗩|textField], 𝗛|marquee|𝗛, 𝗛|textField|𝗛)

    let color = tintColor
    marquee.textColor = color
    marquee.font = font
    textField.textColor = color
    textField.font = editingFont
    textField.textAlignment = .Center
    textField.backgroundColor = .clearColor()
    textField.hidden = true
    textField.delegate = self
    textField.addTarget(self, action: "textFieldValueChanged", forControlEvents: .ValueChanged)

    addTarget(self, action: "handleTap", forControlEvents: .TouchUpInside)

  }

  @objc private func textFieldValueChanged() {
    text = textField.text ?? ""
    sendActionsForControlEvents(.ValueChanged)
  }

  /** handleTap */
  @objc private func handleTap() {
    if textField.hidden {
      UIView.transitionFromView(marquee, toView: textField, duration: 0.25, options: [.ShowHideTransitionViews]) {
        [unowned textField] in
        guard $0 else { return }
        textField.becomeFirstResponder()
      }
    }
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) {
    marquee = Marquee(autolayout: true)
    textField = TextField(autolayout: true)
    super.init(frame: frame)
    setup()
  }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeObject(marquee, forKey: "marquee")
    aCoder.encodeObject(textField, forKey: "textField")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    marquee = (aDecoder.decodeObjectForKey("marquee") as? Marquee) ?? Marquee(autolayout: true)
    textField = (aDecoder.decodeObjectForKey("textField") as? TextField) ?? TextField(autolayout: true)
    super.init(coder: aDecoder)
    setup()
  }

}

extension MarqueeField: UITextFieldDelegate {
  /**
  textFieldShouldBeginEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    return delegate?.textFieldShouldBeginEditing?(textField) ?? true
  }

  /**
  textFieldDidBeginEditing:

  - parameter textField: UITextField
  */
  public func textFieldDidBeginEditing(textField: UITextField) {
    delegate?.textFieldDidBeginEditing?(textField)
  }

  /**
  textFieldShouldEndEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  public func textFieldShouldEndEditing(textField: UITextField) -> Bool {
    return delegate?.textFieldShouldEndEditing?(textField) ?? true
  }

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  public func textFieldDidEndEditing(textField: UITextField) {
    UIView.transitionFromView(textField, toView: marquee, duration: 0.25, options: [.ShowHideTransitionViews]) {
      [unowned self, unowned textField] in
      guard $0 else { return }
      self.delegate?.textFieldDidEndEditing?(textField)
    }
  }

  /**
  textField:shouldChangeCharactersInRange:replacementString:

  - parameter textField: UITextField
  - parameter range: NSRange
  - parameter string: String

  - returns: Bool
  */
  public func           textField(textField: UITextField,
    shouldChangeCharactersInRange range: NSRange,
         replacementString string: String) -> Bool
  {
    return delegate?.textField?(textField, shouldChangeCharactersInRange: range, replacementString: string) ?? true
  }

  /**
  textFieldShouldClear:

  - parameter textField: UITextField

  - returns: Bool
  */
  public func textFieldShouldClear(textField: UITextField) -> Bool {
    return delegate?.textFieldShouldClear?(textField) ?? true
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  public func textFieldShouldReturn(textField: UITextField) -> Bool {
    let shouldReturn: Bool
    if let delegateMethod = delegate?.textFieldShouldReturn { shouldReturn = delegateMethod(textField) }
    else { shouldReturn = true }

    if shouldReturn {
      textField.resignFirstResponder()
    }

    return shouldReturn
  }
}