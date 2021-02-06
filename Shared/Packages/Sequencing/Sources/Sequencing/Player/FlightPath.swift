//
//  FlightPath.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/5/21.
//
import Foundation
import CoreGraphics
import struct Common.Trajectory
import MoonDev
import CoreMIDI
import MIDI
import SwiftUI

/// Type for generating consecutive line segments.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class FlightPath: CustomStringConvertible, CustomDebugStringConvertible
{
  /// Bounding box for the path's segments.
  private let bounds: CGRect

  /// The in-order segments from which the path is composed.
  private var segments: SortedArray<Segment>

  /// Returns the `position` segment in the path.
  subscript(position: Int) -> Segment { return segments[position] }

  /// Time associated with the path's starting end point.
  var startTime: BarBeatTime { return segments[0].startTime }

  /// Velocity and angle specifying the first vector from the path's starting end point.
  var initialTrajectory: Trajectory { return segments[0].trajectory }

  /// The first segment in the path.
  var initialSegment: Segment { return segments[0] }

  /// Default initializer for `Path`.
  /// - Parameter trajectory: The path's initial trajectory.
  /// - Parameter playerSize: The size of the rectangle bounding the path.
  /// - Parameter time: The start time for the path. Default is `BarBeatTime.zero`.
  init(trajectory: Trajectory, playerSize: CGSize, time: BarBeatTime = .zero)
  {
    // Calculate bounds by insetting a rect with origin zero and a size of `playerSize`.
    bounds = UIEdgeInsets(*(MIDINode.texture.size() * 0.375))
      .inset(CGRect(size: playerSize))

    // Create the initial segment.
    segments = [Segment(trajectory: trajectory, time: time, bounds: bounds)]
  }

  /// Returns the index of the segment with a `timeInterval` that contains `time`
  /// unless `time < startTime`, in which case `nil` is returned. If an existing
  /// segment is found for `time` it's index will be returned; otherwise, new
  /// segments will be created successively until a segment is created that contains
  /// `time` and its index is returned.
  func segmentIndex(for time: BarBeatTime) -> Int?
  {
    // Check that the time does not predate the path's start time.
    guard time >= startTime else { return nil }

    if let index = segments.firstIndex(where: { $0.timeInterval.contains(time) })
    {
      return index
    }

    var segment = segments[segments.index(before: segments.endIndex)]

    guard segment.endTime <= time
    else
    {
      fatalError("segment's end time ≰ to time but matching segment not found")
    }

    // Iteratively create segments until one is created whose `timeInterval`
    // contains `time`.
    while !segment.timeInterval.contains(time)
    {
      segment = advance(segment: segment)
      segments.append(segment)
    }

    guard segment.timeInterval.contains(time)
    else
    {
      fatalError("segment to return does not contain time specified")
    }

    return segments.index(before: segments.endIndex)
  }

  /// Returns a new segment that continues the path by connecting to the end
  /// location of `segment`.
  private func advance(segment: Segment) -> Segment
  {
    // Redirect trajectory according to which boundary edge the new location touches
    var velocity = segment.trajectory.velocity

    switch segment.endLocation.unpack
    {
      case (bounds.minX, _),
           (bounds.maxX, _):
        // Touched a horizontal boundary.

        velocity.dx = -velocity.dx

      case (_, bounds.minY),
           (_, bounds.maxY):
        // Touched a vertical boundary.

        velocity.dy = -velocity.dy

      default:
        fatalError("next location should contact an edge of the player")
    }

    // Create a trajectory with the calculated vector rooted at `segment.endLocation`.
    let nextTrajectory = Trajectory(velocity: velocity, position: segment.endLocation)

    // Create a segment with the new trajectory with a start time equal to
    // `segment.endTime`.
    let nextSegment = Segment(trajectory: nextTrajectory,
                              time: segment.endTime,
                              bounds: bounds)

    return nextSegment
  }

  /// Returns a brief description of the path.
  var description: String
  {
    "Node.Path { startTime: \(startTime); segments: \(segments.count) }"
  }

  /// Returns an exhaustive description of the path.
  var debugDescription: String
  {
    var result = "Node.Path {\n\t"

    result += [
      "bounds: \(bounds)",
      "startTime: \(startTime)",
      "initialTrajectory: \(initialTrajectory)",
      "segments: [\n\t\t",
    ].joined(separator: "\n\t")

    result += segments.map { $0.description.indented(by: 2,
                                                     preserveFirst: true,
                                                     useTabs: true) }
      .joined(separator: ",\n\t\t")

    result += "\n\t]\n}"

    return result
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension FlightPath
{
  /// A struct representing a line segment within a path.
  struct Segment: Comparable, CustomStringConvertible
  {
    /// The position, angle and velocity describing the segment.
    let trajectory: Trajectory

    /// The start and stop time of the segment expressed as a bar-beat time interval.
    let timeInterval: Range<BarBeatTime>

    /// The start and stop time of the segment expressed as a tick interval.
    let tickInterval: Range<MIDITimeStamp>

    /// The total elapsed time at the start of the segment.
    var startTime: BarBeatTime { timeInterval.lowerBound }

    /// The total elapsed time at the end of the segment.
    var endTime: BarBeatTime { timeInterval.upperBound }

    /// The elapsed time from start to end.
    var totalTime: BarBeatTime { timeInterval.upperBound - timeInterval.lowerBound }

    /// The total elapsed ticks at the start of the segment.
    var startTicks: MIDITimeStamp { tickInterval.lowerBound }

    /// The total elapsed ticks at the end of the segment.
    var endTicks: MIDITimeStamp { tickInterval.upperBound }

    /// The number of elapsed ticks from start to end.
    var totalTicks: MIDITimeStamp
    {
      endTicks > startTicks ? endTicks - startTicks : 0
    }

    /// The starting point of the segment.
    var startLocation: CGPoint { trajectory.position }

    /// The ending point of the segment.
    let endLocation: CGPoint

    /// The length of the segment in points.
    let length: CGFloat

    /// Returns the point along the segment with the associated `time` or `nil`.
    func location(for time: BarBeatTime) -> CGPoint?
    {
      // Check that the segment has a location for `time`.
      guard timeInterval.contains(time) else { return nil }

      // Calculate the total ticks from start to `time`.
      let 𝝙ticks = CGFloat(time.ticks - startTime.ticks)

      // Calculate what fraction of the total ticks from start to end `𝝙ticks` represents.
      let ratio = 𝝙ticks / CGFloat(tickInterval.count)

      // Calculate the change in x and y from start to end
      let (𝝙x, 𝝙y) = *(endLocation - startLocation)

      // Start with the segment's starting position
      var result = startLocation

      // Add the fractional x and y values
      result.x += ratio * 𝝙x
      result.y += ratio * 𝝙y

      return result
    }

    /// Default initializer for a new segment.
    ///
    /// - Parameter trajectory: The segment's postion, velocity and angle.
    /// - Parameter time: The total elapsed time at the start of the segment.
    /// - Parameter bounds: The bounding rectangle for the segment.
    init(trajectory: Trajectory, time: BarBeatTime, bounds: CGRect)
    {
      self.trajectory = trajectory

      // Determine the y value at the end of the segment.
      let endY: CGFloat

      switch trajectory.direction.vertical
      {
        case .none:
          // No vertical movement so the y value is the same as at the start of
          // the segment.
          endY = trajectory.position.y

        case .up:
          // Moving up so the y value is that of the maximum point.

          endY = bounds.maxY

        case .down:
          // Moving down so the y value is that of the minimum point.

          endY = bounds.minY
      }

      // Calculate the y-projected end location, which will be the segment point
      // where y is `endY` or `nil` if the point lies outside of the bounding box.
      let pY: CGPoint? = {
        let (x, y) = *trajectory.position
        let p = CGPoint(x: (endY - y + trajectory.slope * x) / trajectory.slope, y: endY)
        guard (bounds.minX ... bounds.maxX).contains(p.x) else { return nil }
        return p
      }()

      // Determine the x value at the end of the segment.
      let endX: CGFloat

      switch trajectory.direction.horizontal
      {
        case .none:
          // No horizontal movement so the x value is the same as at the start of
          // the segment.

          endX = trajectory.position.x

        case .left:
          // Moving left so the x value is that of the minimum point.

          endX = bounds.minX

        case .right:
          // Moving right so the x value is that of the maximum point.

          endX = bounds.maxX
      }

      // Calculate the x-projected end location, which will be the segment point
      // where x is `endX` or `nil` if the point lies outside of the bounding box.
      let pX: CGPoint? = {
        let (x, y) = *trajectory.position
        let p = CGPoint(x: endX, y: trajectory.slope * (endX - x) + y)
        guard (bounds.minY ... bounds.maxY).contains(p.y) else { return nil }
        return p
      }()

      // Determine the value for `endLocation` using the two projected points.
      switch (pY, pX)
      {
        case let (pY?, pX?)
              where trajectory.position.distanceTo(pY) < trajectory.position.distanceTo(pX):
          // Neither projection is nil, the y projection is closer so end there.

          endLocation = pY

        case let (_, pX?):
          // The y projection is nil or the x projection is no further away so end
          // at `pX`.
          endLocation = pX

        case let (pY?, _):
          // The x projection is nil so end at `pY`.
          endLocation = pY

        default:
          fatalError("at least one of projected end points should be valid")
      }

      // Calculate the length of the segment in points.
      length = trajectory.position.distanceTo(endLocation)

      // Calculate the change in time from start to end in seconds.
      let 𝝙t = trajectory.time(from: trajectory.position, to: endLocation)

      // Set the time and tick intervals.
      let lowerBound = time
      let upperBound = BarBeatTime(seconds: time.seconds + 𝝙t)
      assert(lowerBound <= upperBound)

      timeInterval = lowerBound ..< upperBound
      tickInterval = timeInterval.lowerBound.ticks ..< timeInterval.upperBound.ticks
    }

    /// For the purpose of ordering, only the times are considered.
    static func == (lhs: Segment, rhs: Segment) -> Bool
    {
      lhs.startTime == rhs.startTime
    }

    /// For the purpose of ordering, only the times are considered.
    static func < (lhs: Segment, rhs: Segment) -> Bool
    {
      lhs.startTime < rhs.startTime
    }

    /// Detailed description of the segment's data.
    var description: String
    {
      """
      Segment {
        trajectory: \(trajectory)
        endLocation: \(endLocation)
        timeInterval: \(timeInterval)
        totalTime: \(endTime - startTime)
        tickInterval: \(tickInterval)
        totalTicks: \(totalTicks)
        length: \(length)
      }
      """
    }
  }
}
