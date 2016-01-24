//
//  MIDINodePathTests.swift
//  MIDINodePathTests
//
//  Created by Jason Cardwell on 1/15/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
import MoonKit
@testable import Groove

final class MIDINodePathTests: XCTestCase {

  let startTime: BarBeatTime = "3:3/4.54/480@120₁"
  let initialPoint = CGPoint(x: 206.8070373535156, y: 143.28111267089841)
  let initialVelocity = CGVector(dx: 144.9763520779608, dy: -223.41468148063581)
  var initialTrajectory: Trajectory { return Trajectory(vector: initialVelocity, point: initialPoint) }
  let playerSize = CGSize(square: 447)

  func testTrajectory() {
    XCTAssertEqual(initialTrajectory.x, initialPoint.x)
    XCTAssertEqual(initialTrajectory.y, initialPoint.y)
    XCTAssertEqual(initialTrajectory.dx, initialVelocity.dx)
    XCTAssertEqual(initialTrajectory.dy, initialVelocity.dy)
    XCTAssertEqual(initialTrajectory.direction, Trajectory.Direction.Diagonal(.Down, .Right))
    XCTAssertEqual(initialTrajectory.direction.reversed, Trajectory.Direction.Diagonal(.Up, .Left))
    XCTAssertEqual(initialTrajectory.pointAtX(426), CGPoint(x: 426, y: -228.874708364744))
    XCTAssertEqual(initialTrajectory.pointAtY(21), CGPoint(x: 263.8534326608042, y: 21))
  }

  func testSegment() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let segment = path.initialSegment
    XCTAssertEqualWithAccuracy(segment.endLocation.x, 263.8534326608042, accuracy: 0.0001)
    XCTAssertEqual(segment.endLocation.y, 21)
    XCTAssertEqual(segment.endTime, "4:1/4.473/480@120₁")
  }

  func testCreation() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    XCTAssertEqual(path.min, CGPoint(x: 21, y: 21))
    XCTAssertEqual(path.max, CGPoint(x: 426, y: 426))
    XCTAssertEqual(path.startTime, startTime)
    XCTAssertEqual(path.initialTrajectory, initialTrajectory)
    let _ = path.segmentForTime("10:1/4.250/480@120₁")
    print(path)
  }

  func testSegmentForTime() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let time1: BarBeatTime = "10:1/4.250/480@120₁"
    let segment1 = path.segmentForTime(time1)
    print(segment1)
    XCTAssertNotNil(segment1)
    XCTAssert(segment1?.timeInterval.contains(time1) == true)
    let time2: BarBeatTime = "6:3/4.210/480@120₁"
    let segment2 = path.segmentForTime(time2)
    XCTAssertNotNil(segment2)
    XCTAssert(segment2?.timeInterval.contains(time2) == true)
    print(segment2)
    let time3: BarBeatTime = "7:1/4.469/480@120₁"
    let segment3 = path.segmentForTime(time3)
    XCTAssertNotNil(segment3)
    XCTAssert(segment3?.timeInterval.contains(time3) == true)
    print(segment3)
    print(path)
  }

  func testLocationForTime() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let time1: BarBeatTime = "11:1/4.116/480@120₁"
    /*
      Segment {
        trajectory: { x: 324.606743623764; y: 21.0; dx: -144.976352077961; dy: 223.414681480636; direction: Up-Left }
        endLocation: (61.7975933814904, 426.0)
        timeInterval: 010:2.030..<011:4.157
        totalTime: 001:2.127
        tickInterval: 17789..<20796
        totalTicks: 3007
        length: 482.797731406296
      }
    */
    let segment = path.segmentForTime(time1)!

    print("segment =", segment)
    let trajectory = segment.trajectory
    print("trajectory =", trajectory)

    let ticks = time1.ticks
    let startTicks = segment.startTime.ticks
    let relativeTicks = ticks - startTicks
    print("ticks =", ticks)
    print("startTicks =", startTicks)
    print("relativeTicks =", relativeTicks)


    let location1 = trajectory.pointAtTime(relativeTicks)
    print("location1 =", location1)
    let location2 = segment.locationForTime(time1)
    print("location2 =", location2)
//    XCTAssertNotNil(location1)
  }
}
