//
//  CABarBeatTime.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import struct AudioToolbox.CABarBeatTime
import typealias CoreMIDI.MIDITimeStamp
import MoonKit

// MARK: - Wrapping CABarBeatTime in an NSValue

extension NSValue {
  convenience init(var barBeatTime: CABarBeatTime) {
    self.init(bytes: &barBeatTime, objCType:"{CABarBeatTime=iSSSS}".withCString {$0})
  }
  var barBeatTimeValue: CABarBeatTime? {
    guard String.fromCString(objCType) == "{CABarBeatTime=iSSSS}" else { return nil }
    let pointer = UnsafeMutablePointer<CABarBeatTime>.alloc(1)
    let voidPointer = UnsafeMutablePointer<Void>(pointer)
    getValue(voidPointer)
    return pointer.memory
  }
}

// MARK: - CustomStringConvertible
extension CABarBeatTime: CustomStringConvertible {
  public var description: String {
    let barString = String(bar, radix: 10, pad: 3)
    let beatString = String(beat)
    let subbeatString = String(subbeat, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(barString) : \(beatString) . \(subbeatString)"
  }
}

// MARK: - CustomDebugStringConvertible
extension CABarBeatTime: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "{bar: \(bar); beat: \(beat); subbeat: \(subbeat); subbeatDivisor: \(subbeatDivisor); ticks: \(ticks)}"
  }
}

// MARK: - StringLiteralConvertible
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
                         subbeatDivisor: UInt16(Sequencer.resolution),
                         reserved: 0)
  }
  public init(extendedGraphemeClusterLiteral value: String) { self.init(value) }
  public init(unicodeScalarLiteral value: String) { self.init(value) }
  public init(stringLiteral value: String) { self.init(value) }
}

// MARK: - Hashable
extension CABarBeatTime: Hashable {
  public var hashValue: Int { return "\(bar).\(beat).\(subbeat)╱\(subbeatDivisor)".hashValue }
}

public func ==(lhs: CABarBeatTime, rhs: CABarBeatTime) -> Bool { return lhs.hashValue == rhs.hashValue }

// MARK: - Comparable
extension CABarBeatTime: Comparable {}

public func <(lhs: CABarBeatTime, rhs: CABarBeatTime) -> Bool {
  guard lhs.bar == rhs.bar else { return lhs.bar < rhs.bar }
  guard lhs.beat == rhs.beat else { return lhs.beat < rhs.beat }
  guard lhs.subbeatDivisor != rhs.subbeatDivisor else { return lhs.subbeat < rhs.subbeat }
  return lhs.subbeat╱lhs.subbeatDivisor < rhs.subbeat╱rhs.subbeatDivisor
}

// MARK: - Sequencer-related properties and methods
extension CABarBeatTime {

  /**
  addedToBarBeatTime:beatsPerBar:

  - parameter time: CABarBeatTime
  - parameter beatsPerBar: UInt16

  - returns: CABarBeatTime
  */
  public func addedToBarBeatTime(time: CABarBeatTime, beatsPerBar: UInt16) -> CABarBeatTime {
    var bars = bar + time.bar
    var beats = beat + time.beat
    let subbeatsSum = (subbeat╱subbeatDivisor + time.subbeat╱time.subbeatDivisor).fractionWithBase(Int16(subbeatDivisor))
    var subbeats = UInt16(subbeatsSum.numerator)
    if subbeats > subbeatDivisor { beats += subbeats / subbeatDivisor; subbeats %= subbeatDivisor }
    if beats > beatsPerBar { bars += Int32(beats / beatsPerBar); beats %= beatsPerBar }
    return CABarBeatTime(bar: bars, beat: beats, subbeat: subbeats, subbeatDivisor: subbeatDivisor, reserved: 0)
  }

  public static var start: CABarBeatTime {
    return CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: UInt16(Sequencer.resolution), reserved: 0)
  }

  /**
  init:beatsPerBar:subbeatDivisor:

  - parameter tickValue: UInt64
  - parameter beatsPerBar: UInt8 = Sequencer.timeSignature.beatsPerBar
  - parameter subbeatDivisor: UInt16 = Sequencer.time.partsPerQuarter
  */
  init(var tickValue: UInt64,
            beatsPerBar: UInt8 = Sequencer.timeSignature.beatsPerBar,
            subbeatDivisor: UInt16 = Sequencer.time.partsPerQuarter)
  {
    let subbeat = tickValue % UInt64(subbeatDivisor)
    tickValue -= subbeat
    let totalBeats = tickValue / UInt64(subbeatDivisor)
    let beat = totalBeats % UInt64(beatsPerBar) + 1
    let bar = totalBeats / UInt64(beatsPerBar) + 1
    self = CABarBeatTime(bar: Int32(bar),
                         beat: UInt16(beat),
                         subbeat: UInt16(subbeat + 1),
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

  var doubleValue: Double { return doubleValueWithBeatsPerBar(Sequencer.timeSignature.beatsPerBar) }

  /**
  tickValueWithBeatsPerBar:

  - parameter beatsPerBar: UInt8

  - returns: UInt64
  */
  func tickValueWithBeatsPerBar(beatsPerBar: UInt8) -> UInt64 {
    let bar = UInt64(max(Int(self.bar) - 1, 0))
    let beat = UInt64(max(Int(self.beat) - 1, 0))
    let subbeat = UInt64(max(Int(self.subbeat) - 1, 0))
    return (bar * UInt64(beatsPerBar) + beat) * UInt64(subbeatDivisor) + subbeat
  }

  var ticks: MIDITimeStamp { return tickValueWithBeatsPerBar(Sequencer.timeSignature.beatsPerBar) }

}
