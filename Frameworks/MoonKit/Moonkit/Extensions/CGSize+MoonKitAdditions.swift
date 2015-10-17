//
//  CGSize+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension CGSize {

  public init?(_ string: String?) { if let s = string { self = CGSizeFromString(s) } else { return nil } }
  public init(square: CGFloat) { self = CGSize(width: square, height: square) }
  public func contains(size: CGSize) -> Bool { return width >= size.width && height >= size.height }
  public var minAxis: UILayoutConstraintAxis { return height < width ? .Vertical : .Horizontal }
  public var maxAxis: UILayoutConstraintAxis { return width < height ? .Vertical : .Horizontal }
  public var minAxisValue: CGFloat { return min(width, height) }
  public var maxAxisValue: CGFloat { return max(width, height) }
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

  public mutating func scaleBy(ratio: Ratio<CGFloat>) {
    width = width * ratio.numerator
    height = height * ratio.denominator
  }

  public func ratioForFittingSize(size: CGSize) -> Ratio<CGFloat> {
    let (w, h) = min(aspectMappedToWidth(size.width), aspectMappedToHeight(size.height)).unpack
    return Ratio((width/w) / (height/h))
  }

  public func scaledBy(ratio: Ratio<CGFloat>) -> CGSize { var s = self; s.scaleBy(ratio); return s }

  public func aspectMappedToWidth(w: CGFloat) -> CGSize { return CGSize(width: w, height: (w * height) / width) }
  public func aspectMappedToHeight(h: CGFloat) -> CGSize { return CGSize(width: (h * width) / height, height: h) }
  public func aspectMappedToSize(size: CGSize, binding: Bool = false) -> CGSize {
  	let widthMapped = aspectMappedToWidth(size.width)
  	let heightMapped = aspectMappedToHeight(size.height)
  	return binding ? min(widthMapped, heightMapped) : max(widthMapped, heightMapped)
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
extension CGSize: Packable2 {
  public init(_ elements: (CGFloat, CGFloat)) { self.init(width: elements.0, height: elements.1) }
}
public func max(s1: CGSize, _ s2: CGSize) -> CGSize { return s1 > s2 ? s1 : s2 }
public func min(s1: CGSize, _ s2: CGSize) -> CGSize { return s1 < s2 ? s1 : s2 }

//public func +(lhs: CGSize, rhs: CGSize) -> CGSize {
//	return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
//}
//public func +<U:Unpackable2 where U.Element == CGFloat>(lhs: CGSize, rhs: U) -> CGSize {
//  let (w, h) = rhs.unpack
//  return CGSize(width: lhs.width + w, height: lhs.height + h)
//}
public func +=(inout lhs: CGSize, rhs: CGFloatable) { lhs.width += rhs.CGFloatValue; lhs.height += rhs.CGFloatValue }
public func +(lhs: CGSize, rhs: CGFloat) -> CGSize { return CGSize(width: lhs.width + rhs, height: lhs.height + rhs) }

//public func -(lhs: CGSize, rhs: CGSize) -> CGSize {
//	return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
//}
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
