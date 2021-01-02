//
//  BarBeatTimeTests.swift
//  BarBeatTimeTests
//
//  Created by Jason Cardwell on 1/21/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import XCTest
import MoonKit
import Nimble
@testable import Groove

final class BarBeatTimeTests: XCTestCase {

  func testEquatable() {
    expect(BarBeatTime(bar: 4, beat: 3, subbeat: 2)) == BarBeatTime(bar: 4, beat: 3, subbeat: 2)
    expect(BarBeatTime(bar: 4, beat: 3, subbeat: 2)) != BarBeatTime(bar: 4, beat: 3, subbeat: 2, isNegative: true)
    expect(BarBeatTime(bar: 3, beat: 7, subbeat: 2)) == BarBeatTime(bar: 4, beat: 3, subbeat: 2)
    expect(BarBeatTime(bar: 4, beat: 3, subbeat: 2)) != BarBeatTime(bar: 3, beat: 3, subbeat: 2)
    expect(BarBeatTime(bar: 4, beat: 2, subbeat: 2)) != BarBeatTime(bar: 4, beat: 3, subbeat: 2)
    expect(BarBeatTime(bar: 4, beat: 3, subbeat: 1)) != BarBeatTime(bar: 4, beat: 3, subbeat: 2)
    expect(BarBeatTime(bar: 4, beat: 3, subbeat: 2, beatsPerBar: 1, beatsPerMinute: 120, subbeatDivisor: 480)) != BarBeatTime(bar: 4, beat: 3, subbeat: 2)
  }

  func testTotalBeats() {
    let time1: BarBeatTime = BarBeatTime(bar: 0, beat: 2, subbeat: 209)
    expect(time1.totalBeats) ==  2 + 209/480
    expect((-time1).totalBeats) ==  -(2 + 209/480)

    let time2: BarBeatTime = BarBeatTime(bar: 2, beat: 0, subbeat: 111)
    expect(time2.totalBeats) ==  8 + 111/480
    expect((-time2).totalBeats) ==  -(8 + 111/480)

    let time3: BarBeatTime = BarBeatTime(bar: 0, beat: 2, subbeat: 400)
    expect(time3.totalBeats) ==  2 + 400/480
    expect((-time3).totalBeats) ==  -(2 + 400/480)

    let time4: BarBeatTime = BarBeatTime(bar: 0, beat: 0, subbeat: 90)
    expect(time4.totalBeats) ==  90/480
    expect((-time4).totalBeats) ==  -90/480
  }

  func testAddition() {
    let time1: BarBeatTime = BarBeatTime(bar: 0, beat: 2, subbeat: 209)
    let time2: BarBeatTime = BarBeatTime(bar: 2, beat: 0, subbeat: 111)
    expect(time1 + time2) ==  BarBeatTime(bar: 2, beat: 2, subbeat: 320)

    let time3: BarBeatTime = BarBeatTime(bar: 0, beat: 2, subbeat: 400)
    let time4: BarBeatTime = BarBeatTime(bar: 0, beat: 0, subbeat: 90)
    expect(time3 + time4) ==  BarBeatTime(bar: 0, beat: 3, subbeat: 10)
  }

  func testSubtraction() {
    let time1: BarBeatTime = BarBeatTime(bar: 0, beat: 2, subbeat: 209)
    let time2: BarBeatTime = BarBeatTime(bar: 2, beat: 0, subbeat: 111)
    expect(time2 - time1) ==  BarBeatTime(bar: 1, beat: 1, subbeat: 382)

    let time3: BarBeatTime = BarBeatTime(bar: 3, beat: 1, subbeat: 112)
    expect(time3 - time1) ==  BarBeatTime(bar: 2, beat: 2, subbeat: 383)

    let time4: BarBeatTime = BarBeatTime(bar: 0, beat: 2, subbeat: 400)
    let time5: BarBeatTime = BarBeatTime(bar: 0, beat: 0, subbeat: 90)
    expect(time5 - time4) ==  BarBeatTime(bar: 0, beat: 2, subbeat: 310, isNegative: true)
  }

