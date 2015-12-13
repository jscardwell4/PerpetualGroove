//
//  CGRect+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension CGRect {

  public var x: CGFloat { return origin.x }
  public var y: CGFloat { return origin.y }

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

  public typealias ResizingAxis = UILayoutConstraintAxis
//  public enum ResizingAxis { case Horizontal, Vertical }
  public enum ResizingAnchor {
    case TopLeft, Top, TopRight, Left, Center, Right, BottomLeft, Bottom, BottomRight
  }

  @warn_unused_result(mutable_variant="applyRatioInPlace")
  public func applyRatio(ratio: Ratio<CGFloat>,
                    axis: ResizingAxis = .Vertical,
                  anchor: ResizingAnchor = .Center) -> CGRect
  {
    var result = self
    result.applyRatioInPlace(ratio, axis: axis, anchor: anchor)
    return result
  }

  public mutating func applyRatioInPlace(ratio: Ratio<CGFloat>,
                                    axis: ResizingAxis = .Vertical,
                                  anchor: ResizingAnchor = .Center)
  {
    let newSize: CGSize
    switch axis {
      case .Horizontal: newSize = CGSize(width: size.width, height: size.height * ratio.value)
      case .Vertical:   newSize = CGSize(width: size.width * ratio.value, height: size.height)
    }

    let newOrigin: CGPoint
    switch anchor {
      case .TopLeft:     newOrigin = CGPoint(x: origin.x, y: origin.y)
      case .Top:         newOrigin = CGPoint(x: midX - half(newSize.width), y: origin.y)
      case .TopRight:    newOrigin = CGPoint(x: maxX - newSize.width, y: origin.y)
      case .Left:        newOrigin = CGPoint(x: origin.x, y: midY - half(newSize.height))
      case .Center:      newOrigin = CGPoint(x: midX - half(newSize.width), y: midY - half(newSize.height))
      case .Right:       newOrigin = CGPoint(x: maxX - newSize.width, y: midY - half(newSize.height))
      case .BottomLeft:  newOrigin = CGPoint(x: origin.x, y: maxY - newSize.height)
      case .Bottom:      newOrigin = CGPoint(x: midX - half(newSize.width), y: maxY - newSize.height)
      case .BottomRight: newOrigin = CGPoint(x: maxX - newSize.width, y: maxY - newSize.height)
    }
    size = newSize
    origin = newOrigin
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

