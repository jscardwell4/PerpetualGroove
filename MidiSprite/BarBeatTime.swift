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

class BarBeatTime: Hashable, CustomStringConvertible {

  static private var instanceCount = 0
  private var client = MIDIClientRef()
  private var inPort = MIDIPortRef()

  var partsPerQuarter: UInt16 {
    get { return time.subbeatDivisor }
    set {
      time.subbeatDivisor = newValue
      let n = clockCount.numerator % Int64(newValue)
      clockCount = n╱Int64(newValue)
      beatInterval = Int64(Float(newValue) * 0.25)╱Int64(newValue)
    }
  }

  private var time: CABarBeatTime
  private var beatInterval: Fraction<Float>

  /** Tracks the current subdivision of a bar */
  private var clockCount: Fraction<Float> {
    didSet {
      if clockCount == 1 {
        clockCount.numerator = 0;
        time.bar++
        time.beat = 1
        time.subbeat = 1
      } else if clockCount % beatInterval == 0 {
        time.beat++
        time.subbeat = 1
      } else {
        time.subbeat++
      }
    }
  }

  var hashValue: Int { return Int(ObjectIdentifier(self).uintValue) }

  /**
  synchronizeWithTime:

  - parameter barBeatTime: BarBeatTime
  */
  func synchronizeWithTime(barBeatTime: BarBeatTime) { time = barBeatTime.time; clockCount = barBeatTime.clockCount }

  var bar: Int { return Int(time.bar) }
  var beat: Int { return Int(time.beat) }
  var subbeat: Int { return Int(time.subbeat) }
  var timestamp: MIDITimeStamp {
    return MIDITimeStamp(Sequencer.resolution / Double(subbeat) * Double(bar) * Double(beat))
  }

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
      try MIDIClientCreateWithBlock("BarBeatTime\(BarBeatTime.instanceCount++)", &client, nil)
        ➤ "Failed to create midi client for track manager"
      try MIDIInputPortCreateWithBlock(client, "Input", &inPort, read) ➤ "Failed to create in port for track manager"
      try MIDIPortConnectSource(inPort, clockSource, nil) ➤ "Failed to connect track manager to clock"
    } catch {
      logError(error)
    }
    Sequencer.synchronizeTime(self)
  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
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
