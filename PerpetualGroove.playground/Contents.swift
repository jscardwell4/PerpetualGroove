//: Playground - noun: a place where people can play

import Foundation
import MoonKit
import typealias CoreMIDI.MIDITimeStamp

//////////// BarBeatTime

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
  var bar: UInt = 0

  private var rawBar: UInt { return bar - base.rawValue }

  /// The number of complete beats. 
  var beat: UInt { get { return beatFraction.numerator } set { beatFraction.numerator = newValue } }

  private var rawBeat: UInt { return beat - base.rawValue }

  /// The number of subbeats.
  var subbeat: UInt {
    get { return subbeatFraction.numerator }
    set { subbeatFraction.numerator = newValue }
  }

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
  var beatsPerMinute: UInt = 120

  private var beatFraction: Fraction<UInt> = 0╱4

  private var subbeatFraction: Fraction<UInt> = 0╱480

  /// The time's zero-based representation
  var zeroBased: BarBeatTime {
    guard base != .Zero else { return self }
    var result = self
    result.base = .Zero
    return result
  }

  /// The time's one-based representation
  var oneBased: BarBeatTime {
    guard base != .One else { return self }
    var result = self
    result.base = .One
    return result
  }

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
       subbeatDivisor: UInt = 480,
       beatsPerBar: UInt = 4,
       beatsPerMinute: UInt = 120,
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

  /// A bar-beat time for representing a null value
  static let null = BarBeatTime(subbeatDivisor: 0, beatsPerBar: 0, beatsPerMinute: 0)

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
       beatsPerBar: UInt = 4,
       subbeatDivisor: UInt = 480,
       beatsPerMinute: UInt = 120,
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
       beatsPerBar: UInt = 4,
       subbeatDivisor: UInt = 480,
       beatsPerMinute: UInt = 120,
       base: Base = .Zero,
       negative: Bool = false)
  {
    let totalBeats = seconds * (NSTimeInterval(beatsPerMinute) / 60)
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
       beatsPerBar: UInt = 4,
       subbeatDivisor: UInt = 480,
       beatsPerMinute: UInt = 120,
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

  var secondsPerBeat: NSTimeInterval {
    return 1 / (NSTimeInterval(beatsPerMinute) / 60)
  }

  /// The time's value in seconds
  var seconds: NSTimeInterval { return totalBeats * secondsPerBeat }

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
    let beatsPerMinute: UInt
    let subbeatDivisor: UInt
    let base: Base
    let negative = match["negative"] != nil
    if let beatsPerBarString = match["beatsPerBar"]?.string, beatsPerBarUInt = UInt(beatsPerBarString) {
      beatsPerBar = beatsPerBarUInt
    } else {
      beatsPerBar = 4
    }
    if let subbeatDivisorString = match["subbeatDivisor"]?.string,
           subbeatDivisorUInt = UInt(subbeatDivisorString) {
           subbeatDivisor = subbeatDivisorUInt
    } else {
      subbeatDivisor = 480
    }
    if let beatsPerMinuteString = match["beatsPerMinute"]?.string, beatsPerMinuteUInt = UInt(beatsPerMinuteString) {
      beatsPerMinute = beatsPerMinuteUInt
    } else {
      beatsPerMinute = 120
    }
    if let baseString = match["base"]?.string where baseString == "₁" { base = .One } else {
      base = .Zero
    }
    self.init(bar: bar,
              beat: beat,
              subbeat: subbeat,
              subbeatDivisor: subbeatDivisor,
              beatsPerBar: beatsPerBar,
              beatsPerMinute: beatsPerMinute,
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
    var result = self
    result.subbeat++
    result.normalize()
    return result
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

//////////// Trajectory

struct Trajectory {

  /// The constant used to adjust the velocity units when calculating times
  static let modifier: Ratio<CGFloat> = 1∶1000

  /// The slope of the trajectory (`dy` / `dx`)
  var m: CGFloat { return dy / dx }

  /// The velocity in units along the lines of those used by `SpriteKit`.
  var v: CGVector { return CGVector(dx: dx, dy: dy) }

  /// The initial point
  var p: CGPoint { return CGPoint(x: x, y: y) }

  /// The direction specified by the trajectory
  var direction: Direction {
    get { return Direction(vector: v) }
    set {
      guard direction != newValue else { return }
      switch (direction.vertical, newValue.vertical) {
        case (.Up, .Down), (.Down, .Up): dy *= -1
        case (_, .None): dy = 0
        default: break
      }
      switch (direction.horizontal, newValue.horizontal) {
        case (.Left, .Right), (.Right, .Left): dx *= -1
        case (_, .None): dx = 0
        default: break
      }
    }
  }

  /// The horizontal velocity in units along the lines of those used by `SpriteKit`.
  var dx: CGFloat

  /// The vertical velocity in units along the lines of those used by `SpriteKit`.
  var dy: CGFloat

  /// The initial position along the x axis
  var x: CGFloat

  /// The initial position along the y axis
  var y: CGFloat

  /**
   Default initializer

   - parameter vector: CGVector
   - parameter p: CGPoint
  */
  init(vector: CGVector, point: CGPoint) { dx = vector.dx; dy = vector.dy; x = point.x; y = point.y }

  /**
   The point along the trajectory with the specified x value

       y = m (x - x<sub>1</sub>) + y<sub>1</sub>

   - parameter x: CGFloat

    - returns: CGPoint
  */
  func pointAtX(x: CGFloat) -> CGPoint {
    let result = CGPoint(x: x, y: m * (x - p.x) + p.y)
//    logVerbose("self = \(self)\nx = \(x)\nresult = \(result)")
    return result
  }

  /**
   The point along the trajectory with the specified y value
         
       x = (y - y<sub>1</sub> + mx<sub>1</sub>) / m

   - parameter y: CGFloat

    - returns: CGPoint
  */
  func pointAtY(y: CGFloat) -> CGPoint {
    let result = CGPoint(x: (y - p.y + m * p.x) / m, y: y)
//    logVerbose("self = \(self)\ny = \(y)\nresult = \(result)")
    return result
  }

  /**
   Elapsed time in seconds between the two points along the trajectory with the respective x values specified.

   - parameter x1: CGFloat
   - parameter x2: CGFloat

    - returns: NSTimeInterval
  */
  func timeFromX(x1: CGFloat, toX x2: CGFloat) -> NSTimeInterval {
    return timeFromPoint(pointAtX(x1), toPoint: pointAtX(x2))
  }

  /**
   Elapsed time in seconds between the two points along the trajectory with the respective y values specified.

   - parameter y1: CGFloat
   - parameter y2: CGFloat

    - returns: NSTimeInterval
  */
  func timeFromY(y1: CGFloat, toY y2: CGFloat) -> NSTimeInterval {
    return timeFromPoint(pointAtY(y1), toPoint: pointAtY(y2))
  }

  /**
   Elapsed time in seconds between the specified points

   - parameter p1: CGPoint
   - parameter p2: CGPoint

    - returns: NSTimeInterval
  */
  func timeFromPoint(p1: CGPoint, toPoint p2: CGPoint) -> NSTimeInterval {
    let result = abs(NSTimeInterval(p1.distanceTo(p2) / m)) * NSTimeInterval(Trajectory.modifier.value)
    guard result.isFinite else { fatalError("wtf") }
//    logVerbose("self = \(self)\np1 = \(p1)\np2 = \(p2)\nresult = \(result)")
    return result
  }

  /**
   The point along trajectory given the specified delta time.

   - parameter time: NSTimeInterval

    - returns: CGPoint
  */
//  func pointAtTime(time: NSTimeInterval) -> CGPoint {
//    return pointAtTime(BarBeatTime(seconds: time))
//  }

  /**
   The point along trajectory given the specified delta time.

   - parameter time: BarBeatTime

    - returns: CGPoint
  */
//  func pointAtTime(time: BarBeatTime) -> CGPoint {
//    return pointAtTime(time.ticks)
//  }

  /**
   The point along trajectory given the specified delta time.

   - parameter time: BarBeatTime

    - returns: CGPoint
  */
//  func pointAtTime(time: MIDITimeStamp) -> CGPoint {
//    let distance = CGFloat(time) * CGFloat(Trajectory.pointsPerTick)
//    let y = distance * m / sqrt(1 + pow(m, 2)) + p.y
//    let result = pointAtY(y)
//    logVerbose("self = \(self)\ntime = \(time)\ndistance = \(distance)\ny = \(y)\nresult = \(result)")
//    return result
//  }

  /**
   Whether the specified point lies along the trajectory (approximated by rounding to three decimal places).

   - parameter point: CGPoint

    - returns: Bool
  */
  func containsPoint(point: CGPoint) -> Bool {
    let lhs = abs((point.y - p.y).rounded(3))
    let rhs = abs((m * (point.x - p.x)).rounded(3))
    let result = lhs == rhs
//    logVerbose("self = \(self)\npoint = \(point)\nresult = \(result)")
    return result
  }

//  static let zero = Trajectory(vector: CGVector.zero, point: CGPoint.zero)

  /// Trajectory value for representing a 'null' or 'invalid' trajectory
  static let null = Trajectory(vector: CGVector.zero, point: CGPoint.null)
}

extension Trajectory {
  /// Type for specifiying the direction of a `Trajectory`.
  enum Direction: Equatable, CustomStringConvertible {
    enum VerticalMovement: String, Equatable { case None, Up, Down }
    enum HorizontalMovement: String, Equatable { case None, Left, Right }

    case None
    case Vertical (VerticalMovement)
    case Horizontal (HorizontalMovement)
    case Diagonal (VerticalMovement, HorizontalMovement)

    init(vector: CGVector) {
      switch (vector.dx, vector.dy) {
        case (0, 0):                                                  self = .None
        case (0, let dy) where dy.isSignMinus:                        self = .Vertical(.Down)
        case (0, _):                                                  self = .Vertical(.Up)
        case (let dx, 0) where dx.isSignMinus:                        self = .Horizontal(.Left)
        case (_, 0):                                                  self = .Horizontal(.Right)
        case (let dx, let dy) where dx.isSignMinus && dy.isSignMinus: self = .Diagonal(.Down, .Left)
        case (let dx, _) where dx.isSignMinus:                        self = .Diagonal(.Up, .Left)
        case (_, let dy) where dy.isSignMinus:                        self = .Diagonal(.Down, .Right)
        case (_, _):                                                  self = .Diagonal(.Up, .Right)
      }
    }

    init(start: CGPoint, end: CGPoint) {
      switch (start.unpack, end.unpack) {
        case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 == y2: self = .None
        case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 < y2:  self = .Vertical(.Up)
        case let ((x1,  _), (x2,  _)) where x1 == x2:             self = .Vertical(.Down)
        case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 == y2:  self = .Horizontal(.Right)
        case let (( _, y1), ( _, y2)) where y1 == y2:             self = .Horizontal(.Left)
        case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 < y2:   self = .Diagonal(.Up, .Right)
        case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 > y2:   self = .Diagonal(.Down, .Right)
        case let (( _, y1), ( _, y2)) where y1 < y2:              self = .Diagonal(.Up, .Left)
        case let (( _, y1), ( _, y2)) where y1 > y2:              self = .Diagonal(.Down, .Left)
        default:                                                  self = .None
      }
    }

    var vertical: VerticalMovement {
      get {
        switch self {
          case .Vertical(let movement):    return movement
          case .Diagonal(let movement, _): return movement
          default:                         return .None
        }
      }
      set {
        guard vertical != newValue else { return }
        switch self {
          case .Horizontal(let h):  self = .Diagonal(newValue, h)
          case .Vertical(_):        self = .Vertical(newValue)
          case .Diagonal(_, let h): self = .Diagonal(newValue, h)
          case .None:               self = .Vertical(newValue)
        }
      }
    }

    var horizontal: HorizontalMovement {
      get {
        switch self {
          case .Horizontal(let movement):  return movement
          case .Diagonal(_, let movement): return movement
          default:                         return .None
        }
      }
      set {
        guard horizontal != newValue else { return }
        switch self {
          case .Vertical(let v):    self = .Diagonal(v, newValue)
          case .Horizontal(_):      self = .Horizontal(newValue)
          case .Diagonal(let v, _): self = .Diagonal(v, newValue)
          case .None:               self = .Horizontal(newValue)
        }
      }
    }

    var reversed: Direction {
      switch self {
        case .Vertical(.Up):           return .Vertical(.Down)
        case .Vertical(.Down):         return .Vertical(.Up)
        case .Horizontal(.Left):       return .Horizontal(.Right)
        case .Horizontal(.Right):      return .Horizontal(.Left)
        case .Diagonal(.Up, .Left):    return .Diagonal(.Down, .Right)
        case .Diagonal(.Down, .Left):  return .Diagonal(.Up, .Right)
        case .Diagonal(.Up, .Right):   return .Diagonal(.Down, .Left)
        case .Diagonal(.Down, .Right): return .Diagonal(.Up, .Left)
        default:                       return .None
      }
    }

    var description: String {
      switch self {
        case .Vertical(let v):        return v.rawValue
        case .Horizontal(let h):      return h.rawValue
        case .Diagonal(let v, let h): return "-".join(v.rawValue, h.rawValue)
        case .None:                   return "None"
      }
    }
  }

}

func ==(lhs: Trajectory.Direction.VerticalMovement, rhs: Trajectory.Direction.VerticalMovement) -> Bool {
  switch (lhs, rhs) {
    case (.None, .None), (.Up, .Up), (.Down, .Down): return true
    default:                                         return false
  }
}
func ==(lhs: Trajectory.Direction.HorizontalMovement, rhs: Trajectory.Direction.HorizontalMovement) -> Bool {
  switch (lhs, rhs) {
    case (.None, .None), (.Left, .Left), (.Right, .Right): return true
    default:                                               return false
  }
}

func ==(lhs: Trajectory.Direction, rhs: Trajectory.Direction) -> Bool {
  return lhs.vertical == rhs.vertical && lhs.horizontal == rhs.horizontal
}

extension Trajectory: ByteArrayConvertible {

  /// A string representation of the Trajectory as an array of bytes.
  var bytes: [Byte] { return Array("{\(NSStringFromCGPoint(p)), \(NSStringFromCGVector(v))}".utf8) }

  /**
  Initializing with an array of bytes.

  - parameter bytes: [Byte]
  */
  init(_ bytes: [Byte]) {
    let string = String(bytes)
    let float = "-?[0-9]+(?:\\.[0-9]+)?"
    let value = "\\{\(float), \(float)\\}"
    guard let match = (~/"\\{(\(value)), (\(value))\\}").firstMatch(string, anchored: true),
      positionCapture = match.captures[1],
      vectorCapture = match.captures[2] else { self = .null; return }
    guard let point = CGPoint(positionCapture.string), vector = CGVector(vectorCapture.string) else {
      self = .null
      return
    }
    x = point.x; y = point.y
    dx = vector.dx; dy = vector.dy
  }
}

extension Trajectory: JSONValueConvertible {
  /// The json object for the trajectory
  var jsonValue: JSONValue { return ["p": p, "v": v] }
}

extension Trajectory: JSONValueInitializable {

  /**
   Initializing with a json value.

   - parameter jsonValue: JSONValue?
  */
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue), p = CGPoint(dict["p"]), v = CGVector(dict["v"]) else {
      return nil
    }
    self.init(vector: v, point: p)
  }
}

