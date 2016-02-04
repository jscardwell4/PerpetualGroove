//
//  Segment.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/21/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import typealias AudioToolbox.MIDITimeStamp

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

  private weak var _successor: Segment?

  var successor: Segment {
    guard _successor == nil else { return _successor! }
    let segment = advance()
    segment.predessor = self
    _successor = segment
    path.insertSegment(segment)
    return segment
  }

  weak var predessor: Segment?


  unowned let path: MIDINodePath

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
   - parameter path: MIDINodePath
   */
  init(trajectory: Trajectory, time: BarBeatTime, path: MIDINodePath) {
    self.trajectory = trajectory
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

