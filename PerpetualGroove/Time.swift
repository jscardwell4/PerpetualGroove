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

  fileprivate var client = MIDIClientRef()  /// Client for receiving MIDI clock
  fileprivate var inPort = MIDIPortRef()    /// Port for receiving MIDI clock

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafePointer<Void>
  */
  fileprivate func read(_ packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer?) {
    // Runs on MIDI Services thread
    switch packetList.pointee.packet.data.0 {
      case 0b1111_1000: queue.async(execute: incrementClock)
      case 0b1111_1010: queue.async { [unowned self] in self._reset()
                                                        self.invokeCallbacksForTime(self.barBeatTime) }
      default: break
    }
  }

  // MARK: - Keeping the time

  fileprivate let queue: DispatchQueue

  /// The musical representation of the current time
  fileprivate var _barBeatTime: BarBeatTime = .start1 {
    didSet { if Sequencer.playing { invokeCallbacksForTime(barBeatTime) } }
  }

  /** Synchronized access to the musical representation of the current time */
  var barBeatTime: BarBeatTime {
    get { /*objc_sync_enter(self); defer { objc_sync_exit(self) };*/ return _barBeatTime }
    set { /*objc_sync_enter(self); defer { objc_sync_exit(self) };*/ /*guard isValidTime(newValue) else { return };*/ _barBeatTime = newValue }
  }

  /** incrementClock */
  fileprivate func incrementClock() {
//    objc_sync_enter(self)
//    defer { objc_sync_exit(self) }

    barBeatTime = barBeatTime.successor()
  }

  // MARK: - Time-triggered callbacks

  typealias Callback  = (BarBeatTime) -> Void
  typealias Predicate = (BarBeatTime) -> Bool

  fileprivate var callbacks: [BarBeatTime:[(Callback, ObjectIdentifier?)]] = [:] {
    didSet { haveCallbacks = callbacks.count > 0 || predicatedCallbacks.count > 0 }
  }
  fileprivate var predicatedCallbacks: [String:(predicate: Predicate, callback: Callback)] = [:] {
    didSet { haveCallbacks = callbacks.count > 0 || predicatedCallbacks.count > 0 }
  }

  /**
   callbackRegisteredForKey:

   - parameter key: String

    - returns: Bool
  */
  func callbackRegisteredForKey(_ key: String) -> Bool {
    return predicatedCallbacks[key] != nil
  }

  var suppressCallbacks = false
  fileprivate var haveCallbacks = false
  fileprivate var checkCallbacks: Bool { return haveCallbacks && !suppressCallbacks }

  /** clearCallbacks */
  func clearCallbacks() {
    logDebug("clearing all registered callbacks…")
    callbacks.removeAll(keepingCapacity: true)
    predicatedCallbacks.removeAll(keepingCapacity: true)
  }

  /**
   Invokes the blocks registered in `callbacks` for the specified time and any blocks in
   `predicatedCallbacks` whose predicate evaluates to `true`

   - parameter t: BarBeatTime
  */
  fileprivate func invokeCallbacksForTime(_ t: BarBeatTime) {
    guard checkCallbacks else { return }
    callbacks[t]?.forEach({$0.0(t)})
    predicatedCallbacks.values.filter({$0.predicate(t)}).forEach({$0.callback(t)})
  }

  /**
  registerCallback:forTime:

  - parameter callback: (BarBeatTime) -> Void
  - parameter time: BarBeatTime
  */
  func registerCallback(_ callback: @escaping Callback, forTime time: BarBeatTime, forObject obj: AnyObject? = nil) {
    registerCallback(callback, forTimes: [time], forObject: obj)
  }

  /**
  registerCallback:forTimes:forObject:

  - parameter callback: Callback
  - parameter times: S
  - parameter obj: AnyObject? = nil
  */
  func registerCallback<S:Swift.Sequence>(_ callback: @escaping Callback,
                                     forTimes times: S,
                                    forObject obj: AnyObject? = nil)
    where S.Iterator.Element == BarBeatTime
  {
    let value: (Callback, ObjectIdentifier?) = (callback, obj != nil ? ObjectIdentifier(obj!) : nil)
    times.forEach { var bag = callbacks[$0] ?? []; bag.append(value); callbacks[$0] = bag }
  }

  /**
  removeCallbackForTime:

  - parameter time: BarBeatTime
  */
  func removeCallbackForTime(_ time: BarBeatTime, forObject obj: AnyObject? = nil) {
    if let obj = obj {
      callbacks[time] = callbacks[time]?.filter {
        [identifier = ObjectIdentifier(obj)] in $1 != identifier
      }
    } else { callbacks[time] = nil }
  }

  /**
  removeCallbackForKey:

  - parameter key: String
  */
  func removeCallbackForKey(_ key: String) { predicatedCallbacks[key] = nil }


  /**
  Set the `inout Bool` to true to unregister the callback

  - parameter callback: (BarBeatTime) -> Void
  - parameter predicate: (BarBeatTime) -> Bool
  */
  func registerCallback(_ callback: @escaping Callback, predicate: @escaping Predicate, forKey key: String) {
    predicatedCallbacks[key] = (predicate: predicate, callback: callback)
  }

  var bar:     UInt           { return barBeatTime.bar     }  /// Accessor for `time.bar`
  var beat:    UInt           { return barBeatTime.beat    }  /// Accessor for `time.beat`
  var subbeat: UInt           { return barBeatTime.subbeat }  /// Accessor for `time.subbeat`
  var ticks:   MIDITimeStamp  { return barBeatTime.ticks   }  /// Accessor for `time.ticks`
  var seconds: TimeInterval   { return barBeatTime.seconds }  /// Accessor for `time.doubleValue`

  let clockName: String

  // MARK: - Initializing and resetting

  /**
  initWithClockSource:partsPerQuarter:

  - parameter clockSource: MIDIEndpointRef
  */
  init(clockSource: MIDIEndpointRef) {
    var unmanagedName: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(clockSource, kMIDIPropertyName, &unmanagedName)
    guard unmanagedName != nil else { fatalError("Endpoint should have been given a name") }
    let name = unmanagedName!.takeUnretainedValue() as String
    clockName = name
    queue = DispatchQueue(label: name, qos: .userInteractive)
    do {
      try MIDIClientCreateWithBlock(name as CFString, &client, nil)
        ➤ "Failed to create midi client for bar beat time"
      try MIDIInputPortCreateWithBlock(client, "Input" as CFString, &inPort, weakMethod(self, Time.read))
        ➤ "Failed to create in port for bar beat time"
      try MIDIPortConnectSource(inPort, clockSource, nil) ➤ "Failed to connect bar beat time to clock"
    } catch {
      logError(error)
    }
  }

  /**
   reset:

   - parameter completion: (() -> Void)? = nil
   */
  func reset(_ completion: (() -> Void)? = nil) { queue.async { [unowned self] in self._reset(completion) } }

  /**
  _reset:

  - parameter completion: (() -> Void)? = nil
  */
  fileprivate func _reset(_ completion: (() -> Void)? = nil) {
    _barBeatTime = .start1
//    objc_sync_enter(self)
    /*defer { objc_sync_exit(self); */completion?()// }
  }

  /**
   hardReset:

   - parameter completion: (() -> Void
  */
  func hardReset(_ completion: (() -> Void)? = nil) {
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
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

// MARK: - Hashable
extension Time: Hashable { var hashValue: Int { return ObjectIdentifier(self).hashValue } }

// MARK: - Equatable
func ==(lhs: Time, rhs: Time) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }
