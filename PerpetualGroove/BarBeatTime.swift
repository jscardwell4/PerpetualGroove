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
  enum Base: Int {
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

  var negative: Bool { return bar < 0 }

  /// The number of complete bars
  ///
  /// Must satisfy `bar >= 0` to qualify as 'normal'.
  var bar = 0

  /// The number of complete beats. 
  ///
  /// Must satisfy `1...beatsPerBar ∋ beat` to qualify as 'normal'
  var beat: UInt {
    get { return UInt(beatFraction.numerator) }
    set { beatFraction.numerator = Int(newValue) }
  }

  /// The number of subbeats.
  ///
  /// Must satisfy `1...subbeatDivisor ∋ subbeat` to qualify as 'normal'
  var subbeat: UInt {
    get { return UInt(subbeatFraction.numerator) }
    set { subbeatFraction.numerator = Int(newValue) }
  }

  /// The number of subbeats per beat
  var subbeatDivisor: UInt {
    get { return UInt(subbeatFraction.denominator) }
    set {
      guard newValue > 0 && UInt(subbeatFraction.denominator) != newValue else { return }
      subbeatFraction = subbeatFraction.fractionWithBase(Int(newValue))
      normalize()
    }
  }

  /// The number of beats per bar
  var beatsPerBar: UInt {
    get { return UInt(beatFraction.denominator) }
    set {
      guard newValue > 0 && UInt(beatFraction.denominator) != newValue else { return }
      beatFraction = beatFraction.fractionWithBase(Int(newValue))
      normalize()
    }
  }

  /// The number of beats per minute. This value is used when converting to/from seconds.
  var beatsPerMinute = Sequencer.beatsPerMinute

  private var beatFraction: Fraction<Int> = 0╱Int(Sequencer.beatsPerBar)

  private var subbeatFraction: Fraction<Int> = 0╱Int(Sequencer.partsPerQuarter)

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
  */
  init(bar: Int = 0,
       beat: UInt = 0,
       subbeat: UInt = 0,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    self.bar = bar
    beatFraction = Int(beat)╱Int(beatsPerBar)
    subbeatFraction = Int(subbeat)╱Int(subbeatDivisor)
    self.beatsPerMinute = beatsPerMinute
    self.base = base
  }

  /// Whether the time qualifies as 'normal'
  ///
  /// A time is 'normal' when all of the following are true:
  /// - `bar >= 0`
  /// - `1...beatsPerBar ∋ beat`
  /// - `1...subbeatDivisor ∋ subbeat`
  /// - `subbeatDivisor > 0`
  var isNormal: Bool {
    guard subbeatDivisor > 0 && beatsPerBar > 0 else { return false }
    switch base {
      case .Zero: return bar >= 0 && 0 ..< beatsPerBar ∋ beat && 0 ..< subbeatDivisor ∋ subbeat
      case .One:  return bar >= 1 && 1 ... beatsPerBar ∋ beat && 1 ... subbeatDivisor ∋ subbeat
    }
  }

  /// Attempts to adjust the time into a normalized form. 
  /// Returns `self` when `bar` or `subbeatDivisor` conditions are unsatisfiable.
  var normalized: BarBeatTime { var result = self; result.normalize(); return result }

  /** Updates `self` to equal its `normalized` form. */
  mutating func normalize() {
    guard !isNormal && subbeatDivisor > 0 && beatsPerBar > 0 && bar >= 0 else { return }
    switch base {
      case .Zero:
        if subbeat >= subbeatDivisor {
          beat += subbeat / subbeatDivisor
          subbeat %= subbeatDivisor
        }
        while subbeat < 0 {
          subbeat += subbeatDivisor
          beat--
        }

        if beat >= beatsPerBar {
          bar += Int(beat / beatsPerBar)
          beat %= beatsPerBar
        }

        while beat < 0 {
          beat += beatsPerBar
          bar--
        }

      case .One:
        if subbeat > subbeatDivisor {
          beat += subbeat / subbeatDivisor
          subbeat %= subbeatDivisor
        }
        while subbeat < 1 {
          subbeat += subbeatDivisor
          beat--
        }
        if beat > beatsPerBar {
          bar += Int(beat / beatsPerBar)
          beat %= beatsPerBar
        }
        while beat < 1 {
          beat += beatsPerBar
          bar--
        }
    }
  }

  /// The starting point for a zero-based bar-beat time, '0:0.0'
  static let start0 = BarBeatTime()

  /// The starting point for one-based bar-beat time, '1:1.1'
  static let start1 = BarBeatTime(bar: 1, beat: 1, subbeat: 1, base: .One)

  /// A bar-beat time for representing a null value, -1:-1:-1
  static let null  = BarBeatTime(bar: Int.min, beat: 0, subbeat: 0)

  /**
   Initialize with a tick value

   - parameter tickValue: MIDITimeStamp
   - parameter beatsPerBar: UInt8 = Sequencer.beatsPerBar
   - parameter subbeatDivisor: UInt16 = Sequencer.time.partsPerQuarter
   - parameter beatsPerMinute: Int = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   */
  init(tickValue: MIDITimeStamp,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    let subbeat = Int(tickValue % MIDITimeStamp(subbeatDivisor))
    guard tickValue > MIDITimeStamp(subbeat) else {
      self = BarBeatTime(bar: base.rawValue,
                         beat: UInt(base.rawValue),
                         subbeat: UInt(subbeat + base.rawValue),
                         subbeatDivisor: subbeatDivisor,
                         beatsPerBar: beatsPerBar,
                         base: base)
      return
    }
    let totalBeats = (tickValue - MIDITimeStamp(subbeat)) / MIDITimeStamp(subbeatDivisor)
    let beat = Int(totalBeats % MIDITimeStamp(beatsPerBar))
    let bar = Int(totalBeats / MIDITimeStamp(beatsPerBar))
    self = BarBeatTime(bar: bar + base.rawValue,
                       beat: UInt(beat + base.rawValue),
                       subbeat: UInt(subbeat + base.rawValue),
                       subbeatDivisor: subbeatDivisor,
                       beatsPerBar: beatsPerBar,
                       beatsPerMinute: beatsPerMinute,
                       base: base)
  }

  /**
   Initialize with the number of seconds

   - parameter seconds: Double
   - parameter beatsPerBar: Int = Sequencer.beatsPerBar
   - parameter subbeatDivisor: Int = Sequencer.partsPerQuarter
   - parameter beatsPerMinute: Int = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   */
  init(seconds: Double,
       beatsPerBar: UInt = Sequencer.beatsPerBar,
       subbeatDivisor: UInt = Sequencer.partsPerQuarter,
       beatsPerMinute: UInt = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    let beatsPerSecond = NSTimeInterval(beatsPerMinute) / 60
    let totalBeats = seconds * beatsPerSecond
    let bar = Int(totalBeats) / Int(beatsPerBar) + base.rawValue
    let beat = Int(totalBeats) % Int(beatsPerBar) + base.rawValue
    let subbeat = Int(totalBeats % 1 * NSTimeInterval(subbeatDivisor)) + base.rawValue
    self.init(bar: bar,
              beat: UInt(beat),
              subbeat: UInt(subbeat),
              subbeatDivisor: subbeatDivisor,
              beatsPerBar: beatsPerBar,
              beatsPerMinute: beatsPerMinute,
              base: base)
  }

  /// The time's value in seconds
  var seconds: NSTimeInterval {
    let beatsPerSecond = NSTimeInterval(beatsPerMinute) / 60
    let wholeBeats = NSTimeInterval((bar - base.rawValue) * Int(beatsPerBar) + Int(beat) - base.rawValue)
    let fractionalBeat = NSTimeInterval(Int(subbeat) - base.rawValue) / NSTimeInterval(subbeatDivisor)
    let totalBeats = wholeBeats + fractionalBeat
    return totalBeats / beatsPerSecond
  }

  /// The time's value in ticks
  var ticks: MIDITimeStamp {
    let bar = MIDITimeStamp(max(self.bar - base.rawValue, 0))
    let beat = MIDITimeStamp(max(Int(self.beat) - base.rawValue, 0))
    let subbeat = MIDITimeStamp(max(Int(self.subbeat) - base.rawValue, 0))
    return (bar * MIDITimeStamp(beatsPerBar) + beat) * MIDITimeStamp(subbeatDivisor) + subbeat
  }

  var display: String {
    let barString = String(bar, radix: 10, pad: 3)
    let beatString = String(beat)
    let subbeatString = String(subbeat, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(barString):\(beatString).\(subbeatString)"
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

extension BarBeatTime: RawRepresentable {
  var rawValue: String { return "\(bar):\(beatFraction).\(subbeatFraction)@\(beatsPerMinute)\(base.string)" }

  /**
   initWithRawValue:

   - parameter rawValue: String
   */
  init?(rawValue: String) {
    let pattern = "".join(
      "^",
      "(?<bar>-?[0-9]+)",
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
              bar = Int(barString),
              beat = UInt(beatString),
              subbeat = UInt(subbeatString) else { return nil }
    let beatsPerBar: UInt
    let beatsPerMinute: Int
    let subbeatDivisor: Int
    let base: Base
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
              base: base)
  }
}

extension BarBeatTime: StringLiteralConvertible {
  init(stringLiteral value: String) { self = BarBeatTime(rawValue: value) ?? .null }
  init(unicodeScalarLiteral value: String) { self.init(stringLiteral: value) }
  init(extendedGraphemeClusterLiteral value: String) { self.init(stringLiteral: value) }
}

extension BarBeatTime: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension BarBeatTime: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

func ==(var lhs: BarBeatTime, var rhs: BarBeatTime) -> Bool {
  lhs.normalize()
  rhs.normalize()
  rhs.base = lhs.base
  guard lhs.bar == rhs.bar else { return false }
  guard lhs.beatFraction.reduced == rhs.beatFraction.reduced else { return false }
  guard lhs.subbeatFraction.reduced == rhs.subbeatFraction.reduced else { return false }
  guard lhs.base == rhs.base else { return false }
  guard lhs.beatsPerMinute == rhs.beatsPerMinute else { return false }
  return lhs.negative == rhs.negative
}

extension BarBeatTime: BidirectionalIndexType {

  typealias Distance = BarBeatTime

  func predecessor() -> BarBeatTime {
    var result = self
    result.subbeat--
    result.normalize()
    return result
  }

  /**
   successor

    - returns: BarBeatTime
  */
  func successor() -> BarBeatTime {
    var result = self
    result.subbeat++
    result.normalize()
    return result
  }

}

extension BarBeatTime: SignedNumberType, _SignedIntegerType, BitwiseOperationsType {
  typealias IntegerLiteralType = UInt64
  init(integerLiteral value: UInt64) { self.init(tickValue: value) }
  init(_builtinIntegerLiteral value: _MaxBuiltinIntegerType) {
    self.init(integerLiteral: UInt64(_builtinIntegerLiteral: value))
  }
  init(_ value: IntMax) { self.init(integerLiteral: UInt64(value)) }
  func toIntMax() -> IntMax { return IntMax(ticks) }
  static func addWithOverflow(lhs: BarBeatTime, var _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    rhs.base = lhs.base
    let (ticks, overflow) = MIDITimeStamp.addWithOverflow(lhs.ticks, rhs.ticks)
    let result = BarBeatTime(tickValue: ticks,
                             beatsPerBar: lhs.beatsPerBar,
                             subbeatDivisor: lhs.subbeatDivisor,
                             beatsPerMinute: lhs.beatsPerMinute,
                             base: lhs.base)
    return (result, overflow)
  }
  static func subtractWithOverflow(lhs: BarBeatTime, var _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    rhs.base = lhs.base
    let (ticks, overflow) = MIDITimeStamp.subtractWithOverflow(lhs.ticks, rhs.ticks)
    let result = BarBeatTime(tickValue: ticks,
                             beatsPerBar: lhs.beatsPerBar,
                             subbeatDivisor: lhs.subbeatDivisor,
                             beatsPerMinute: lhs.beatsPerMinute,
                             base: lhs.base)
    return (result, overflow)
  }
  static func multiplyWithOverflow(lhs: BarBeatTime, var _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    rhs.base = lhs.base
    let (ticks, overflow) = MIDITimeStamp.multiplyWithOverflow(lhs.ticks, rhs.ticks)
    let result = BarBeatTime(tickValue: ticks,
                             beatsPerBar: lhs.beatsPerBar,
                             subbeatDivisor: lhs.subbeatDivisor,
                             beatsPerMinute: lhs.beatsPerMinute,
                             base: lhs.base)
    return (result, overflow)
  }
  static func remainderWithOverflow(lhs: BarBeatTime, var _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    rhs.base = lhs.base
    let (ticks, overflow) = MIDITimeStamp.remainderWithOverflow(lhs.ticks, rhs.ticks)
    let result = BarBeatTime(tickValue: ticks,
                             beatsPerBar: lhs.beatsPerBar,
                             subbeatDivisor: lhs.subbeatDivisor,
                             beatsPerMinute: lhs.beatsPerMinute,
                             base: lhs.base)
    return (result, overflow)
  }
  static func divideWithOverflow(lhs: BarBeatTime, var _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool) {
    rhs.base = lhs.base
    let (ticks, overflow) = MIDITimeStamp.divideWithOverflow(lhs.ticks, rhs.ticks)
    let result = BarBeatTime(tickValue: ticks,
                             beatsPerBar: lhs.beatsPerBar,
                             subbeatDivisor: lhs.subbeatDivisor,
                             beatsPerMinute: lhs.beatsPerMinute,
                             base: lhs.base)
    return (result, overflow)
  }

  static var allZeros: BarBeatTime { return start0 }

}

func +(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {

  rhs.base = lhs.base
  let subbeats = (lhs.subbeatFraction + rhs.subbeatFraction).fractionWithBase(lhs.subbeatFraction.denominator)
  let beats = (lhs.beatFraction + rhs.beatFraction).fractionWithBase(lhs.beatFraction.denominator)
  let bars = lhs.bar + rhs.bar

  var result = BarBeatTime(bar: bars,
                           beat: UInt(beats.numerator),
                           subbeat: UInt(subbeats.numerator),
                           subbeatDivisor: lhs.subbeatDivisor,
                           beatsPerBar: lhs.beatsPerBar,
                           base: lhs.base)

  result.normalize()

  return result
}

func -(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  var subbeats = (lhs.subbeatFraction - rhs.subbeatFraction).fractionWithBase(lhs.subbeatFraction.denominator)
  var beats = (lhs.beatFraction - rhs.beatFraction).fractionWithBase(lhs.beatFraction.denominator)
  var bars = lhs.bar - rhs.bar

  while subbeats.numerator < 0 {
    beats.numerator--
    subbeats.numerator += subbeats.denominator
  }

  while beats.numerator < 0 {
    bars--
    beats.numerator += beats.denominator
  }

  var result = BarBeatTime(bar: bars,
                           beat: UInt(beats.numerator),
                           subbeat: UInt(subbeats.numerator),
                           subbeatDivisor: lhs.subbeatDivisor,
                           beatsPerBar: lhs.beatsPerBar,
                           base: lhs.base)

  result.normalize()

  return result
}

prefix func -(var value: BarBeatTime) -> BarBeatTime {
  value.bar *= -1
  return value
}

func *(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  return BarBeatTime(tickValue: lhs.ticks * rhs.ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func /(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  return BarBeatTime(tickValue: lhs.ticks / rhs.ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func %(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  return BarBeatTime(tickValue: lhs.ticks % rhs.ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func &(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  let ticks = lhs.ticks & rhs.ticks
  return BarBeatTime(tickValue: ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func ^(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  let ticks = lhs.ticks ^ rhs.ticks
  return BarBeatTime(tickValue: ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

func |(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  let ticks = lhs.ticks | rhs.ticks
  return BarBeatTime(tickValue: ticks,
                     beatsPerBar: lhs.beatsPerBar,
                     subbeatDivisor: lhs.subbeatDivisor,
                     beatsPerMinute: lhs.beatsPerMinute,
                     base: lhs.base)
}

prefix func ~(value: BarBeatTime) -> BarBeatTime {
  let ticks = ~value.ticks
  return BarBeatTime(tickValue: ticks,
                     beatsPerBar: value.beatsPerBar,
                     subbeatDivisor: value.subbeatDivisor,
                     beatsPerMinute: value.beatsPerMinute,
                     base: value.base)
}

// MARK: - Comparable
extension BarBeatTime: Comparable {}

func <(lhs: BarBeatTime, var rhs: BarBeatTime) -> Bool {
  rhs.base = lhs.base
  guard lhs.bar == rhs.bar else { return lhs.bar < rhs.bar }
  guard lhs.beat == rhs.beat else { return lhs.beat < rhs.beat }
  guard lhs.subbeatDivisor != rhs.subbeatDivisor else { return lhs.subbeat < rhs.subbeat }
  return lhs.subbeat╱lhs.subbeatDivisor < rhs.subbeat╱rhs.subbeatDivisor
}