  func testSeconds() {
    let time1 = BarBeatTime(seconds: 0.5)
    expect(time1.bar) == 0
    expect(time1.beat) == 1
    expect(time1.subbeat) == 0
    expect(time1.seconds) == 0.5

    let time2 = BarBeatTime(seconds: 0.5)
    expect(time2.bar) == 0
    expect(time2.beat) == 1
    expect(time2.subbeat) == 0
    expect(time2.seconds) == 0.5

    let time3 = BarBeatTime(seconds: 3.5)
    expect(time3.bar) == 1
    expect(time3.beat) == 3
    expect(time3.subbeat) == 0
    expect(time3.seconds) == 3.5

    let time4 = BarBeatTime(seconds: 3.5)
    expect(time4.bar) == 1
    expect(time4.beat) == 3
    expect(time4.subbeat) == 0
    expect(time4.seconds) == 3.5

    let time5 = BarBeatTime(seconds: 3.34)
    expect(time5.bar) == 1
    expect(time5.beat) == 2
    expect(time5.subbeat) == 326
    expect(time5.seconds).to(beCloseTo(3.34, within: 0.001))

    let time6 = BarBeatTime(seconds: 3.34)
    expect(time6.bar) == 1
    expect(time6.beat) == 2
    expect(time6.subbeat) == 326
    expect(time6.seconds).to(beCloseTo(3.34, within: 0.001))
  }

  func testTicks() {
    expect(BarBeatTime(bar: 1, beat: 3, subbeat: 430).ticks) == 3790
    expect(BarBeatTime(tickValue: 3790)) == BarBeatTime(bar: 1, beat: 3, subbeat: 430)
  }

  func testIntervals() {
    let interval: Range<BarBeatTime> = BarBeatTime(bar: 9, beat: 3, subbeat: 310) ..< BarBeatTime(bar: 10, beat: 2, subbeat: 30)
    expect(interval.contains(BarBeatTime(bar: 8, beat: 3, subbeat: 478))) == false
    expect(interval.contains(BarBeatTime(bar: 10, beat: 0, subbeat: 19))) == true
  }

  func testNegation() {
    let time = -BarBeatTime(bar: 2, beat: 1, subbeat: 342)
    expect(time.bar) == 2
    expect(time.beat) == 1
    expect(time.subbeat) == 342
    expect(time.isNegative) == true
  }

  func testBeat() {
    var time = BarBeatTime(bar: 5, beat: 2, subbeat: 19)
    expect(time.bar) == 5
    expect(time.beat) == 2
    expect(time.subbeat) == 19

    time.beat = 0
    expect(time.bar) == 5
    expect(time.beat) == 0
    expect(time.subbeat) == 19

    time.beat = 10
    expect(time.bar) == 5
    expect(time.beat) == 10
    expect(time.subbeat) == 19
  }

  func testSubbeat() {
    var time = BarBeatTime(bar: 5, beat: 2, subbeat: 19)
    expect(time.bar) == 5
    expect(time.beat) == 2
    expect(time.subbeat) == 19

    time.subbeat = 201
    expect(time.bar) == 5
    expect(time.beat) == 2
    expect(time.subbeat) == 201

    time.subbeat = 492
    expect(time.bar) == 5
    expect(time.beat) == 3
    expect(time.subbeat) == 12
  }

  func testSubbeatDivisor() {
    var time = BarBeatTime(bar: 4, beat: 3, subbeat: 193)
    expect(time.subbeatDivisor) == 480

    time.subbeatDivisor = 480
    expect(time.subbeatDivisor) == 480
    expect(time.subbeat) == 193
    expect(time.beat) == 3
    expect(time.bar) == 4

    time.subbeatDivisor = 240
    expect(time.subbeatDivisor) == 240
    expect(time.subbeat) == 193
    expect(time.beat) == 2
    expect(time.bar) == 9

  }

  func testStringConversion() {
    guard let time1 = BarBeatTime(rawValue: "4:3.2") else {
      XCTFail("unexpected nil value return from `BarBeatTime(rawValue:)`")
      return
    }

    expect(time1.bar) == 4
    expect(time1.beat) == 3
    expect(time1.subbeat) == 2
    expect(time1.subbeatDivisor) == 480
    expect(time1.beatsPerBar) == 4
    expect(time1.beatsPerMinute) == 120
    expect(time1.description) == "4:3/4.2/480@120"
    expect(BarBeatTime(time1.description)) == time1

    guard let time2 = BarBeatTime(rawValue: "-4:3.2") else {
      XCTFail("unexpected nil value return from `BarBeatTime(rawValue:)`")
      return
    }

    expect(time2.bar) ==  4
    expect(time2.beat) ==  3
    expect(time2.subbeat) ==  2
    expect(time2.subbeatDivisor) ==  480
    expect(time2.beatsPerBar) ==  4
    expect(time2.beatsPerMinute) ==  120
    expect(time2.isNegative) ==  true
    expect(time2.description) == "-4:3/4.2/480@120"
    expect(BarBeatTime(time2.description)) == time2

    expect(BarBeatTime(rawValue: "blah")).to(beNil())
  }

