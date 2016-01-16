//: Playground - noun: a place where people can play

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
    guard containsPoint(p1) && containsPoint(p2) else {
      fatalError("one or both of the provided points do not lie along the trajectory")
    }
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

final class MIDINodePath {


  private var segments = Tree<Segment>()

  private let min: CGPoint
  private let max: CGPoint

  let startTime: NSTimeInterval
  let initialTrajectory: Trajectory

  private weak var currentSegment: Segment!

  /**
   initWithTrajectory:playerSize:time:

   - parameter trajectory: Trajectory
   - parameter playerSize: CGSize
   - parameter time: NSTimeInterval = 0
  */
  init(trajectory: Trajectory, playerSize: CGSize, time: NSTimeInterval = 0) {

    let offset = CGSize(square: 50) * 0.375
    max = CGPoint((playerSize - offset).unpack)
    min = CGPoint(offset.unpack)
    startTime = time
    initialTrajectory = trajectory
    let segment = Segment(trajectory: trajectory, time: time, path: self)
    segments.insert(segment)
    currentSegment = segment
  }

  /**
   locationForTime:

   - parameter time: NSTimeInterval

    - returns: CGPoint?
  */
  func locationForTime(time: NSTimeInterval) -> CGPoint? {
    return segmentForTime(time)?.locationForTime(time)
  }

  /**
   nextLocationForTime:

   - parameter time: NSTimeInterval

    - returns: CGPoint?
  */
  func nextLocationForTime(time: NSTimeInterval, fromPoint point: CGPoint) -> (CGPoint, NSTimeInterval)? {
    guard let segment = segmentForTime(time) else { return nil }
    return (segment.endLocation, segment.timeToEndLocationFromPoint(point))
  }

  /**
   segmentForTime:

   - parameter time: NSTimeInterval

    - returns: Segment?
  */
  private func segmentForTime(time: NSTimeInterval) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments.find({$0.endTime < time}, {$0.interval ∋ time}) { return segment }
    guard let segment = segments.maxElement() else { fatalError("segments is empty, no max element") }

    var currentSegment = segment
    var additionalSegments: [Segment] = []
    while currentSegment.endTime < time {
      let newSegment = currentSegment.advance()
      newSegment.predessor = currentSegment
      currentSegment.successor = newSegment
      additionalSegments.append(newSegment)
      currentSegment = newSegment
    }
    segments.insert(additionalSegments)
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
      "currentSegment: \n\(currentSegment?.description.indentedBy(2, useTabs: true) ?? "nil")",
      "segments: [\n\t\t\(",\n\t\t".join(segments.map({$0.description.indentedBy(2, preserveFirst: true, useTabs: true)})))\n\t]"
      ) + "\n}"
  }
}

/**
 advance

  - returns: Segment
*/
//private func advanceSegmentWithTrajectory(trajectory: Trajectory,
//                                     time: NSTimeInterval,
//                                     path: MIDINodePath) -> (Trajectory, NSTimeInterval)
//{
//
//  // Determine possible end point axes
//  let projectedX: CGFloat = trajectory.dx.isSignMinus ? path.min.x : path.max.x,
//      projectedY: CGFloat = trajectory.dy.isSignMinus ? path.min.y : path.max.y
//
//  // Calculate projected end points
//  let pX = trajectory.pointAtX(projectedX)
//  let pY = trajectory.pointAtY(projectedY)
//
//  // Calculate the time elapsed from  trajectory to end points
//  let tX = trajectory.timeFromX(trajectory.p.x, toX: projectedX)
//  let tY = trajectory.timeFromY(trajectory.p.y, toY: projectedY)
//
//  /**
//   Helper function for determining whether a given point lies within bounds
//
//   - parameter p: CGPoint
//
//    - returns: Bool
//  */
//  func validPoint(p: CGPoint) -> Bool {
//    return (path.min.x ... path.max.x).contains(p.x)
//        && (path.min.y ... path.max.y).contains(p.y)
//  }
//
//  let p: CGPoint           // The extrapolated location
//  let 𝝙t: NSTimeInterval  // The time from trajectory to extrapolated location
//  let t: NSTimeInterval   // The total elapsed time at extrapolated location
//  let v: CGVector         // The extrapolated velocity
//
//  // If both projected points are valid, use the point with a smaller travel time
//  switch (validPoint(pX), validPoint(pY)) {
//    case (true, true):   (p, 𝝙t) = tX < tY ? (pX, tX) : (pY, tY)
//    case (true, false):  (p, 𝝙t) = (pX, tX)
//    case (false, true):  (p, 𝝙t) = (pY, tY)
//    case (false, false): fatalError("failed to obtain a valid point for the next location")
//  }
//
//  t = time + 𝝙t  // Add the delta time to origin time
//
//  // Redirect trajectory according to which boundary edge the new location touches
//  switch p.unpack {
//    case (path.min.x, _), (path.max.x, _):
//      v = CGVector(dx: trajectory.dx * -1, dy: trajectory.dy)
//    case (_, path.min.y), (_, path.max.y):
//      v = CGVector(dx: trajectory.dx, dy: trajectory.dy * -1)
//    default:
//      fatalError("next location should contact an edge of the player")
//  }
//
//  return (Trajectory(vector: v, point: p), t)
//}

extension MIDINodePath {
  private final class Segment: Equatable, Comparable, CustomStringConvertible {
    let trajectory: Trajectory
    let startTime: NSTimeInterval
    let endTime: NSTimeInterval

    weak var successor: Segment?
    weak var predessor: Segment?

    var interval: HalfOpenInterval<NSTimeInterval> { return startTime ..< endTime }

    unowned let path: MIDINodePath

    var startLocation: CGPoint { return trajectory.p }

    let endLocation: CGPoint

    /**
     locationForTime:

     - parameter time: NSTimeInterval

      - returns: CGPoint?
    */
    func locationForTime(time: NSTimeInterval) -> CGPoint? {
      guard interval ∋ time else { return nil }
      return trajectory.pointAtTime(time - startTime)
    }

    /**
     timeToEndLocationFromPoint:

     - parameter point: CGPoint

      - returns: NSTimeInterval
    */
    func timeToEndLocationFromPoint(point: CGPoint) -> NSTimeInterval {
//      guard trajectory.containsPoint(point) else {
//        fatalError("segment does not contain point '\(point)'")
//      }
      return trajectory.timeFromPoint(point, toPoint: endLocation)
    }

    /**
     initWithTrajectory:time:path:

     - parameter trajectory: Trajectory
     - parameter time: NSTimeInterval
     - parameter path: MIDINodePath
    */
    init(trajectory: Trajectory, time: NSTimeInterval, path: MIDINodePath) {
      self.trajectory = trajectory
      self.startTime = time
      self.path = path

      // Determine possible end point axes
      let projectedX: CGFloat = trajectory.dx.isSignMinus ? path.min.x : path.max.x,
      projectedY: CGFloat = trajectory.dy.isSignMinus ? path.min.y : path.max.y

      // Calculate projected end points
      let pX = trajectory.pointAtX(projectedX), pY = trajectory.pointAtY(projectedY)

      // Calculate the time elapsed from  trajectory to end points
      let tX = trajectory.timeFromX(trajectory.p.x, toX: projectedX),
      tY = trajectory.timeFromY(trajectory.p.y, toY: projectedY)

      /**
       Helper function for determining whether a given point lies within bounds

       - parameter p: CGPoint

       - returns: Bool
       */
      func validPoint(p: CGPoint) -> Bool {
        return (path.min.x ... path.max.x).contains(p.x)
          && (path.min.y ... path.max.y).contains(p.y)
      }

      let p: CGPoint           // The extrapolated location
      let 𝝙t: NSTimeInterval  // The time from trajectory to extrapolated location

      // If both projected points are valid, use the point with a smaller travel time
      switch (validPoint(pX), validPoint(pY)) {
        case (true, true):   (p, 𝝙t) = tX < tY ? (pX, tX) : (pY, tY)
        case (true, false):  (p, 𝝙t) = (pX, tX)
        case (false, true):  (p, 𝝙t) = (pY, tY)
        case (false, false): fatalError("failed to obtain a valid point for the next location")
      }
      
      endLocation = p
      endTime = time + 𝝙t

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
        "startTime: \(startTime)",
        "endTime: \(endTime)",
        "endLocation: \(endLocation)"
        ) + "\n}"
    }

  }
}

private func ==(lhs: MIDINodePath.Segment, rhs: MIDINodePath.Segment) -> Bool {
  return lhs.startTime == rhs.startTime
}

private func <(lhs: MIDINodePath.Segment, rhs: MIDINodePath.Segment) -> Bool {
  return lhs.startTime < rhs.startTime
}

var str = "Hello, playground"

let point = CGPoint(x: 143.2811126708984, y: 206.8070373535156)
let velocity = CGVector(dx: 144.9763520779608, dy: -223.4146814806358)
let playerSize = CGSize(width: 430, height: 430)
let trajectory = Trajectory(vector: velocity, point: point)

let path = MIDINodePath(trajectory: trajectory, playerSize: playerSize, time: 0)
let _ = path.segmentForTime(24)
print(path)
