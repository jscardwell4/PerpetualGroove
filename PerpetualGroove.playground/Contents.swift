//: Playground - noun: a place where people can play

import Foundation
import MoonKit

struct Sequencer {
  static let partsPerQuarter = 480
  static let beatsPerMinute = 120
  static let beatsPerBar = 4
}

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

  /// The number of complete bars
  ///
  /// Must satisfy `bar >= 0` to qualify as 'normal'.
  var bar = 0

  /// The number of complete beats. 
  ///
  /// Must satisfy `1...beatsPerBar ∋ beat` to qualify as 'normal'
  var beat = 0

  /// The number of subbeats.
  ///
  /// Must satisfy `1...subbeatDivisor ∋ subbeat` to qualify as 'normal'
  var subbeat = 0

  /// The number of subbeats per beat
  var subbeatDivisor = Sequencer.partsPerQuarter

  /// The number of beats per bar
  var beatsPerBar = Sequencer.beatsPerBar

  /// The number of beats per minute. This value is used when converting to/from seconds.
  var beatsPerMinute = Sequencer.beatsPerMinute

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
       beat: Int = 0,
       subbeat: Int = 0,
       subbeatDivisor: Int = Sequencer.partsPerQuarter,
       beatsPerBar: Int = Sequencer.beatsPerBar,
       beatsPerMinute: Int = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    self.bar = bar
    self.beat = beat
    self.subbeat = subbeat
    self.subbeatDivisor = subbeatDivisor
    self.beatsPerBar = beatsPerBar
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
          bar += beat / beatsPerBar
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
          bar += beat / beatsPerBar
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
  static let null  = BarBeatTime(bar: -1, beat: -1, subbeat: -1)

  /**
   Initialize with a tick value

   - parameter tickValue: MIDITimeStamp
   - parameter beatsPerBar: UInt8 = Sequencer.beatsPerBar
   - parameter subbeatDivisor: UInt16 = Sequencer.time.partsPerQuarter
   - parameter beatsPerMinute: Int = Sequencer.beatsPerMinute
   - parameter base: Base = .Zero
   */
  init(tickValue: MIDITimeStamp,
       beatsPerBar: Int = Sequencer.beatsPerBar,
       subbeatDivisor: Int = Sequencer.partsPerQuarter,
       beatsPerMinute: Int = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    let subbeat = Int(tickValue % MIDITimeStamp(subbeatDivisor)) + base.rawValue
    guard tickValue > MIDITimeStamp(subbeat) else {
      self = BarBeatTime(bar: base.rawValue,
                         beat: base.rawValue,
                         subbeat: subbeat,
                         subbeatDivisor: subbeatDivisor,
                         beatsPerBar: beatsPerBar,
                         base: base)
      return
    }
    let totalBeats = (tickValue - MIDITimeStamp(subbeat)) / MIDITimeStamp(subbeatDivisor)
    let beat = Int(totalBeats % MIDITimeStamp(beatsPerBar)) + base.rawValue
    let bar = Int(totalBeats / MIDITimeStamp(beatsPerBar)) + base.rawValue
    self = BarBeatTime(bar: bar,
                       beat: beat,
                       subbeat: subbeat,
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
       beatsPerBar: Int = Sequencer.beatsPerBar,
       subbeatDivisor: Int = Sequencer.partsPerQuarter,
       beatsPerMinute: Int = Sequencer.beatsPerMinute,
       base: Base = .Zero)
  {
    let beatsPerSecond = NSTimeInterval(beatsPerMinute) / 60
    let totalBeats = seconds * beatsPerSecond
    let bar = Int(totalBeats) / beatsPerBar + base.rawValue
    let beat = Int(totalBeats) % beatsPerBar + base.rawValue
    let subbeat = Int(totalBeats % 1 * NSTimeInterval(subbeatDivisor)) + base.rawValue
    self.init(bar: bar,
              beat: beat,
              subbeat: subbeat,
              subbeatDivisor: subbeatDivisor,
              beatsPerBar: beatsPerBar,
              beatsPerMinute: beatsPerMinute,
              base: base)
  }

  /// The time's value in seconds
  var seconds: NSTimeInterval {
    let beatsPerSecond = NSTimeInterval(beatsPerMinute) / 60
    let wholeBeats = NSTimeInterval((bar - base.rawValue) * beatsPerBar + beat - base.rawValue)
    let fractionalBeat = NSTimeInterval(subbeat) / NSTimeInterval(subbeatDivisor)
    let totalBeats = wholeBeats + fractionalBeat
    return totalBeats / beatsPerSecond
  }

  /// The time's value in ticks
  var ticks: MIDITimeStamp {
    let bar = MIDITimeStamp(max(self.bar - base.rawValue, 0))
    let beat = MIDITimeStamp(max(self.beat - base.rawValue, 0))
    let subbeat = MIDITimeStamp(max(self.subbeat - base.rawValue, 0))
    return (bar * MIDITimeStamp(beatsPerBar) + beat) * MIDITimeStamp(subbeatDivisor) + subbeat
  }
}

