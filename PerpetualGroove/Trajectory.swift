//
//  Trajectory.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct Trajectory {

  /// slope of the line (`dy` / `dx`)
  var m: CGFloat { return dy / dx }

  /// velocity in units per second
  var v: CGVector

  /// initial point
  var p: CGPoint

  /// horizontal velocity in units per second
  var dx: CGFloat { get { return v.dx } set { v.dx = newValue } }

  /// vertical velocity in units per second
  var dy: CGFloat { get { return v.dy } set { v.dy = newValue } }

  /// initial position along the x axis
  var x: CGFloat { get { return p.x } set { p.x = newValue } }

  /// initial position along the y axis
  var y: CGFloat { get { return p.y } set { p.y = newValue } }

  /**
   Default initializer

   - parameter vector: CGVector
   - parameter p: CGPoint
  */
  init(vector: CGVector, point: CGPoint) { v = vector; p = point }

  /**
   y = m (x - x<sub>1</sub>) + y<sub>1</sub>

   - parameter x: CGFloat

    - returns: CGPoint
  */
  func pointAtX(x: CGFloat) -> CGPoint {
    return CGPoint(x: x, y: m * (x - p.x) + p.y)
  }

  /**
   x = (y - y<sub>1</sub> + mx<sub>1</sub>) / m

   - parameter y: CGFloat

    - returns: CGPoint
  */
  func pointAtY(y: CGFloat) -> CGPoint {
    return CGPoint(x: (y - p.y + m * p.x) / m, y: y)
  }

  /**
   (x<sub>2</sub> - x<sub>1</sub>) / `dx`

   - parameter x1: CGFloat
   - parameter x2: CGFloat

    - returns: NSTimeInterval
  */
  func timeFromX(x1: CGFloat, toX x2: CGFloat) -> NSTimeInterval {
    return NSTimeInterval((x2 - x1) / dx)
  }

  /**
   (y<sub>2</sub> - y<sub>1</sub>) / `dy`

   - parameter y1: CGFloat
   - parameter y2: CGFloat

    - returns: NSTimeInterval
  */
  func timeFromY(y1: CGFloat, toY y2: CGFloat) -> NSTimeInterval {
    return NSTimeInterval((y2 - y1) / dy)
  }

  /**
   timeFromPoint:toPoint:

   - parameter p1: CGPoint
   - parameter p2: CGPoint

    - returns: NSTimeInterval
  */
  func timeFromPoint(p1: CGPoint, toPoint p2: CGPoint) -> NSTimeInterval {
//    guard containsPoint(p1) && containsPoint(p2) else {
//      fatalError("one or both of the provided points do not lie along the trajectory")
//    }
    let tx = timeFromX(p1.x, toX: p2.x)
    let ty = timeFromY(p1.y, toY: p2.y)
//    guard tx == ty else { fatalError("expected tx '\(tx)' and ty '\(ty)' to be equal") }
    return min(tx, ty)
  }

  /**
   The point along trajectory given the specified delta time.

   - parameter time: NSTimeInterval

    - returns: CGPoint
  */
  func pointAtTime(time: NSTimeInterval) -> CGPoint {
    var result = p
    result.x += CGFloat(time) * dx
    result.y += CGFloat(time) * dy
    return result
  }

  /**
   containsPoint:

   - parameter point: CGPoint

    - returns: Bool
  */
  func containsPoint(point: CGPoint) -> Bool {
    let lhs = abs((point.y - p.y).rounded(3))
    let rhs = abs((m * (point.x - p.x)).rounded(3))
    return lhs == rhs
  }

  static let zero = Trajectory(vector: CGVector.zero, point: CGPoint.zero)
  static let null = Trajectory(vector: CGVector.zero, point: CGPoint.null)
}

extension Trajectory: ByteArrayConvertible {
  var bytes: [Byte] {
    return Array("{\(NSStringFromCGPoint(p)), \(NSStringFromCGVector(v))}".utf8)
  }

  /**
  init:

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
    p = point
    v = vector
  }
}

extension Trajectory: JSONValueConvertible {
  var jsonValue: JSONValue { return ["p": p, "v": v] }
}

extension Trajectory: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue), p = CGPoint(dict["p"]), v = CGVector(dict["v"]) else {
      return nil
    }
    self.init(vector: v, point: p)
  }
}

extension Trajectory: CustomStringConvertible {
  var description: String { return "{ p: \(p.description(3)); v: \(v.description(3)) }" }
}

extension Trajectory: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}
