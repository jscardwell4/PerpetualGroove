//
//  CoreGraphics.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/26/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
//import UIKit

public enum VerticalAlignment: String { case Top, Center, Bottom }

public func +<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(lhs: U1, rhs: U2) -> U1
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 += values2.0
  values1.1 += values2.1
  return U1(values1)
}

public func -<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(lhs: U1, rhs: U2) -> U1
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 -= values2.0
  values1.1 -= values2.1
  return U1(values1)
}

public func *<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(lhs: U1, rhs: U2) -> U1
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 *= values2.0
  values1.1 *= values2.1
  return U1(values1)
}

public func /<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(lhs: U1, rhs: U2) -> U1
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 /= values2.0
  values1.1 /= values2.1
  return U1(values1)
}

public func %<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(lhs: U1, rhs: U2) -> U1
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 %= values2.0
  values1.1 %= values2.1
  return U1(values1)
}

public func +=<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(inout lhs: U1, rhs: U2)
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 += values2.0
  values1.1 += values2.1
  lhs = U1(values1)
}

public func -=<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(inout lhs: U1, rhs: U2)
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 -= values2.0
  values1.1 -= values2.1
  lhs = U1(values1)
}

public func *=<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(inout lhs: U1, rhs: U2)
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 *= values2.0
  values1.1 *= values2.1
  lhs = U1(values1)
}

public func /=<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(inout lhs: U1, rhs: U2)
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 /= values2.0
  values1.1 /= values2.1
  lhs = U1(values1)
}

public func %=<U1:Unpackable2, U2:Unpackable2
  where U1:Packable2, U1.Element == U2.Element, U1.Element:ArithmeticType>(inout lhs: U1, rhs: U2)
{
  var values1 = lhs.unpack
  let values2 = rhs.unpack
  values1.0 %= values2.0
  values1.1 %= values2.1
  lhs = U1(values1)
}

extension CGFloat {
  public var degrees: CGFloat { return self * 180 / π }
  public var radians: CGFloat { return self * π / 180 }
  public func rounded(mantissaLength: Int) -> CGFloat {
    let remainder = self % pow(10, -CGFloat(mantissaLength))
    return self - remainder
         + round(remainder * pow(10, CGFloat(mantissaLength))) / pow(10, CGFloat(mantissaLength))
  }
}

public extension CGBlendMode {
  public var stringValue: String {
    switch self {
      case .Normal:          return "Normal"
      case .Multiply:        return "Multiply"
      case .Screen:          return "Screen"
      case .Overlay:         return "Overlay"
      case .Darken:          return "Darken"
      case .Lighten:         return "Lighten"
      case .ColorDodge:      return "ColorDodge"
      case .ColorBurn:       return "ColorBurn"
      case .SoftLight:       return "SoftLight"
      case .HardLight:       return "HardLight"
      case .Difference:      return "Difference"
      case .Exclusion:       return "Exclusion"
      case .Hue:             return "Hue"
      case .Saturation:      return "Saturation"
      case .Color:           return "Color"
      case .Luminosity:      return "Luminosity"
      case .Clear:           return "Clear"
      case .Copy:            return "Copy"
      case .SourceIn:        return "SourceIn"
      case .SourceOut:       return "SourceOut"
      case .SourceAtop:      return "SourceAtop"
      case .DestinationOver: return "DestinationOver"
      case .DestinationIn:   return "DestinationIn"
      case .DestinationOut:  return "DestinationOut"
      case .DestinationAtop: return "DestinationAtop"
      case .XOR:             return "XOR"
      case .PlusDarker:      return "PlusDarker"
      case .PlusLighter:     return "PlusLighter"
    }
  }
  public init(stringValue: String) {
    switch stringValue {
      case "Multiply":        self = .Multiply
      case "Screen":          self = .Screen
      case "Overlay":         self = .Overlay
      case "Darken":          self = .Darken
      case "Lighten":         self = .Lighten
      case "ColorDodge":      self = .ColorDodge
      case "ColorBurn":       self = .ColorBurn
      case "SoftLight":       self = .SoftLight
      case "HardLight":       self = .HardLight
      case "Difference":      self = .Difference
      case "Exclusion":       self = .Exclusion
      case "Hue":             self = .Hue
      case "Saturation":      self = .Saturation
      case "Color":           self = .Color
      case "Luminosity":      self = .Luminosity
      case "Clear":           self = .Clear
      case "Copy":            self = .Copy
      case "SourceIn":        self = .SourceIn
      case "SourceOut":       self = .SourceOut
      case "SourceAtop":      self = .SourceAtop
      case "DestinationOver": self = .DestinationOver
      case "DestinationIn":   self = .DestinationIn
      case "DestinationOut":  self = .DestinationOut
      case "DestinationAtop": self = .DestinationAtop
      case "XOR":             self = .XOR
      case "PlusDarker":      self = .PlusDarker
      case "PlusLighter":     self = .PlusLighter
      default:                self = .Normal
    }
  }
}
