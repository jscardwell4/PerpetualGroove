//
//  CATransform3D.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/10/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension CATransform3D {

  public static var identity: CATransform3D { return CATransform3DIdentity }

  public static var perspective: CATransform3D {
    return CATransform3D(
      m11: 1, m12: 0, m13: 0, m14: 0,
      m21: 0, m22: 1, m23: 0, m24: 0,
      m31: 0, m32: 0, m33: 0, m34: CGFloat(-1.0/1000.0),
      m41: 0, m42: 0, m43: 0, m44: 1
    )
  }

  /**
  initWithTx:ty:tz:

  - parameter tx: CGFloat
  - parameter ty: CGFloat
  - parameter tz: CGFloat
  */
  public init(tx: CGFloat, ty: CGFloat, tz: CGFloat) {
    self = CATransform3DMakeTranslation(tx, ty, tz)
  }

  /**
  initWithSx:sy:sz:

  - parameter sx: CGFloat
  - parameter sy: CGFloat
  - parameter sz: CGFloat
  */
  public init(sx: CGFloat, sy: CGFloat, sz: CGFloat) {
    self = CATransform3DMakeScale(sx, sy, sz)
  }

  /**
  initWithAngle:x:y:z:

  - parameter angle: CGFloat
  - parameter x: CGFloat
  - parameter y: CGFloat
  - parameter z: CGFloat
  */
  public init(angle: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat) {
    self = CATransform3DMakeRotation(angle, x, y, z)
  }

  /**
  scale:sy:sz:

  - parameter sx: CGFloat
  - parameter sy: CGFloat
  - parameter sz: CGFloat

  - returns: CATransform3D
  */
  @warn_unused_result(mutable_variant="scaleInPlace")
  public func scale(sx sx: CGFloat, sy: CGFloat, sz: CGFloat) -> CATransform3D {
    return CATransform3DScale(self, sx, sy, sz)
  }

  /**
  scaleInPlace:sy:sz:

  - parameter sx: CGFloat
  - parameter sy: CGFloat
  - parameter sz: CGFloat
  */
  public mutating func scaleInPlace(sx sx: CGFloat, sy: CGFloat, sz: CGFloat) {
    self = scale(sx: sx, sy: sy, sz: sz)
  }

  /**
  translate:ty:tz:

  - parameter tx: CGFloat
  - parameter ty: CGFloat
  - parameter tz: CGFloat

  - returns: CATransform3D
  */
  @warn_unused_result(mutable_variant="translateInPlace")
  public func translate(tx tx: CGFloat, ty: CGFloat, tz: CGFloat) -> CATransform3D {
    return CATransform3DTranslate(self, tx, ty, tz)
  }

  /**
  translateInPlace:ty:tz:

  - parameter tx: CGFloat
  - parameter ty: CGFloat
  - parameter tz: CGFloat
  */
  public mutating func translateInPlace(tx tx: CGFloat, ty: CGFloat, tz: CGFloat) {
    self = translate(tx: tx, ty: ty, tz: tz)
  }

  /**
  rotate:x:y:z:

  - parameter angle: CGFloat
  - parameter x: CGFloat
  - parameter y: CGFloat
  - parameter z: CGFloat

  - returns: CATransform3D
  */
  @warn_unused_result(mutable_variant="rotateInPlace")
  public func rotate(angle angle: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat) -> CATransform3D {
    return CATransform3DRotate(self, angle, x, y, z)
  }

  /**
  rotateInPlace:x:y:z:

  - parameter angle: CGFloat
  - parameter x: CGFloat
  - parameter y: CGFloat
  - parameter z: CGFloat
  */
  public mutating func rotateInPlace(angle angle: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat) {
    self = rotate(angle: angle, x: x, y: y, z: z)
  }


  /**
  invert

  - returns: CATransform3D
  */
  @warn_unused_result(mutable_variant="invertInPlace")
  public func invert() -> CATransform3D { return CATransform3DInvert(self) }

  /** invertInPlace */
  public mutating func invertInPlace() { self = invert() }

  /**
  concat:

  - parameter t: CATransform3D

  - returns: CATransform3D
  */
  @warn_unused_result(mutable_variant="concatInPlace")
  public func concat(t: CATransform3D) -> CATransform3D { return CATransform3DConcat(self, t) }

  /**
  concatInPlace:

  - parameter t: CATransform3D
  */
  public mutating func concatInPlace(t: CATransform3D) { self = concat(t) }

  public var isAffine: Bool { return CATransform3DIsAffine(self) }

  public var affineTransform: CGAffineTransform { return CATransform3DGetAffineTransform(self) }

  public var isIdentity: Bool { return CATransform3DIsIdentity(self) }

  public var rotation: CGFloat {
    get {
      guard m11 == m22 && m12 == -m21 else { return 0 }
      return m12.isSignMinus ? -acos(m11) : acos(m11)
    }
    set {
      let cosine = cos(abs(newValue))
      let sine = sin(abs(newValue))
      m11 = cosine
      m22 = cosine
      m12 = newValue.isSignMinus ? -sine : sine
      m21 = newValue.isSignMinus ? sine : -sine
    }
  }
}

extension CATransform3D: Equatable {}

public func ==(lhs: CATransform3D, rhs: CATransform3D) -> Bool {
  return CATransform3DEqualToTransform(lhs, rhs)
}
