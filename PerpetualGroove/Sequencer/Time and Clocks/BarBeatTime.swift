//
//  BarBeatTime
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import typealias CoreMIDI.MIDITimeStamp
import MoonKit

// TODO: Review file

func ∶(lhs: UInt, rhs: Double) -> BarBeatTime {
  let isNegative = lhs < 0
  let rhs = Fraction(rhs)
  let beat = UInt(rhs.integerPart)
  let subbeat = UInt(rhs.fractionalPart.decimalForm.numerator)
  return BarBeatTime(bar: lhs, beat: beat, subbeat: subbeat, negative: isNegative)
}

struct BarBeatTime {

  private var negative = false

  mutating func negate() { negative = !negative }
  var negated: BarBeatTime { var result = self; result.negate(); return result }

  var isNegative: Bool { return negative }

  /// The number of complete bars
  var bar: UInt = 0

  /// The number of complete beats. 
  var beat: UInt {
    get { return UInt(beatFraction.numerator) }
    set {
      beatFraction = UInt128(newValue)╱beatFraction.denominator
      if beatFraction.isImproper { normalize() }
    }
  }

  /// The number of subbeats.
  var subbeat: UInt {
    get { return UInt(subbeatFraction.numerator) }
    set {
      subbeatFraction = UInt128(newValue)╱subbeatFraction.denominator
      if subbeatFraction.isImproper { normalize() }
    }
  }

  /// The number of subbeats per beat
  var subbeatDivisor: UInt {
    get { return UInt(subbeatFraction.denominator) }
    set {
      guard newValue != subbeatDivisor else { return }

      let currentTicks = beats * subbeatDivisor + subbeat

      let newBeats = currentTicks / newValue
      bar = newBeats / beatsPerBar
      beatFraction = UInt128(newBeats - bar * beatsPerBar)╱beatFraction.denominator
      subbeatFraction = UInt128(currentTicks - newBeats * newValue)╱UInt128(newValue)
      subbeatUnit = 1╱UInt128(newValue)
    }
  }

  /// The number of beats per bar
  var beatsPerBar: UInt {
    get { return UInt(beatFraction.denominator) }
    set {
      precondition(newValue > 0, "`beatsPerBar` must be a positive value")
      guard newValue != beatsPerBar else { return }
      let currentBeats = beats
      bar = currentBeats / newValue
      beatFraction = UInt128(currentBeats - bar * newValue)╱UInt128(newValue)
      beatUnit = 1╱UInt128(newValue)
    }
  }

  /// The number of beats per minute. This value is used when converting to/from seconds.
  var beatsPerMinute: UInt = 120

  var units: Units {
    get {
      return Units(beatsPerBar: beatsPerBar,
                   beatsPerMinute: beatsPerMinute,
                   subbeatDivisor: subbeatDivisor)
    }
    set {
      beatsPerMinute = newValue.beatsPerMinute
      beatsPerBar = newValue.beatsPerBar
      subbeatDivisor = newValue.subbeatDivisor
    }
  }

  fileprivate var beatFraction: Fraction
  private(set) var beatUnit: Fraction
  var beatUnitTime: BarBeatTime { return BarBeatTime(beat: 1, units: units) }

  fileprivate var subbeatFraction: Fraction
  private(set) var subbeatUnit: Fraction
  var subbeatUnitTime: BarBeatTime { return BarBeatTime(subbeat: 1, units: units) }

  fileprivate init(bar: UInt, beatFraction: Fraction, subbeatFraction: Fraction, units: Units, negative: Bool = false) {
    self.bar = bar
    self.beatsPerMinute = units.beatsPerMinute
    self.beatFraction = beatFraction.fractionWithBase(UInt128(units.beatsPerBar))
    beatUnit = 1╱UInt128(units.beatsPerBar)
    self.subbeatFraction = subbeatFraction.fractionWithBase(UInt128(units.subbeatDivisor))
    subbeatUnit = 1╱UInt128(units.subbeatDivisor)
    self.negative = negative
    normalize()
  }

  init(bar: UInt = 0, beat: UInt = 0, subbeat: UInt = 0, units: Units = Units(), negative: Bool = false) {
    self.init(bar: bar,
              beatFraction: UInt128(beat)╱UInt128(units.beatsPerBar),
              subbeatFraction: UInt128(subbeat)╱UInt128(units.subbeatDivisor),
              units: units,
              negative: negative)
  }

