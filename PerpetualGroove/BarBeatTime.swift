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

struct BarBeatTime {

  /// Type for specifying whether an empty time would be represented by 0:0.0 or 1:1.1
  enum Base: UInt {
    case Zero, One
    var string: String { return self == .One ? "₁" : "₀" }
    init(string: String) { self = string == "₁" ? .One : .Zero }
  }

  var base: Base = .Zero {
    didSet {
      guard base != oldValue else { return }
      switch base {
        case .Zero: bar -= 1; beat -= 1; subbeat -= 1
        case .One:  bar += 1; beat += 1; subbeat += 1
      }
    }
  }

  var negative = false

  /// The number of complete bars
  ///
  /// Must satisfy `bar >= 0` to qualify as 'normal'.
  var bar: UInt = 0

  private var rawBar: UInt { return bar - base.rawValue }

  /// The number of complete beats. 
  ///
  /// Must satisfy `1...beatsPerBar ∋ beat` to qualify as 'normal'
  var beat: UInt { get { return beatFraction.numerator } set { beatFraction.numerator = newValue } }

  private var rawBeat: UInt { return beat - base.rawValue }

  /// The number of subbeats.
  ///
  /// Must satisfy `1...subbeatDivisor ∋ subbeat` to qualify as 'normal'
  var subbeat: UInt { get { return subbeatFraction.numerator } set { subbeatFraction.numerator = newValue } }

  private var rawSubbeat: UInt { return subbeat - base.rawValue }

  /// The number of subbeats per beat
  var subbeatDivisor: UInt {
    get { return subbeatFraction.denominator }
    set {
      guard subbeatFraction.denominator != newValue else { return }
      subbeatFraction = subbeatFraction.fractionWithBase(newValue)
      normalize()
    }
  }

  /// The number of beats per bar
  var beatsPerBar: UInt {
    get { return beatFraction.denominator }
    set {
      guard beatFraction.denominator != newValue else { return }
      beatFraction = beatFraction.fractionWithBase(newValue)
      normalize()
    }
  }

  /// The number of beats per minute. This value is used when converting to/from seconds.
  var beatsPerMinute = Sequencer.beatsPerMinute

  private var beatFraction: Fraction<UInt> = 0╱Sequencer.beatsPerBar

  private var subbeatFraction: Fraction<UInt> = 0╱Sequencer.partsPerQuarter

  /// The time's zero-based representation
  var zeroBased: BarBeatTime { guard base != .Zero else { return self }; var result = self; result.base = .Zero; return result }

  /// The time's one-based representation
  var oneBased: BarBeatTime { guard base != .One else { return self }; var result = self; result.base = .One; return result }

  /**
   Default initializer

   - parameter bar: Int = 0
   - parameter beat: Int = 0
   - parameter subbeat: Int = 0
   - parameter subbeatDivisor: Int = Sequencer.partsPerQuarter
   - parameter beatsPerBar: Int = Sequencer.beatsPerBar
   - parameter beatsPerMinute: Int = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   - parameter negative: Bool = false
  */
  init(bar: UInt = 0,
       beat: UInt = 0,
       subbeat: UInt = 0,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero,
       negative: Bool = false)
  {
    self.bar = bar
    beatFraction = beat╱beatsPerBar
    subbeatFraction = subbeat╱subbeatDivisor
    self.beatsPerMinute = beatsPerMinute
    self.base = base
    self.negative = negative
  }

  /// Whether the time qualifies as 'normal'
  ///
  /// A time is 'normal' when all of the following are true:
  /// - `bar >= 0`
  /// - `1...beatsPerBar ∋ beat`
  /// - `1...subbeatDivisor ∋ subbeat`
  /// - `subbeatDivisor > 0`
  var isNormal: Bool {
    return base.rawValue ..< (beatsPerBar + base.rawValue) ∋ beat
        && base.rawValue ..< (subbeatDivisor + base.rawValue) ∋ subbeat
  }

  /// Attempts to adjust the time into a normalized form. 
  /// Returns `self` when `bar` or `subbeatDivisor` conditions are unsatisfiable.
  var normalized: BarBeatTime { var result = self; result.normalize(); return result }

  /** Updates `self` to equal its `normalized` form. */
  mutating func normalize() {
    guard !isNormal else { return }

    if subbeat >= subbeatDivisor + base.rawValue {
      beat += subbeat / subbeatDivisor
      subbeat %= subbeatDivisor
    }
    if beat >= beatsPerBar + base.rawValue {
      bar += beat / beatsPerBar
      beat %= beatsPerBar
    }
  }

