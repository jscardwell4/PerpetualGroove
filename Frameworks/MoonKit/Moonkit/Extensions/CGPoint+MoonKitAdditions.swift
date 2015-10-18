//
//  CGPoint+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension CGPoint {

  public init?(_ string: String?) {
    if let s = string {
      #if os(OSX)
        self = NSPointFromString(s)
        #else
        self = CGPointFromString(s)
      #endif
    } else { return nil }
  }
  public static var null: CGPoint = CGPoint(x: CGFloat.NaN, y: CGFloat.NaN)
  public var isNull: Bool { return x.isNaN || y.isNaN }
  public func xDelta(point: CGPoint) -> CGFloat { return point.isNull ? x : x - point.x }
  public func yDelta(point: CGPoint) -> CGFloat { return point.isNull ? y : y - point.y }
  public func delta(point: CGPoint) -> CGPoint { return self - point }
  public func absXDelta(point: CGPoint) -> CGFloat { return abs(xDelta(point)) }
  public func absYDelta(point: CGPoint) -> CGFloat { return abs(yDelta(point)) }
  public func absDelta(point: CGPoint) -> CGPoint { return (self - point).absolute }
  public mutating func transform(transform: CGAffineTransform) { self = pointByApplyingTransform(transform) }
  public var absolute: CGPoint { return self.isNull ? self :  CGPoint(x: abs(x), y: abs(y)) }
  public func pointByApplyingTransform(transform: CGAffineTransform) -> CGPoint {
    return CGPointApplyAffineTransform(self, transform)
  }
  public func offsetBy(dx dx: CGFloat, dy: CGFloat) -> CGPoint { return CGPoint(x: x + dx, y: y + dy) }
  public func distanceTo(point: CGPoint) -> CGFloat {
    guard !point.isNull else { return CGFloat.NaN }
    return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
  }

  public func description(precision: Int) -> String {
    return precision >= 0 ? "(\(x.rounded(precision)), \(y.rounded(precision)))" : description
  }

  public var max: CGFloat { return y > x ? y : x }
  public var min: CGFloat { return y < x ? y : x }
  public init(_ vector: CGVector) { x = vector.dx; y = vector.dy }
}

extension CGPoint: NilLiteralConvertible {
  public init(nilLiteral: ()) { self = CGPoint.null }
}

#if os(iOS)
extension UIOffset {
  public static var zeroOffset: UIOffset { return UIOffset(horizontal: 0, vertical: 0) }
}
#endif
extension CGPoint: Unpackable2 {
  public var unpack: (CGFloat, CGFloat) { return (x, y) }
}

extension CGPoint: Packable2 {
  public init(_ elements: (CGFloat, CGFloat)) { self.init(x: elements.0, y: elements.1) }
}
extension CGPoint: CustomStringConvertible {
  public var description: String { return "(\(x), \(y))" }
}
extension CGPoint: CustomDebugStringConvertible {
  public var debugDescription: String {
    #if os(iOS)
      return NSStringFromCGPoint(self)
      #else
      return NSStringFromPoint(self)
    #endif
  }
}

public func +(lhs: CGPoint, rhs: (CGFloat, CGFloat)) -> CGPoint {
  return lhs.isNull ? CGPoint(x: rhs.0, y: rhs.1) : CGPoint(x: lhs.x + rhs.0, y: lhs.y + rhs.1)
}

public func +(lhs: CGPoint, rhs: (CGFloatable, CGFloatable)) -> CGPoint {
  return lhs.isNull
    ? CGPoint(x: rhs.0.CGFloatValue, y: rhs.1.CGFloatValue)
    : CGPoint(x: lhs.x + rhs.0.CGFloatValue, y: lhs.y + rhs.1.CGFloatValue)
}

public func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint { return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs) }
public func /(lhs: CGPoint, rhs: CGFloatable) -> CGPoint {
  return CGPoint(x: lhs.x / rhs.CGFloatValue, y: lhs.y / rhs.CGFloatValue)
}

public func /(lhs: CGFloatable, rhs: CGPoint) -> CGPoint {
  let floatable = lhs.CGFloatValue
  return CGPoint(x: floatable / rhs.x, y: floatable / rhs.y)
}

public func /=(inout lhs: CGPoint, rhs: CGFloat) { lhs = lhs / rhs }
public func /=(inout lhs: CGPoint, rhs: CGFloatable) { lhs = lhs / rhs }

public func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint { return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }
public func *(lhs: CGPoint, rhs: CGFloatable) -> CGPoint {
  return CGPoint(x: lhs.x * rhs.CGFloatValue, y: lhs.y * rhs.CGFloatValue)
}

public func *=(inout lhs: CGPoint, rhs: CGFloat) { lhs = lhs * rhs }
public func *=(inout lhs: CGPoint, rhs: CGFloatable) { lhs = lhs * rhs }


//extension CGPoint: ArithmeticType {}

//public func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
//  return lhs.isNull ? rhs : (rhs.isNull ? lhs : CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y))
//}

//public func -(lhs: CGPoint, rhs: (CGFloat, CGFloat)) -> CGPoint {
//  return lhs.isNull ? CGPoint(x: rhs.0, y: rhs.1) : CGPoint(x: lhs.x - rhs.0, y: lhs.y - rhs.1)
//}

//public func -(lhs: CGPoint, rhs: (CGFloatable, CGFloatable)) -> CGPoint {
//  return lhs.isNull
//           ? CGPoint(x: rhs.0.CGFloatValue, y: rhs.1.CGFloatValue)
//           : CGPoint(x: lhs.x - rhs.0.CGFloatValue, y: lhs.y - rhs.1.CGFloatValue)
//}

//public func -<T:Unpackable2 where T.Element == CGFloat>(lhs: CGPoint, rhs: T) -> CGPoint {
//  return lhs - rhs.unpack
//}

//public func -<T:Unpackable2 where T.Element:CGFloatable>(lhs: CGPoint, rhs: T) -> CGPoint {
//  let floatables = rhs.unpack
//  return lhs - (floatables.0.CGFloatValue, floatables.1.CGFloatValue)
//}

//public func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
//  return lhs.isNull ? rhs : (rhs.isNull ? lhs : CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y))
//}

//public func +<T:Unpackable2 where T.Element:CGFloatable>(lhs: CGPoint, rhs: T) -> CGPoint {
//  let floatables = rhs.unpack
//  return lhs + (floatables.0.CGFloatValue, floatables.1.CGFloatValue)
//}
//public func +=<T:Unpackable2 where T.Element:CGFloatable>(inout lhs: CGPoint, rhs: T) {
//  let floatables = rhs.unpack
//  lhs = lhs + (floatables.0.CGFloatValue, floatables.1.CGFloatValue)
//}

//public func +<T:Unpackable2 where T.Element == CGFloat>(lhs: CGPoint, rhs: T) -> CGPoint {
//  return lhs + rhs.unpack
//}

//public func -=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs - rhs }
//public func +=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs + rhs }

//public func /(lhs: CGPoint, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y) }

//public func /=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs / rhs }

//public func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y) }

//public func *=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs * rhs }