extension Trajectory: CustomStringConvertible {
  var description: String { return "{ x: \(x); y: \(y); dx: \(dx); dy: \(dy); direction: \(direction) }" }
}

extension Trajectory: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}


//////////// Segment

final class Segment: Equatable, Comparable, CustomStringConvertible {
  let trajectory: Trajectory

  let timeInterval: HalfOpenInterval<BarBeatTime>
  let tickInterval: HalfOpenInterval<MIDITimeStamp>

  var startTime: BarBeatTime { return timeInterval.start }
  var endTime: BarBeatTime { return timeInterval.end }
  var totalTime: BarBeatTime { return timeInterval.end - timeInterval.start }

  var startTicks: MIDITimeStamp { return tickInterval.start }
  var endTicks: MIDITimeStamp { return tickInterval.end }
  var totalTicks: MIDITimeStamp { return endTicks > startTicks ? endTicks - startTicks : 0 }

//  private weak var _successor: Segment?
//
//  var successor: Segment {
//    guard _successor == nil else { return _successor! }
//    let segment = advance()
//    segment.predessor = self
//    _successor = segment
//    path.insertSegment(segment)
//    return segment
//  }
//
//  weak var predessor: Segment?


//  unowned let path: MIDINodePath

  var startLocation: CGPoint { return trajectory.p }
  let endLocation: CGPoint
  let length: CGFloat

  /**
   locationForTime:

   - parameter time: NSTimeInterval

   - returns: CGPoint?
   */
  func locationForTime(time: BarBeatTime) -> CGPoint? {
    guard timeInterval ∋ time else { return nil }
    let 𝝙ticks = CGFloat(time.ticks - startTime.ticks)
    let ratio = 𝝙ticks / CGFloat(tickInterval.length)
    var result = trajectory.p
    result.x += ratio * (endLocation.x - result.x)
    result.y += ratio * (endLocation.y - result.y)
    return result
  }

  /**
   timeToEndLocationFromPoint:

   - parameter point: CGPoint

   - returns: NSTimeInterval
   */
  func timeToEndLocationFromPoint(point: CGPoint) -> NSTimeInterval {
    return trajectory.timeFromPoint(point, toPoint: endLocation)
  }

  /**
   initWithTrajectory:time:path:

   - parameter trajectory: Trajectory
   - parameter time: BarBeatTime
   - parameter min: CGPoint
   - parameter max: CGPoint
   */
  init(trajectory: Trajectory, time: BarBeatTime, min: CGPoint, max: CGPoint) {
    self.trajectory = trajectory
//    self.path = path

    let endY: CGFloat

    switch trajectory.direction.vertical {
      case .None: endY = trajectory.p.y
      case .Up:   endY = max.y
      case .Down: endY = min.y
    }

    let pY: CGPoint? = {
      let p = trajectory.pointAtY(endY)
      guard (min.x ... max.x).contains(p.x) else { return nil }
      return p
    }()

    let endX: CGFloat

    switch trajectory.direction.horizontal {
      case .None:  endX = trajectory.p.x
      case .Left:  endX = min.x
      case .Right: endX = max.x
    }

    let pX: CGPoint? = {
      let p = trajectory.pointAtX(endX)
      guard (min.y ... max.y).contains(p.y) else { return nil }
      return p
    }()

    switch (pY, pX) {
      case (let p1?, let p2?)
        where trajectory.p.distanceTo(p1) < trajectory.p.distanceTo(p2): endLocation = p1
      case (_, let p?): endLocation = p
      case (let p?, _): endLocation = p
      default: fatalError("at least one of projected end points should be valid")
    }

    length = trajectory.p.distanceTo(endLocation)

    let 𝝙t = trajectory.timeFromPoint(trajectory.p, toPoint: endLocation)
    let endTime = BarBeatTime(seconds: time.seconds + 𝝙t, base: .One)

    timeInterval = time ..< endTime
    tickInterval = timeInterval.start.ticks ..< timeInterval.end.ticks
  }

