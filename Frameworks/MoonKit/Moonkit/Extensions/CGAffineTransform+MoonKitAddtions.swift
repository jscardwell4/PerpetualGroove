//
//  CGAffineTransform+MoonKitAddtions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension CGAffineTransform: CustomStringConvertible {
  public var description: String {
    let prefixes = ["┌─", "│ ", "│ ", "│ ", "└─"]
    let suffixes = ["─┐", " │", " │", " │", "─┘"]
    var col1 = ["", "\(a)", "\(c)", "\(tx)", ""]
    var col2 = ["", "\(b)", "\(d)", "\(ty)", ""]
    let col3 = [" ", "0", "0", "1", " "]
    let col1MaxCount = col1.map({$0.utf8.count}).maxElement()!

    for row in 0 ... 4 {
      let delta = col1MaxCount - col1[row].utf8.count
      if delta > 0 {
        let leftPadCount = delta / 2 //(col1[row].hasPrefix("-") ? delta / 2 - 1 : delta / 2)
        let leftPad = " " * leftPadCount
        let rightPad = " " * (delta - leftPadCount)
        col1[row] = leftPad + col1[row] + rightPad
      }
    }

    let col2MaxCount = col2.map({$0.utf8.count}).maxElement()!

    for row in 0 ... 4 {
      let delta = col2MaxCount - col2[row].utf8.count
      if delta > 0 {
        let leftPadCount = delta / 2 //(col2[row].hasPrefix("-") ? delta / 2 - 1 : delta / 2)
        let leftPad = " " * leftPadCount
        let rightPad = " " * (delta - leftPadCount)
        col2[row] = leftPad + col2[row] + rightPad
      }
    }

    var result = ""
    for i in 0 ... 4 {
      result += prefixes[i] + " " + col1[i] + " " + col2[i] + " " + col3[i] + " " + suffixes[i] + "\n"
    }
    return result//NSStringFromCGAffineTransform(self)
  }

  public var rotation: CGFloat {
    get {
      guard a == d && b == -c else { return 0 }
      return b.isSignMinus ? -acos(a) : acos(a)
    }
    set {
      let cosine = cos(abs(newValue))
      let sine = sin(abs(newValue))
      a = cosine
      d = cosine
      b = newValue.isSignMinus ? -sine : sine
      c = newValue.isSignMinus ? sine : -sine
    }
  }
    
}

public func +(lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
  return CGAffineTransformConcat(lhs, rhs)
}
public func +=(inout lhs: CGAffineTransform, rhs: CGAffineTransform) { lhs = lhs + rhs }
public func ==(lhs: CGAffineTransform, rhs: CGAffineTransform) -> Bool {
  return CGAffineTransformEqualToTransform(lhs, rhs)
}

extension CGAffineTransform {
  public init(tx: CGFloat, ty: CGFloat) { self = CGAffineTransformMakeTranslation(tx, ty) }
  public init(translation: CGPoint) { self = CGAffineTransform(tx: translation.x, ty: translation.y) }
  public init(sx: CGFloat, sy: CGFloat) { self = CGAffineTransformMakeScale(sx, sy) }
  public init(angle: CGFloat) { self = CGAffineTransformMakeRotation(angle) }
  public var isIdentity: Bool { return CGAffineTransformIsIdentity(self) }
  public mutating func translate(tx: CGFloat, _ ty: CGFloat) { self = translated(tx, ty) }
  public func translated(tx: CGFloat, _ ty: CGFloat) -> CGAffineTransform { return CGAffineTransformTranslate(self, tx, ty) }
  public mutating func scale(sx: CGFloat, sy: CGFloat) { self = scaled(sx, sy) }
  public func scaled(sx: CGFloat, _ sy: CGFloat) -> CGAffineTransform { return CGAffineTransformScale(self, sx, sy) }
  public mutating func rotate(angle: CGFloat) { self = rotated(angle) }
  public func rotated(angle: CGFloat) -> CGAffineTransform { return CGAffineTransformRotate(self, angle) }
  public mutating func invert() { self = inverted }
  public var inverted: CGAffineTransform { return CGAffineTransformInvert(self) }
  public static var identityTransform: CGAffineTransform { return CGAffineTransformIdentity }
  public init?(_ string: String?) {
    if let s = string {
        self = CGAffineTransformFromString(s)
    } else { return nil }
  }
}
