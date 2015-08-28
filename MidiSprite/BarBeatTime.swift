//
//  BarBeatTime.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/26/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreMIDI
import MoonKit

extension CABarBeatTime: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { return "\(bar).\(beat).\(subbeat)" }
  public var debugDescription: String {
    return "{bar: \(bar); beat: \(beat); subbeat: \(subbeat); subbeatDivisor: \(subbeatDivisor)}"
  }
  public static let start = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: 1, reserved: 0)
  
  func doubleValueWithBeatsPerBar(beatsPerBar: UInt8) -> Double {
    return Double(bar) * Double(beatsPerBar) + Double(beat) + 1 / Double(subbeatDivisor)
  }
}

final class BarBeatTime: Hashable, CustomStringConvertible {

  enum SimpleTimeSignature {
    case FourFour
    case ThreeFour
    case TwoFour
    case Other (UInt8, UInt8)

    var beatUnit: UInt8 { if case .Other(_, let u) = self { return u } else { return 4 } }
    var beatsPerBar: UInt8 {
      switch self {
        case .FourFour:        return 4
        case .ThreeFour:       return 3
        case .TwoFour:         return 2
        case .Other(let b, _): return b
      }
    }
  }

  private var client = MIDIClientRef()  /// Client for receiving MIDI clock
  private var inPort = MIDIPortRef()    /// Port for receiving MIDI clock

  /** The resolution used to divide a beat into subbeats */
  var partsPerQuarter: UInt16 {
    get { return time.subbeatDivisor }
    set {
      time.subbeatDivisor = newValue
      let n = clockCount.numerator % Int64(newValue)
      clockCount = n╱Int64(newValue)
      beatInterval = Int64(Float(newValue) * 0.25)╱Int64(newValue)
    }
  }

  private var validBeats: Range<UInt16>
  private var validSubbeats: Range<UInt16>

  /** Stores the musical representation of the current time */
  private(set) var time: CABarBeatTime {
    didSet {
      guard validBeats.contains(time.beat) && validSubbeats.contains(time.subbeat) else { fatalError("corrupted time '\(time)'") }
    }
  }

  /** The portion of `clockCount` that constitutes a beat */
  private var beatInterval: Fraction<Float>

  /** Tracks the current subdivision of a beat, incrementing `time` as it updates */
  private var clockCount: Fraction<Float> {
    didSet { // Runs on MIDI Services thread
      guard oldValue != clockCount else { return }
      if clockCount == 1 { clockCount.numerator = 0; time.bar++; time.beat = 1; time.subbeat = 1 }
      else if clockCount % beatInterval == 0 { time.beat++; time.subbeat = 1 }
      else { time.subbeat++ }
    }
  }

  var hashValue: Int { return ObjectIdentifier(self).hashValue }

  private var marker: CABarBeatTime
  func mark() { marker = time }

  var timeSinceMarker: CABarBeatTime {
    var time = self.time
    var result = CABarBeatTime(bar: 0, beat: 0, subbeat: 0, subbeatDivisor: 0, reserved: 0)
    if time.subbeatDivisor != marker.subbeatDivisor {
      let divisor = max(time.subbeatDivisor, marker.subbeatDivisor)
      time.subbeat *= divisor / time.subbeatDivisor
      time.subbeatDivisor = divisor
      marker.subbeat *= divisor / marker.subbeatDivisor
      marker.subbeatDivisor = divisor
      result.subbeatDivisor = divisor
    }

    if time.subbeat < marker.subbeat {
      time.subbeat += time.subbeatDivisor
      time.beat -= 1
    }
    result.subbeat = time.subbeat - marker.subbeat

    if time.beat < marker.beat {
      time.beat += 4
      time.bar -= 1
    }
    result.beat = time.beat - marker.beat
    result.bar = time.bar - marker.bar
    return result
  }

  /**
  Sets the state of `barBeatTime` and `clockCount` from the specified `BarBeatTime`

  - parameter barBeatTime: BarBeatTime
  */
  func synchronizeWithTime(barBeatTime: BarBeatTime) { time = barBeatTime.time; clockCount = barBeatTime.clockCount }

  var bar: Int { return Int(time.bar) }          /// Accessor for `time.bar`
  var beat: Int { return Int(time.beat) }        /// Accessor for `time.beat`
  var subbeat: Int { return Int(time.subbeat) }  /// Accessor for `time.subbeat`

  /**
  timeStampForBarBeatTime:

  - parameter barBeatTime: CABarBeatTime

  - returns: MIDITimeStamp
  */
  func timeStampForBarBeatTime(barBeatTime: CABarBeatTime) -> MIDITimeStamp {
    return timeStampForBars(UInt64(barBeatTime.bar), beats: UInt64(barBeatTime.beat), subbeats: UInt64(barBeatTime.subbeat))
  }

  /**
  timeStampForBars:beats:subbeats:

  - parameter bars: Int
  - parameter beats: Int
  - parameter subbeats: Int

  - returns: MIDITimeStamp
  */
  func timeStampForBars(bars: UInt64, beats: UInt64, subbeats: UInt64) -> MIDITimeStamp {
    let realBars = bars == 0 ? 0 : bars - 1
    let realBeats = beats == 0 ? 0 : beats - 1
    let realSubbeats = subbeats == 0 ? 0 : subbeats - 1
    return (realBars * UInt64(timeSignature.beatsPerBar) + realBeats) * UInt64(partsPerQuarter) + realSubbeats
  }

  /// Generates the current `MIDI` representation of the current time
  var timeStamp: MIDITimeStamp { return timeStampForBarBeatTime(time) }

  var timeSignature: SimpleTimeSignature = .FourFour

  var doubleValue: Double { return time.doubleValueWithBeatsPerBar(timeSignature.beatsPerBar) }

  var description: String { return time.description }

  /** reset */
  func reset() { clockCount = 0╱Int64(partsPerQuarter); time.bar = 1; time.beat = 1; time.subbeat = 1 }

  /**
  initWithClockSource:partsPerQuarter:

  - parameter clockSource: MIDIEndpointRef
  - parameter ppq: UInt16 = 480
  */
  init(clockSource: MIDIEndpointRef, partsPerQuarter ppq: UInt16 = 480) {
    time = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: ppq, reserved: 0)
    marker = time
    clockCount = 0╱Int64(ppq)
    beatInterval = Int64(Float(ppq) * 0.25)╱Int64(ppq)
    validBeats = 1 ... UInt16(timeSignature.beatsPerBar)
    validSubbeats = 1 ... ppq

    do {
      try MIDIClientCreateWithBlock("BarBeatTime[\(ObjectIdentifier(self).uintValue)]", &client, nil)
        ➤ "Failed to create midi client for track manager"
      try MIDIInputPortCreateWithBlock(client, "Input", &inPort, read) ➤ "Failed to create in port for track manager"
      try MIDIPortConnectSource(inPort, clockSource, nil) ➤ "Failed to connect track manager to clock"
    } catch {
      logError(error)
    }
    delayedDispatchToMain(0.2) { [unowned self] in  Sequencer.synchronizeTime(self) }  // Avoids deadlock
  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
    // Runs on MIDI Services thread
    guard packetList.memory.packet.data.0 == 0b1111_1000 else { return }
    clockCount.numerator += 1
  }

  // ???: Will this ever get called to remove the reference in Sequencer's `Set`?
  deinit {
    Sequencer.synchronizeTime(self)
    do {
      try MIDIPortDispose(inPort) ➤ "Failed to dispose of in port"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }

  }
}

func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }
