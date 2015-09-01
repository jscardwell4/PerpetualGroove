//
//  Geometry.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/26/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
  public init(_ values: (CGFloat, CGFloat)) { self.init(x: values.0, y: values.1) }
  public init?(_ string: String?) { if let s = string { self = CGPointFromString(s) } else { return nil } }
  public static var nullPoint: CGPoint = CGPoint(x: CGFloat.NaN, y: CGFloat.NaN)
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
  public func distanceTo(point: CGPoint) -> CGFloat {
    guard !point.isNull else { return CGFloat.NaN }
    return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
  }

  public var max: CGFloat { return y > x ? y : x }
  public var min: CGFloat { return y < x ? y : x }
  public init(_ vector: CGVector) { x = vector.dx; y = vector.dy }
}

extension CGPoint: NilLiteralConvertible {
  public init(nilLiteral: ()) { self = CGPoint.nullPoint }
}

extension UIOffset {
  public static var zeroOffset: UIOffset { return UIOffset(horizontal: 0, vertical: 0) }
}

extension CGPoint: Unpackable2 {
  public var unpack: (CGFloat, CGFloat) { return (x, y) }
}

extension CGPoint: CustomStringConvertible { public var description: String { return NSStringFromCGPoint(self) } }

//extension CGPoint: ArithmeticType {}

public func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return lhs.isNull ? rhs : (rhs.isNull ? lhs : CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y))
}

public func -(lhs: CGPoint, rhs: (CGFloat, CGFloat)) -> CGPoint {
  return lhs.isNull ? CGPoint(x: rhs.0, y: rhs.1) : CGPoint(x: lhs.x - rhs.0, y: lhs.y - rhs.1)
}

public func -(lhs: CGPoint, rhs: (CGFloatable, CGFloatable)) -> CGPoint {
  return lhs.isNull
           ? CGPoint(x: rhs.0.CGFloatValue, y: rhs.1.CGFloatValue)
           : CGPoint(x: lhs.x - rhs.0.CGFloatValue, y: lhs.y - rhs.1.CGFloatValue)
}

public func -<T:Unpackable2 where T.Element == CGFloat>(lhs: CGPoint, rhs: T) -> CGPoint {
  return lhs - rhs.unpack
}

public func -<T:Unpackable2 where T.Element:CGFloatable>(lhs: CGPoint, rhs: T) -> CGPoint {
  let floatables = rhs.unpack
  return lhs - (floatables.0.CGFloatValue, floatables.1.CGFloatValue)
}

public func +(lhs: CGPoint, rhs: (CGFloat, CGFloat)) -> CGPoint {
  return lhs.isNull ? CGPoint(x: rhs.0, y: rhs.1) : CGPoint(x: lhs.x + rhs.0, y: lhs.y + rhs.1)
}

public func +(lhs: CGPoint, rhs: (CGFloatable, CGFloatable)) -> CGPoint {
  return lhs.isNull
    ? CGPoint(x: rhs.0.CGFloatValue, y: rhs.1.CGFloatValue)
    : CGPoint(x: lhs.x + rhs.0.CGFloatValue, y: lhs.y + rhs.1.CGFloatValue)
}

public func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return lhs.isNull ? rhs : (rhs.isNull ? lhs : CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y))
}

public func +<T:Unpackable2 where T.Element:CGFloatable>(lhs: CGPoint, rhs: T) -> CGPoint {
  let floatables = rhs.unpack
  return lhs + (floatables.0.CGFloatValue, floatables.1.CGFloatValue)
}
public func +=<T:Unpackable2 where T.Element:CGFloatable>(inout lhs: CGPoint, rhs: T) {
  let floatables = rhs.unpack
  lhs = lhs + (floatables.0.CGFloatValue, floatables.1.CGFloatValue)
}

public func +<T:Unpackable2 where T.Element == CGFloat>(lhs: CGPoint, rhs: T) -> CGPoint {
  return lhs + rhs.unpack
}

public func -=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs - rhs }
public func +=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs + rhs }

public func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint { return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs) }
public func /(lhs: CGPoint, rhs: CGFloatable) -> CGPoint {
  return CGPoint(x: lhs.x / rhs.CGFloatValue, y: lhs.y / rhs.CGFloatValue)
}
public func /(lhs: CGPoint, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y) }

public func /(lhs: CGFloatable, rhs: CGPoint) -> CGPoint {
  let floatable = lhs.CGFloatValue
  return CGPoint(x: floatable / rhs.x, y: floatable / rhs.y)
}

public func /=(inout lhs: CGPoint, rhs: CGFloat) { lhs = lhs / rhs }
public func /=(inout lhs: CGPoint, rhs: CGFloatable) { lhs = lhs / rhs }
public func /=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs / rhs }

public func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint { return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }
public func *(lhs: CGPoint, rhs: CGFloatable) -> CGPoint {
  return CGPoint(x: lhs.x * rhs.CGFloatValue, y: lhs.y * rhs.CGFloatValue)
}
public func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint { return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y) }

public func *=(inout lhs: CGPoint, rhs: CGFloat) { lhs = lhs * rhs }
public func *=(inout lhs: CGPoint, rhs: CGFloatable) { lhs = lhs * rhs }
public func *=(inout lhs: CGPoint, rhs: CGPoint) { lhs = lhs * rhs }

extension CGVector {
  public init?(_ string: String?) { if let s = string { self = CGVectorFromString(s) } else { return nil } }
  public static var nullVector: CGVector = CGVector(dx: CGFloat.NaN, dy: CGFloat.NaN)
  public var isNull: Bool { return dx.isNaN || dy.isNaN }
  public func dxDelta(vector: CGVector) -> CGFloat { return vector.isNull ? dx : dx - vector.dx }
  public func dyDelta(vector: CGVector) -> CGFloat { return vector.isNull ? dy : dy - vector.dy }
  public func delta(vector: CGVector) -> CGVector { return self - vector }
  public func absDXDelta(vector: CGVector) -> CGFloat { return abs(dxDelta(vector)) }
  public func absDYDelta(vector: CGVector) -> CGFloat { return abs(dyDelta(vector)) }
  public func absDelta(vector: CGVector) -> CGVector { return (self - vector).absolute }
  public var absolute: CGVector { return isNull ? self : CGVector(dx: abs(dx), dy: abs(dy)) }
  public init(_ point: CGPoint) { dx = point.x; dy = point.y }
  public var max: CGFloat { return dy > dx ? dy : dx }
  public var min: CGFloat { return dy < dx ? dy : dx }
}
extension CGVector: NilLiteralConvertible {
  public init(nilLiteral: ()) { self = CGVector.nullVector }
}

extension CGVector: CustomStringConvertible {
  public var description: String { return NSStringFromCGVector(self) }
}

extension CGVector: Unpackable2 {
  public var unpack: (CGFloat, CGFloat) { return (dx, dy) }
}

public func -(lhs: CGVector, rhs: CGVector) -> CGVector {
  return lhs.isNull ? rhs : (rhs.isNull ? lhs : CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy))
}
public func +(lhs: CGVector, rhs: CGVector) -> CGVector {
  return lhs.isNull ? rhs : (rhs.isNull ? lhs : CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy))
}
public func -=(inout lhs: CGVector, rhs: CGVector) { lhs = lhs - rhs }
public func +=(inout lhs: CGVector, rhs: CGVector) { lhs = lhs + rhs }
public func /(lhs: CGVector, rhs: CGVector) -> CGVector { return CGVector(dx: lhs.dx / rhs.dx, dy: lhs.dy / rhs.dy) }
public func /(lhs: CGVector, rhs: CGFloat) -> CGVector { return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs) }
public func /=(inout lhs: CGVector, rhs: CGFloat) { lhs = lhs / rhs }
public func *(lhs: CGVector, rhs: CGFloat) -> CGVector { return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs) }
public func *(lhs: CGVector, rhs: CGVector) -> CGVector { return CGVector(dx: lhs.dx * rhs.dx, dy: lhs.dy * rhs.dy) }
public func *=(inout lhs: CGVector, rhs: CGFloat) { lhs = lhs * rhs }

public func sum<S:SequenceType where S.Generator.Element == CGVector>(s: S) -> CGVector {
  return s.reduce(CGVector(), combine: +)
}

