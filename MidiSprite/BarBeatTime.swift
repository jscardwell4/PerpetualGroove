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

final class BarBeatTime {

  // MARK: - Receiving MIDI clocks

  private var client = MIDIClientRef()  /// Client for receiving MIDI clock
  private var inPort = MIDIPortRef()    /// Port for receiving MIDI clock

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
    // Runs on MIDI Services thread
    switch packetList.memory.packet.data.0 {
      case 0b1111_1000: queue.addOperationWithBlock { [weak self] in self?.incrementClock() }
      case 0b1111_1010: queue.addOperationWithBlock { [weak self] in self?.reset(); self?.invokeCallbacksForTime(self!.time) }
      default: break
    }
  }

  // MARK: - Keeping the time

  private let queue: NSOperationQueue = { let q = NSOperationQueue(); q.maxConcurrentOperationCount = 1; return q }()

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

  /// Valid beat range for the current settings
  private(set) var validBeats: Range<UInt16>

  /// Valid subbeat range for the current settings
  private(set) var validSubbeats: Range<UInt16>

  /**
  Whether the specified `time` holds a valid representation

  - parameter time: CABarBeatTime

  - returns: Bool
  */
  func isValidTime(time: CABarBeatTime) -> Bool {
    return validBeats ∋ time.beat && validSubbeats ∋ time.subbeat && time.subbeatDivisor == partsPerQuarter
  }

  /// The musical representation of the current time
  private var _time: CABarBeatTime { didSet { invokeCallbacksForTime(time) } }

  /** Synchronized access to the musical representation of the current time */
  var time: CABarBeatTime {
    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return _time }
    set { objc_sync_enter(self); defer { objc_sync_exit(self) }; guard isValidTime(newValue) else { return }; _time = newValue }
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

  // MARK: - Time-triggered callbacks

  typealias Callback  = (CABarBeatTime) -> Void
  typealias Predicate = (CABarBeatTime) -> Bool

  private var callbacks:           [CABarBeatTime:[(Callback, ObjectIdentifier?)]]     = [:] { didSet { updateCallbackCheck() } }
  private var predicatedCallbacks: [String:(predicate: Predicate, callback: Callback)] = [:] { didSet { updateCallbackCheck() } }

  private var callbackCheck = false
  private func updateCallbackCheck() { callbackCheck = callbacks.count > 0 || predicatedCallbacks.count > 0 }

  /**
  Invokes the blocks registered in `callbacks` for the specified time and any blocks in `predicatedCallbacks` 
  whose predicate evaluates to `true`

  - parameter t: CABarBeatTime
  */
  private func invokeCallbacksForTime(t: CABarBeatTime) {
    callbacks[t]?.forEach({$0.0(t)})
    predicatedCallbacks.values.filter({$0.predicate(t)}).forEach({$0.callback(t)})
  }

  /**
  registerCallback:forTime:

  - parameter callback: (CABarBeatTime) -> Void
  - parameter time: CABarBeatTime
  */
  func registerCallback(callback: Callback, forTime time: CABarBeatTime, forObject obj: AnyObject? = nil) {
    var bag = callbacks[time] ?? []
    if let obj = obj { bag.append((callback, ObjectIdentifier(obj))) } else { bag.append((callback, nil)) }
    callbacks[time] = bag
  }

  /**
  removeCallbackForTime:

  - parameter time: CABarBeatTime
  */
  func removeCallbackForTime(time: CABarBeatTime, forObject obj: AnyObject? = nil) {
    if let obj = obj { callbacks[time] = callbacks[time]?.filter({[identifier = ObjectIdentifier(obj)] in $1 != identifier}) }
    else { callbacks[time] = nil }
  }

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
  func registerCallback(callback: Callback, predicate: Predicate, forKey key: String) {
    predicatedCallbacks[key] = (predicate: predicate, callback: callback)
  }


  // MARK: - Measurements and conversions

  /// Holds a bar beat time value that can be used later to measure the amount of time elapsed
  private var marker: CABarBeatTime

  /** Updates `marker` with current `time` */
  func setMarker() { marker = time }

  /// The amount of time elapsed since `marker`
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

  var bar:         Int           { return Int(time.bar)       }  /// Accessor for `time.bar`
  var beat:        Int           { return Int(time.beat)      }  /// Accessor for `time.beat`
  var subbeat:     Int           { return Int(time.subbeat)   }  /// Accessor for `time.subbeat`
  var ticks:       MIDITimeStamp { return time.ticks          }  /// Accessor for `time.ticks`
  var doubleValue: Double        { return time.doubleValue    }  /// Accessor for `time.doubleValue`

  // MARK: - Initializing and resetting

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
    queue.name = "BarBeatTime[\(ObjectIdentifier(self).uintValue)]"

    do {
      try MIDIClientCreateWithBlock(queue.name!, &client, nil)
        ➤ "Failed to create midi client for bar beat time"
      try MIDIInputPortCreateWithBlock(client, "Input", &inPort, read) ➤ "Failed to create in port for bar beat time"
      try MIDIPortConnectSource(inPort, clockSource, nil) ➤ "Failed to connect bar beat time to clock"
    } catch {
      logError(error)
    }
  }

  /**
  reset:

  - parameter completion: (() -> Void)? = nil
  */
  func reset(completion: (() -> Void)? = nil) {
    queue.addOperationWithBlock  {
      [unowned self] in
      let ppq = self._time.subbeatDivisor
      self._time = CABarBeatTime(bar: 1, beat: 1, subbeat: 1, subbeatDivisor: ppq, reserved: 0)
      objc_sync_enter(self)
      defer { objc_sync_exit(self); completion?() }
      self.clockCount = 0╱Float(ppq)
    }
  }

  deinit {
    do {
      try MIDIPortDispose(inPort) ➤ "Failed to dispose of in port"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }

  }
}

// MARK: - CustomStringConvertible
extension BarBeatTime: CustomStringConvertible { var description: String { return time.description } }

// MARK: - Hashable
extension BarBeatTime: Hashable { var hashValue: Int { return ObjectIdentifier(self).hashValue } }

// MARK: - Equatable
func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }
