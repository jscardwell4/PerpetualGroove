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
    /// slope of the line
    var m: CGFloat { return dy / dx }

    /// velocity in units per second
    var v: CGVector

    /// initial point
    var p: CGPoint

    /// horizontal velocity in units per second
    var dx: CGFloat { get { return v.dx } set { v.dx = newValue } }

    /// vertical velocity in units per second
    var dy: CGFloat { get { return v.dy } set { v.dy = newValue } }

    /**
     initWithVector:point:

     - parameter vector: CGVector
     - parameter p: CGPoint
    */
    init(vector: CGVector, point: CGPoint) { v = vector; p = point }

    /**
     initWithSnapshot:

     - parameter snapshot: Snapshot
    */
    init(snapshot: MIDINodeHistory.Snapshot) { self = snapshot.trajectory }

    /**
     pointAtX:

     - parameter x: CGFloat

      - returns: CGPoint
    */
    func pointAtX(x: CGFloat) -> CGPoint {
      return CGPoint(x: x, y: m * (x - p.x) + p.y)
    }

    /**
     pointAtY:

     - parameter y: CGFloat

      - returns: CGPoint
    */
    func pointAtY(y: CGFloat) -> CGPoint {
      return CGPoint(x: (y - p.y + m * p.x) / m, y: y)
    }

    /**
     timeFromX:toX:

     - parameter x1: CGFloat
     - parameter x2: CGFloat

      - returns: NSTimeInterval
    */
    func timeFromX(x1: CGFloat, toX x2: CGFloat) -> NSTimeInterval {
      return NSTimeInterval((x2 - x1) / dx)
    }

    /**
     timeFromY:toY:

     - parameter y1: CGFloat
     - parameter y2: CGFloat

      - returns: NSTimeInterval
    */
    func timeFromY(y1: CGFloat, toY y2: CGFloat) -> NSTimeInterval {
      return NSTimeInterval((y2 - y1) / dy)
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
    guard let point = CGPoint(positionCapture.string), vector = CGVector(vectorCapture.string) else { self = .null; return }
    p = point
    v = vector
  }
}

extension Trajectory: JSONValueConvertible {
  var jsonValue: JSONValue {
    return ObjectJSONValue(["p": p.jsonValue, "v": v.jsonValue]).jsonValue
  }
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
  var description: String { return "{\(p.description(3)), \(v.description(3))}" }
}

extension Trajectory: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}