extension CGSize {
  public init(_ values: (CGFloat, CGFloat)) { self.init(width: values.0, height: values.1) }
  public init?(_ string: String?) { if let s = string { self = CGSizeFromString(s) } else { return nil } }
  public init(square: CGFloat) { self = CGSize(width: square, height: square) }
  public func contains(size: CGSize) -> Bool { return width >= size.width && height >= size.height }
  public var minAxis: CGFloat { return min(width, height) }
  public var maxAxis: CGFloat { return max(width, height) }
  public var area: CGFloat { return width * height }
  public var integralSize: CGSize { return CGSize(width: round(width), height: round(height)) }
  public var integralSizeRoundingUp: CGSize {
  	var size = CGSize(width: round(width), height: round(height))
  	if size.width < width { size.width += CGFloat(1) }
  	if size.height < height { size.height += CGFloat(1) }
  	return size
  }
  public var integralSizeRoundingDown: CGSize {
  	var size = CGSize(width: round(width), height: round(height))
  	if size.width > width { size.width -= CGFloat(1) }
  	if size.height > height { size.height -= CGFloat(1) }
  	return size
  }

  public mutating func scaleBy<T>(ratio: Ratio<T>) {
    width = width * CGFloat(ratio.numerator)
    height = height * CGFloat(ratio.denominator)
  }

  public func ratioForFittingSize(size: CGSize) -> Ratio<CGFloat> {
    let (w, h) = min(aspectMappedToWidth(size.width), s2: aspectMappedToHeight(size.height)).unpack
    return Ratio((width/w) / (height/h))
  }

  public func scaledBy<T>(ratio: Ratio<T>) -> CGSize { var s = self; s.scaleBy(ratio); return s }

  public func aspectMappedToWidth(w: CGFloat) -> CGSize { return CGSize(width: w, height: (w * height) / width) }
  public func aspectMappedToHeight(h: CGFloat) -> CGSize { return CGSize(width: (h * width) / height, height: h) }
  public func aspectMappedToSize(size: CGSize, binding: Bool = false) -> CGSize {
  	let widthMapped = aspectMappedToWidth(size.width)
  	let heightMapped = aspectMappedToHeight(size.height)
  	return binding ? min(widthMapped, s2: heightMapped) : max(widthMapped, s2: heightMapped)
  }
  public mutating func transform(transform: CGAffineTransform) {
    self = sizeByApplyingTransform(transform)
  }
  public func sizeByApplyingTransform(transform: CGAffineTransform) -> CGSize {
    return CGSizeApplyAffineTransform(self, transform)
  }
}
extension CGSize: CustomStringConvertible { public var description: String { return NSStringFromCGSize(self) } }
extension CGSize: Unpackable2 {
  public var unpack: (CGFloat, CGFloat) { return (width, height) }
}

public func max(s1: CGSize, s2: CGSize) -> CGSize { return s1 > s2 ? s1 : s2 }
public func min(s1: CGSize, s2: CGSize) -> CGSize { return s1 < s2 ? s1 : s2 }

public func +(lhs: CGSize, rhs: CGSize) -> CGSize {
	return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}
public func +<U:Unpackable2 where U.Element == CGFloat>(lhs: CGSize, rhs: U) -> CGSize {
  let (w, h) = rhs.unpack
  return CGSize(width: lhs.width + w, height: lhs.height + h)
}

public func +(lhs: CGSize, rhs: CGFloat) -> CGSize { return CGSize(width: lhs.width + rhs, height: lhs.height + rhs) }

public func -(lhs: CGSize, rhs: CGSize) -> CGSize {
	return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}
public func -(lhs: CGSize, rhs: CGFloat) -> CGSize { return CGSize(width: lhs.width - rhs, height: lhs.height - rhs) }

public func >(lhs: CGSize, rhs: CGSize) -> Bool { return lhs.area > rhs.area }
public func <(lhs: CGSize, rhs: CGSize) -> Bool { return lhs.area < rhs.area }
public func >=(lhs: CGSize, rhs: CGSize) -> Bool { return lhs.area >= rhs.area }
public func <=(lhs: CGSize, rhs: CGSize) -> Bool { return lhs.area <= rhs.area }

public func *(lhs: CGSize, rhs: CGFloat) -> CGSize { return CGSize(width: lhs.width * rhs, height: lhs.height * rhs) }
public func *(lhs: CGFloat, rhs: CGSize) -> CGSize { return rhs * lhs }
public func ∪(lhs: CGSize, rhs: CGSize) -> CGSize {
  return CGSize(width: max(lhs.width, rhs.width), height: max(lhs.height, rhs.height))
}

extension UIEdgeInsets {
  public func insetRect(rect: CGRect) -> CGRect {
    return UIEdgeInsetsInsetRect(rect, self)
  }
  public init?(_ string: String?) { if let s = string { self = UIEdgeInsetsFromString(s) } else { return nil } }
  public static var zeroInsets: UIEdgeInsets { return UIEdgeInsets(inset: 0) }
  public init(inset: CGFloat) { self = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset) }
  public var displacement: UIOffset { return UIOffset(horizontal: left + right, vertical: top + bottom) }
}

