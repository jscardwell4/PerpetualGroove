//
//  Slider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import MoonKit

import AudioToolbox

extension CABarBeatTime: CustomStringConvertible {
  public var description: String { return "\(bar).\(beat).\(subbeat)" }
}

extension CABarBeatTime: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "{bar: \(bar); beat: \(beat); subbeat: \(subbeat); subbeatDivisor: \(subbeatDivisor)}"
  }
}

extension CABarBeatTime: StringLiteralConvertible {
  public init(_ string: String) {
    let values = string.split(".")
    guard values.count == 3,
      let bar: Int32 = Int32(values[0]), beat = UInt16(values[1]), subbeat = UInt16(values[2]) else {
        fatalError("Invalid `CABarBeatTime` string literal '\(string)'")
    }
    self = CABarBeatTime(bar: bar,
      beat: beat,
      subbeat: subbeat,
      subbeatDivisor: CABarBeatTime.defaultSubbeatDivisor,
      reserved: 0)
  }
  public init(extendedGraphemeClusterLiteral value: String) { self.init(value) }
  public init(unicodeScalarLiteral value: String) { self.init(value) }
  public init(stringLiteral value: String) { self.init(value) }
}

extension CABarBeatTime: Hashable {
  public var hashValue: Int { return "\(bar).\(beat).\(subbeat)╱\(subbeatDivisor)".hashValue }
}

public func ==(lhs: CABarBeatTime, rhs: CABarBeatTime) -> Bool { return lhs.hashValue == rhs.hashValue }

extension CABarBeatTime {

  public static var start: CABarBeatTime {
    return CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: defaultSubbeatDivisor, reserved: 0)
  }

  public static let defaultSubbeatDivisor: UInt16 = 480

  init(var tickValue: UInt64, beatsPerBar: UInt8, subbeatDivisor: UInt16) {
    let subbeat = tickValue % UInt64(subbeatDivisor)
    tickValue -= subbeat
    let totalBeats = tickValue / UInt64(subbeatDivisor)
    let beat = totalBeats % UInt64(beatsPerBar) + 1
    let bar = totalBeats / UInt64(beatsPerBar) + 1
    self = CABarBeatTime(bar: Int32(bar),
      beat: UInt16(beat),
      subbeat: UInt16(subbeat),
      subbeatDivisor: subbeatDivisor,
      reserved: 0)
  }

  /**
  doubleValueWithBeatsPerBar:

  - parameter beatsPerBar: UInt8

  - returns: Double
  */
  func doubleValueWithBeatsPerBar(beatsPerBar: UInt8) -> Double {
    let bar = Double(max(Int(self.bar) - 1, 0))
    let beat = Double(max(Int(self.beat) - 1, 0))
    let subbeat = Double(max(Int(self.subbeat) - 1, 0))
    return bar * Double(beatsPerBar) + beat + subbeat / Double(subbeatDivisor)
  }

  var tickValue: UInt64 {
    let bar = UInt64(max(Int(self.bar) - 1, 0))
    let beat = UInt64(max(Int(self.beat) - 1, 0))
    let subbeat = UInt64(max(Int(self.subbeat) - 1, 0))
    return (bar * UInt64(4) + beat) * UInt64(subbeatDivisor) + subbeat
  }

  var doubleValue: Double { return doubleValueWithBeatsPerBar(4) }

}

let time = CABarBeatTime(bar: 24, beat: 3, subbeat: 115, subbeatDivisor: 480, reserved: 0)
let ticks = time.tickValue

let time2 = CABarBeatTime(tickValue: ticks, beatsPerBar: 4, subbeatDivisor: 480)

