//
//  MIDINodePath.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class MIDINodePath {


  private var segments = Tree<Segment>()

  private let min: CGPoint
  private let max: CGPoint

  let startTime: NSTimeInterval
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
   - parameter time: NSTimeInterval = 0
  */
  init(trajectory: Trajectory, playerSize: CGSize, time: NSTimeInterval = 0) {

    let offset = MIDINode.texture.size() * 0.375
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
  func segmentForTime(time: NSTimeInterval) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments.find({$0.endTime < time}, {$0.interval ∋ time}) { return segment }
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

extension MIDINodePath {
  final class Segment: Equatable, Comparable, CustomStringConvertible {
    let trajectory: Trajectory
    let startTime: NSTimeInterval
    let endTime: NSTimeInterval

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

func ==(lhs: MIDINodePath.Segment, rhs: MIDINodePath.Segment) -> Bool {
  return lhs.startTime == rhs.startTime
}

func <(lhs: MIDINodePath.Segment, rhs: MIDINodePath.Segment) -> Bool {
  return lhs.startTime < rhs.startTime
}
