//
//  NSParagraphStyle+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/4/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension NSParagraphStyle {

  /**
  Method of convenience for creating a paragraph style with attributes already set.

  - parameter lineSpacing: CGFloat = 0
  - parameter paragraphSpacing: CGFloat = 0
  - parameter alignment: NSTextAlignment = .Natural
  - parameter headIndent: CGFloat = 0
  - parameter tailIndent: CGFloat = 0
  - parameter firstLineHeadIndent: CGFloat = 0
  - parameter minimumLineHeight: CGFloat = 0
  - parameter maximumLineHeight: CGFloat = 0
  - parameter lineBreakMode: NSLineBreakMode = .ByWordWrapping
  - parameter lineHeightMultiple: CGFloat = 0
  - parameter paragraphSpacingBefore: CGFloat = 0
  - parameter hyphenationFactor: Float = 0
  - parameter tabStops: [AnyObject]? = nil
  - parameter defaultTabInterval: CGFloat = 0

  - returns: NSParagraphStyle
  */
  public class func paragraphStyleWithAttributes(
    lineSpacing lineSpacing: CGFloat = 0,
    paragraphSpacing: CGFloat = 0,
    alignment: NSTextAlignment = .Natural,
    headIndent: CGFloat = 0,
    tailIndent: CGFloat = 0,
    firstLineHeadIndent: CGFloat = 0,
    minimumLineHeight: CGFloat = 0,
    maximumLineHeight: CGFloat = 0,
    lineBreakMode: NSLineBreakMode = .ByWordWrapping,
    lineHeightMultiple: CGFloat = 0,
    paragraphSpacingBefore: CGFloat = 0,
    hyphenationFactor: Float = 0,
    tabStops: [NSTextTab]? = nil,
    defaultTabInterval: CGFloat = 0
    ) -> NSParagraphStyle
  {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = lineSpacing
    paragraphStyle.paragraphSpacing = paragraphSpacing
    paragraphStyle.alignment = alignment
    paragraphStyle.headIndent = headIndent
    paragraphStyle.tailIndent = tailIndent
    paragraphStyle.firstLineHeadIndent = firstLineHeadIndent
    paragraphStyle.minimumLineHeight = minimumLineHeight
    paragraphStyle.maximumLineHeight = maximumLineHeight
    paragraphStyle.lineBreakMode = lineBreakMode
    paragraphStyle.lineHeightMultiple = lineHeightMultiple
    paragraphStyle.paragraphSpacingBefore = paragraphSpacingBefore
    paragraphStyle.hyphenationFactor = hyphenationFactor
    paragraphStyle.tabStops = tabStops
    paragraphStyle.defaultTabInterval = defaultTabInterval
    return paragraphStyle
  }


}
