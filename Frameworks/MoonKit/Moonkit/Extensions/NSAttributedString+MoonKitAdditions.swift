//
//  NSAttributedString+MoonKitAdditions.swift
//  Remote
//
//  Created by Jason Cardwell on 12/11/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

import UIKit

extension NSAttributedString {
  public var font: UIFont? { return attribute(NSFontAttributeName, atIndex: 0, effectiveRange: nil) as? UIFont }

  public var foregroundColor: UIColor? {
    return length > 0 ? attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor : nil
  }

  public var backgroundColor: UIColor? {
    return length > 0 ? attribute(NSBackgroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor : nil
  }

}

extension NSMutableAttributedString {

  public override var font: UIFont? {
    get { return length > 0 ? attribute(NSFontAttributeName, atIndex: 0, effectiveRange: nil) as? UIFont : nil }
    set {
      if length > 0 {
        if newValue != nil { addAttribute(NSFontAttributeName, value: newValue!, range: NSRange(0..<length)) }
        else { removeAttribute(NSFontAttributeName, range: NSRange(0..<length)) }
      }
    }
  }

  /**
  setFont:

  - parameter font: UIFont
  */
  public func setFont(font: UIFont, range: Range<Int>? = nil) {
    if length > 0 { addAttribute(NSFontAttributeName, value: font, range: NSRange(range ?? 0..<length)) }
  }

}

public prefix func ¶(string: String) -> NSAttributedString {
  return NSAttributedString(string: string)
}

public func |(lhs: NSAttributedString, rhs: UIColor) -> NSAttributedString {
  guard lhs.length > 0 else { return lhs }
  var attributes = lhs.attributesAtIndex(0, effectiveRange: nil)
  attributes[NSForegroundColorAttributeName] = rhs
  return NSAttributedString(string: lhs.string, attributes: attributes)
}

public func |(lhs: NSAttributedString, rhs: UIFont) -> NSAttributedString {
  guard lhs.length > 0 else { return lhs }
  var attributes = lhs.attributesAtIndex(0, effectiveRange: nil)
  attributes[NSFontAttributeName] = rhs
  return NSAttributedString(string: lhs.string, attributes: attributes)
}

public func |(lhs: NSAttributedString, rhs: NSParagraphStyle) -> NSAttributedString {
  guard lhs.length > 0 else { return lhs }
  var attributes = lhs.attributesAtIndex(0, effectiveRange: nil)
  attributes[NSParagraphStyleAttributeName] = rhs
  return NSAttributedString(string: lhs.string, attributes: attributes)
}

public func |(lhs: NSAttributedString, rhs: NSShadow) -> NSAttributedString {
  guard lhs.length > 0 else { return lhs }
  var attributes = lhs.attributesAtIndex(0, effectiveRange: nil)
  attributes[NSShadowAttributeName] = rhs
  return NSAttributedString(string: lhs.string, attributes: attributes)
}

public func ¶|(string: String, attributes: [AnyObject]) -> NSAttributedString {
  var dict: [String:AnyObject] = [:]
  for attribute in attributes {
    switch attribute {
      case let font as UIFont: dict[NSFontAttributeName] = font
      case let color as UIColor: dict[NSForegroundColorAttributeName] = color
      case let paragraphStyle as NSParagraphStyle: dict[NSParagraphStyleAttributeName] = paragraphStyle
      case let shadow as NSShadow: dict[NSShadowAttributeName] = shadow
      default: break
    }
  }
  return dict.count > 0 ? NSAttributedString(string: string, attributes: dict) : NSAttributedString(string: string)
}

