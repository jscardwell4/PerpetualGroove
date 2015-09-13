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
    return CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: UInt16(Sequencer.resolution), reserved: 0)
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

}

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


final class BarBeatTime: Hashable, CustomStringConvertible {

  private var client = MIDIClientRef()  /// Client for receiving MIDI clock
  private var inPort = MIDIPortRef()    /// Port for receiving MIDI clock
  private var queue: dispatch_queue_t!

  /** The resolution used to divide a beat into subbeats */
  var partsPerQuarter: UInt16 {
    get { return time.subbeatDivisor }
    set {
      time.subbeatDivisor = newValue
      let n = clockCount.numerator % Float(newValue)
      clockCount = n╱Float(newValue)
      beatInterval = Fraction((Float(newValue) * Float(0.25)), Float(newValue))
    }
  }

  private var validBeats: Range<UInt16>
  private var validSubbeats: Range<UInt16>

  /** Stores the musical representation of the current time */
  private(set) var time: CABarBeatTime {
    didSet {
      guard validBeats.contains(time.beat) && validSubbeats.contains(time.subbeat) else { fatalError("corrupted time '\(time)'") }
      checkCallbacksForTime(time)
    }
  }

  /** The portion of `clockCount` that constitutes a beat */
  private var beatInterval: Fraction<Float>

  /** Tracks the current subdivision of a beat, incrementing `time` as it updates */
  private var clockCount: Fraction<Float>

  /** incrementClock */
  private func incrementClock() {
    clockCount.numerator += 1
    if clockCount == 1 {
      clockCount.numerator = 0
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

  var hashValue: Int { return ObjectIdentifier(self).hashValue }

  private var marker: CABarBeatTime

  /** Updates `marker` with current `time` */
  func setMarker() { marker = time }

  /**
  registerCallback:forTime:

  - parameter callback: (CABarBeatTime) -> Void
  - parameter time: CABarBeatTime
  */
  func registerCallback(callback: (CABarBeatTime) -> Void, forTime time: CABarBeatTime) { callbacks[time] = callback }

  /**
  removeCallbackForTime:

  - parameter time: CABarBeatTime
  */
  func removeCallbackForTime(time: CABarBeatTime) { callbacks[time] = nil }

  /**
  removeCallbackForKey:

  - parameter key: String
  */
  func removeCallbackForKey(key: String) { predicatedCallbacks[key] = nil }

  /**
  Set the `inout Bool` to true to unregister the callback

  - parameter callback: (CABarBeatTime) -> Void
  - parameter predicate: (CABarBeatTime) -> Bool
  */
  func registerCallback(callback: (CABarBeatTime) -> Void, predicate: (CABarBeatTime) -> Bool, forKey key: String) {
    predicatedCallbacks[key] = (predicate: predicate, callback: callback)
  }

  private var callbackCheck = false
  private func updateCallbackCheck() { callbackCheck = callbacks.count > 0 || predicatedCallbacks.count > 0 }

  /**
  checkCallbacksForTime:

  - parameter t: CABarBeatTime
  */
  private func checkCallbacksForTime(t: CABarBeatTime) {
    callbacks[t]?(t)
    predicatedCallbacks.values.filter({$0.predicate(t)}).forEach({$0.callback(t)})
  }

  private var callbacks: [CABarBeatTime:(CABarBeatTime) -> Void] = [:] { didSet { updateCallbackCheck() } }

  private typealias PredicateCallback = (predicate: (CABarBeatTime) -> Bool, callback: (CABarBeatTime) -> Void)
  private var predicatedCallbacks: [String:PredicateCallback] = [:] { didSet { updateCallbackCheck() } }

  var timeSinceMarker: CABarBeatTime {
    var t = time
    var result = CABarBeatTime(bar: 0, beat: 0, subbeat: 0, subbeatDivisor: 0, reserved: 0)
    if t.subbeatDivisor != marker.subbeatDivisor {
      let divisor = max(t.subbeatDivisor, marker.subbeatDivisor)
      t.subbeat *= divisor / t.subbeatDivisor
      t.subbeatDivisor = divisor
      marker.subbeat *= divisor / marker.subbeatDivisor
      marker.subbeatDivisor = divisor
      result.subbeatDivisor = divisor
    }

    if t.subbeat < marker.subbeat {
      t.subbeat += t.subbeatDivisor
      t.beat -= 1
    }
    result.subbeat = t.subbeat - marker.subbeat

    if t.beat < marker.beat {
      t.beat += 4
      t.bar -= 1
    }
    result.beat = t.beat - marker.beat
    result.bar = t.bar - marker.bar
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

  /// Generates the current `MIDI` representation of the current time
  var timeStamp: MIDITimeStamp {  return time.tickValueWithBeatsPerBar(Sequencer.timeSignature.beatsPerBar) }

  var doubleValue: Double {  return time.doubleValueWithBeatsPerBar(Sequencer.timeSignature.beatsPerBar) }

  var description: String { return time.description }

  /** reset */
  func reset() {
    // This causes problems
//    dispatch_async(queue) {
//      [unowned self] in
//      self.time.bar = 1
//      self.time.beat = 1
//      self.time.subbeat = 1
//      self.clockCount = 0╱Float(self.partsPerQuarter)
//      self.resetCount++
//      self.clockReset = true
//    }
  }

  /**
  initWithClockSource:partsPerQuarter:

  - parameter clockSource: MIDIEndpointRef
  - parameter ppq: UInt16 = 480
  */
  init(clockSource: MIDIEndpointRef, partsPerQuarter ppq: UInt16 = 480) {
    time = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: ppq, reserved: 0)
    marker = time
    clockCount = 0╱Float(ppq)
    beatInterval = (Float(ppq) * Float(0.25))╱Float(ppq)
    validBeats = 1 ... UInt16(Sequencer.timeSignature.beatsPerBar)
    validSubbeats = 1 ... ppq

    let name = "BarBeatTime[\(ObjectIdentifier(self).uintValue)]"
    queue = serialQueueWithLabel(name)

    do {
      try MIDIClientCreateWithBlock(name, &client, nil)
        ➤ "Failed to create midi client for bar beat time"
      try MIDIInputPortCreateWithBlock(client, "Input", &inPort, read) ➤ "Failed to create in port for bar beat time"
      try MIDIPortConnectSource(inPort, clockSource, nil) ➤ "Failed to connect bar beat time to clock"
    } catch {
      logError(error)
    }
    dispatch_async(queue) { [unowned self] in  Sequencer.synchronizeTime(self) }
  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
    // Runs on MIDI Services thread
    guard packetList.memory.packet.data.0 == 0b1111_1000 else { return }
    dispatch_async(queue) { [weak self] in self?.incrementClock() }
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