  /**
   advance

   - returns: Segment
   */
//  private func advance() -> Segment {
//    // Redirect trajectory according to which boundary edge the new location touches
//    let v: CGVector
//    switch endLocation.unpack {
//    case (path.min.x, _), (path.max.x, _):
//      v = CGVector(dx: trajectory.dx * -1, dy: trajectory.dy)
//    case (_, path.min.y), (_, path.max.y):
//      v = CGVector(dx: trajectory.dx, dy: trajectory.dy * -1)
//    default:
//      fatalError("next location should contact an edge of the player")
//    }
//
//    let nextTrajectory = Trajectory(vector: v, point: endLocation)
//    return Segment(trajectory: nextTrajectory, time: endTime, path: path)
//  }

  var description: String {
    return "Segment {\n\t" + "\n\t".join(
      "trajectory: \(trajectory)",
      "endLocation: \(endLocation)",
      "timeInterval: \(timeInterval)",
      "totalTime: \(endTime.zeroBased - startTime.zeroBased)",
      "tickInterval: \(tickInterval)",
      "totalTicks: \(totalTicks)",
      "length: \(length)"
      ) + "\n}"
  }

}



func ==(lhs: Segment, rhs: Segment) -> Bool {
  return lhs.startTime == rhs.startTime
}

func <(lhs: Segment, rhs: Segment) -> Bool {
  return lhs.startTime < rhs.startTime
}

