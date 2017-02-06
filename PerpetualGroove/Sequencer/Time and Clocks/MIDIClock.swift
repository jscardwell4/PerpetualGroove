//
//  MIDIClock.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

/// A class capable of keeping time for MIDI events
final class MIDIClock: CustomStringConvertible, Named {

  /// The MIDI clock source for the current transport.
  static var current: MIDIClock { return Transport.current.clock }

  var description: String {

    let currentHostTicks = hostTicks
    let nsPerTick = nanosecondsPerHostTick
    let currentHostTime = currentHostTicks * UInt64(nsPerTick.fraction)
    let hostInfo = "{ ; }".wrap([ "hostTicks: \(currentHostTicks)",
                                  "nanosecondsPerTick: \(nsPerTick)",
                                  "hostTime: \(currentHostTime)" ].joined(separator: "; "),
                                separator: ";")

    return "\(type(of: self).self) {\n\t" + [
      "name: \(name)",
      "beatsPerMinute: \(beatsPerMinute)",
      "resolution: \(resolution)",
      "ticks: \(ticks)",
      "tickInterval: \(tickInterval)",
      "nanosecondsPerBeat: \(nanosecondsPerBeat)",
      "microsecondsPerBeat: \(microsecondsPerBeat)",
      "secondsPerBeat: \(secondsPerBeat)",
      "secondsPerTick: \(secondsPerTick)",
      "hostInfo: \(hostInfo)"
    ].joined(separator: "\n\t") + "\n}"

  }

  /// The name assigned to the MIDI clock source.
  let name: String

  /// The dispatch queue used by the clock.
  private let queue = DispatchQueue(label: "MIDI Clock (Dispatch)", qos: .userInteractive)

  /// The number of subbeats per beat.
  let resolution: UInt64 = 480

  /// The number of beats per minute. Setting the value of this property causes the clock
  /// to recalculate all of its properties deriving from this property.
  var beatsPerMinute: UInt16 = 120 { didSet { recalculate() } }

  /// The number of nanoseconds per MIDI clock tick. The value of this property is 
  /// calculated using the values of `resolution` and `beatsPerMinute`.
  private(set) var tickInterval: UInt64 = 0

  /// The number of nanoseconds in one beat. The value of this property is derived from
  /// the value of `beatsPerMinute`.
  private(set) var nanosecondsPerBeat: UInt64 = 0

  /// The number of microseconds in one beat. The value of this property is derived from
  /// the value of `beatsPerMinute`.
  private(set) var microsecondsPerBeat: UInt64 = 0

  /// The number of seconds in one beat. The value of this property is derived from
  /// the value of `beatsPerMinute`.
  private(set) var secondsPerBeat: Double = 0

  /// The number of seconds per MIDI clock tick. The value of this property is
  /// calculated using the values of `resolution` and `beatsPerMinute`.
  private(set) var secondsPerTick: Double = 0

  /// Recalculates all properties deriving from `beatsPerMinute` and/or `resolution`.
  /// Also updates the interval used by the timer with the recalculated tick interval.
  private func recalculate() {

    // Calculate the number of nanoseconds per beat by dividing the number of nanoseconds 
    // in one minute by the number of beats per minute.
    nanosecondsPerBeat = UInt64(60.0e9) / UInt64(beatsPerMinute)

    // Calculate the number of microseconds per beat by dividing the number of microseconds 
    // in one minute by the number of beats per minute.
    microsecondsPerBeat = UInt64(60.0e6) / UInt64(beatsPerMinute)

    // Calculate the number of seconds per beat by dividing the number of seconds in one 
    // minute by the number of beats per minute.
    secondsPerBeat = 60 / Double(beatsPerMinute)

    // Calculate the number of seconds per tick by dividing the number of seconds per beat
    // by the number of ticks per beat.
    secondsPerTick = secondsPerBeat / Double(resolution)

    // Calculate the number of nanoseconds per tick by dividing the number of nanoseconds
    // per beat by the number of ticks per beat.
    tickInterval = nanosecondsPerBeat / UInt64(resolution)

    // Update the timer's interval with the new `tickInterval` value.
    timer.interval = .nanoseconds(Int(tickInterval))

  }

  /// Starts the clock by
  func start() {

    // Execute on the clock's queue to enforce thread safety.
    queue.async {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the timer is not already running.
      guard !weakself.timer.running else { return }

      Log.debug("setting ticks to 0, sending start message and starting timer…")

      // Reset the tick count.
      weakself.ticks = 0

      do {

        // Send the MIDI clock start message.
        try weakself.sendEvent(0b1111_1010)

        // Start the timer.
        weakself.timer.start()

      } catch {

        // Just log the error.
        Log.error(error)

      }

    }

  }

