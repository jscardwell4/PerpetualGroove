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
    let pointAtX = initialTrajectory.pointAtX(426)
    XCTAssertEqual(pointAtX.x, 426)
    XCTAssertEqualWithAccuracy(pointAtX.y, -194.504500158752, accuracy: 0.0001)

    let pointAtY = initialTrajectory.pointAtY(21)
    XCTAssertEqualWithAccuracy(pointAtY.x, 286.156655407142, accuracy: 0.0001)
    XCTAssertEqual(pointAtY.y, 21)
  }

  func testSegment() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let segment = path.initialSegment
    XCTAssertEqualWithAccuracy(segment.endLocation.x, 286.156655407142, accuracy: 0.0001)
    XCTAssertEqual(segment.endLocation.y, 21)
    XCTAssertEqual(segment.endTime, "3:3/4.145/480@120₁")
  }

  func testCreation() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    XCTAssertEqual(path.min, CGPoint(x: 21, y: 21))
    XCTAssertEqual(path.max, CGPoint(x: 426, y: 426))
    XCTAssertEqual(path.startTime, startTime)
    XCTAssertEqual(path.initialTrajectory, initialTrajectory)
  }

  func testSegmentForTime() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let time1: BarBeatTime = "10:1/4.250/480@120₁"
    let segment1 = path.segmentForTime(time1)
    XCTAssertNotNil(segment1)
    XCTAssert(segment1?.timeInterval.contains(time1) == true)
    let time2: BarBeatTime = "6:3/4.210/480@120₁"
    let segment2 = path.segmentForTime(time2)
    XCTAssertNotNil(segment2)
    XCTAssert(segment2?.timeInterval.contains(time2) == true)
    let time3: BarBeatTime = "7:3/4.261/480@120₁"
    let segment3 = path.segmentForTime(time3)
    XCTAssertNotNil(segment3)
    XCTAssert(segment3?.timeInterval.contains(time3) == true)
    print(path)
  }

  func testLocationForTime() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let location = path.locationForTime("11:1/4.116/480@120₁")
    XCTAssertNotNil(location)
  }

  func testSegmentGenerationPerformance() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    let time: BarBeatTime = "581:1/4.116/480@120₁"
    measure { let _ = path.locationForTime(time) }
  }

}
