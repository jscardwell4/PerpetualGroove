//
//  ClosedInterval+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/16/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension ClosedInterval {
  public func clampValue(value: Bound) -> Bound {
    if contains(value) { return value }
    else if start > value { return start }
    else { return end }
  }
  public var reversed: ReverseClosedInterval<Bound> { return ReverseClosedInterval<Bound>(self) }
}
public extension ClosedInterval where Bound:SignedNumberType, Bound:ArithmeticType {
  // FIXME: I think this only works for positive start intervals and intervals of the form -x ... x
  public var diameter: Bound { return abs(end - start) }

  public func normalizeValue(var value: Bound) -> Bound {
    value = clampValue(value)
    if start < 0 { return (value + abs(start)) / diameter }
    else if start > 0 { return (value - start) / diameter }
    else { return value / diameter }
  }

  public func valueForNormalizedValue(normalizedValue: Bound) -> Bound {
    guard normalizedValue >= 0 && normalizedValue <= 1 else {
      logWarning("normalized value must be in 0 ... 1")
      return normalizedValue
    }
    var value = diameter * normalizedValue
    if start < 0 { value -= abs(start) }
    else if start > 0 { value += start }

    return clampValue(value)
  }

  public func mapValue(value: Bound, from interval: ClosedInterval<Bound>) -> Bound {
    guard self != interval && !(isEmpty || interval.isEmpty) else { return clampValue(value) }
    return valueForNormalizedValue(interval.normalizeValue(value))
  }

  public var median: Bound { return (diameter / 2) + start }
}

public struct ReverseClosedInterval<Bound: Comparable>: IntervalType, Equatable {

  let base: ClosedInterval<Bound>

  public init(_ interval: ReverseClosedInterval<Bound>) { self = interval }
  public init(_ start: Bound, _ end: Bound) { base = ClosedInterval<Bound>(end, start) }
  public init(_ base: ClosedInterval<Bound>) { self.base = base }
  public func contains(value: Bound) -> Bool { return base.contains(value) }

  public func clamp(intervalToClamp: ReverseClosedInterval<Bound>) -> ReverseClosedInterval<Bound> {
    return ReverseClosedInterval<Bound>(base.clamp(intervalToClamp.base))
  }
  public var isEmpty: Bool { return base.isEmpty }
  public var start: Bound { return base.end }
  public var end: Bound { return base.start }
}
extension ReverseClosedInterval {
  public func clampValue(value: Bound) -> Bound {
    if contains(value) { return value }
    else if end > value { return end }
    else { return start }
  }
}
extension ReverseClosedInterval where Bound:SignedNumberType, Bound:ArithmeticType {
  public var diameter: Bound { return abs(start - end) }
  public func normalizeValue(value: Bound) -> Bound {
    return 1 - base.normalizeValue(value)
  }
  public func valueForNormalizedValue(normalizedValue: Bound) -> Bound {
    guard normalizedValue >= 0 && normalizedValue <= 1 else {
      logWarning("normalized value must be in 0 ... 1")
      return normalizedValue
    }
    var value = diameter - diameter * normalizedValue
    if end < 0 { value -= abs(end) }
    else if end > 0 { value += end }

    return clampValue(value)
  }
  public func mapValue(value: Bound, from interval: ReverseClosedInterval<Bound>) -> Bound {
    guard self != interval && !(isEmpty || interval.isEmpty) else { return clampValue(value) }
    return valueForNormalizedValue(interval.normalizeValue(value))
  }
  public var median: Bound { return (diameter / 2) + end }
}
extension ReverseClosedInterval: CustomStringConvertible {
  public var description: String { return "\(start)...\(end)" }
}
public func ==<B: Comparable>(lhs: ReverseClosedInterval<B>, rhs: ReverseClosedInterval<B>) -> Bool {
  return lhs.start == rhs.start && lhs.end == rhs.end
}

//@warn_unused_result
//public func ...<Bound : Comparable>(start: Bound, end: Bound) -> ReverseClosedInterval<Bound> {
//  return ReverseClosedInterval<Bound>(start, end)
//}
