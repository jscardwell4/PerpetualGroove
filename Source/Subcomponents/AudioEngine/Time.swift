//
//  Time.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/26/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import CoreMIDI
import MoonKit
import MIDI

/// A high level bar beat time representation that builds around the basic `BarBeatTime`
/// structure. An instance of this class represents a bar beat time value synchronized with
/// a MIDI clock source. Additionally, callbacks may be registered with an instance of 
/// `Time` that are invoked when the bar beat time represented by the instance changes.
public final class Time: Named, CustomStringConvertible, Hashable {

  /// The instance of `Time` owned by the transport currently in use by the sequencer.
  public static var current: Time? //{ return Transport.current.time }

  /// Client for receiving MIDI clock messages.
  private var client = MIDIClientRef()

  /// Port for receiving MIDI clock messages.
  private var inPort = MIDIPortRef()

  /// Callback invoked from MIDI Services thread when the time's MIDI clock source sends out
  /// MIDI packets.
  private func read(packetList: UnsafePointer<MIDIPacketList>,
                    context: UnsafeMutableRawPointer?)
  {

    // Check the first byte of data from the first packet in the packet list.
    switch packetList.pointee.packet.data.0 {

      case 0b1111_1000:
        // The packet contains a timing clock message, increment the bar beat time.

        queue.async {
          [unowned self] in
          self.barBeatTime = self.barBeatTime.advanced(by: self.barBeatTime.subbeatUnitTime)
        }

      case 0b1111_1010:
        // The packet contains a start message. Reset the bar beat time.

        queue.async {
          [unowned self] in
          self.barBeatTime = .zero
        }

      default:
        // The packet does not contain one of the messages handled by `Time`, just ignore it.

        break

    }

  }

  /// The dispatch queue for working manipulating the time's bar beat time value.
  private let queue: DispatchQueue

  /// The musical representation of the current time kept by the MIDI clock source. The 
  /// value of this property updates as MIDI packets are read that originate with the MIDI 
  /// clock source. Each update causes the invocation of registered callbacks.
  /// - Note: The current assumption is that, aside from initialization (which doesn't 
  ///         cause the 'didSet' code to execute), the value of this property only changes
  ///         in response to receiving a 'clock' or 'start' message from the MIDI clock
  ///         source. Either message would indicate a running clock, which means a running
  ///         transport; therefore, there need to be a check for a running transport in
  ///         'didSet' before callbacks are invoked.
  public var barBeatTime: BarBeatTime = BarBeatTime.zero {

    didSet {

      // Invoke callbacks for the new bar beat time value.
      invokeCallbacks(for: barBeatTime)

    }

  }

  /// The type serving as a registerable callback.
  /// - Parameter time: The bar beat time value at the point of invocation.
  public typealias Callback  = (_ time: BarBeatTime) -> Void

  /// The type serving as a predicate for filtering callback invocations.
  /// - Parameter time: The bar beat time to be evaluated.
  /// - Returns: Whether the callback paired with the predicate should be invoked for 
  ///            `time`.
  public typealias Predicate = (_ time: BarBeatTime) -> Bool

  /// The type registerable as a predicated callback. The tuple consists of a `predicate` to 
  /// evaluate and a `callback` to execute when `predicate` returns `true`.
  public typealias PredicatedCallback = (predicate: Predicate, callback: Callback)

  /// The index of callbacks registered with the time. Each key is a bar beat time that 
  /// triggers invocation of the callbacks contained by the value. The value itself is
  /// another index for storing each callback under a unique identifier.
  private var callbacks: [BarBeatTime:[UUID:Callback]] = [:]

  /// The index of predicated callbacks registered with the time. Predicated callbacks are
  /// stored under a unique identifier to support lookup and removal operations.
  private var predicatedCallbacks: [UUID:PredicatedCallback] = [:]

  /// Returns whether any kind of callback has been registered with `identifier`.
  public func callbackRegistered(with identifier: UUID) -> Bool {

    return predicatedCallbacks[identifier] != nil
        || Set(callbacks.values.flatMap({$0.keys})).contains(identifier)

  }

  /// Flag for overriding callback invocation. Setting the value of this property to `true` 
  /// prevents the time from invoking callbacks that otherwise would have been executed.
  public var suppressCallbacks = false

  /// Invokes any callback registered for `time` and any predicated callback with a 
  /// predicate that evaluates `true` for `time`.
  private func invokeCallbacks(for time: BarBeatTime) {

    // Check that there are callbacks and that they should be invoked/evaluated.
    guard !(suppressCallbacks || callbacks.isEmpty && predicatedCallbacks.isEmpty) else {
      return
    }

    // Invoke the callbacks registered for `time`.
    callbacks[time]?.values.forEach({$0(time)})

    // Invoke the callbacks registered with a predicate returning `true` for `time`.
    predicatedCallbacks.values.filter({$0.predicate(time)}).forEach({$0.callback(time)})

  }

  /// Registers `callback` with `identifier` for each time in `times`.
  public func register<Source>(callback: @escaping Callback,
                forTimes times: Source,
                identifier: UUID)
    where Source:Swift.Sequence, Source.Iterator.Element == BarBeatTime
  {

    // Iterate the times.
    for time in times {

      // Get the bag for `time` or initialize an empty bag.
      var bag = callbacks[time] ?? [:]

      // Set `callback` for `identifier`.
      bag[identifier] = callback

      // Set the modified bag for `time`.
      callbacks[time] = bag

    }

  }

  /// Removes the callback registered for `time` with `identifier`. If `identifier` is 
  /// `nil`, removes all callbacks registered for `time`.
  public func removeCallback(time: BarBeatTime, identifier: UUID? = nil) {

    // Check if an identifier was provided.
    if let identifier = identifier {

      // Remove the entry for `identifier` in the bag for `time`.
      callbacks[time]?[identifier] = nil

    }

    // Otherwise, remove all entries for `time`.
    else {

      callbacks[time] = nil

    }

  }

  /// Removes the predicated callback registered with `identifier`.
  public func removePredicatedCallback(with identifier: UUID) {

    predicatedCallbacks[identifier] = nil

  }

  /// Registers a predicated callback with `identifier`.
  /// - Parameters:
  ///   - callback: The callback to invoke when `predicate` evaluates to `true`.
  ///   - predicate: The closure determining whether `callback` should be invoked.
  ///   - identifier: The unique identifier for this registration.
  public func register(callback: @escaping Callback,
                predicate: @escaping Predicate,
                identifier: UUID)
  {

    predicatedCallbacks[identifier] = (predicate: predicate, callback: callback)

  }

  /// The current bar. This is a convenience for accessing `barBeatTime.bar`.
  public var bar: UInt { return barBeatTime.bar }

  /// The current beat. This is a convenience for accessing `barBeatTime.beat`.
  public var beat: UInt { return barBeatTime.beat }

  /// The current subbeat. This is a convenience for accessing `barBeatTime.subbeat`.
  public var subbeat: UInt { return barBeatTime.subbeat }

  /// The bar beat time converted to ticks. This is a convenience for accessing 
  /// `barBeatTime.ticks`.
  public var ticks: MIDITimeStamp  { return barBeatTime.ticks }

  /// The bar beat time converted to seconds. This is a convenience for accessing 
  /// `barBeatTime.seconds`.
  public var seconds: TimeInterval { return barBeatTime.seconds }

  /// The name assigned to the time's MIDI clock source.
  public let name: String

  /// Initializing with the MIDI clock source.
  public init(clockSource: MIDIEndpointRef) {

    // Create an unmanaged variable to hold the name assigned to the clock source.
    var unmanagedName: Unmanaged<CFString>?

    // Get the value of the clock source's name property.
    MIDIObjectGetStringProperty(clockSource, kMIDIPropertyName, &unmanagedName)

    // Get the name as a String.
    guard let name = unmanagedName?.takeUnretainedValue() as String? else {

      fatalError("Endpoint should have been given a name")

    }

    // Initialize `clockName` using the name retrieved from the clock source.
    self.name = name

    // Initialize the dispatch queue.
    queue = DispatchQueue(label: name, qos: .userInteractive)

    do {

      // Initialize the time's MIDI client.
      try MIDIClientCreateWithBlock(name as CFString, &client, nil)
        ➤ "Failed to create MIDI client."

      // Initialize the time's input port setting the callback to `read(_:context:)`.
      try MIDIInputPortCreateWithBlock(client, "Input" as CFString, &inPort,
                                       self.read)
        ➤ "Failed to create input port."

      // Connect the clock source to the time's input port.
      try MIDIPortConnectSource(inPort, clockSource, nil)
        ➤ "Failed to connect clock source."

    } catch {

      // Just log the error.
      loge("\(error)")

    }

  }

  /// Sets `barBeatTime` to `zero` asynchronously before invoking `completion`.
  public func reset(_ completion: (() -> Void)? = nil) {

    // Invoke code that updates `barBeatTime` on the time's dispatch queue for thread 
    // safety.
    queue.async {
      [unowned self] in

      // Reset the bar beat time.
      self.barBeatTime = .zero

      // Invoke the completion closure.
      completion?()

    }

  }

  /// Asynchronously removes any registered callabcks and sets `barBeatTime` to `zero` 
  /// before invoking `completion`.
  /// - Note: While the callbacks are removed the storage allocated is retained.
  public func hardReset(_ completion: (() -> Void)? = nil) {

    // Invoke code that updates `barBeatTime` on the time's dispatch queue for thread
    // safety.
    queue.async {
      [unowned self] in

      // Clear any registered callbacks first to prevent invocation when setting the
      // bar beat time to zero.
      self.callbacks.removeAll(keepingCapacity: true)
      self.predicatedCallbacks.removeAll(keepingCapacity: true)

      // Reset the bar beat time.
      self.barBeatTime = .zero

      // Invoke the completion closure.
      completion?()
      
    }

  }

  deinit {

    do {

      // Dispose of the input port.
      try MIDIPortDispose(inPort) ➤ "Failed to dispose of the input port."

      // Dispose of the MIDI client.
      try MIDIClientDispose(client) ➤ "Failed to dispose of the MIDI client."

    } catch {

      // Just log the error.
      loge("\(error)")
      
    }
    
  }

  public var description: String { return barBeatTime.description }

  /// Returns `true` iff `ObjectIdentifier` instance intialized with `lhs` and `rhs` are 
  /// equal.
  public static func ==(lhs: Time, rhs: Time) -> Bool {

    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)

  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

}
