//
//  CGRect+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension CGRect {

  // MARK: - Initializers
  /**
  init:

  - parameter string: String?
  */
  public init?(_ string: String?) {
    if let s = string {
        self = CGRectFromString(s)
    } else { return nil }
  }

  /**
  initWithSize:

  - parameter size: CGSize
  */
  public init(size: CGSize) { self = CGRect(origin: .zero, size: size) }

  /**
  initWithSize:center:

  - parameter size: CGSize
  - parameter center: CGPoint
  */
  public init(size: CGSize, center: CGPoint) { self = CGRect(origin: center - size * 0.5, size: size) }

  // MARK: - Centering

  public var centerInscribedSquare: CGRect {
    guard width != height else { return self }
    var result = self
    result.size = CGSize(square: size.minAxisValue)
    result.origin += (size - result.size) * 0.5
    return result
  }

  public var center: CGPoint {
    get { return CGPoint(x: midX, y: midY) }
    set { self = CGRect(size: size, center: newValue) }
  }

  // MARK: - Convenience methods that call to library `offsetBy` and `offsetInPlace` methods


  @warn_unused_result(mutable_variant="offsetInPlace")
  public func offsetBy(offset: UIOffset) -> CGRect { return offsetBy(dx: offset.horizontal, dy: offset.vertical) }

  @warn_unused_result(mutable_variant="offsetInPlace")
  public func offsetBy(point: CGPoint) -> CGRect { return offsetBy(dx: point.x, dy: point.y) }

  public mutating func offsetInPlace(point: CGPoint) { offsetInPlace(dx: point.x, dy: point.y) }
  public mutating func offsetInPlace(off: UIOffset) { offsetInPlace(dx: off.horizontal, dy: off.vertical) }

  public mutating func transformInPlace(transform t: CGAffineTransform) { self = transform(t) }
  public func transform(transform: CGAffineTransform) -> CGRect {
    return CGRectApplyAffineTransform(self, transform)
  }

}

// MARK: - CustomStringConvertible

extension CGRect: CustomStringConvertible {
  public var description: String {
      return NSStringFromCGRect(self)
  }
}

// MARK: - Unpacking

extension CGRect: Unpackable4 {
  public var unpack4: (CGFloat, CGFloat, CGFloat, CGFloat) { return (origin.x, origin.y, size.width, size.height) }
}
extension CGRect: NonHomogeneousUnpackable2 {
  public var unpack2: (CGPoint, CGSize) { return (origin, size) }
}

// MARK: - Set operators

public func ∪(lhs: CGRect, rhs: CGRect) -> CGRect { return lhs.union(rhs) }

public func ∩(lhs: CGRect, rhs: CGRect) -> CGRect { return lhs.intersect(rhs) }

public func ∪=(inout lhs: CGRect, rhs: CGRect) { lhs.unionInPlace(rhs) }

public func ∩=(inout lhs: CGRect, rhs: CGRect) { lhs.intersectInPlace(rhs) }