  /// The starting point for a zero-based bar-beat time, '0:0.0'
  static var start0: BarBeatTime { return BarBeatTime() }

  /// The starting point for one-based bar-beat time, '1:1.1'
  static var start1: BarBeatTime { return BarBeatTime(bar: 1, beat: 1, subbeat: 1, base: .One) }

  /// A bar-beat time for representing a null value, -1:-1:-1
  static let null = BarBeatTime(bar: 0, beat: 0, subbeat: 0, subbeatDivisor: 0, beatsPerBar: 0, beatsPerMinute: 0)

  /**
   Initialize with a tick value

   - parameter tickValue: MIDITimeStamp
   - parameter beatsPerBar: UInt8 = Sequencer.beatsPerBar
   - parameter subbeatDivisor: UInt16 = Sequencer.time.partsPerQuarter
   - parameter beatsPerMinute: Int = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   - parameter negative: Bool = false
   */
  init(tickValue: MIDITimeStamp,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero,
       negative: Bool = false)
  {
    let totalBeats = Double(tickValue) / Double(subbeatDivisor)
    self.init(totalBeats: negative ? -totalBeats : totalBeats,
              beatsPerBar: beatsPerBar,
              subbeatDivisor: subbeatDivisor,
              beatsPerMinute: beatsPerMinute,
              base: base)
  }

  /**
   Initialize with the number of seconds

   - parameter seconds: NSTimeInterval
   - parameter beatsPerBar: Int = Sequencer.beatsPerBar
   - parameter subbeatDivisor: Int = Sequencer.partsPerQuarter
   - parameter beatsPerMinute: Int = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   - parameter negative: Bool = false
   */
  init(seconds: NSTimeInterval,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero,
       negative: Bool = false)
  {
    let totalBeats = seconds * NSTimeInterval(beatsPerMinute) / 60
    self.init(totalBeats: negative ? -totalBeats : totalBeats,
              beatsPerBar: beatsPerBar,
              subbeatDivisor: subbeatDivisor,
              beatsPerMinute: beatsPerMinute,
              base: base)
  }

  /**
   initWithTotalBeats:beatsPerBar:subbeatDivisor:beatsPerMinute:base:

   - parameter totalBeats: Double
   - parameter beatsPerBar: UInt = Sequencer.beatsPerBar
   - parameter subbeatDivisor: UInt = Sequencer.partsPerQuarter
   - parameter beatsPerMinute: UInt = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   - parameter negative: Bool = false
  */
  init(totalBeats: Double,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    let negative = totalBeats.isSignMinus
    let totalBeats = abs(totalBeats)
    let bar = UInt(totalBeats) / beatsPerBar + base.rawValue
    let beat = UInt(totalBeats) % beatsPerBar + base.rawValue
    let subbeat = UInt(modf(totalBeats).1 * Double(subbeatDivisor)) + base.rawValue
    self.init(bar: bar,
              beat: beat,
              subbeat: subbeat,
              subbeatDivisor: subbeatDivisor,
              beatsPerBar: beatsPerBar,
              beatsPerMinute: beatsPerMinute,
              base: base,
              negative: negative)
  }

  /// The time's value in seconds
  var seconds: NSTimeInterval { return totalBeats / NSTimeInterval(beatsPerMinute) / 60 }

  var totalBeats: Double {
    let wholeBeats = Double((rawBar) * beatsPerBar + rawBeat)
    let fractionalBeat = Double(rawSubbeat) / Double(subbeatDivisor)
    let totalBeats = wholeBeats + fractionalBeat
    return negative ? -totalBeats : totalBeats
  }

  /// The time's value in ticks
  var ticks: MIDITimeStamp {
    return MIDITimeStamp((rawBar * beatsPerBar + rawBeat) * subbeatDivisor + rawSubbeat)
  }