//////////// MIDINodePath

final class MIDINodePath {


  private var segments: [Segment]
  private var segments2 =  Tree<Segment>()

  let min: CGPoint
  let max: CGPoint

  let startTime: BarBeatTime
  let initialTrajectory: Trajectory

  var initialSegment: Segment {
    guard let segment = segments.minElement() else {
      fatalError("segments is empty, no min element")
    }
    return segment
  }

  /**
   initWithTrajectory:playerSize:time:

   - parameter trajectory: Trajectory
   - parameter playerSize: CGSize
   - parameter time: BarBeatTime = .start
  */
  init(trajectory: Trajectory, playerSize: CGSize, time: BarBeatTime = .start1) {

    let offset = /*MIDINode.texture.size()*/ CGSize(square: 56) * 0.375
    max = CGPoint((playerSize - offset).unpack)
    min = CGPoint(offset.unpack)
    startTime = time
    initialTrajectory = trajectory
    segments = [Segment(trajectory: trajectory, time: time, min: min, max: max)]
    segments2.insert(segments[0])
  }


  /**
   insertSegment:

   - parameter segment: Segment
  */
//  func insertSegment(segment: Segment) { segments.insert(segment) }

  /**
   locationForTime:

   - parameter time: NSTimeInterval

    - returns: CGPoint?
  */
  func locationForTime(time: BarBeatTime) -> CGPoint? { return segmentForTime(time)?.locationForTime(time) }