  func testComparable() {
    expect(BarBeatTime(bar: 9, beat: 2, subbeat: 123)) < BarBeatTime(bar: 9, beat: 2, subbeat: 124)
    expect(BarBeatTime(bar: 0, beat: 3, subbeat: 479)) < BarBeatTime(bar: 1, beat: 0, subbeat: 0)
  }

  func testStrideable() {
    expect(BarBeatTime(bar: 3, beat: 2, subbeat: 15).advanced(by: BarBeatTime(bar: 3, beat: 0, subbeat: 12))) == BarBeatTime(bar: 6, beat: 2, subbeat: 27)
    expect(BarBeatTime(bar: 3, beat: 2, subbeat: 15).advanced(by: BarBeatTime(bar: 3, beat: 0, subbeat: 12, isNegative: true))) == BarBeatTime(bar: 0, beat: 2, subbeat: 3)
    expect(BarBeatTime(bar: 3, beat: 2, subbeat: 15).distance(to: BarBeatTime(bar: 6, beat: 2, subbeat: 27))) == BarBeatTime(bar: 3, beat: 0, subbeat: 12)
    expect(BarBeatTime(bar: 3, beat: 2, subbeat: 15).distance(to: BarBeatTime(bar: 0, beat: 2, subbeat: 3))) == BarBeatTime(bar: 3, beat: 0, subbeat: 12, isNegative: true)
  }

  func testDisplay() {
    expect(BarBeatTime(bar: 0, beat: 2, subbeat: 45).display) == "001:3.046"
    expect(BarBeatTime(bar: 4, beat: 0, subbeat: 0).display) == "005:1.001"
  }

  func testBeatUnit() {
    var time = BarBeatTime(bar: 26, beat: 2, subbeat: 119, beatsPerBar: 4, beatsPerMinute: 120, subbeatDivisor: 480)
    expect(time.beatUnit) == 1╱4
    expect(time.beatUnitTime) == BarBeatTime(bar: 0, beat: 1, subbeat: 0, beatsPerBar: 4, beatsPerMinute: 120, subbeatDivisor: 480)

    time.beatsPerBar = 6
    expect(time.beatUnit) == 1╱6
    expect(time.beatUnitTime) == BarBeatTime(bar: 0, beat: 1, subbeat: 0, beatsPerBar: 6, beatsPerMinute: 120, subbeatDivisor: 480)
  }

  func testSubbeatUnit() {
    var time = BarBeatTime(bar: 26, beat: 2, subbeat: 119, beatsPerBar: 4, beatsPerMinute: 120, subbeatDivisor: 480)
    expect(time.subbeatUnit) == 1╱480
    expect(time.subbeatUnitTime) == BarBeatTime(bar: 0, beat: 0, subbeat: 1, beatsPerBar: 4, beatsPerMinute: 120, subbeatDivisor: 480)

    time.subbeatDivisor = 240
    expect(time.subbeatUnit) == 1╱240
    expect(time.subbeatUnitTime) == BarBeatTime(bar: 0, beat: 0, subbeat: 1, beatsPerBar: 4, beatsPerMinute: 120, subbeatDivisor: 240)
  }

  func testBeatsPerBar() {
    var time = BarBeatTime(bar: 4, beat: 3, subbeat: 193)
    expect(time.beatsPerBar) == 4

    time.beatsPerBar = 4
    expect(time.beatsPerBar) == 4
    expect(time.subbeat) == 193
    expect(time.beat) == 3
    expect(time.bar) == 4

    time.beatsPerBar = 2
    expect(time.beatsPerBar) == 2
    expect(time.subbeat) == 193
    expect(time.beat) == 1
    expect(time.bar) == 9
  }

  func testRatioOperatorInitializer() {
    expect(3∶2.312) == BarBeatTime(bar: 3, beat: 2, subbeat: 312)
    expect(3∶0.0) == BarBeatTime(bar: 3, beat: 0, subbeat: 0)
    expect(0∶0.0) == BarBeatTime(bar: 0, beat: 0, subbeat: 0)
    expect(0∶0.24) == BarBeatTime(bar: 0, beat: 0, subbeat: 24)
    expect(2∶5.0) == BarBeatTime(bar: 3, beat: 1, subbeat: 0)
    expect(0∶0.9339) == BarBeatTime(bar: 4, beat: 3, subbeat: 219)
  }

}