  var display: String {
    let barString = String(bar, radix: 10, pad: 3)
    let beatString = String(beat)
    let subbeatString = String(subbeat, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(negative ? "-" : "")\(barString):\(beatString).\(subbeatString)"
  }

}

// MARK: - CustomStringConvertible
extension BarBeatTime: CustomStringConvertible {
  var description: String { return display }
}

extension BarBeatTime: CustomPlaygroundQuickLookable {
  func customPlaygroundQuickLook() -> PlaygroundQuickLook { return .Text(rawValue) }
}

// MARK: - CustomDebugStringConvertible
extension BarBeatTime: CustomDebugStringConvertible {
  var debugDescription: String { return rawValue }
}

// MARK: - Hashable
extension BarBeatTime: Hashable {
  var hashValue: Int { return rawValue.hashValue }
}

// MARK: - RawRepresentable
extension BarBeatTime: RawRepresentable {
  var rawValue: String {
    return "\(negative ? "-" : "")\(bar):\(beatFraction).\(subbeatFraction)@\(beatsPerMinute)\(base.string)"
  }

  /**
   initWithRawValue:

   - parameter rawValue: String
   */
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
      "(?<base>[₀₁])?",
      "$"
    )
    let re = ~/pattern
    guard let match = re.firstMatch(rawValue),
              barString = match["bar"]?.string,
              beatString = match["beat"]?.string,
              subbeatString = match["subbeat"]?.string,
              bar = UInt(barString),
              beat = UInt(beatString),
              subbeat = UInt(subbeatString) else { return nil }
    let beatsPerBar: UInt
    let beatsPerMinute: Int
    let subbeatDivisor: Int
    let base: Base
    let negative = match["negative"] != nil
    if let beatsPerBarString = match["beatsPerBar"]?.string, beatsPerBarUInt = UInt(beatsPerBarString) {
      beatsPerBar = beatsPerBarUInt
    } else {
      beatsPerBar = Sequencer.beatsPerBar
    }
    if let subbeatDivisorString = match["subbeatDivisor"]?.string, subbeatDivisorInt = Int(subbeatDivisorString) {
      subbeatDivisor = subbeatDivisorInt
    } else {
      subbeatDivisor = Int(Sequencer.partsPerQuarter)
    }
    if let beatsPerMinuteString = match["beatsPerMinute"]?.string, beatsPerMinuteInt = Int(beatsPerMinuteString) {
      beatsPerMinute = beatsPerMinuteInt
    } else {
      beatsPerMinute = Int(Sequencer.beatsPerMinute)
    }
    if let baseString = match["base"]?.string where baseString == "₁" { base = .One } else { base = .Zero }
    self.init(bar: bar,
              beat: beat,
              subbeat: subbeat,
              subbeatDivisor: UInt(subbeatDivisor),
              beatsPerBar: beatsPerBar,
              beatsPerMinute: UInt(beatsPerMinute),
              base: base,
              negative: negative)
  }
}

// MARK: - StringLiteralConvertible
extension BarBeatTime: StringLiteralConvertible {
  init(stringLiteral value: String) { self = BarBeatTime(rawValue: value) ?? .null }
  init(unicodeScalarLiteral value: String) { self.init(stringLiteral: value) }
  init(extendedGraphemeClusterLiteral value: String) { self.init(stringLiteral: value) }
}

// MARK: - JSONValueConvertible
extension BarBeatTime: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

// MARK: - JSONValueInitializable
extension BarBeatTime: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return lhs.totalBeats == rhs.totalBeats }

// MARK: - BidirectionalIndexType
extension BarBeatTime: BidirectionalIndexType {

  typealias Distance = BarBeatTime

  func predecessor() -> BarBeatTime {
    return BarBeatTime(totalBeats: totalBeats - 1 / Double(subbeatDivisor),
                       beatsPerBar: beatsPerBar,
                       subbeatDivisor: subbeatDivisor,
                       beatsPerMinute: beatsPerMinute,
                       base: base)
  }

  /**
   successor

    - returns: BarBeatTime
  */
  func successor() -> BarBeatTime {
    return BarBeatTime(totalBeats: totalBeats + 1 / Double(subbeatDivisor),
                       beatsPerBar: beatsPerBar,
                       subbeatDivisor: subbeatDivisor,
                       beatsPerMinute: beatsPerMinute,
                       base: base)
  }

}

// MARK: - NilLiteralConvertible
extension BarBeatTime: NilLiteralConvertible {
  init(nilLiteral: ()) {
    self = BarBeatTime.null
  }
}

// MARK: - FloatLiteralConvertible
extension BarBeatTime: FloatLiteralConvertible {
  init(floatLiteral value: Double) {
    self.init(totalBeats: value)
  }
}