  /**
   advanceSegment:

   - parameter segment: Segment

    - returns: Segment
  */
  private func advanceSegment(segment: Segment) -> Segment {
    // Redirect trajectory according to which boundary edge the new location touches
    let v: CGVector
    switch segment.endLocation.unpack {
    case (min.x, _), (max.x, _):
      v = CGVector(dx: segment.trajectory.dx * -1, dy: segment.trajectory.dy)
    case (_, min.y), (_, max.y):
      v = CGVector(dx: segment.trajectory.dx, dy: segment.trajectory.dy * -1)
    default:
      fatalError("next location should contact an edge of the player")
    }

    let nextTrajectory = Trajectory(vector: v, point: segment.endLocation)
    return Segment(trajectory: nextTrajectory, time: segment.endTime, min: min, max: max)

  }

  /**
   segmentForTime:

   - parameter time: BarBeatTime

    - returns: Segment?
  */
  func segmentForTime(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments.indexOf({$0.timeInterval ∋ time}) {//find({$0.endTime < time}, {$0.timeInterval ∋ time}) {
      return segments[segment]
    }
    guard let segment = segments.last else { fatalError("segments is empty, no max element") }
    guard segment.endTime < time else {
      fatalError("segment's end time is not less than time, a matching segment should have been found")
    }

    var currentSegment = segment
    while currentSegment.timeInterval ∌ time {
      currentSegment = advanceSegment(currentSegment)
      segments.append(currentSegment)
    }
//    logDebug("time = \(time)\nresult = \(currentSegment)")
    guard currentSegment.timeInterval ∋ time else {
      fatalError("segment to return does not contain time specified") // 1:2/4.196/480₁ ∉ 2:1/4.168/480₁ ..< 2:2/4.153/480₁
    }

    return currentSegment
  }

