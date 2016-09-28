//
//  Trajectory.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct CoreGraphics.CGFloat
import struct CoreGraphics.CGVector
import struct CoreGraphics.CGPoint
import func UIKit.NSStringFromCGPoint
import func UIKit.NSStringFromCGVector

struct Trajectory {

  /// The constant used to adjust the velocity units when calculating times
  static let modifier: Ratio = 1∶1000

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
        case (.up, .down), (.down, .up): dy *= -1
        case (_, .none): dy = 0
        default: break
      }
      switch (direction.horizontal, newValue.horizontal) {
        case (.left, .right), (.right, .left): dx *= -1
        case (_, .none): dx = 0
        default: break
      }
    }
  }

  func rotatedTo(angle: CGFloat) -> Trajectory { var result = self; result.angle = angle; return result }

  mutating func formRotatedTo(angle: CGFloat) { self.angle = angle }

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

  /// Default initializer
  init(vector: CGVector, point: CGPoint) { dx = vector.dx; dy = vector.dy; x = point.x; y = point.y }

  
   /// The point along the trajectory with the specified x value
   ///
   ///    y = m (x - x<sub>1</sub>) + y<sub>1</sub>
  func point(atX x: CGFloat) -> CGPoint {
    let result = CGPoint(x: x, y: m * (x - p.x) + p.y)
    logVerbose("self = \(self)\nx = \(x)\nresult = \(result)")
    return result
  }


  /// The point along the trajectory with the specified y value
  ///
  ///    x = (y - y<sub>1</sub> + mx<sub>1</sub>) / m
  func point(atY y: CGFloat) -> CGPoint {
    let result = CGPoint(x: (y - p.y + m * p.x) / m, y: y)
    logVerbose("self = \(self)\ny = \(y)\nresult = \(result)")
    return result
  }

  
  /// Elapsed time in seconds between the two points along the trajectory with the respective x values specified.
  func time(fromX x1: CGFloat, toX x2: CGFloat) -> TimeInterval {
    return time(fromPoint: point(atX: x1), toPoint: point(atX: x2))
  }

  
  /// Elapsed time in seconds between the two points along the trajectory with the respective y values specified.
  func time(fromY y1: CGFloat, toY y2: CGFloat) -> TimeInterval {
    return time(fromPoint: point(atY: y1), toPoint: point(atY: y2))
  }

  /// Elapsed time in seconds between the specified points
  func time(fromPoint p1: CGPoint, toPoint p2: CGPoint) -> TimeInterval {
    let result = abs(TimeInterval(p1.distanceTo(p2) / m)) * TimeInterval(Trajectory.modifier.fraction)
    guard result.isFinite else { fatalError("wtf") }
    logVerbose("self = \(self)\np1 = \(p1)\np2 = \(p2)\nresult = \(result)")
    return result
  }

  /// Whether the specified point lies along the trajectory (approximated by rounding to three decimal places).
  func contains(point: CGPoint) -> Bool {
    let lhs = abs((point.y - p.y).rounded(3))
    let rhs = abs((m * (point.x - p.x)).rounded(3))
    let result = lhs == rhs
    logVerbose("self = \(self)\npoint = \(point)\nresult = \(result)")
    return result
  }

  static var zero: Trajectory { return Trajectory(vector: CGVector.zero, point: CGPoint.zero) }

  /// Trajectory value for representing a 'null' or 'invalid' trajectory
  static var null: Trajectory { return Trajectory(vector: CGVector.zero, point: CGPoint.null) }
}

extension Trajectory {

  /// Type for specifiying the direction of a `Trajectory`.
  enum Direction: Equatable, CustomStringConvertible {
    enum VerticalMovement: String, Equatable { case none, up, down }
    enum HorizontalMovement: String, Equatable { case none, left, right }

    case none
    case vertical (VerticalMovement)
    case horizontal (HorizontalMovement)
    case diagonal (VerticalMovement, HorizontalMovement)

    init(vector: CGVector) {
      switch (vector.dx, vector.dy) {
        case (0, 0):                                                        self = .none
        case (0, let dy) where dy.sign == .minus:                           self = .vertical(.down)
        case (0, _):                                                        self = .vertical(.up)
        case (let dx, 0) where dx.sign == .minus:                           self = .horizontal(.left)
        case (_, 0):                                                        self = .horizontal(.right)
        case (let dx, let dy) where dx.sign == .minus && dy.sign == .minus: self = .diagonal(.down, .left)
        case (let dx, _) where dx.sign == .minus:                           self = .diagonal(.up, .left)
        case (_, let dy) where dy.sign == .minus:                           self = .diagonal(.down, .right)
        case (_, _):                                                        self = .diagonal(.up, .right)
      }
    }