extension UIEdgeInsets: CustomStringConvertible {
  public var description: String { return NSStringFromUIEdgeInsets(self) }
}

extension UIEdgeInsets: Unpackable4 {
  public var unpack: (CGFloat, CGFloat, CGFloat, CGFloat) { return (top, left, bottom, right) }
}

extension UIOffset {
  public init?(_ string: String?) { if let s = string { self = UIOffsetFromString(s) } else { return nil } }
}

extension UIOffset: Unpackable2 { public var unpack: (CGFloat, CGFloat) { return (horizontal, vertical) } }

extension UIOffset: CustomStringConvertible { public var description: String { return NSStringFromUIOffset(self) } }

extension CGAffineTransform {
  public init(tx: CGFloat, ty: CGFloat) { self = CGAffineTransformMakeTranslation(tx, ty) }
  public init(translation: CGPoint) { self = CGAffineTransform(tx: translation.x, ty: translation.y) }
  public init(sx: CGFloat, sy: CGFloat) { self = CGAffineTransformMakeScale(sx, sy) }
  public init(angle: CGFloat) { self = CGAffineTransformMakeRotation(angle) }
  public var isIdentity: Bool { return CGAffineTransformIsIdentity(self) }
  public mutating func translate(tx: CGFloat, ty: CGFloat) { self = translated(tx, ty) }
  public func translated(tx: CGFloat, _ ty: CGFloat) -> CGAffineTransform { return CGAffineTransformTranslate(self, tx, ty) }
  public mutating func scale(sx: CGFloat, sy: CGFloat) { self = scaled(sx, sy) }
  public func scaled(sx: CGFloat, _ sy: CGFloat) -> CGAffineTransform { return CGAffineTransformScale(self, sx, sy) }
  public mutating func rotate(angle: CGFloat) { self = rotated(angle) }
  public func rotated(angle: CGFloat) -> CGAffineTransform { return CGAffineTransformRotate(self, angle) }
  public mutating func invert() { self = inverted }
  public var inverted: CGAffineTransform { return CGAffineTransformInvert(self) }
  public static var identityTransform: CGAffineTransform { return CGAffineTransformIdentity }
  public init?(_ string: String?) { if let s = string { self = CGAffineTransformFromString(s) } else { return nil } }
}

extension CGAffineTransform: CustomStringConvertible { public var description: String { return NSStringFromCGAffineTransform(self) } }

