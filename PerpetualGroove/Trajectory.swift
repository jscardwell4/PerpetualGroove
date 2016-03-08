//
//  Trajectory.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import typealias AudioToolbox.MIDITimeStamp

struct Trajectory {

  /// The constant used to adjust the velocity units when calculating times
  static let modifier: Ratio<CGFloat> = 1∶1000

  /// The ticks per cartesian point. Can be calculated with a segment along the trajectory 
  /// by dividing the segment's total elapsed ticks by the length of the segment.
//  static let ticksPerPoint = 6.22897042913752

  /// The cartesian points per tick. Can be calculated with a segment along the trajectory
  /// by dividing the length of the segment by the segment's total elapsed ticks.
//  static let pointsPerTick = 0.160540174556337

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

  /**
   rotate:

   - parameter radians: CGFloat

    - returns: Trajectory
  */
  func rotate(radians: CGFloat) -> Trajectory {
    var result = self
    result.rotateInPlace(radians)
    return result
  }

  /**
   rotateInPlace:

   - parameter radians: CGFloat
  */
  mutating func rotateInPlace(radians: CGFloat) { (dx, dy) = *v.rotate(radians) }

  /**
   rotateTo:

   - parameter angle: CGFloat

    - returns: Trajectory
  */
  func rotateTo(angle: CGFloat) -> Trajectory {
    var result = self
    result.rotateToInPlace(angle)
    return result
  }

  /**
   rotateToInPlace:

   - parameter angle: CGFloat
  */
  mutating func rotateToInPlace(angle: CGFloat) { self.angle = angle }

  /// The horizontal velocity in units along the lines of those used by `SpriteKit`.
  var dx: CGFloat

  /// The vertical velocity in units along the lines of those used by `SpriteKit`.
  var dy: CGFloat

  /// The initial position along the x axis
  var x: CGFloat

  /// The initial position along the y axis
  var y: CGFloat

  var angle: CGFloat {
    get { return v.angle }
    set { (dx, dy) = *v.rotateTo(newValue) }
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
  func pointAtX(x: CGFloat) -> CGPoint {
    let result = CGPoint(x: x, y: m * (x - p.x) + p.y)
    logVerbose("self = \(self)\nx = \(x)\nresult = \(result)")
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
    logVerbose("self = \(self)\ny = \(y)\nresult = \(result)")
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
    logVerbose("self = \(self)\np1 = \(p1)\np2 = \(p2)\nresult = \(result)")
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
    logVerbose("self = \(self)\npoint = \(point)\nresult = \(result)")
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
