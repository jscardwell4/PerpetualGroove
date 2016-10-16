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

/// Synchronizes a `BarBeatTime` with received MIDI clock messages.
final class Time {


  private var client = MIDIClientRef()  /// Client for receiving MIDI clock messages.
  private var inPort = MIDIPortRef()    /// Port for receiving MIDI clock messages.

  /// Runs on MIDI Services thread.
  private func read(_ packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer?) {

    switch packetList.pointee.packet.data.0 {

      case 0b1111_1000:
        queue.async(execute: incrementClock)

      case 0b1111_1010:
        queue.async {
          [unowned self] in
          self._reset()
          self.invokeCallbacks(for: self.barBeatTime)
        }

      default:
        break
    }

  }


  private let queue: DispatchQueue

  /// The musical representation of the current time.
  var barBeatTime: BarBeatTime = BarBeatTime.zero {
    didSet { if Sequencer.playing { invokeCallbacks(for: barBeatTime) } }
  }


  private func incrementClock() {
    barBeatTime = barBeatTime.advanced(by: barBeatTime.subbeatUnitTime)
  }

  typealias Callback  = (BarBeatTime) -> Void
  typealias Predicate = (BarBeatTime) -> Bool
  typealias PredicatedCallback = (predicate: Predicate, callback: Callback)

  fileprivate var callbacks: [BarBeatTime:[UUID:Callback]] = [:] {
    didSet { haveCallbacks = callbacks.count > 0 || predicatedCallbacks.count > 0 }
  }

  fileprivate var predicatedCallbacks: [UUID:PredicatedCallback] = [:] {
    didSet { haveCallbacks = callbacks.count > 0 || predicatedCallbacks.count > 0 }
  }

  func callbackRegistered(with identifier: UUID) -> Bool {
    return predicatedCallbacks[identifier] != nil
  }

  var suppressCallbacks = false

  private var haveCallbacks = false
  private var checkCallbacks: Bool { return haveCallbacks && !suppressCallbacks }

  func clearCallbacks() {
    callbacks.removeAll(keepingCapacity: true)
    predicatedCallbacks.removeAll(keepingCapacity: true)
  }

  /// Invokes the blocks registered in `callbacks` for the specified time and any blocks in
  /// `predicatedCallbacks` whose predicate evaluates to `true`.
  private func invokeCallbacks(for time: BarBeatTime) {
    guard checkCallbacks else { return }

    callbacks[time]?.values.forEach({$0(time)})
    predicatedCallbacks.values.filter({$0.predicate(time)}).forEach({$0.callback(time)})
  }

  ///
  func register<S:Swift.Sequence>(callback: @escaping Callback, forTimes times: S, identifier: UUID)
    where S.Iterator.Element == BarBeatTime
  {
    times.forEach { var bag = callbacks[$0] ?? [:]; bag[identifier] = callback; callbacks[$0] = bag }
  }

  func removeCallback(time: BarBeatTime, identifier: UUID? = nil) {
    if let identifier = identifier {
      callbacks[time]?[identifier] = nil
    } else {
      callbacks[time] = nil
    }
  }

  func removePredicatedCallback(with identifier: UUID) { predicatedCallbacks[identifier] = nil }


  /// Set the `inout Bool` to true to unregister the callback
  func register(callback: @escaping Callback, predicate: @escaping Predicate, identifier: UUID) {
    predicatedCallbacks[identifier] = (predicate: predicate, callback: callback)
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

extension Time: CustomStringConvertible {

  var description: String { return barBeatTime.description }

}

extension Time: Hashable {

  static func ==(lhs: Time, rhs: Time) -> Bool { return ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }

  var hashValue: Int { return ObjectIdentifier(self).hashValue }

}

extension Time {

  fileprivate enum _Callback {

    case time (BarBeatTime, (BarBeatTime) -> Void)
    case predicated ((BarBeatTime) -> Bool, (BarBeatTime) -> Void)

//    let time: BarBeatTime
//    let callback: (BarBeatTime) -> Void
//    let predicate: ((BarBeatTime) -> Bool)?
//    let identifier = UUID()

//    func invoke() {
//      guard predicate
//    }
  }

}