public func +(lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform { return CGAffineTransformConcat(lhs, rhs) }
public func +=(inout lhs: CGAffineTransform, rhs: CGAffineTransform) { lhs = lhs + rhs }
public func ==(lhs: CGAffineTransform, rhs: CGAffineTransform) -> Bool { return CGAffineTransformEqualToTransform(lhs, rhs) }

extension CGRect {
  public init?(_ string: String?) { if let s = string { self = CGRectFromString(s) } else { return nil } }
  public init(size: CGSize) { self = CGRect(x: 0, y: 0, width: size.width, height: size.height) }
  public init(size: CGSize, center: CGPoint) {
  	self = CGRect(x: center.x - size.width / CGFloat(2.0),
						  	  y: center.y - size.height / CGFloat(2.0),
						  	  width: size.width,
						  	  height: size.height)
  }
  public var center: CGPoint { return CGPoint(x: midX, y: midY) }
  public func rectWithOrigin(origin: CGPoint) -> CGRect { return CGRect(origin: origin, size: size) }
  public func rectWithSize(size: CGSize, anchored: Bool = false) -> CGRect {
  	var rect =  CGRect(origin: origin, size: size)
  	if anchored { rect.offsetInPlace(dx: midX - rect.midX, dy: midY - rect.midY) }
  	return rect
  }
  public func rectByOffsetting(offset: UIOffset) -> CGRect {
    return offsetBy(dx: offset.horizontal, dy: offset.vertical)
  }
  public mutating func offset(off: UIOffset) { offsetInPlace(dx: off.horizontal, dy: off.vertical) }

  public mutating func proportionallyInsetX(dx: CGFloat) {
    let (w, h) = size.unpack
    let ww = w - 2 * dx
    let ratio = ww / w
    let hh = h * ratio
    let dy = (h - hh) / 2
    origin.x += dx
    origin.y += dy
    size.width = ww
    size.height = hh
  }
  public func rectByProportionallyInsettingX(dx: CGFloat) -> CGRect {
    var r = self; r.proportionallyInsetX(dx); return r
  }
  public mutating func proportionallyInsetY(dy: CGFloat) {
    let (w, h) = size.unpack
    let hh = h - 2 * dy
    let ratio = hh / h
    let ww = w * ratio
    let dx = (w - ww) / 2
    origin.x += dx
    origin.y += dy
    size.width = ww
    size.height = hh
  }
  public func rectByProportionallyInsettingY(dy: CGFloat) -> CGRect {
    var r = self; r.proportionallyInsetY(dy); return r
  }
  public mutating func proportionallyInset(dx dx: CGFloat, dy: CGFloat) {
    let xRect = rectByProportionallyInsettingX(dx)
    let yRect = rectByProportionallyInsettingY(dy)
    // self = xRect.size > yRect.size ? xRect : yRect
    let w = width > height ? max(xRect.width, yRect.width) : min(xRect.width, yRect.width)
    let h = height > width ? max(xRect.height, yRect.height) : min(xRect.height, yRect.height)
    let x = (width - w) * 0.5
    let y = (height - h) * 0.5
    self = CGRect(x: x, y: y, width: w, height: h)
  }
  public func rectByProportionallyInsetting(dx dx: CGFloat, dy: CGFloat) -> CGRect {
    var r = self; r.proportionallyInset(dx: dx, dy: dy); return r
  }
  public mutating func transform(transform: CGAffineTransform) {
    self = rectByApplyingTransform(transform)
  }
  public func rectByApplyingTransform(transform: CGAffineTransform) -> CGRect {
    return CGRectApplyAffineTransform(self, transform)
  }
  public func rectWithHeight(height: CGFloat) -> CGRect {
  	return CGRect(origin: origin, size: CGSize(width: size.width, height: height))
  }
  public func rectWithWidth(width: CGFloat) -> CGRect {
  	return CGRect(origin: origin, size: CGSize(width: width, height: size.height))
  }
  public func rectWithCenter(center: CGPoint) -> CGRect { return CGRect(size: size, center: center) }
  public func rectByBindingToRect(rect: CGRect) -> CGRect {
  	let slaveMinX = minX
  	let slaveMaxX = maxX
  	let slaveMinY = minY
  	let slaveMaxY = maxY

  	let masterMinX = rect.minX
  	let masterMaxX = rect.maxX
  	let masterMinY = rect.minY
  	let masterMaxY = rect.maxY

  	let pushX = slaveMinX >= masterMinX ? 0.0 : masterMinX - slaveMinX
  	let pushY = slaveMinY >= masterMinY ? 0.0 : masterMinY - slaveMinY
  	let pullX = slaveMaxX <= masterMaxX ? 0.0 : slaveMaxX - masterMaxX
  	let pullY = slaveMaxY <= masterMaxY ? 0.0 : slaveMaxY - masterMaxY

  	return CGRect(x: origin.x + pushX + pullX,
  		            y: origin.y + pushY + pullY,
                  width: min(size.width + pushX + pullY, size.width),
                  height: min(size.height + pushY + pullY, size.height))
  }
}

extension CGRect: CustomStringConvertible { public var description: String { return NSStringFromCGRect(self) } }

extension CGRect: Unpackable4 {
  public var unpack: (CGFloat, CGFloat, CGFloat, CGFloat) { return (origin.x, origin.y, size.width, size.height) }
}

public func ∪(lhs: CGRect, rhs: CGRect) -> CGRect { return lhs.union(rhs) }

public func ∩(lhs: CGRect, rhs: CGRect) -> CGRect { return lhs.intersect(rhs) }

public func ∪=(inout lhs: CGRect, rhs: CGRect) { lhs.unionInPlace(rhs) }

public func ∩=(inout lhs: CGRect, rhs: CGRect) { lhs.intersectInPlace(rhs) }

public func -(lhs: UIOffset, rhs: UIOffset) -> UIOffset {
	return UIOffset(horizontal: lhs.horizontal - rhs.horizontal, vertical: lhs.vertical - rhs.vertical)
}

public func +(lhs: UIOffset, rhs: UIOffset) -> UIOffset {
	return UIOffset(horizontal: lhs.horizontal + rhs.horizontal, vertical: lhs.vertical + rhs.vertical)
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
