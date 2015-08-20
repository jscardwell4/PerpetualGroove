//
//  CAHostTimeBase.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
//  Converted source from C++ class from Apple's Core Audio Utility Classes sample code

import Foundation

final class	CAHostTimeBase {

  /**
  convertToNanos:

  - parameter inHostTime: UInt64

  - returns: UInt64
  */
  static func convertToNanos(inHostTime: UInt64) -> UInt64 { 
   guard isInitialized else { initialize(); return convertToNanos(inHostTime) }
   return multiplyByRatio(inHostTime, _toNanosNumerator, _toNanosDenominator)
  }

  /**
  convertFromNanos:

  - parameter inNanos: UInt64

  - returns: UInt64
  */
  static func convertFromNanos(inNanos: UInt64) -> UInt64 {
   guard isInitialized else { initialize(); return convertFromNanos(inNanos) }
   return multiplyByRatio(inNanos, _toNanosDenominator, _toNanosNumerator)
  }

  static var	currentTime: UInt64 { return mach_absolute_time() }
  static var  currentTimeInNanos: UInt64 { return convertToNanos(currentTime) }

  static private var isInitialized = false

  static var frequency: Double {
    guard isInitialized else { initialize(); return _frequency }
    return _frequency
  }

  static var inverseFrequency: Double {
    guard isInitialized else { initialize(); return _inverseFrequency }
    return _inverseFrequency
  }

  /**
  absoluteHostDeltaToNanos::

  - parameter start: UInt64
  - parameter end: UInt64

  - returns: UInt64
  */
  static func absoluteHostDeltaToNanos(start: UInt64, _ end: UInt64) -> UInt64 {
    return convertToNanos(start <= end ? end - start : start - end)
  }

  /**
  hostDeltaToNanos::

  - parameter start: UInt64
  - parameter end: UInt64

  - returns: Int64
  */
  static func hostDeltaToNanos(start: UInt64, _ end: UInt64) -> Int64 {
    return start <= end ? Int64(convertToNanos(end - start)) : -Int64(convertToNanos(start - end))
  }

  /**
  multiplyByRatio:inNumerator:inDenominator:

  - parameter inMuliplicand: UInt64
  - parameter inNumerator: UInt32
  - parameter inDenominator: UInt32

  - returns: UInt64
  */
  static func multiplyByRatio(multiplicand: UInt64, _ numerator: UInt32, _ denominator: UInt32) -> UInt64 {
    guard numerator != denominator else { return multiplicand }
    return UInt64((Double(multiplicand) * Double(numerator)) / Double(denominator))
  }

  /** Initialize */
  static private func initialize() {
    guard !isInitialized else { return }

    var timeBaseInfo = mach_timebase_info()
     mach_timebase_info(&timeBaseInfo)
    _toNanosNumerator = timeBaseInfo.numer
    _toNanosDenominator = timeBaseInfo.denom
 
    _frequency = (Double(_toNanosDenominator) / Double(_toNanosNumerator)) * 1_000_000_000

    isInitialized = true
  }

  static private var _frequency: Double = 0 { didSet { _inverseFrequency = 1 / _frequency } }
  static private var _inverseFrequency: Double = 0
  static private var _toNanosNumerator: UInt32 = 0
  static private var _toNanosDenominator: UInt32 = 0

}