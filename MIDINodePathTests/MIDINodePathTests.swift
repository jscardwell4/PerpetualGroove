//
//  MIDINodePathTests.swift
//  MIDINodePathTests
//
//  Created by Jason Cardwell on 1/15/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
@testable import Groove

final class MIDINodePathTests: XCTestCase {
    
  func testTrajectory() {
    let point = CGPoint(x: 143.2811126708984, y: 206.8070373535156)
    let vector = CGVector(dx: 144.9763520779608, dy: -223.4146814806358)
    let trajectory = Trajectory(vector: vector, point: point)
  }

}
