//
//  MIDINodePathTests.swift
//  MIDINodePathTests
//
//  Created by Jason Cardwell on 1/15/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
//import MoonKit
//import Nimble
//@testable import Groove

final class MIDINodePathTests: XCTestCase {

//  typealias Trajectory = MIDINode.Trajectory
//
//  let startTime: BarBeatTime = 3∶3.54
//  let initialPoint = CGPoint(x: 206.8070373535156, y: 143.28111267089841)
//  let initialVelocity = CGVector(dx: 144.9763520779608, dy: -223.41468148063581)
//  var initialTrajectory: Trajectory { return Trajectory(velocity: initialVelocity, position: initialPoint) }
//  let playerSize = CGSize(square: 447)
//
//  func testTrajectory() {
//    let initialTrajectory = self.initialTrajectory
//    expect(initialTrajectory.position.x) == initialPoint.x
//    expect(initialTrajectory.position.y) == initialPoint.y
//    expect(initialTrajectory.velocity.dx) == initialVelocity.dx
//    expect(initialTrajectory.velocity.dy) == initialVelocity.dy
//    expect(initialTrajectory.direction) == Trajectory.Direction.diagonal(.down, .right)
//    expect(initialTrajectory.direction.reversed) == Trajectory.Direction.diagonal(.up, .left)
//
///* 
//    let pointAtX = initialTrajectory.point(atX: 426)
//    expect(pointAtX.x) == 426
//    expect(pointAtX.y).to(equalWithAccuracy(-194.504500158752, 0.0001))
//
//    let pointAtY = initialTrajectory.point(atY: 21)
//    expect(pointAtY.x).to(equalWithAccuracy(286.156655407142, 0.0001))
//    expect(pointAtY.y) == 21
// */
//  }
//
//
//  func testSegment() {
//    let path = MIDINode.Path(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
//    let segment = path.initialSegment
//    expect(segment.endLocation.x).to(equalWithAccuracy(286.156655407142, 0.0001))
//    expect(segment.endLocation.y) == 21
//    expect(segment.endTime) == 3∶3.145
//  }
//
//  func testCreation() {
//    let path = MIDINode.Path(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
////    expect(path.min) == CGPoint(x: 21, y: 21)
////    expect(path.max) == CGPoint(x: 426, y: 426)
//    expect(path.startTime) == startTime
//    expect(path.initialTrajectory) == initialTrajectory
//  }
//
//  func testSegmentForTime() {
//    let path = MIDINode.Path(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
//    let time1: BarBeatTime = 10∶1.250
//    let segment1 = path.segmentIndex(for: time1)
//    guard expect(segment1).toNot(beNil()) else { return }
//    expect(path[segment1!].timeInterval.contains(time1)) == true
//
//    let time2: BarBeatTime = 6∶3.210
//    let segment2 = path.segmentIndex(for: time2)
//    guard expect(segment2).toNot(beNil()) else { return }
//    expect(path[segment2!].timeInterval.contains(time2)) == true
//
//    let time3: BarBeatTime = 7∶3.261
//    let segment3 = path.segmentIndex(for: time3)
//    guard expect(segment3).toNot(beNil()) else { return }
//    expect(path[segment3!].timeInterval.contains(time3)) == true
//  }
//
//  func testLocationForTime() {
//    let path = MIDINode.Path(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
//    let segmentIndex = path.segmentIndex(for: 11∶1.116)
//    guard expect(segmentIndex).toNot(beNil()) else { return }
//    let segment = path[segmentIndex!]
//    let location = segment.location(for: 11∶1.116)
//    expect(location).toNot(beNil())
//  }
//
//  func testSegmentGenerationPerformance() {
//    let path = MIDINode.Path(trajectory: initialTrajectory, playerSize: playerSize, time: startTime)
//    let time: BarBeatTime = 581∶1.116
//    measure {
//      let segmentIndex = path.segmentIndex(for: time)
//      let segment = path[segmentIndex!]
//      let _ = segment.location(for: time)
//    }
//  }

}
