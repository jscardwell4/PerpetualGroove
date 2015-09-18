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
  public var description: String {
    let barString = String(bar, radix: 10, pad: 3)
    let beatString = String(beat)
    let subbeatString = String(subbeat, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(barString) : \(beatString) . \(subbeatString)"
  }
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
                         subbeatDivisor: UInt16(Sequencer.resolution),
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

extension CABarBeatTime: Comparable {}

public func <(lhs: CABarBeatTime, rhs: CABarBeatTime) -> Bool {
  guard lhs.bar == rhs.bar else { return lhs.bar < rhs.bar }
  guard lhs.beat == rhs.beat else { return lhs.beat < rhs.beat }
  guard lhs.subbeatDivisor != rhs.subbeatDivisor else { return lhs.subbeat < rhs.subbeat }
  return lhs.subbeat╱lhs.subbeatDivisor < rhs.subbeat╱rhs.subbeatDivisor
}

extension CABarBeatTime {

  public static var start: CABarBeatTime {
    return CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: UInt16(Sequencer.resolution), reserved: 0)
  }

  /**
  init:beatsPerBar:subbeatDivisor:

  - parameter tickValue: UInt64
  - parameter beatsPerBar: UInt8
  - parameter subbeatDivisor: UInt16
  */
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

  /**
  initWithUpper:lower:

  - parameter upper: UInt8
  - parameter lower: UInt8
  */
  init(upper: UInt8, lower: UInt8) {
    switch (upper, lower) {
      case (4, 4): self = .FourFour
      case (3, 4): self = .ThreeFour
      case (2, 4): self = .TwoFour
      default: self = .Other(upper, lower)
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

  private(set) var validBeats: Range<UInt16>
  private(set) var validSubbeats: Range<UInt16>

  private var _time: CABarBeatTime

  /**
  isValidTime:

  - parameter time: CABarBeatTime

  - returns: Bool
  */
  func isValidTime(time: CABarBeatTime) -> Bool {
    return validBeats ∋ time.beat && validSubbeats ∋ time.subbeat && time.subbeatDivisor == partsPerQuarter
  }

  /** Stores the musical representation of the current time */
  var time: CABarBeatTime {
    get {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      return _time
    }
    set {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      guard isValidTime(newValue) else { return }
      _time = newValue
      checkCallbacksForTime(time)
    }
  }

  /** The portion of `clockCount` that constitutes a beat */
  private var beatInterval: Fraction<Float>

  /** Tracks the current subdivision of a beat, incrementing `time` as it updates */
  private var clockCount: Fraction<Float>

  /** incrementClock */
  private func incrementClock() {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

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
  func registerCallback(callback: Callback, forTime time: CABarBeatTime) { callbacks[time] = callback }

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

  typealias Callback = (CABarBeatTime) -> Void
  typealias Predicate = (CABarBeatTime) -> Bool

  /**
  Set the `inout Bool` to true to unregister the callback

  - parameter callback: (CABarBeatTime) -> Void
  - parameter predicate: (CABarBeatTime) -> Bool
  */
  func registerCallback(callback: Callback, predicate: Predicate, forKey key: String) {
    predicatedCallbacks[key] = (predicate: predicate, callback: callback)
  }

  private var callbackCheck = false
  private func updateCallbackCheck() { callbackCheck = callbacks.count > 0 || predicatedCallbacks.count > 0 }

  static let TruePredicate: Predicate = {_ in true }

  /**
  checkCallbacksForTime:

  - parameter t: CABarBeatTime
  */
  private func checkCallbacksForTime(t: CABarBeatTime) {
    callbacks[t]?(t)
    predicatedCallbacks.values.filter({$0.predicate(t)}).forEach({$0.callback(t)})
  }

  private var callbacks: [CABarBeatTime:Callback] = [:] { didSet { updateCallbackCheck() } }

  private typealias PredicateCallback = (predicate: Predicate, callback: Callback)
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

  var bar: Int { return Int(time.bar) }          /// Accessor for `time.bar`
  var beat: Int { return Int(time.beat) }        /// Accessor for `time.beat`
  var subbeat: Int { return Int(time.subbeat) }  /// Accessor for `time.subbeat`

  /// Generates the current `MIDI` representation of the current time
  var timeStamp: MIDITimeStamp {  return time.tickValueWithBeatsPerBar(Sequencer.timeSignature.beatsPerBar) }

  var doubleValue: Double {  return time.doubleValueWithBeatsPerBar(Sequencer.timeSignature.beatsPerBar) }

  var description: String { return time.description }

  /** reset */
  func reset() {
    dispatch_async(queue) {
      [unowned self] in
      let ppq = self._time.subbeatDivisor
      self._time = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: ppq, reserved: 0)
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      self.clockCount = 0╱Float(ppq)
    }
  }

  /**
  initWithClockSource:partsPerQuarter:

  - parameter clockSource: MIDIEndpointRef
  - parameter ppq: UInt16 = 480
  */
  init(clockSource: MIDIEndpointRef, partsPerQuarter ppq: UInt16 = 480) {
    let t = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: ppq, reserved: 0)
    _time = t
    marker = t
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
  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
    // Runs on MIDI Services thread
    switch packetList.memory.packet.data.0 {
      case 0b1111_1000: dispatch_async(queue) { [weak self] in self?.incrementClock() }
      case 0b1111_1010: dispatch_async(queue) { [weak self] in self?.reset(); self?.checkCallbacksForTime(self!.time) }
      default: break
    }
  }

  // ???: Will this ever get called to remove the reference in Sequencer's `Set`?
  deinit {
    do {
      try MIDIPortDispose(inPort) ➤ "Failed to dispose of in port"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }

  }
}

func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }
