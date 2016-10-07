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
  var barBeatTime: BarBeatTime = BarBeatTime.zero {
    didSet { if Sequencer.playing { invokeCallbacksForTime(barBeatTime) } }
  }


  fileprivate func incrementClock() {
    barBeatTime = barBeatTime.advanced(by: barBeatTime.subbeatUnitTime) //successor()
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

  func callbackRegisteredForKey(_ key: String) -> Bool {
    return predicatedCallbacks[key] != nil
  }

  var suppressCallbacks = false

  fileprivate var haveCallbacks = false
  fileprivate var checkCallbacks: Bool { return haveCallbacks && !suppressCallbacks }

  func clearCallbacks() {
    logDebug("clearing all registered callbacks…")
    callbacks.removeAll(keepingCapacity: true)
    predicatedCallbacks.removeAll(keepingCapacity: true)
  }

  /// Invokes the blocks registered in `callbacks` for the specified time and any blocks in
  /// `predicatedCallbacks` whose predicate evaluates to `true`.
  fileprivate func invokeCallbacksForTime(_ t: BarBeatTime) {
    guard checkCallbacks else { return }
    callbacks[t]?.forEach({$0.0(t)})
    predicatedCallbacks.values.filter({$0.predicate(t)}).forEach({$0.callback(t)})
  }

  func register(callback: @escaping Callback, time: BarBeatTime, object: AnyObject? = nil) {
    register(callback: callback, times: [time], object: object)
  }

  func register<S:Swift.Sequence>(callback: @escaping Callback, times: S, object: AnyObject? = nil)
    where S.Iterator.Element == BarBeatTime
  {
    let value: (Callback, ObjectIdentifier?) = (callback, object != nil ? ObjectIdentifier(object!) : nil)
    times.forEach { var bag = callbacks[$0] ?? []; bag.append(value); callbacks[$0] = bag }
  }

  func removeCallback(time: BarBeatTime, object: AnyObject? = nil) {
    if let object = object {
      callbacks[time] = callbacks[time]?.filter {
        [identifier = ObjectIdentifier(object)] in $1 != identifier
      }
    } else { callbacks[time] = nil }
  }

  func removeCallbackForKey(_ key: String) { predicatedCallbacks[key] = nil }


  /// Set the `inout Bool` to true to unregister the callback
  func register(callback: @escaping Callback, predicate: @escaping Predicate, key: String) {
    predicatedCallbacks[key] = (predicate: predicate, callback: callback)
  }

  var bar:     UInt           { return barBeatTime.bar     }  /// Accessor for `time.bar`
  var beat:    UInt           { return barBeatTime.beat    }  /// Accessor for `time.beat`
  var subbeat: UInt           { return barBeatTime.subbeat }  /// Accessor for `time.subbeat`
  var ticks:   MIDITimeStamp  { return barBeatTime.ticks   }  /// Accessor for `time.ticks`
  var seconds: TimeInterval   { return barBeatTime.seconds }  /// Accessor for `time.doubleValue`

  let clockName: String

  // MARK: - Initializing and resetting

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

  func reset(_ completion: (() -> Void)? = nil) { queue.async { [unowned self] in self._reset(completion) } }

  fileprivate func _reset(_ completion: (() -> Void)? = nil) {
    barBeatTime = BarBeatTime.zero
    completion?()
  }

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

extension Time: CustomStringConvertible { var description: String { return barBeatTime.description } }

extension Time: Hashable {

  static func ==(lhs: Time, rhs: Time) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }

  var hashValue: Int { return ObjectIdentifier(self).hashValue }

}
