//
//  MIDINodePath.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import typealias AudioToolbox.MIDITimeStamp

final class MIDINodePath {


  private var segments: [Segment]
  private var segments2 =  Tree<Segment>()
  private var segments3 = SortedArray<Segment>()

  let min: CGPoint
  let max: CGPoint

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
    segments = [Segment(trajectory: trajectory, time: time, min: min, max: max)]
    segments2.insert(segments[0])
    segments3.append(segments[0])
  }


  /**
   insertSegment:

   - parameter segment: Segment
  */
//  func insertSegment(segment: Segment) { segments.insert(segment) }

  /**
   locationForTime:

   - parameter time: NSTimeInterval

    - returns: CGPoint?
  */
  func locationForTime(time: BarBeatTime) -> CGPoint? { return segmentForTime(time)?.locationForTime(time) }

  func locationForTime2(time: BarBeatTime) -> CGPoint? { return segmentForTime2(time)?.locationForTime(time) }

  func locationForTime3(time: BarBeatTime) -> CGPoint? { return segmentForTime3(time)?.locationForTime(time) }

  /**
   advanceSegment:

   - parameter segment: Segment

    - returns: Segment
  */
  private func advanceSegment(segment: Segment) -> Segment {
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
    let nextSegment = Segment(trajectory: nextTrajectory, time: segment.endTime, min: min, max: max)
    return nextSegment
  }

  /**
   segmentForTime:

   - parameter time: BarBeatTime

    - returns: Segment?
  */
  func segmentForTime(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments.indexOf({$0.timeInterval ∋ time}) {//find({$0.endTime < time}, {$0.timeInterval ∋ time}) {
      return segments[segment]
    }
    guard let segment = segments.last else { fatalError("segments is empty, no max element") }
    guard segment.endTime < time else {
      fatalError("segment's end time is not less than time, a matching segment should have been found")
    }

    var currentSegment = segment
    while currentSegment.timeInterval ∌ time {
      currentSegment = advanceSegment(currentSegment)
      segments.append(currentSegment)
    }
//    logDebug("time = \(time)\nresult = \(currentSegment)")
    guard currentSegment.timeInterval ∋ time else {
      fatalError("segment to return does not contain time specified") // 1:2/4.196/480₁ ∉ 2:1/4.168/480₁ ..< 2:2/4.153/480₁
    }

    return currentSegment
  }

  func segmentForTime2(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments2.find({$0.endTime < time}, {$0.timeInterval ∋ time}) {
      return segment
    }
    guard let segment = segments2.maxElement() else { fatalError("segments is empty, no max element") }
    guard segment.endTime < time else {
      fatalError("segment's end time is not less than time, a matching segment should have been found")
    }

    var currentSegment = segment
    while currentSegment.timeInterval ∌ time {
      currentSegment = advanceSegment(currentSegment)
      segments2.insert(currentSegment)
    }
    //    logDebug("time = \(time)\nresult = \(currentSegment)")
    guard currentSegment.timeInterval ∋ time else {
      fatalError("segment to return does not contain time specified") // 1:2/4.196/480₁ ∉ 2:1/4.168/480₁ ..< 2:2/4.153/480₁
    }

    return currentSegment
  }

    func segmentForTime3(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments3.indexOf({$0.timeInterval ∋ time}) {//find({$0.endTime < time}, {$0.timeInterval ∋ time}) {
      return segments3[segment]
    }
    guard let segment = segments3.last else { fatalError("segments is empty, no max element") }
    guard segment.endTime < time else {
      fatalError("segment's end time is not less than time, a matching segment should have been found")
    }

    var currentSegment = segment
    while currentSegment.timeInterval ∌ time {
      currentSegment = advanceSegment(currentSegment)
      segments3.append(currentSegment)
    }
//    logDebug("time = \(time)\nresult = \(currentSegment)")
    guard currentSegment.timeInterval ∋ time else {
      fatalError("segment to return does not contain time specified") // 1:2/4.196/480₁ ∉ 2:1/4.168/480₁ ..< 2:2/4.153/480₁
    }
    return currentSegment
  }
}

extension MIDINodePath: CustomStringConvertible, CustomDebugStringConvertible {
  private func makeDescription(debug debug: Bool = false) -> String {
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