  /// Whether the time qualifies as 'normal'
  ///
  /// A time is 'normal' when all of the following are true:
  /// - `bar >= 0`
  /// - `1...beatsPerBar ∋ beat`
  /// - `1...subbeatDivisor ∋ subbeat`
  /// - `subbeatDivisor > 0`
  fileprivate var isNormal: Bool { return beatFraction.isProper && subbeatFraction.isProper }

  /** Updates `self` to equal its `normalized` form. */
  mutating func normalize() {
    guard !isNormal else { return }

    if !subbeatFraction.isProper {
      let (integer, fractional) = subbeatFraction.parts
      beatFraction.add(integer╱1 * beatUnit)
      subbeatFraction = fractional
    }

    if beatFraction.isImproper {
      let (integer, fractional) = beatFraction.parts
      bar += UInt(integer)
      beatFraction = fractional
    }
  }

  var isZero: Bool { return bar == 0 && beatFraction == 0 && subbeatFraction == 0 }

  /// A bar-beat time for representing a null value
  static var null: BarBeatTime { return BarBeatTime(units: Units(beatsPerBar: 0, beatsPerMinute: 0, subbeatDivisor: 0)) }

  static var zero: BarBeatTime { return BarBeatTime() }

  init(time: BarBeatTime, units: Units) {
    self = time
    self.units = units
  }

  /// Initialize with a tick value
  init(tickValue: MIDITimeStamp, units: Units = Units(), negative: Bool = false) {
    let totalBeats = Double(tickValue) / Double(units.subbeatDivisor)
    self.init(totalBeats: negative ? -totalBeats : totalBeats, units: units)
  }

   /// Initialize with the number of seconds
  init(seconds: TimeInterval, units: Units = Units(), negative: Bool = false) {
    let totalBeats = seconds * (TimeInterval(units.beatsPerMinute) / 60)
    self.init(totalBeats: negative ? -totalBeats : totalBeats, units: units)
  }

  init(totalBeats: Double, units: Units = Units()) {
    let negative = totalBeats.sign == .minus
    let totalBeats = abs(totalBeats)
    let bar = UInt(totalBeats) / units.beatsPerBar
    let beat = UInt(totalBeats) % units.beatsPerBar
    let subbeat = UInt(round(modf(totalBeats).1 * Double(units.subbeatDivisor)))
    self.init(bar: bar, beat: beat, subbeat: subbeat, units: units, negative: negative)
  }

  var secondsPerBeat: TimeInterval {
    return 1 / (TimeInterval(beatsPerMinute) / 60)
  }

  /// The time's value in seconds
  var seconds: TimeInterval { return totalBeats * secondsPerBeat }

  var beats: UInt { return bar * beatsPerBar + beat }

  var totalBeats: Double {
    let totalBeats = Fraction(bar * beatsPerBar) + beatFraction / beatUnit + subbeatFraction
    return Double(isNegative ? -totalBeats : totalBeats)
  }

  /// The time's value in ticks
  var ticks: MIDITimeStamp {
    return MIDITimeStamp(beats * subbeatDivisor + subbeat)
  }

  var display: String {
    let barString = String(bar + 1, radix: 10, pad: 3)
    let beatString = String(beat + 1)
    let subbeatString = String(subbeat + 1, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(isNegative ? "-" : "")\(barString):\(beatString).\(subbeatString)"
  }

}

// MARK: - CustomStringConvertible
extension BarBeatTime: CustomStringConvertible {
  var description: String { return rawValue }
}

extension BarBeatTime: LosslessStringConvertible {
  init?(_ description: String) { self.init(rawValue: description) }
}

extension BarBeatTime: CustomPlaygroundQuickLookable {
  var customPlaygroundQuickLook: PlaygroundQuickLook { return .text(display) }
}

// MARK: - Hashable
extension BarBeatTime: Hashable {
  var hashValue: Int {
    defer { _fixLifetime(self) }
    return rawValue.hashValue
  }
}

// MARK: - RawRepresentable
extension BarBeatTime: RawRepresentable, LosslessJSONValueConvertible {
  var rawValue: String {
    return "\(isNegative ? "-" : "")\(bar):\(beatFraction).\(subbeatFraction)@\(beatsPerMinute)"
  }

