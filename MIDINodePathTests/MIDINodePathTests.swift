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
  let initialPoint = CGPoint(x: 143.2811126708984, y: 206.8070373535156)
  let initialVelocity = CGVector(dx: 144.9763520779608, dy: -223.4146814806358)
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

  func _testSegment() {

  }

  func testCreation() {
    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
    XCTAssertEqual(path.min, CGPoint(x: 21, y: 21))
    XCTAssertEqual(path.max, CGPoint(x: 426, y: 426))
    XCTAssertEqual(path.startTime, startTime)
    XCTAssertEqual(path.initialTrajectory, initialTrajectory)
//    let segment = path.initialSegment
    print(path)
  }

  func testSegmentForTime() {
//    let path = MIDINodePath(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
  }

}