  /// Whether the clock is currently paused. The clock is paused when it is not running
  /// but its count of elapsed ticks is greater than zero.
  var isPaused: Bool { return !isRunning && ticks > 0 }

  /// Resumes the clock when it is paused.
  func resume() {

    queue.async {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the clock is paused.
      guard weakself.isPaused else { return }

      Log.debug("sending continue message and starting timer…")

      do {

        // Send the MIDI clock continue message.
        try weakself.sendEvent(0b1111_1011)

        // Restart the timer.
        weakself.timer.start()

      } catch {

        // Just log the error.
        Log.error(error)

      }

    }

  }

  /// Resets the clock.
  /// - Precondition: The clock is not currently running.
  func reset() {

    queue.async {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the timer is not running.
      guard !weakself.timer.running else { return }

      Log.debug("setting ticks to 0…")

      // Reset the count for the number of elapsed ticks.
      weakself.ticks = 0

    }

  }

  /// Stops the clock.
  /// - Precondition: The clock is currently running.
  func stop() {

    queue.async {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the timer is running.
      guard weakself.timer.running else { return }

      Log.debug("stopping timer and sending stop message…")

      // Stop the timer.
      weakself.timer.stop()

      do {

        // Send the MIDI clock stop message.
        try weakself.sendEvent(0b1111_1100)

      } catch {

        // Just log the error.
        Log.error(error)

      }

    }

  }

  /// The timer used to generate MIDI ticks.
  private let timer = Timer(queue: DispatchQueue(label: "MIDI Clock (Timer)",
                                                 qos: .userInteractive))

  /// Whether the clock is currently running.
  var isRunning: Bool { return timer.running }

  /// The running number of MIDI clocks that have elapsed
  private(set) var ticks: MIDITimeStamp = 0

  /// Initializing with the clock's name.
  init(name: String) {

    // Initialize the clock's name using the value specified.
    self.name = name

    // Force property calculations.
    recalculate()

    // Set the handler on the timer to send MIDI clock messages and increment the count
    // of elapsed ticks.
    timer.handler = {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      weakself.queue.async {
        [weak weakself] in

        // Get a strong reference for `self` using the captured weak reference.
        guard let weakself = weakself else { return }

        // Increment the count of elapsed ticks.
        weakself.ticks = weakself.ticks &+ 1

        do {

          // Send the MIDI clock message.
          try weakself.sendEvent(0b1111_1000)

        } catch {

          // Just log the error.
          Log.error(error)

        }

      }

    }


    do {

      // Create the clock's MIDI client.
      try MIDIClientCreateWithBlock("Clock" as CFString, &client, nil)
        ➤ "Failed to create the clock's MIDI client."

      // Create the clock's source.
      try MIDISourceCreate(client, "Clock" as CFString, &endPoint)
        ➤ "Failed to create the clock's source."

      // Set the name property on the clock's source.
      MIDIObjectSetStringProperty(endPoint, kMIDIPropertyName, "\(name) clock" as CFString)

    } catch {

      // Log the error.
      Log.error(error)

      #if !TARGET_INTERFACE_BUILDER

        // Trap since the ability to create the MIDI clock is critical.
        fatalError("could not create clock as a MIDI source.")

      #endif

    }

  }

  /// The clock's MIDI client.
  private var client = MIDIClientRef()

  /// The endpoint used by the clock to establish itself as a MIDI source.
  private(set) var endPoint = MIDIEndpointRef()

  /// Creates a MIDI packet using `event` which is then distributed through `endPoint`.
  /// - Throws: Any `OSStatus`-based error encountered receiving the generated packet list
  ///           at `endPoint`.
  private func sendEvent(_ event: UInt8) throws {

    // Create an empty packet list.
    var packetList = MIDIPacketList()

    // Add a packet using the count of elapsed ticks as the tick offset and `event` as data.
    MIDIPacketListAdd(&packetList,
                      MemoryLayout<UInt32>.size + MemoryLayout<MIDIPacket>.size,
                      MIDIPacketListInit(&packetList),
                      ticks,
                      1,
                      [event])

    // Try pushing the packet list through the clock's endpoint.
    try withUnsafePointer(to: &packetList) { MIDIReceived(endPoint, $0) }
      ➤ "Failed to send packets"

  }

}