  /// Initialize with string with form: (-)?<bar>:<beat>(/<beatsPerBar>)?.<subbeat>(/<subbeatDivisor>)?(@<beatsPerMinute>)?<base>
  init?(rawValue: String) {
    let pattern = "".join(
      "^",
      "(?<negative>-)?",
      "(?<bar>[0-9]+)",
      ":",
      "(?<beat>[0-9]+)",
      "(?:",
        "[╱/]",
        "(?<beatsPerBar>[0-9]+)",
      ")?",
      "[.]",
      "(?<subbeat>[0-9]+)",
      "(?:",
        "[╱/]",
        "(?<subbeatDivisor>[0-9]+)",
      ")?",
      "(?:",
        "@",
        "(?<beatsPerMinute>[0-9]+)",
      ")?",
      "$"
    )
    let re = ~/pattern
    guard let match = re.firstMatch(in: rawValue),
              let barString = match["bar"]?.string,
              let beatString = match["beat"]?.string,
              let subbeatString = match["subbeat"]?.string,
              let bar = UInt(barString),
              let beat = UInt(beatString),
              let subbeat = UInt(subbeatString) else { return nil }

    var units = Units()

    let negative = match["negative"] != nil
    if let beatsPerBarString = match["beatsPerBar"]?.string, let beatsPerBarUInt = UInt(beatsPerBarString) {
      units.beatsPerBar = beatsPerBarUInt
    }
    if let subbeatDivisorString = match["subbeatDivisor"]?.string,
      let subbeatDivisorUInt = UInt(subbeatDivisorString)
    {
      units.subbeatDivisor = subbeatDivisorUInt
    }
    if let beatsPerMinuteString = match["beatsPerMinute"]?.string, let beatsPerMinuteUInt = UInt(beatsPerMinuteString) {
      units.beatsPerMinute = beatsPerMinuteUInt
    }

    self.init(bar: bar, beat: beat, subbeat: subbeat, units: units, negative: negative)
  }
}

// MARK: - StringLiteralConvertible
extension BarBeatTime: ExpressibleByStringLiteral {
  init(stringLiteral value: String) { self = BarBeatTime(rawValue: value) ?? .null }
  init(unicodeScalarLiteral value: String) { self.init(stringLiteral: value) }
  init(extendedGraphemeClusterLiteral value: String) { self.init(stringLiteral: value) }
}

// MARK: - NilLiteralConvertible
//extension BarBeatTime: ExpressibleByNilLiteral {
//  init(nilLiteral: ()) {
//    self = BarBeatTime.null
//  }
//}

// MARK: - FloatLiteralConvertible
extension BarBeatTime: ExpressibleByFloatLiteral {
  init(floatLiteral value: Double) {
    self.init(totalBeats: value)
  }
}

extension BarBeatTime: ExpressibleByIntegerLiteral {
  init(integerLiteral value: MIDITimeStamp) { self.init(tickValue: value) }
}

extension BarBeatTime: SignedNumber {
  static prefix func -(value: BarBeatTime) -> BarBeatTime { return value.negated }
  static func -(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime { return BarBeatTime.subtractWithOverflow(lhs, rhs).0 }
}

extension BarBeatTime: SignedInteger {
  init(_ value: IntMax) { self = BarBeatTime(tickValue: MIDITimeStamp(abs(value)), negative: value < 0) }
  func toIntMax() -> IntMax { let ticks = IntMax(self.ticks); return isNegative ? -ticks : ticks }
}

extension BarBeatTime: _ExpressibleByBuiltinIntegerLiteral {
  init(_builtinIntegerLiteral value: _MaxBuiltinIntegerType) {
    self.init(IntMax(_builtinIntegerLiteral: value))
  }
}

extension BarBeatTime: _IntegerArithmetic {
  static func addWithOverflow(_ lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    switch (lhs.isNegative, rhs.isNegative) {
    case (false, false), (true, true):
      // x + y; -x + -y
      let units = lhs.units
      let rhs = BarBeatTime(time: rhs, units: units)
      return (BarBeatTime(bar: lhs.bar + rhs.bar,
                          beatFraction: lhs.beatFraction + rhs.beatFraction,
                          subbeatFraction: lhs.subbeatFraction + rhs.subbeatFraction,
                          units: units,
                          negative: lhs.isNegative),
              false)
    case (true, false):
      // -x + y = y - x
      return subtractWithOverflow(rhs, lhs.negated)
    case (false, true):
      // x + -y = x - y
      return subtractWithOverflow(lhs, rhs.negated)
    }
  }
  static func subtractWithOverflow(_ lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    switch (lhs.isNegative, rhs.isNegative) {
    case (false, false):
      let units = lhs.units
      let rhs = BarBeatTime(time: rhs, units: units)
      switch (lhs.ticks, rhs.ticks) {
        case let (lhsTicks, rhsTicks) where lhsTicks == rhsTicks:
          return (BarBeatTime(units: units), false)
        case let (lhsTicks, rhsTicks) where lhsTicks > rhsTicks:
          return (BarBeatTime(tickValue: lhsTicks - rhsTicks, units: units), false)
        case let (lhsTicks, rhsTicks) /*where lhsTicks < rhsTicks*/:
          return (BarBeatTime(tickValue: rhsTicks - lhsTicks, units: units).negated, false)
      }
    case(true, true):
      // -x - -y = -x + y = y - x
      return subtractWithOverflow(rhs.negated, lhs.negated)
    case (true, false):
      // -x - y = -x + -y
      return addWithOverflow(lhs, rhs.negated)
    case (false, true):
      // x - -y = x + y
      return addWithOverflow(lhs, rhs.negated)
    }
  }

