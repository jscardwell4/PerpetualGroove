//
//  CAHostTimeBase.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
//  Converted source from C++ class from Apple's Core Audio Utility Classes sample code

import Foundation
import MoonKit

final class	CAHostTimeBase {

  /**
  convertToNanos:

  - parameter inHostTime: Float80

  - returns: Float80
  */
  static func toNanos(x: Float80) -> Float80 { guard isSetup else { setup(); return x * ratio }; return x * ratio }

  /**
  convertFromNanos:

  - parameter inNanos: Float80

  - returns: Float80
  */
  static func fromNanos(x: Float80) -> Float80 { guard isSetup else { setup(); return x * ratio }; return x * ratio }

  static var currentTime: UInt64 { return mach_absolute_time() }
  static var currentTimeInNanos: UInt64 { return UInt64(toNanos(Float80(currentTime))) }

  static private var isSetup = false

  static var frequency: Float80 { guard isSetup else { setup(); return _frequency }; return _frequency }
  static var inverseFrequency: Float80 { guard isSetup else { setup(); return _inverse }; return _inverse }

  static var ratio: Ratio<Float80> = 1∶1

  /** Initialize */
  static private func setup() {
    guard !isSetup else { return }

    var timeBaseInfo = mach_timebase_info()
    mach_timebase_info(&timeBaseInfo)

    ratio.numerator = IntMax(timeBaseInfo.numer)
    ratio.denominator = IntMax(timeBaseInfo.denom)

    _frequency = ratio * 1_000_000_000

    isSetup = true
  }

  static private var _frequency: Float80 = 0 { didSet { _inverse = 1 / _frequency } }
  static private var _inverse: Float80 = 0

}