  func segmentForTime2(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments2.find({$0.endTime < time}, {$0.timeInterval ∋ time}) {
      return segment
    }
    guard let segment = segments2.maxElement() else { fatalError("segments is empty, no max element") }
    guard segment.endTime < time else {
      fatalError("segment's end time is not less than time, a matching segment should have been found")
    }

    var currentSegment = segment
    while currentSegment.timeInterval ∌ time {
      currentSegment = advanceSegment(currentSegment)
      segments2.insert(currentSegment)
    }
    //    logDebug("time = \(time)\nresult = \(currentSegment)")
    guard currentSegment.timeInterval ∋ time else {
      fatalError("segment to return does not contain time specified") // 1:2/4.196/480₁ ∉ 2:1/4.168/480₁ ..< 2:2/4.153/480₁
    }

    return currentSegment
  }

}

extension MIDINodePath: CustomStringConvertible, CustomDebugStringConvertible {
  private func makeDescription(debug debug: Bool = false) -> String {
    var result = "MIDINodePath {"
    if debug {
      result += "\n\t" + "\n\t".join(
        "min: \(min)",
        "max: \(max)",
        "startTime: \(startTime)",
        "initialTrajectory: \(initialTrajectory)",
        "segments: [\n\t\t\(",\n\t\t".join(segments.map({$0.description.indentedBy(2, preserveFirst: true, useTabs: true)})))\n\t]"
        ) + "\n"
    } else {
      result += "startTime: \(startTime); segments: \(segments.count)"
    }
    result += "}"
    return result
  }

  var description: String { return makeDescription() }
  var debugDescription: String { return makeDescription(debug: true) }
}


var wtfArray: [Int] = [4, 2, 1, 6, 7, 3, 2, 56].sort()
wtfArray
binarySearch(wtfArray, element: 6)
binarySearch(wtfArray, element: 4)
binarySearch(wtfArray, element: 2)
binarySearch(wtfArray, element: 1)
binarySearch(wtfArray, element: 7)
binarySearch(wtfArray, element: 3)
binarySearch(wtfArray, element: 56)
binarySearch(wtfArray, element: 49)

binaryInsertion(wtfArray, element: 29)
binaryInsertion(wtfArray, element: 0)
binaryInsertion(wtfArray, element: 8)
binaryInsertion(wtfArray, element: 3)
binaryInsertion(wtfArray, element: 12)
binaryInsertion(wtfArray, element: 200)
wtfArray.replaceRange(7..<8, with: [29, wtfArray[7]])
//let time: BarBeatTime = "3:3/4.54/480@120₁"
//let point = CGPoint(x: 206.8070373535156, y: 143.28111267089841)
//let velocity = CGVector(dx: 144.9763520779608, dy: -223.41468148063581)
//let trajectory = Trajectory(vector: velocity, point: point)
//let size = CGSize(square: 447)
//let path = MIDINodePath(trajectory: trajectory, playerSize: size, time: time)

//let time0: BarBeatTime = "4:1/4.22/480@120₁"
//let segment0 = path.segmentForTime(time0)
//print("segment0:", "\(segment0)")
//print("path: ", "\(path)")
//let time1: BarBeatTime = "10:1/4.250/480@120₁"
//let segment1 = path.segmentForTime2(time1)
//let time2: BarBeatTime = "6:3/4.210/480@120₁"
//let segment2 = path.segmentForTime(time2)
//print("segment2:", "\(segment2)")
//print("path: ", "\(path)")
//let time3: BarBeatTime = "7:3/4.261/480@120₁"
//let segment3 = path.segmentForTime(time3)