  static func multiplyWithOverflow(_ lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats * rhs.totalBeats, units: lhs.units), false)
  }

  static func remainderWithOverflow(_ lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats.truncatingRemainder(dividingBy: rhs.totalBeats), units: lhs.units), false)
  }

  static func divideWithOverflow(_ lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats / rhs.totalBeats, units: lhs.units), false)
  }

  static func +(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
    return BarBeatTime.addWithOverflow(lhs, rhs).0
  }
}

extension BarBeatTime: BitwiseOperations {
  static func &(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
    let rhs = BarBeatTime(time: rhs, units: lhs.units)
    return BarBeatTime(tickValue: lhs.ticks & rhs.ticks, units: lhs.units)
  }

  static func ^(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
    let rhs = BarBeatTime(time: rhs, units: lhs.units)
    return BarBeatTime(tickValue: lhs.ticks ^ rhs.ticks, units: lhs.units)
  }

  static func |(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
    let rhs = BarBeatTime(time: rhs, units: lhs.units)
    return BarBeatTime(tickValue: lhs.ticks | rhs.ticks, units: lhs.units)
  }

  static prefix func ~(value: BarBeatTime) -> BarBeatTime {
    return BarBeatTime(tickValue: ~value.ticks, units: value.units)
  }

  static var allZeros: BarBeatTime { return BarBeatTime.zero }
}

// MARK: - Comparable
extension BarBeatTime: Comparable {
  
  static func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool {
    return lhs.isNegative == rhs.isNegative
        && lhs.bar == rhs.bar
        && lhs.beatFraction == rhs.beatFraction
        && lhs.subbeatFraction == rhs.subbeatFraction
  }

  static func <(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool {
    switch (lhs.isNegative, rhs.isNegative) {
      case (true, false) where lhs.isZero && rhs.isZero: return false
      case (true, false): return true
      case (false, true): return false
      case (true, true):
        switch (lhs.bar, rhs.bar) {
          case let (bar1, bar2) where bar1 > bar2: return true
          case let (bar1, bar2) where bar1 < bar2: return false
          default:
            switch (lhs.beatFraction, rhs.beatFraction) {
              case let (beat1, beat2) where beat1 > beat2: return true
              case let (beat1, beat2) where beat1 < beat2: return false
              default: return lhs.subbeatFraction > rhs.subbeatFraction
            }
        }
      case (false, false):
        switch (lhs.bar, rhs.bar) {
          case let (bar1, bar2) where bar1 < bar2: return true
          case let (bar1, bar2) where bar1 > bar2: return false
          default:
            switch (lhs.beatFraction, rhs.beatFraction) {
              case let (beat1, beat2) where beat1 < beat2: return true
              case let (beat1, beat2) where beat1 > beat2: return false
              default: return lhs.subbeatFraction < rhs.subbeatFraction
            }
        }

    }
  }
}

extension BarBeatTime: Strideable {
  func advanced(by n: BarBeatTime) -> BarBeatTime { return self + n }
  func distance(to other: BarBeatTime) -> BarBeatTime { return other - self }
}

extension BarBeatTime {

  struct Units: Equatable {
    var beatsPerBar: UInt = 4
    var beatsPerMinute: UInt = 120
    var subbeatDivisor: UInt = 480

    static func ==(lhs: Units, rhs: Units) -> Bool {
      return lhs.beatsPerBar == rhs.beatsPerBar
          && lhs.beatsPerMinute == rhs.beatsPerMinute
          && lhs.subbeatDivisor == rhs.subbeatDivisor
    }
  }

}
