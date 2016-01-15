//: Playground - noun: a place where people can play

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
//  init(snapshot: MIDINodeHistory.Snapshot) { self = snapshot.trajectory }

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

  /**
   initWithTrajectory:playerSize:time:

   - parameter trajectory: Trajectory
   - parameter playerSize: CGSize
   - parameter time: NSTimeInterval = 0
   */
  init(trajectory: Trajectory, playerSize: CGSize, time: NSTimeInterval = 0) {

    let offset = /*MIDINode.texture.size()*/ CGSize(square: 50) * 0.375
    max = CGPoint((playerSize - offset).unpack)
    min = CGPoint(offset.unpack)
    segments.insert(Segment(trajectory: trajectory, time: time, path: self))
  }

  /**
   segmentForTime:

   - parameter time: NSTimeInterval

   - returns: Segment?
   */
  func segmentForTime(time: NSTimeInterval, calculateIfNeeded: Bool = false) -> Segment?  {
    if let segment = segments.find({$0.endTime < time}, {$0.interval ∋ time}) { return segment }
    guard let segment = segments.maxElement() else { fatalError("segments is empty, no max element") }
    var currentSegment = segment
    var additionalSegments: [Segment] = []
    while currentSegment.endTime < time {
      let newSegment = currentSegment.advance()
      additionalSegments.append(newSegment)
      currentSegment = newSegment
    }
    segments.insert(additionalSegments)
    return currentSegment
  }

  subscript(time: NSTimeInterval) -> Segment {
    guard let segment = segmentForTime(time, calculateIfNeeded: true) else {
      fatalError("failed to generate a segment")
    }
    return segment
  }

}

/**
 advance

 - returns: Segment
 */
private func advanceSegmentWithTrajectory(trajectory: Trajectory,
  time: NSTimeInterval,
  path: MIDINodePath) -> (Trajectory, NSTimeInterval)
{

  // Determine possible end point axes
  let projectedX: CGFloat = trajectory.dx.isSignMinus ? path.min.x : path.max.x,
  projectedY: CGFloat = trajectory.dy.isSignMinus ? path.min.y : path.max.y

  // Calculate projected end points
  let pX = trajectory.pointAtX(projectedX)
  let pY = trajectory.pointAtY(projectedY)

  // Calculate the time elapsed from  trajectory to end points
  let tX = trajectory.timeFromX(trajectory.p.x, toX: projectedX)
  let tY = trajectory.timeFromY(trajectory.p.y, toY: projectedY)

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
  let t: NSTimeInterval   // The total elapsed time at extrapolated location
  let v: CGVector         // The extrapolated velocity

  // If both projected points are valid, use the point with a smaller travel time
  switch (validPoint(pX), validPoint(pY)) {
  case (true, true):   (p, 𝝙t) = tX < tY ? (pX, tX) : (pY, tY)
  case (true, false):  (p, 𝝙t) = (pX, tX)
  case (false, true):  (p, 𝝙t) = (pY, tY)
  case (false, false): fatalError("failed to obtain a valid point for the next location")
  }

  t = time + 𝝙t  // Add the delta time to origin time

  // Redirect trajectory according to which boundary edge the new location touches
  switch p.unpack {
  case (path.min.x, _), (path.max.x, _):
    v = CGVector(dx: trajectory.dx * -1, dy: trajectory.dy)
  case (_, path.min.y), (_, path.max.y):
    v = CGVector(dx: trajectory.dx, dy: trajectory.dy * -1)
  default:
    fatalError("next location should contact an edge of the player")
  }

  return (Trajectory(vector: v, point: p), t)
}

extension MIDINodePath {
  struct Segment: Equatable, Comparable, CustomStringConvertible {
    let trajectory: Trajectory
    let startTime: NSTimeInterval
    let endTime: NSTimeInterval

    var interval: HalfOpenInterval<NSTimeInterval> { return startTime ..< endTime }

    unowned let path: MIDINodePath

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
     initWithTrajectory:time:path:

     - parameter trajectory: Trajectory
     - parameter time: NSTimeInterval
     - parameter path: MIDINodePath
     */
    init(trajectory: Trajectory, time: NSTimeInterval, path: MIDINodePath) {
      self.trajectory = trajectory
      self.startTime = time
      self.path = path
      endTime = advanceSegmentWithTrajectory(trajectory, time: time, path: path).1
    }

    /**
     advance

     - returns: Segment
     */
    private func advance() -> Segment {
      let (nextTrajectory, nextTime) = advanceSegmentWithTrajectory(trajectory, time: startTime, path: path)
      return Segment(trajectory: nextTrajectory, time: nextTime, path: path)
    }

    var description: String {
      return "{ trajectory: \(trajectory); interval: (\(rounded(startTime, 3)) ..< \(rounded(endTime, 3))) }"
    }
    
  }
}

func ==(lhs: MIDINodePath.Segment, rhs: MIDINodePath.Segment) -> Bool {
  return lhs.startTime == rhs.startTime
}

func <(lhs: MIDINodePath.Segment, rhs: MIDINodePath.Segment) -> Bool {
  return lhs.startTime < rhs.startTime
}



var str = "Hello, playground"

let velocity = CGVector(dx: 125.6607818603516, dy: 84.39211273193359)
let point = CGPoint(x: 125.6607818603516, y: 84.39211273193359)
let playerSize = CGSize(width: 430, height: 430)
let trajectory = Trajectory(vector: velocity, point: point)

let path = MIDINodePath(trajectory: trajectory, playerSize: playerSize, time: 0)

let segment1 = path[0]
print(segment1)
print("\n")

let segment2 = path[2.3]
print(segment2)
print("\n")
let segment3 = path[3.9]
print(segment3)
print("\n")

let segment4 = path[19.34]
print(segment4)
print("\n")


print("[\n\t" + "\n\t".join(path.segments.map({$0.description})) + "\n]")

let p = segment1.trajectory.pointAtTime(segment1.endTime)
