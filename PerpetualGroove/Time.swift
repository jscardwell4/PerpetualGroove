//
//  Time.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/26/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreMIDI
import MoonKit

final class Time {

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
      case 0b1111_1010: queue.addOperationWithBlock { [weak self] in self?.reset(); self?.invokeCallbacksForTime(self!.barBeatTime) }
      default: break
    }
  }

  // MARK: - Keeping the time

  private let queue: NSOperationQueue = { let q = NSOperationQueue(); q.maxConcurrentOperationCount = 1; return q }()

  /** The resolution used to divide a beat into subbeats */
//  var partsPerQuarter: UInt16 {
//    get { return time.subbeatDivisor }
//    set {
//      time.subbeatDivisor = newValue
//      let n = clockCount.numerator % Float(newValue)
//      clockCount = n╱Float(newValue)
//      beatInterval = Fraction((Float(newValue) * Float(0.25)), Float(newValue))
//    }
//  }

  /// Valid beat range for the current settings
  private(set) var validBeats: Range<Int>

  /// Valid subbeat range for the current settings
  private(set) var validSubbeats: Range<Int>

  /**
  Whether the specified `time` holds a valid representation

  - parameter time: BarBeatTime

  - returns: Bool
  */
  func isValidTime(time: BarBeatTime) -> Bool {
    return validBeats ∋ time.beat && validSubbeats ∋ time.subbeat && time.subbeatDivisor == Sequencer.partsPerQuarter
  }

  /// The musical representation of the current time
  private var _barBeatTime: BarBeatTime = .start { didSet { if Sequencer.playing { invokeCallbacksForTime(barBeatTime) } } }

  /** Synchronized access to the musical representation of the current time */
  var barBeatTime: BarBeatTime {
    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return _barBeatTime }
    set { objc_sync_enter(self); defer { objc_sync_exit(self) }; guard isValidTime(newValue) else { return }; _barBeatTime = newValue }
  }

  /** The portion of `clockCount` that constitutes a beat */
  private var beatInterval: Fraction<Float>

  /** Tracks the current subdivision of a beat, incrementing `time` as it updates */
  private var clockCount: Fraction<Float>

  /** incrementClock */
  private func incrementClock() {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    var updatedTime = barBeatTime

    clockCount.numerator += 1
    if clockCount == 1 {
      clockCount.numerator = 0
      updatedTime.bar++
      updatedTime.beat = 1
      updatedTime.subbeat = 1
    } else if clockCount % beatInterval == 0 {
      updatedTime.beat++
      updatedTime.subbeat = 1
    } else {
      updatedTime.subbeat++
    }

    barBeatTime = updatedTime
  }

  // MARK: - Time-triggered callbacks

  typealias Callback  = (BarBeatTime) -> Void
  typealias Predicate = (BarBeatTime) -> Bool

  private var callbacks: [BarBeatTime:[(Callback, ObjectIdentifier?)]] = [:] {
    didSet { haveCallbacks = callbacks.count > 0 || predicatedCallbacks.count > 0 }
  }
  private var predicatedCallbacks: [String:(predicate: Predicate, callback: Callback)] = [:] {
    didSet { haveCallbacks = callbacks.count > 0 || predicatedCallbacks.count > 0 }
  }

  /**
   callbackRegisteredForKey:

   - parameter key: String

    - returns: Bool
  */
  func callbackRegisteredForKey(key: String) -> Bool {
    return predicatedCallbacks[key] != nil
  }

  var suppressCallbacks = false
  private var haveCallbacks = false
  private var checkCallbacks: Bool { return haveCallbacks && !suppressCallbacks }

  /** clearCallbacks */
  func clearCallbacks() {
    logDebug("clearing all registered callbacks…")
    callbacks.removeAll(keepCapacity: true)
    predicatedCallbacks.removeAll(keepCapacity: true)
  }

  /**
  Invokes the blocks registered in `callbacks` for the specified time and any blocks in `predicatedCallbacks` 
  whose predicate evaluates to `true`

  - parameter t: BarBeatTime
  */
  private func invokeCallbacksForTime(t: BarBeatTime) {
    guard checkCallbacks else { return }
    callbacks[t]?.forEach({$0.0(t)})
    predicatedCallbacks.values.filter({$0.predicate(t)}).forEach({$0.callback(t)})
  }

  /**
  registerCallback:forTime:

  - parameter callback: (BarBeatTime) -> Void
  - parameter time: BarBeatTime
  */
  func registerCallback(callback: Callback, forTime time: BarBeatTime, forObject obj: AnyObject? = nil) {
    registerCallback(callback, forTimes: [time], forObject: obj)
  }

  /**
  registerCallback:forTimes:forObject:

  - parameter callback: Callback
  - parameter times: S
  - parameter obj: AnyObject? = nil
  */
  func registerCallback<S:SequenceType
    where S.Generator.Element == BarBeatTime>(callback: Callback, forTimes times: S, forObject obj: AnyObject? = nil)
  {
    let value: (Callback, ObjectIdentifier?) = obj != nil ? (callback, ObjectIdentifier(obj!)) : (callback, nil)
    times.forEach { var bag = callbacks[$0] ?? []; bag.append(value); callbacks[$0] = bag }
  }

  /**
  removeCallbackForTime:

  - parameter time: BarBeatTime
  */
  func removeCallbackForTime(time: BarBeatTime, forObject obj: AnyObject? = nil) {
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

  - parameter callback: (BarBeatTime) -> Void
  - parameter predicate: (BarBeatTime) -> Bool
  */
  func registerCallback(callback: Callback, predicate: Predicate, forKey key: String) {
    predicatedCallbacks[key] = (predicate: predicate, callback: callback)
  }


  // MARK: - Measurements and conversions

  /// Holds a bar beat time value that can be used later to measure the amount of time elapsed
  private var marker: BarBeatTime = .start

  /** Updates `marker` with current `time` */
  func setMarker() { marker = barBeatTime }

  /// The amount of time elapsed since `marker`
  var timeSinceMarker: BarBeatTime {
    var t = barBeatTime
    var result = BarBeatTime()
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

  var bar:         Int           { return barBeatTime.bar         }  /// Accessor for `time.bar`
  var beat:        Int           { return barBeatTime.beat        }  /// Accessor for `time.beat`
  var subbeat:     Int           { return barBeatTime.subbeat     }  /// Accessor for `time.subbeat`
  var ticks:       MIDITimeStamp { return barBeatTime.ticks       }  /// Accessor for `time.ticks`
  var doubleValue: Double        { return barBeatTime.doubleValue }  /// Accessor for `time.doubleValue`

  let clockName: String

  // MARK: - Initializing and resetting

  /**
  initWithClockSource:partsPerQuarter:

  - parameter clockSource: MIDIEndpointRef
  */
  init(clockSource: MIDIEndpointRef) {

    var unmanagedProperties: Unmanaged<CFPropertyList>?
    MIDIObjectGetProperties(clockSource, &unmanagedProperties, true)

    var unmanagedName: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(clockSource, kMIDIPropertyName, &unmanagedName)
    guard unmanagedName != nil else { fatalError("Endpoint should have been given a name") }
    clockName = unmanagedName!.takeUnretainedValue() as String

    let ppq = Sequencer.partsPerQuarter
    clockCount = 0╱Float(ppq)
    beatInterval = (Float(ppq) * Float(0.25))╱Float(ppq)
    validBeats = 1 ... Sequencer.timeSignature.beatsPerBar
    validSubbeats = 1 ... ppq
    queue.name = name

    do {
      try MIDIClientCreateWithBlock(queue.name!, &client, nil)
        ➤ "Failed to create midi client for bar beat time"
      try MIDIInputPortCreateWithBlock(client, "Input", &inPort, weakMethod(self, Time.read)) ➤ "Failed to create in port for bar beat time"
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
    logDebug("time ➞ 1:1.1╱\(_barBeatTime.subbeatDivisor); clockCount ➞ 0╱\(_barBeatTime.subbeatDivisor)")
    queue.addOperationWithBlock  {
      [unowned self] in
      let ppq = self._barBeatTime.subbeatDivisor
      self._barBeatTime = .start
      objc_sync_enter(self)
      defer { objc_sync_exit(self); completion?() }
      self.clockCount = 0╱Float(ppq)
    }
  }

  /**
   hardReset:

   - parameter completion: (() -> Void
  */
  func hardReset(completion: (() -> Void)? = nil) {
    clearCallbacks()
    reset(completion)
  }

  deinit {
    do {
      try MIDIPortDispose(inPort) ➤ "Failed to dispose of in port"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }

  }
}

extension Time: Named {
  var name: String { return clockName }
}

// MARK: - CustomStringConvertible
extension Time: CustomStringConvertible { var description: String { return barBeatTime.description } }

// MARK: - CustomDebugStringConvertible
extension Time: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Hashable
extension Time: Hashable { var hashValue: Int { return ObjectIdentifier(self).hashValue } }

// MARK: - Equatable
func ==(lhs: Time, rhs: Time) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }
