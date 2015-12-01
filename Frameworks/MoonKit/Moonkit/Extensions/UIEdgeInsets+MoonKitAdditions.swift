//
//  UIEdgeInsets+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension UIEdgeInsets {
  public func insetRect(rect: CGRect) -> CGRect { return UIEdgeInsetsInsetRect(rect, self) }
  public func outsetRect(rect: CGRect) -> CGRect { return inverted.insetRect(rect) }
  public var inverted: UIEdgeInsets { return UIEdgeInsets(top: -top , left: -left , bottom: -bottom , right: -right) }
  public init?(_ string: String?) { if let s = string { self = UIEdgeInsetsFromString(s) } else { return nil } }
  public static var zeroInsets: UIEdgeInsets { return UIEdgeInsets(inset: 0) }
  public init(horizontal: CGFloat, vertical: CGFloat) {
    self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
  }
  public init(inset: CGFloat) { self = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset) }
  public var displacement: UIOffset { return UIOffset(horizontal: left + right, vertical: top + bottom) }
  public var stringValue: String { return NSStringFromUIEdgeInsets(self) }
}

extension UIEdgeInsets: CustomStringConvertible {
  public var description: String { return NSStringFromUIEdgeInsets(self) }
}

extension UIEdgeInsets: Unpackable4 {
  public var unpack4: (CGFloat, CGFloat, CGFloat, CGFloat) { return (top, left, bottom, right) }
}

public func +(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
  return UIEdgeInsets(
    top: lhs.top + rhs.top,
    left: lhs.left + rhs.left,
    bottom: lhs.bottom + rhs.bottom,
    right: lhs.right + rhs.right
  )
}

public func -(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
  return UIEdgeInsets(
    top: lhs.top - rhs.top,
    left: lhs.left - rhs.left,
    bottom: lhs.bottom - rhs.bottom,
    right: lhs.right - rhs.right
  )
}

