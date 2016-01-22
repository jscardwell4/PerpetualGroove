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


  private var segments = Tree<Segment>()

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

    let offset = MIDINode.texture.size() * 0.375
    max = CGPoint((playerSize - offset).unpack)
    min = CGPoint(offset.unpack)
    startTime = time
    initialTrajectory = trajectory
    segments.insert(Segment(trajectory: trajectory, time: time, path: self))
  }


  /**
   insertSegment:

   - parameter segment: Segment
  */
  func insertSegment(segment: Segment) { segments.insert(segment) }

  /**
   locationForTime:

   - parameter time: NSTimeInterval

    - returns: CGPoint?
  */
  func locationForTime(time: BarBeatTime) -> CGPoint? {
    let segment = segmentForTime(time)
    let result = segment?.locationForTime(time)
    logDebug("time = \(time)\nsegment = \(segment)\nresult = \(result)")
    return result
  }

  /**
   nextLocationForTime:

   - parameter time: BarBeatTime

    - returns: CGPoint?
  */
//  func nextLocationForTime(time: BarBeatTime, fromPoint point: CGPoint) -> (CGPoint, NSTimeInterval)? {
//    guard let segment = segmentForTime(time) else { return nil }
//    return (segment.endLocation, segment.timeToEndLocationFromPoint(point))
//  }

  /**
   segmentForTime:

   - parameter time: BarBeatTime

    - returns: Segment?
  */
  func segmentForTime(time: BarBeatTime) -> Segment?  {
    guard time >= startTime else { return nil }

    if let segment = segments.find({$0.endTime < time}, {$0.timeInterval ∋ time}) {
      logDebug("time = \(time)\nresult = \(segment)")
      return segment
    }
    guard let segment = segments.maxElement() else { fatalError("segments is empty, no max element") }

    var currentSegment = segment
    while currentSegment.endTime < time { currentSegment = currentSegment.successor }
    logDebug("time = \(time)\nresult = \(currentSegment)")
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