// MARK: - SignedNumberType, _SignedIntegerType, BitwiseOperationsType
extension BarBeatTime: SignedNumberType, _SignedIntegerType, BitwiseOperationsType {
  typealias IntegerLiteralType = UInt64
  init(integerLiteral value: UInt64) { self.init(tickValue: value) }
  init(_builtinIntegerLiteral value: _MaxBuiltinIntegerType) {
    self.init(integerLiteral: UInt64(_builtinIntegerLiteral: value))
  }
  init(_ value: IntMax) { self.init(integerLiteral: UInt64(value)) }
  func toIntMax() -> IntMax { return IntMax(ticks) }

  static func addWithOverflow(lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats + rhs.totalBeats,
                        beatsPerBar: lhs.beatsPerBar,
                        subbeatDivisor: lhs.subbeatDivisor,
                        beatsPerMinute: lhs.beatsPerMinute,
                        base: lhs.base),
            false)
  }
  static func subtractWithOverflow(lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats - rhs.totalBeats,
                        beatsPerBar: lhs.beatsPerBar,
                        subbeatDivisor: lhs.subbeatDivisor,
                        beatsPerMinute: lhs.beatsPerMinute,
                        base: lhs.base),
            false)
  }
  static func multiplyWithOverflow(lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats * rhs.totalBeats,
                        beatsPerBar: lhs.beatsPerBar,
                        subbeatDivisor: lhs.subbeatDivisor,
                        beatsPerMinute: lhs.beatsPerMinute,
                        base: lhs.base),
            false)
  }
  static func remainderWithOverflow(lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats % rhs.totalBeats,
                        beatsPerBar: lhs.beatsPerBar,
                        subbeatDivisor: lhs.subbeatDivisor,
                        beatsPerMinute: lhs.beatsPerMinute,
                        base: lhs.base),
            false)
  }
  static func divideWithOverflow(lhs: BarBeatTime, _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    return (BarBeatTime(totalBeats: lhs.totalBeats / rhs.totalBeats,
                        beatsPerBar: lhs.beatsPerBar,
                        subbeatDivisor: lhs.subbeatDivisor,
                        beatsPerMinute: lhs.beatsPerMinute,
                        base: lhs.base),
            false)
  }

  static var allZeros: BarBeatTime { return start0 }

}

func +(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime.addWithOverflow(lhs, rhs).0
}

func -(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime.subtractWithOverflow(lhs, rhs).0
}

prefix func -(value: BarBeatTime) -> BarBeatTime {
  return BarBeatTime(totalBeats: -value.totalBeats,
                     subbeatDivisor: value.subbeatDivisor,
                     beatsPerBar: value.beatsPerBar,
                     beatsPerMinute: value.beatsPerMinute,
                     base: value.base)
}

func *(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime.multiplyWithOverflow(lhs, rhs).0
}

func /(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime.divideWithOverflow(lhs, rhs).0
}

func %(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime.remainderWithOverflow(lhs, rhs).0
}

func &(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime(tickValue: lhs.ticks & rhs.ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func ^(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime(tickValue: lhs.ticks ^ rhs.ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func |(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  return BarBeatTime(tickValue: lhs.ticks | rhs.ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

prefix func ~(value: BarBeatTime) -> BarBeatTime {
  return BarBeatTime(tickValue: ~value.ticks,
                     beatsPerBar: value.beatsPerBar,
                     subbeatDivisor: value.subbeatDivisor,
                     beatsPerMinute: value.beatsPerMinute,
                     base: value.base)
}

func *<T:DoubleConvertible>(lhs: BarBeatTime, rhs: T) -> BarBeatTime {
  return BarBeatTime(totalBeats: lhs.totalBeats * rhs.DoubleValue,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func /<T:DoubleConvertible>(lhs: BarBeatTime, rhs: T) -> BarBeatTime {
  return BarBeatTime(totalBeats: lhs.totalBeats / rhs.DoubleValue,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func +<T:DoubleConvertible>(lhs: BarBeatTime, rhs: T) -> BarBeatTime {
  return BarBeatTime(totalBeats: lhs.totalBeats + rhs.DoubleValue,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func -<T:DoubleConvertible>(lhs: BarBeatTime, rhs: T) -> BarBeatTime {
  return BarBeatTime(totalBeats: lhs.totalBeats - rhs.DoubleValue,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

// MARK: - Comparable
extension BarBeatTime: Comparable {}

func <(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return lhs.totalBeats < rhs.totalBeats }