    init(start: CGPoint, end: CGPoint) {
      switch (start.unpack, end.unpack) {
        case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 == y2: self = .none
        case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 < y2:  self = .vertical(.up)
        case let ((x1,  _), (x2,  _)) where x1 == x2:             self = .vertical(.down)
        case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 == y2:  self = .horizontal(.right)
        case let (( _, y1), ( _, y2)) where y1 == y2:             self = .horizontal(.left)
        case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 < y2:   self = .diagonal(.up, .right)
        case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 > y2:   self = .diagonal(.down, .right)
        case let (( _, y1), ( _, y2)) where y1 < y2:              self = .diagonal(.up, .left)
        case let (( _, y1), ( _, y2)) where y1 > y2:              self = .diagonal(.down, .left)
        default:                                                  self = .none
      }
    }

    var vertical: VerticalMovement {
      get {
        switch self {
          case .vertical(let movement):    return movement
          case .diagonal(let movement, _): return movement
          default:                         return .none
        }
      }
      set {
        guard vertical != newValue else { return }
        switch self {
          case .horizontal(let h):  self = .diagonal(newValue, h)
          case .vertical(_):        self = .vertical(newValue)
          case .diagonal(_, let h): self = .diagonal(newValue, h)
          case .none:               self = .vertical(newValue)
        }
      }
    }

    var horizontal: HorizontalMovement {
      get {
        switch self {
          case .horizontal(let movement):  return movement
          case .diagonal(_, let movement): return movement
          default:                         return .none
        }
      }
      set {
        guard horizontal != newValue else { return }
        switch self {
          case .vertical(let v):    self = .diagonal(v, newValue)
          case .horizontal(_):      self = .horizontal(newValue)
          case .diagonal(let v, _): self = .diagonal(v, newValue)
          case .none:               self = .horizontal(newValue)
        }
      }
    }

    var reversed: Direction {
      switch self {
        case .vertical(.up):           return .vertical(.down)
        case .vertical(.down):         return .vertical(.up)
        case .horizontal(.left):       return .horizontal(.right)
        case .horizontal(.right):      return .horizontal(.left)
        case .diagonal(.up, .left):    return .diagonal(.down, .right)
        case .diagonal(.down, .left):  return .diagonal(.up, .right)
        case .diagonal(.up, .right):   return .diagonal(.down, .left)
        case .diagonal(.down, .right): return .diagonal(.up, .left)
        default:                       return .none
      }
    }

    var description: String {
      switch self {
        case .vertical(let v):        return v.rawValue
        case .horizontal(let h):      return h.rawValue
        case .diagonal(let v, let h): return "-".join(v.rawValue, h.rawValue)
        case .none:                   return "none"
      }
    }
    
    static func ==(lhs: Direction, rhs: Direction) -> Bool {
      return lhs.vertical == rhs.vertical && lhs.horizontal == rhs.horizontal
    }
  }

}

extension Trajectory: ByteArrayConvertible {

  /// A string representation of the Trajectory as an array of bytes.
  var bytes: [Byte] { return Array("{\(NSStringFromCGPoint(p)), \(NSStringFromCGVector(v))}".utf8) }

  /// Initializing with an array of bytes.
  init(_ bytes: [Byte]) {
    let string = String(bytes)
    let float = "-?[0-9]+(?:\\.[0-9]+)?"
    let value = "\\{\(float), \(float)\\}"
    guard let match = (~/"\\{(\(value)), (\(value))\\}").firstMatch(string, anchored: true),
      let positionCapture = match.captures[1],
      let vectorCapture = match.captures[2] else { self = .null; return }
    guard let point = CGPoint(positionCapture.string), let vector = CGVector(vectorCapture.string) else {
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

  
  /// Initializing with a json value.
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue), let p = CGPoint(dict["p"]), let v = CGVector(dict["v"]) else {
      return nil
    }
    self.init(vector: v, point: p)
  }

}

extension Trajectory: CustomStringConvertible {

  var description: String { return "{ x: \(x); y: \(y); dx: \(dx); dy: \(dy); direction: \(direction) }" }

}
