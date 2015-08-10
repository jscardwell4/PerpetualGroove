//
//  LabeledCheckbox.swift
//  Remote
//
//  Created by Jason Cardwell on 12/14/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit

public class LabeledCheckbox: Checkbox {

  /** Text displayed beside the checkbox */
  public var title: String  = "" { didSet { invalidateIntrinsicContentSize() } }

  /** The color to use for the displayed text */
  public var titleColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }

  /** Color used for drawing the checkbox */
  public var checkboxColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }

  /** Font to use when drawing the text */
  public var titleFont: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline) {
    didSet { invalidateIntrinsicContentSize() }
  }

  private var titleFontAttributes: [String:AnyObject] {
    return [ NSFontAttributeName: titleFont, NSForegroundColorAttributeName: titleColor ]
  }

  private var titleSize: CGSize {
    return title.boundingRectWithSize(
        CGSize(square: CGFloat.infinity),
        options: .UsesLineFragmentOrigin,
        attributes: titleFontAttributes,
        context: nil
      ).size
  }

  private var iconFont: UIFont { return UIFont(name: "FontAwesome", size: max(titleSize.height, bounds.height) * 0.92)! }

  private var iconFontAttributes: [String:AnyObject] {
    return [ NSFontAttributeName: iconFont, NSForegroundColorAttributeName: checkboxColor ]
  }

  private var checkboxIcon: String { return UIFont.fontAwesomeIconForName(checked ? "check-square-o" : "square-o") }

  private var iconSize: CGSize { return checked ? checkedIconSize : uncheckedIconSize }

  private var iconOffset: CGFloat { return checkedIconSize.width - iconSize.width }

  private var uncheckedIconSize: CGSize {
    return UIFont.fontAwesomeIconForName("square-o").boundingRectWithSize(
      CGSize(square: CGFloat.infinity),
      options: .UsesLineFragmentOrigin,
      attributes: iconFontAttributes,
      context: nil
    ).size
  }

  private var checkedIconSize: CGSize {
    return UIFont.fontAwesomeIconForName("check-square-o").boundingRectWithSize(
      CGSize(square: CGFloat.infinity),
      options: .UsesLineFragmentOrigin,
      attributes: iconFontAttributes,
      context: nil
    ).size
  }

  /**
  initWithTitle:autolayout:

  - parameter title: String
  - parameter autolayout: Bool = false
  */
  public convenience init(title: String, font: UIFont? = nil, autolayout: Bool = false) {
    self.init(autolayout: autolayout)
    if font != nil { titleFont = font! }
    self.title = title
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    let titleSize = self.titleSize
    let iconSize = checkedIconSize
    return CGSize(width: titleSize.width + iconSize.width + 12.0, height: max(titleSize.height, iconSize.height) + 8.0)
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {

    let context = UIGraphicsGetCurrentContext()

    let textInnerShadow = NSShadow(color: UIColor.blackColor().colorWithAlphaComponent(0.6),
                                   offset: CGSizeMake(0.1, -0.1),
                                   blurRadius: 4)
    let textOuterShadow = NSShadow(color: UIColor.whiteColor(),
                                   offset: CGSize(width: 0.1, height: 0.6),
                                   blurRadius: 0)

    UIGraphicsPushContext(context!)
    CGContextSetShadowWithColor(context,
                                textOuterShadow.shadowOffset,
                                textOuterShadow.shadowBlurRadius,
                                (textOuterShadow.shadowColor as! UIColor).CGColor)


    let (w, h) = rect.size.unpack

    let iconSize = self.iconSize
    let offset = checkedIconSize.width - iconSize.width
    let iconRect = CGRect(origin: CGPoint(x: w - iconSize.width - offset, y: (h - iconSize.height) * 0.5),
                          size: iconSize)
    var iconFontAttributes = self.iconFontAttributes
    checkboxIcon.drawWithRect(iconRect, options: .UsesLineFragmentOrigin, attributes: iconFontAttributes, context: nil)

    let titleSize = self.titleSize
    let titleRect = CGRect(origin: CGPoint(x: iconRect.minX - titleSize.width - 4.0, y: (h - titleSize.height) * 0.5),
                           size: titleSize)
    var titleFontAttributes = self.titleFontAttributes
    title.drawWithRect(titleRect, options: .UsesLineFragmentOrigin, attributes: titleFontAttributes, context: nil)

    CGContextSetShadow(context, CGSize.zeroSize, 0)
    CGContextSetAlpha(context, CGColorGetAlpha((textInnerShadow.shadowColor as! UIColor).CGColor))

    CGContextBeginTransparencyLayer(context, nil)

    let textOpaqueTextShadow = (textInnerShadow.shadowColor as! UIColor).colorWithAlphaComponent(1)

    CGContextSetShadowWithColor(context,
                                textInnerShadow.shadowOffset,
                                textInnerShadow.shadowBlurRadius,
                                (textOpaqueTextShadow as UIColor).CGColor)

    CGContextSetBlendMode(context, .SourceOut)

    CGContextBeginTransparencyLayer(context, nil)

    textOpaqueTextShadow.setFill()

    iconFontAttributes[NSForegroundColorAttributeName] = textInnerShadow.shadowColor!
    titleFontAttributes[NSForegroundColorAttributeName] = textInnerShadow.shadowColor!

    checkboxIcon.drawWithRect(iconRect, options: .UsesLineFragmentOrigin, attributes: iconFontAttributes, context: nil)
    title.drawWithRect(titleRect, options: .UsesLineFragmentOrigin, attributes: titleFontAttributes, context: nil)

    CGContextEndTransparencyLayer(context)
    CGContextEndTransparencyLayer(context)

    UIGraphicsPopContext()

  }

}
