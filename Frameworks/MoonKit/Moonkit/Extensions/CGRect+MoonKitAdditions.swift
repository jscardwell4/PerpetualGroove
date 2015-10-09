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
  public init?(_ string: String?) { if let s = string { self = CGRectFromString(s) } else { return nil } }

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

//  public func rectWithOrigin(origin: CGPoint) -> CGRect { return CGRect(origin: origin, size: size) }
//  public func rectWithSize(size: CGSize, anchored: Bool = false) -> CGRect {
//  	var rect =  CGRect(origin: origin, size: size)
//  	if anchored { rect.offsetInPlace(dx: midX - rect.midX, dy: midY - rect.midY) }
//  	return rect
//  }

  // MARK: - Convenience methods that call to library `offsetBy` and `offsetInPlace` methods

  @warn_unused_result(mutable_variant="offsetInPlace")
  public func offsetBy(offset: UIOffset) -> CGRect { return offsetBy(dx: offset.horizontal, dy: offset.vertical) }

  @warn_unused_result(mutable_variant="offsetInPlace")
  public func offsetBy(point: CGPoint) -> CGRect { return offsetBy(dx: point.x, dy: point.y) }

  public mutating func offsetInPlace(point: CGPoint) { offsetInPlace(dx: point.x, dy: point.y) }
  public mutating func offsetInPlace(off: UIOffset) { offsetInPlace(dx: off.horizontal, dy: off.vertical) }

//  public mutating func proportionallyInsetX(dx: CGFloat) {
//    let (w, h) = size.unpack
//    let ww = w - 2 * dx
//    let ratio = ww / w
//    let hh = h * ratio
//    let dy = (h - hh) / 2
//    origin.x += dx
//    origin.y += dy
//    size.width = ww
//    size.height = hh
//  }
//  public func rectByProportionallyInsettingX(dx: CGFloat) -> CGRect {
//    var r = self; r.proportionallyInsetX(dx); return r
//  }
//  public mutating func proportionallyInsetY(dy: CGFloat) {
//    let (w, h) = size.unpack
//    let hh = h - 2 * dy
//    let ratio = hh / h
//    let ww = w * ratio
//    let dx = (w - ww) / 2
//    origin.x += dx
//    origin.y += dy
//    size.width = ww
//    size.height = hh
//  }
//  public func rectByProportionallyInsettingY(dy: CGFloat) -> CGRect {
//    var r = self; r.proportionallyInsetY(dy); return r
//  }
//  public mutating func proportionallyInset(dx dx: CGFloat, dy: CGFloat) {
//    let xRect = rectByProportionallyInsettingX(dx)
//    let yRect = rectByProportionallyInsettingY(dy)
//    // self = xRect.size > yRect.size ? xRect : yRect
//    let w = width > height ? max(xRect.width, yRect.width) : min(xRect.width, yRect.width)
//    let h = height > width ? max(xRect.height, yRect.height) : min(xRect.height, yRect.height)
//    let x = (width - w) * 0.5
//    let y = (height - h) * 0.5
//    self = CGRect(x: x, y: y, width: w, height: h)
//  }
//  public func rectByProportionallyInsetting(dx dx: CGFloat, dy: CGFloat) -> CGRect {
//    var r = self; r.proportionallyInset(dx: dx, dy: dy); return r
//  }


  public mutating func transformInPlace(transform t: CGAffineTransform) { self = transform(t) }
  public func transform(transform: CGAffineTransform) -> CGRect {
    return CGRectApplyAffineTransform(self, transform)
  }
//  public func rectWithHeight(height: CGFloat) -> CGRect {
//  	return CGRect(origin: origin, size: CGSize(width: size.width, height: height))
//  }
//  public func rectWithWidth(width: CGFloat) -> CGRect {
//  	return CGRect(origin: origin, size: CGSize(width: width, height: size.height))
//  }
//  public func rectByBindingToRect(rect: CGRect) -> CGRect {
//  	let slaveMinX = minX
//  	let slaveMaxX = maxX
//  	let slaveMinY = minY
//  	let slaveMaxY = maxY
//
//  	let masterMinX = rect.minX
//  	let masterMaxX = rect.maxX
//  	let masterMinY = rect.minY
//  	let masterMaxY = rect.maxY
//
//  	let pushX = slaveMinX >= masterMinX ? 0.0 : masterMinX - slaveMinX
//  	let pushY = slaveMinY >= masterMinY ? 0.0 : masterMinY - slaveMinY
//  	let pullX = slaveMaxX <= masterMaxX ? 0.0 : slaveMaxX - masterMaxX
//  	let pullY = slaveMaxY <= masterMaxY ? 0.0 : slaveMaxY - masterMaxY
//
//  	return CGRect(x: origin.x + pushX + pullX,
//  		            y: origin.y + pushY + pullY,
//                  width: min(size.width + pushX + pullY, size.width),
//                  height: min(size.height + pushY + pullY, size.height))
//  }
}

// MARK: - CustomStringConvertible

extension CGRect: CustomStringConvertible { public var description: String { return NSStringFromCGRect(self) } }

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