func +(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {

  rhs.base = lhs.base
  let beatsPerBar = lcm(lhs.beatsPerBar, rhs.beatsPerBar)
  let lhsBeat = (lhs.beat╱lhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let rhsBeat = (rhs.beat╱rhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let subbeatDivisor = lcm(lhs.subbeatDivisor, rhs.subbeatDivisor)
  let lhsSubbeat = (lhs.subbeat╱lhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  let rhsSubbeat = (rhs.subbeat╱rhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  var result = BarBeatTime(bar: lhs.bar + rhs.bar,
                           beat: lhsBeat.numerator + rhsBeat.numerator,
                           subbeat: lhsSubbeat.numerator + rhsSubbeat.numerator,
                           subbeatDivisor: subbeatDivisor,
                           beatsPerBar: beatsPerBar,
                           base: lhs.base)

  result.normalize()

  return result
}

func -(lhs: BarBeatTime, var rhs: BarBeatTime) -> BarBeatTime {
  rhs.base = lhs.base
  let beatsPerBar = lcm(lhs.beatsPerBar, rhs.beatsPerBar)
  let lhsBeat = (lhs.beat╱lhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let rhsBeat = (rhs.beat╱rhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let subbeatDivisor = lcm(lhs.subbeatDivisor, rhs.subbeatDivisor)
  let lhsSubbeat = (lhs.subbeat╱lhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  let rhsSubbeat = (rhs.subbeat╱rhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  var result = BarBeatTime(bar: lhs.bar - rhs.bar,
                           beat: lhsBeat.numerator - rhsBeat.numerator,
                           subbeat: lhsSubbeat.numerator - rhsSubbeat.numerator,
                           subbeatDivisor: subbeatDivisor,
                           beatsPerBar: beatsPerBar,
                           base: lhs.base)

  result.normalize()

  return result
}

// MARK: - CustomStringConvertible
extension BarBeatTime: CustomStringConvertible {
  var description: String {
    let barString = String(bar, radix: 10, pad: 3)
    let beatString = String(beat)
    let subbeatString = String(subbeat, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(barString):\(beatString).\(subbeatString)"
  }
}

extension BarBeatTime: CustomPlaygroundQuickLookable {
  func customPlaygroundQuickLook() -> PlaygroundQuickLook { return .Text(rawValue) }
}

// MARK: - CustomDebugStringConvertible
extension BarBeatTime: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Hashable
extension BarBeatTime: Hashable {
  var hashValue: Int { return rawValue.hashValue }
}

extension BarBeatTime: RawRepresentable {
  var rawValue: String { return "\(bar):\(beat)/\(beatsPerBar).\(subbeat)/\(subbeatDivisor)@\(beatsPerMinute)\(base.string)" }

  /**
   initWithRawValue:

   - parameter rawValue: String
   */
  init?(rawValue: String) {
    let pattern = "".join(
      "^",
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
              bar = Int(barString),
              beat = Int(beatString),
              subbeat = Int(subbeatString) else { return nil }
    let beatsPerBar: Int
    let beatsPerMinute: Int
    let subbeatDivisor: Int
    let base: Base
    if let beatsPerBarString = match["beatsPerBar"]?.string, beatsPerBarInt = Int(beatsPerBarString) {
      beatsPerBar = beatsPerBarInt
    } else {
      beatsPerBar = Sequencer.beatsPerBar
    }
    if let subbeatDivisorString = match["subbeatDivisor"]?.string, subbeatDivisorInt = Int(subbeatDivisorString) {
      subbeatDivisor = subbeatDivisorInt
    } else {
      subbeatDivisor = Sequencer.partsPerQuarter
    }
    if let beatsPerMinuteString = match["beatsPerMinute"]?.string, beatsPerMinuteInt = Int(beatsPerMinuteString) {
      beatsPerMinute = beatsPerMinuteInt
    } else {
      beatsPerMinute = Sequencer.beatsPerMinute
    }
    if let baseString = match["base"]?.string where baseString == "₁" { base = .One } else { base = .Zero }
    self.init(bar: bar,
              beat: beat,
              subbeat: subbeat,
              subbeatDivisor: subbeatDivisor,
              beatsPerBar: beatsPerBar,
              beatsPerMinute: beatsPerMinute,
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

func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return lhs.rawValue == rhs.rawValue }

extension BarBeatTime: ForwardIndexType {
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

// MARK: - Comparable
extension BarBeatTime: Comparable {}

func <(lhs: BarBeatTime, var rhs: BarBeatTime) -> Bool {
  rhs.base = lhs.base
  guard lhs.bar == rhs.bar else { return lhs.bar < rhs.bar }
  guard lhs.beat == rhs.beat else { return lhs.beat < rhs.beat }
  guard lhs.subbeatDivisor != rhs.subbeatDivisor else { return lhs.subbeat < rhs.subbeat }
  return lhs.subbeat╱lhs.subbeatDivisor < rhs.subbeat╱rhs.subbeatDivisor
}


struct Trajectory {

  /// The constant used to adjust the velocity units when calculating times
  static let modifier: Ratio<CGFloat> = 1∶100

  /// The ticks per cartesian point. Can be calculated with a segment along the trajectory 
  /// by dividing the segment's total elapsed ticks by the length of the segment.
  static let ticksPerPoint = 6.22897042913752

  /// The cartesian points per tick. Can be calculated with a segment along the trajectory
  /// by dividing the length of the segment by the segment's total elapsed ticks.
  static let pointsPerTick = 0.160540174556337

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

  /// Type for specifiying the direction of a `Trajectory`.
  enum Direction: Equatable {
    enum VerticalMovement: Equatable { case None, Up, Down }
    enum HorizontalMovement: Equatable { case None, Left, Right }

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

  }

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
  func pointAtX(x: CGFloat) -> CGPoint { return CGPoint(x: x, y: m * (x - p.x) + p.y) }

  /**
   The point along the trajectory with the specified y value
         
       x = (y - y<sub>1</sub> + mx<sub>1</sub>) / m

   - parameter y: CGFloat

    - returns: CGPoint
  */
  func pointAtY(y: CGFloat) -> CGPoint { return CGPoint(x: (y - p.y + m * p.x) / m, y: y) }

  /**
   Elapsed time in seconds between the two points along the trajectory with the respective x values specified.

   - parameter x1: CGFloat
   - parameter x2: CGFloat

    - returns: NSTimeInterval
  */
  func timeFromX(x1: CGFloat, toX x2: CGFloat) -> NSTimeInterval { return timeFromPoint(pointAtX(x1), toPoint: pointAtX(x2)) }

  /**
   Elapsed time in seconds between the two points along the trajectory with the respective y values specified.

   - parameter y1: CGFloat
   - parameter y2: CGFloat

    - returns: NSTimeInterval
  */
  func timeFromY(y1: CGFloat, toY y2: CGFloat) -> NSTimeInterval { return timeFromPoint(pointAtY(y1), toPoint: pointAtY(y2)) }

  /**
   Elapsed time in seconds between the specified points

   - parameter p1: CGPoint
   - parameter p2: CGPoint

    - returns: NSTimeInterval
  */
  func timeFromPoint(p1: CGPoint, toPoint p2: CGPoint) -> NSTimeInterval {
    return abs(NSTimeInterval(p1.distanceTo(p2) / m * Trajectory.modifier))
  }

  /**
   The point along trajectory given the specified delta time.

   - parameter time: NSTimeInterval

    - returns: CGPoint
  */
  func pointAtTime(time: NSTimeInterval) -> CGPoint { return pointAtTime(BarBeatTime(seconds: time)) }

  /**
   The point along trajectory given the specified delta time.

   - parameter time: BarBeatTime

    - returns: CGPoint
  */
  func pointAtTime(time: BarBeatTime) -> CGPoint {
    let distance = CGFloat(time.ticks) * CGFloat(Trajectory.pointsPerTick)
    let y = distance * m / sqrt(1 + pow(m, 2)) + p.y
    return pointAtY(y)
  }

  /**
   Whether the specified point lies along the trajectory (approximated by rounding to three decimal places).

   - parameter point: CGPoint

    - returns: Bool
  */
  func containsPoint(point: CGPoint) -> Bool {
    let lhs = abs((point.y - p.y).rounded(3))
    let rhs = abs((m * (point.x - p.x)).rounded(3))
    return lhs == rhs
  }

//  static let zero = Trajectory(vector: CGVector.zero, point: CGPoint.zero)

  /// Trajectory value for representing a 'null' or 'invalid' trajectory
  static let null = Trajectory(vector: CGVector.zero, point: CGPoint.null)
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
  var description: String { return "{ x: \(x); y: \(y); dx: \(dx); dy: \(dy) }" }
}

extension Trajectory: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

final class MIDINodePath {


  private var segments = Tree<Segment>()

  private let min: CGPoint
  private let max: CGPoint

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
    segments.insert(Segment(trajectory: trajectory, time: time, path: self))
  }

  /**
   locationForTime:

   - parameter time: NSTimeInterval

    - returns: CGPoint?
  */
  func locationForTime(time: BarBeatTime) -> CGPoint? {
    return segmentForTime(time)?.locationForTime(time)
  }

  /**
   nextLocationForTime:

   - parameter time: BarBeatTime

    - returns: CGPoint?
  */
  func nextLocationForTime(time: BarBeatTime, fromPoint point: CGPoint) -> (CGPoint, NSTimeInterval)? {
    guard let segment = segmentForTime(time) else { return nil }
    return (segment.endLocation, segment.timeToEndLocationFromPoint(point))
  }

  /**
   segmentForTime:

   - parameter time: BarBeatTime

    - returns: Segment?
  */
  func segmentForTime(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments.find({$0.endTime < time}, {$0.timeInterval ∋ time}) { return segment }
    guard let segment = segments.maxElement() else { fatalError("segments is empty, no max element") }

    var currentSegment = segment
    while currentSegment.endTime < time { currentSegment = currentSegment.successor }
    return currentSegment
  }

}

extension MIDINodePath: CustomStringConvertible {
  var description: String {
    return "MIDINodePath {\n\t" + "\n\t".join(
      "min: \(min)",
      "max: \(max)",
      "startTime: \(startTime)",
      "initialTrajectory: \(initialTrajectory)",
      "segments: [\n\t\t\(",\n\t\t".join(segments.map({$0.description.indentedBy(2, preserveFirst: true, useTabs: true)})))\n\t]"
      ) + "\n}"
  }
}

import typealias AudioToolbox.MIDITimeStamp

final class Segment: Equatable, Comparable, CustomStringConvertible {
  let trajectory: Trajectory

  let startTime: BarBeatTime
  let endTime: BarBeatTime

  var startTicks: MIDITimeStamp { return startTime.ticks }
  var endTicks: MIDITimeStamp { return endTime.ticks }
  var totalTicks: MIDITimeStamp { return endTicks > startTicks ? endTicks - startTicks : 0 }

  private weak var _successor: Segment?

  var successor: Segment {
    guard _successor == nil else { return _successor! }
    let segment = advance()
    segment.predessor = self
    _successor = segment
    path.segments.insert(segment)
    return segment
  }

  weak var predessor: Segment?

  var timeInterval: HalfOpenInterval<BarBeatTime> { return startTime ..< endTime }
  var tickInterval: HalfOpenInterval<MIDITimeStamp> { return startTicks ..< endTicks }

  unowned let path: MIDINodePath

  var startLocation: CGPoint { return trajectory.p }
  let endLocation: CGPoint

  var distance: CGFloat { return startLocation.distanceTo(endLocation) }

  /**
   locationForTime:

   - parameter time: NSTimeInterval

   - returns: CGPoint?
   */
  func locationForTime(time: BarBeatTime) -> CGPoint? {
    guard timeInterval ∋ time else { return nil }
    return trajectory.pointAtTime(time.seconds - startTime.seconds)
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
   - parameter path: MIDINodePath
   */
  init(trajectory: Trajectory, time: BarBeatTime, path: MIDINodePath) {
    self.trajectory = trajectory
    self.startTime = time
    self.path = path

    let endY: CGFloat

    switch trajectory.direction.vertical {
      case .None: endY = trajectory.p.y
      case .Up:   endY = path.max.y
      case .Down: endY = path.min.y
    }

    let pY: CGPoint? = {
      let p = trajectory.pointAtY(endY)
      guard (path.min.x ... path.max.x).contains(p.x) else { return nil }
      return p
    }()

    let endX: CGFloat

    switch trajectory.direction.horizontal {
      case .None:  endX = trajectory.p.x
      case .Left:  endX = path.min.x
      case .Right: endX = path.max.x
    }

    let pX: CGPoint? = {
      let p = trajectory.pointAtX(endX)
      guard (path.min.y ... path.max.y).contains(p.y) else { return nil }
      return p
    }()

    switch (pY, pX) {
      case (let p1?, let p2?) where trajectory.p.distanceTo(p1) < trajectory.p.distanceTo(p2): endLocation = p1
      case (_, let p?): endLocation = p
      case (let p?, _): endLocation = p
      default: fatalError("at least one of projected end points should be valid")
    }

    time
    let 𝝙t = trajectory.timeFromPoint(trajectory.p, toPoint: endLocation)
    let t = time.seconds
    let tʹ = BarBeatTime(seconds: t + 𝝙t, base: .One)
    let end = tʹ
    time < tʹ
    time.ticks
    end.ticks
    endTime = tʹ//time// + BarBeatTime(seconds: abs(trajectory.timeFromPoint(trajectory.p, toPoint: endLocation)))
  }

  /**
   advance

   - returns: Segment
   */
  private func advance() -> Segment {
    // Redirect trajectory according to which boundary edge the new location touches
    let v: CGVector
    switch endLocation.unpack {
    case (path.min.x, _), (path.max.x, _):
      v = CGVector(dx: trajectory.dx * -1, dy: trajectory.dy)
    case (_, path.min.y), (_, path.max.y):
      v = CGVector(dx: trajectory.dx, dy: trajectory.dy * -1)
    default:
      fatalError("next location should contact an edge of the player")
    }

    let nextTrajectory = Trajectory(vector: v, point: endLocation)
    return Segment(trajectory: nextTrajectory, time: endTime, path: path)
  }

  var description: String {
    return "Segment {\n\t" + "\n\t".join(
      "trajectory: \(trajectory)",
      "endLocation: \(endLocation)",
      "timeInterval: \(timeInterval)",
      "totalTime: \(endTime.zeroBased - startTime.zeroBased)",
      "tickInterval: \(tickInterval)",
      "totalTicks: \(totalTicks)",
      "distance: \(distance)"
      ) + "\n}"
  }

}


func ==(lhs: Segment, rhs: Segment) -> Bool {
  return lhs.startTime == rhs.startTime
}

func <(lhs: Segment, rhs: Segment) -> Bool {
  return lhs.startTime < rhs.startTime
}

let time4: BarBeatTime = "0:2/4.400/480@120₀"
let time5: BarBeatTime = "0:0/4.90/480@120₀"
time4.ticks
time5.ticks
Int(time5.ticks) - Int(time4.ticks)
BarBeatTime(tickValue: 1270)

let t: BarBeatTime = "3:3/4.54/480@120₁"
("3:3/4.54/480@120₁" as BarBeatTime).seconds
("4:1/4.3/480@120₁" as BarBeatTime).seconds
("1:1/4.2/480@120₁" as BarBeatTime).ticks
("0:1/4.3/480@120₀" as BarBeatTime).ticks
let point = CGPoint(x: 206.8070373535156, y: 143.2811126708984)
let velocity = CGVector(dx: 144.9763520779608, dy: -223.41468148063581)
let playerSize = CGSize(width: 447, height: 447)
let trajectory = Trajectory(vector: velocity, point: point)
let path = MIDINodePath(trajectory: trajectory, playerSize: playerSize, time: t)

1.0∶100.0 * 144.9763520779608

print(trajectory)
var testTime = BarBeatTime(bar: 0, beat: 1, subbeat: 428)
testTime.ticks
testTime.base = .One
testTime.ticks
testTime.base = .Zero
testTime.ticks
//let segment = path.segmentForTime("10:1/4.1/480")
print(path)
trajectory.pointAtTime("0:1.429₀")
