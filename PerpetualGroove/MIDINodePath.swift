//
//  MIDINodePath.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGSize
import struct CoreGraphics.CGVector
import struct CoreGraphics.CGFloat
import typealias AudioToolbox.MIDITimeStamp

final class MIDINodePath {

  fileprivate var segments: SortedArray<BoxedSegment> = []

  let min: CGPoint, max: CGPoint

  let startTime: BarBeatTime
  let initialTrajectory: Trajectory
  var initialSegment: Segment {
    guard !segments.isEmpty else { fatalError("segments should always contain at least 1 segment") }
    return Segment(owner: segments[0])
  }

  init(trajectory: Trajectory, playerSize: CGSize, time: BarBeatTime = BarBeatTime.zero) {
    let offset = MIDINode.texture.size() * 0.375
    max = CGPoint((playerSize - offset).unpack)
    min = CGPoint(offset.unpack)
    startTime = time
    initialTrajectory = trajectory
    segments.append(BoxedSegment(trajectory: trajectory, time: time, path: self))
  }

  func location(for time: BarBeatTime) -> CGPoint? { return boxedSegment(for: time)?.location(for: time) }


  fileprivate func advance(segment: BoxedSegment) -> BoxedSegment {
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
    let nextSegment = BoxedSegment(trajectory: nextTrajectory, time: segment.endTime, path: self)
    segment._successor = nextSegment
    nextSegment._predecessor = segment
    return nextSegment
  }

  fileprivate func boxedSegment(for time: BarBeatTime) -> BoxedSegment? {
    guard time >= startTime else { return nil }

    if let segmentIndex = segments.index(where: {$0.timeInterval.lowerBound <= time && $0.timeInterval.upperBound >= time})
    {
      return segments[segmentIndex]
    }

    var segment = segments[segments.index(before: segments.endIndex)]
    guard segment.endTime <= time else {
      fatalError("segment's end time '\(segment.endTime)' is not less than or equal to time '\(time)', "
               + "a matching segment should have been found")
    }

    while !segment.timeInterval.contains(time) { segment = advance(segment: segment); segments.append(segment) }

    guard segment.timeInterval.contains(time) else {
      fatalError("segment to return does not contain time specified")
    }
    return segment
  }

  func segment(for time: BarBeatTime) -> Segment?  {
    guard let segment = boxedSegment(for: time) else { return nil }
    return Segment(owner: segment)
  }
}

extension MIDINodePath: CustomStringConvertible, CustomDebugStringConvertible {
  fileprivate func makeDescription(debug: Bool = false) -> String {
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

struct Segment: Equatable, Comparable, CustomStringConvertible {

  fileprivate let owner: BoxedSegment
  var trajectory: Trajectory { return owner.trajectory }

  var timeInterval: CountableRange<BarBeatTime> { return owner.timeInterval }
  var tickInterval: CountableRange<MIDITimeStamp> { return owner.tickInterval }

  var startTime: BarBeatTime { return owner.startTime }
  var endTime: BarBeatTime { return owner.endTime }
  var totalTime: BarBeatTime { return owner.totalTime }

  var startTicks: MIDITimeStamp { return owner.startTicks }
  var endTicks: MIDITimeStamp { return owner.endTicks }
  var totalTicks: MIDITimeStamp { return owner.totalTicks }

  var startLocation: CGPoint { return owner.startLocation }
  var endLocation: CGPoint { return owner.endLocation }
  var length: CGFloat { return owner.length }

  var description: String { return owner.description }

  func location(for time: BarBeatTime) -> CGPoint? { return owner.location(for: time) }

  func timeToEndLocation(from point: CGPoint) -> TimeInterval {
    return owner.timeToEndLocation(from: point)
  }

  var predecessor: Segment? {
    guard let predecessor = owner.predecessor() else { return nil }
    return Segment(owner: predecessor)
  }

  var successor: Segment { return Segment(owner: owner.successor()) }

  static func ==(lhs: Segment, rhs: Segment) -> Bool { return lhs.owner == rhs.owner }
  static func <(lhs: Segment, rhs: Segment) -> Bool { return lhs.owner < rhs.owner }
}


private final class BoxedSegment: Equatable, Comparable, CustomStringConvertible {
  unowned let path: MIDINodePath

  let trajectory: Trajectory

  let timeInterval: CountableRange<BarBeatTime>
  let tickInterval: CountableRange<MIDITimeStamp>

  var startTime: BarBeatTime { return timeInterval.lowerBound }
  var endTime: BarBeatTime { return timeInterval.upperBound }
  var totalTime: BarBeatTime { return timeInterval.upperBound - timeInterval.lowerBound }

  var startTicks: MIDITimeStamp { return tickInterval.lowerBound }
  var endTicks: MIDITimeStamp { return tickInterval.upperBound }
  var totalTicks: MIDITimeStamp { return endTicks > startTicks ? endTicks - startTicks : 0 }

  var startLocation: CGPoint { return trajectory.p }
  let endLocation: CGPoint
  let length: CGFloat

  weak var _predecessor: BoxedSegment?
  weak var _successor: BoxedSegment?

  func predecessor() -> BoxedSegment? { return _predecessor }
  func successor() -> BoxedSegment {
    guard _successor == nil else { return _successor! }
    return path.advance(segment: self)
  }

  func location(for time: BarBeatTime) -> CGPoint? {
    guard timeInterval.lowerBound <= time && timeInterval.upperBound >= time else { return nil }
    let 𝝙ticks = CGFloat(time.ticks - startTime.ticks)
    let ratio = 𝝙ticks / CGFloat(tickInterval.count)
    var result = trajectory.p
    result.x += ratio * (endLocation.x - result.x)
    result.y += ratio * (endLocation.y - result.y)
    return result
  }

  func timeToEndLocation(from point: CGPoint) -> TimeInterval {
    return trajectory.time(fromPoint: point, toPoint: endLocation)
  }

  init(trajectory: Trajectory, time: BarBeatTime, path: MIDINodePath) {
    self.trajectory = trajectory
    self.path = path
    let endY: CGFloat

    switch trajectory.direction.vertical {
      case .none: endY = trajectory.p.y
      case .up:   endY = path.max.y
      case .down: endY = path.min.y
    }

    let pY: CGPoint? = {
      let p = trajectory.point(atY: endY)
      guard (path.min.x ... path.max.x).contains(p.x) else { return nil }
      return p
    }()

    let endX: CGFloat

    switch trajectory.direction.horizontal {
      case .none:  endX = trajectory.p.x
      case .left:  endX = path.min.x
      case .right: endX = path.max.x
    }

    let pX: CGPoint? = {
      let p = trajectory.point(atX: endX)
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

    let 𝝙t = trajectory.time(fromPoint: trajectory.p, toPoint: endLocation)
    let endTime = BarBeatTime(seconds: time.seconds + 𝝙t)

    timeInterval = time ..< endTime
    tickInterval = timeInterval.lowerBound.ticks ..< timeInterval.upperBound.ticks
  }

  var description: String {
    return "Segment {\n\t" + "\n\t".join(
      "trajectory: \(trajectory)",
      "endLocation: \(endLocation)",
      "timeInterval: \(timeInterval)",
      "totalTime: \(endTime - startTime)",
      "tickInterval: \(tickInterval)",
      "totalTicks: \(totalTicks)",
      "length: \(length)"
      ) + "\n}"
  }

  static func ==(lhs: BoxedSegment, rhs: BoxedSegment) -> Bool { return lhs.startTime == rhs.startTime }
  static func <(lhs: BoxedSegment, rhs: BoxedSegment) -> Bool { return lhs.startTime < rhs.startTime }
}


