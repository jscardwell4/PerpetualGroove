//
//  BarBeatTimeTests.swift
//  BarBeatTimeTests
//
//  Created by Jason Cardwell on 1/21/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
import MoonKit
@testable import Groove

final class BarBeatTimeTests: XCTestCase {

  func testRawValue() {
    let time = BarBeatTime(rawValue: "4:3/4.2/480@120₁")
    XCTAssertEqual(time?.bar, 4)
    XCTAssertEqual(time?.beat, 3)
    XCTAssertEqual(time?.subbeat, 2)
    XCTAssertEqual(time?.subbeatDivisor, 480)
    XCTAssertEqual(time?.beatsPerBar, 4)
    XCTAssertEqual(time?.beatsPerMinute, 120)
    XCTAssertEqual(time?.base, BarBeatTime.Base.One)
  }

  func testEquality() {
    XCTAssertEqual(
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertEqual(
      BarBeatTime(bar: 3, beat: 2, subbeat: 1, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.Zero),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertEqual(
      BarBeatTime(bar: 3, beat: 7, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertNotEqual(
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 3, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertNotEqual(
      BarBeatTime(bar: 4, beat: 2, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertNotEqual(
      BarBeatTime(bar: 4, beat: 3, subbeat: 1, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertNotEqual(
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 960, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertNotEqual(
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 2, beatsPerMinute: 120, base: BarBeatTime.Base.One),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )
    XCTAssertNotEqual(
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.Zero),
      BarBeatTime(bar: 4, beat: 3, subbeat: 2, subbeatDivisor: 480, beatsPerBar: 4, beatsPerMinute: 120, base: BarBeatTime.Base.One)
    )

  }

  func testStringLiteral() {
    XCTAssertEqual(BarBeatTime(rawValue: "4:3/4.2/480@120₁"), ("4:3/4.2/480@120₁" as BarBeatTime))
  }

  func testBaseConversion() {
    let time1: BarBeatTime = "10:4/4.298/480@120₁"
    let time0 = time1.zeroBased
    XCTAssertEqual(time0.bar, 9)
    XCTAssertEqual(time0.beat, 3)
    XCTAssertEqual(time0.subbeat, 297)
    XCTAssertEqual(time0.subbeatDivisor, 480)
    XCTAssertEqual(time0.beatsPerBar, 4)
    XCTAssertEqual(time0.beatsPerMinute, 120)
    XCTAssertEqual(time0.base, BarBeatTime.Base.Zero)
  }

  func testAddition() {
    let time1: BarBeatTime = "1:3/4.210/480@120₁"
    let time2: BarBeatTime = "3:1/4.112/480@120₁"
    XCTAssertEqual(time1 + time2, "4:4/4.322/480@120₁")
    XCTAssertEqual(time1 + time2.zeroBased, "4:4/4.322/480@120₁")
    let time3: BarBeatTime = "3:1/4.112/480@120₀"
    XCTAssertEqual(time1 + time3, "6:1/4.323/480@120₁")
    let time4: BarBeatTime = "0:2/4.400/480@120₀"
    let time5: BarBeatTime = "0:0/4.90/480@120₀"
    XCTAssertEqual(time4 + time5, "0:3/4.10/480@120₀")
  }

  func testSubtraction() {
    let time1: BarBeatTime = "1:3/4.210/480@120₁"
    let time2: BarBeatTime = "3:1/4.112/480@120₁"
    XCTAssertEqual(time2 - time1, "1:1/4.382/480@120₁")
    XCTAssertEqual(time2 - time1.zeroBased, "1:1/4.382/480@120₁")
    let time3: BarBeatTime = "3:1/4.112/480@120₀"
    XCTAssertEqual(time3 - time1, "2:2/4.383/480@120₀")
    let time4: BarBeatTime = "0:2/4.400/480@120₀"
    let time5: BarBeatTime = "0:0/4.90/480@120₀"
    XCTAssertEqual(time5 - time4, "-1:1/4.170/480@120₀")
  }

  func testSeconds() {
    let time1 = BarBeatTime(seconds: 0.5, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .Zero)
    XCTAssertEqual(time1.bar, 0)
    XCTAssertEqual(time1.beat, 1)
    XCTAssertEqual(time1.subbeat, 0)
    XCTAssertEqual(time1.seconds, 0.5)
    let time2 = BarBeatTime(seconds: 0.5, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .One)
    XCTAssertEqual(time2.bar, 1)
    XCTAssertEqual(time2.beat, 2)
    XCTAssertEqual(time2.subbeat, 1)
    XCTAssertEqual(time2.seconds, 0.5)
    let time3 = BarBeatTime(seconds: 3.5, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .Zero)
    XCTAssertEqual(time3.bar, 1)
    XCTAssertEqual(time3.beat, 3)
    XCTAssertEqual(time3.subbeat, 0)
    XCTAssertEqual(time3.seconds, 3.5)
    let time4 = BarBeatTime(seconds: 3.5, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .One)
    XCTAssertEqual(time4.bar, 2)
    XCTAssertEqual(time4.beat, 4)
    XCTAssertEqual(time4.subbeat, 1)
    XCTAssertEqual(time4.seconds, 3.5)
    let time5 = BarBeatTime(seconds: 3.34, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .Zero)
    XCTAssertEqual(time5.bar, 1)
    XCTAssertEqual(time5.beat, 2)
    XCTAssertEqual(time5.subbeat, 326)
    XCTAssertEqualWithAccuracy(time5.seconds, 3.34, accuracy: 0.001)
    let time6 = BarBeatTime(seconds: 3.34, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .One)
    XCTAssertEqual(time6.bar, 2)
    XCTAssertEqual(time6.beat, 3)
    XCTAssertEqual(time6.subbeat, 327)
    XCTAssertEqualWithAccuracy(time6.seconds, 3.34, accuracy: 0.001)
  }

  func testTicks() {
    let time1: BarBeatTime = "1:3/4.430/480@120₀"
    XCTAssertEqual(time1.ticks, 3790)
    let time2: BarBeatTime = "2:4/4.431/480@120₁"
    XCTAssertEqual(time2.ticks, 3790)
    let time3 = BarBeatTime(tickValue: 3790, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .Zero)
    XCTAssertEqual(time3, time1)
    XCTAssertEqual(time3, time2)
    let time4 = BarBeatTime(tickValue: 3790, beatsPerBar: 4, subbeatDivisor: 480, beatsPerMinute: 120, base: .One)
    XCTAssertEqual(time4, time1)
    XCTAssertEqual(time4, time2)
  }

  func testIntervals() {
    let time: BarBeatTime = "8:3/4.478/480@120₀"
    let interval: HalfOpenInterval<BarBeatTime> = "9:3/4.310@120₀" ..< "10:2/4.30/480@120₀"
    XCTAssert(interval ∌ time)
  }
}
