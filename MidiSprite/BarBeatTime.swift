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

final class BarBeatTime: Hashable, CustomStringConvertible {

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

  /** Stores the musical representation of the current time */
  private var time: CABarBeatTime

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
    return max(0, bars - 1) * ticksPerBar + max(0, beats - 1) * UInt64(partsPerQuarter) + max(0, subbeats - 1)
  }

  var ticksPerBar: UInt64 { return UInt64(partsPerQuarter) * 4 }

  /// Generates the current `MIDI` representation of the current time
  var timeStamp: MIDITimeStamp { return timeStampForBarBeatTime(time) }

  var description: String { return "\(time.bar).\(time.beat).\(time.subbeat)" }

  /** reset */
  func reset() { clockCount = 0╱Int64(partsPerQuarter); time.bar = 1; time.beat = 1; time.subbeat = 1 }

  /**
  initWithClockSource:partsPerQuarter:

  - parameter clockSource: MIDIEndpointRef
  - parameter ppq: UInt16 = 480
  */
  init(clockSource: MIDIEndpointRef, partsPerQuarter ppq: UInt16 = 480) {
    time = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: ppq, reserved: 0)
    clockCount = 0╱Int64(ppq)
    beatInterval = Int64(Float(ppq) * 0.25)╱Int64(ppq)

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
