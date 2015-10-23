//
//  UIOffset+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension UIOffset {
  public init?(_ string: String?) { if let s = string { self = UIOffsetFromString(s) } else { return nil } }
}

extension UIOffset: Unpackable2 { public var unpack: (CGFloat, CGFloat) { return (horizontal, vertical) } }

extension UIOffset: CustomStringConvertible {
  public var description: String { return NSStringFromUIOffset(self) }
}

extension UIOffset {
  public static var zeroOffset: UIOffset { return UIOffset(horizontal: 0, vertical: 0) }
}

public func -(lhs: UIOffset, rhs: UIOffset) -> UIOffset {
	return UIOffset(horizontal: lhs.horizontal - rhs.horizontal, vertical: lhs.vertical - rhs.vertical)
}

public func +(lhs: UIOffset, rhs: UIOffset) -> UIOffset {
	return UIOffset(horizontal: lhs.horizontal + rhs.horizontal, vertical: lhs.vertical + rhs.vertical)
}

