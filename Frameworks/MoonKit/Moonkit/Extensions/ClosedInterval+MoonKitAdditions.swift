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
    print(value)
    if start < 0 { value -= abs(start) }
    else if start > 0 { value -= start }

    return value
  }

  public func mapValue(value: Bound, fromInterval interval: ClosedInterval<Bound>) -> Bound {
    guard self == interval || (!isEmpty && !interval.isEmpty) else { return value }
    return valueForNormalizedValue(interval.normalizeValue(value))
  }
}

