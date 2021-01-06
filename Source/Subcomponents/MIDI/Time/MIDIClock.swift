//
//  MIDIClock.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import CoreMIDI
import Foundation
import MoonKit

// MARK: - MIDIClock

/// A class capable of keeping time for MIDI events
public final class MIDIClock: Named
{
  // MARK: Stored Properties

  /// The name assigned to the MIDI clock source.
  public let name: String

  /// The dispatch queue used by the clock.
  private let queue = DispatchQueue(label: "MIDI Clock (Dispatch)",
                                    qos: .userInteractive)

  /// The number of subbeats per beat.
  public let resolution: UInt64 = 480

  /// The number of beats per minute. Setting the value of this property causes the clock
  /// to recalculate all of its properties deriving from this property.
  public var beatsPerMinute: UInt16 = 120 { didSet { recalculate() } }

  /// The number of nanoseconds per MIDI clock tick. The value of this property is
  /// calculated using the values of `resolution` and `beatsPerMinute`.
  public private(set) var tickInterval: UInt64 = 0

  /// The number of nanoseconds in one beat. The value of this property is derived from
  /// the value of `beatsPerMinute`.
  public private(set) var nanosecondsPerBeat: UInt64 = 0

  /// The number of microseconds in one beat. The value of this property is derived from
  /// the value of `beatsPerMinute`.
  public private(set) var microsecondsPerBeat: UInt64 = 0

  /// The number of seconds in one beat. The value of this property is derived from
  /// the value of `beatsPerMinute`.
  public private(set) var secondsPerBeat: Double = 0

  /// The number of seconds per MIDI clock tick. The value of this property is
  /// calculated using the values of `resolution` and `beatsPerMinute`.
  public private(set) var secondsPerTick: Double = 0

  /// The timer used to generate MIDI ticks.
  private let timer = Timer(queue: DispatchQueue(label: "MIDI Clock (Timer)",
                                                 qos: .userInteractive))

  /// The running number of MIDI clocks that have elapsed
  public private(set) var ticks: MIDITimeStamp = 0

  /// The clock's MIDI client.
  private var client = MIDIClientRef()

  /// The endpoint used by the clock to establish itself as a MIDI source.
  public private(set) var endPoint = MIDIEndpointRef()

  // MARK: Initializing

  /// Initializing with the clock's name.
  ///
  /// - Parameter name: The name to assign the clock.
  public init(name: String)
  {
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

      weakself.queue.async
      {
        [weak weakself] in

        // Get a strong reference for `self` using the captured weak reference.
        guard let weakself = weakself else { return }

        // Increment the count of elapsed ticks.
        weakself.ticks = weakself.ticks &+ 1

        do
        {
          // Send the MIDI clock message.
          try weakself.sendEvent(0b1111_1000)
        }
        catch
        {
          // Just log the error.
          loge("\(error)")
        }
      }
    }

    do
    {
      // Create the clock's MIDI client.
      try require(MIDIClientCreateWithBlock("Clock" as CFString, &client, nil),
                  "Failed to create the clock's MIDI client.")

      // Create the clock's source.
      try require(MIDISourceCreate(client, "Clock" as CFString, &endPoint),
                  "Failed to create the clock's source.")

      // Set the name property on the clock's source.
      MIDIObjectSetStringProperty(endPoint,
                                  kMIDIPropertyName,
                                  "\(name) clock" as CFString)
    }
    catch
    {
      // Log the error.
      loge("\(error)")

      #if !TARGET_INTERFACE_BUILDER

        // Trap since the ability to create the MIDI clock is critical.
        fatalError("could not create clock as a MIDI source.")

      #endif
    }
  }

  // MARK: Computed Properties

  /// Whether the clock is currently paused. The clock is paused when it is
  /// not running but its count of elapsed ticks is greater than zero.
  public var isPaused: Bool { !isRunning && ticks > 0 }

  /// Whether the clock is currently running.
  public var isRunning: Bool { timer.running }

  // MARK: Sending MIDI events

  /// Creates a MIDI packet using `event` which is then distributed through `endPoint`.
  ///
  /// - Throws: Any `OSStatus`-based error encountered receiving the generated packet list
  ///           at `endPoint`.
  private func sendEvent(_ event: UInt8) throws
  {
    // Create an empty packet list.
    var packetList = MIDIPacketList()

    // Add a packet using the count of elapsed ticks as the offset and `event` as data.
    MIDIPacketListAdd(&packetList,
                      MemoryLayout<UInt32>.size + MemoryLayout<MIDIPacket>.size,
                      MIDIPacketListInit(&packetList),
                      ticks,
                      1,
                      [event])

    // Try pushing the packet list through the clock's endpoint.
    try require(MIDIReceived(endPoint, &packetList), "Failed to send packets")
  }

  // MARK: Calculations

  /// Recalculates all properties deriving from `beatsPerMinute` and/or `resolution`.
  /// Also updates the interval used by the timer with the recalculated tick interval.
  private func recalculate()
  {
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

  // MARK: Running the clock

  /// Begins the creation MIDI clock events.
  public func start()
  {
    // Execute on the clock's queue to enforce thread safety.
    queue.async
    {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the timer is not already running.
      guard !weakself.timer.running else { return }

      logi("setting ticks to 0, sending start message and starting timer…")

      // Reset the tick count.
      weakself.ticks = 0

      do
      {
        // Send the MIDI clock start message.
        try weakself.sendEvent(0b1111_1010)

        // Start the timer.
        weakself.timer.start()
      }
      catch
      {
        // Just log the error.
        loge("\(error)")
      }
    }
  }

  /// Resumes the clock when it is paused.
  ///
  /// - Precondition: The clock is has been paused.
  public func resume()
  {
    queue.async
    {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the clock is paused.
      guard weakself.isPaused else { return }

      logi("sending continue message and starting timer…")

      do
      {
        // Send the MIDI clock continue message.
        try weakself.sendEvent(0b1111_1011)

        // Restart the timer.
        weakself.timer.start()
      }
      catch
      {
        // Just log the error.
        loge("\(error)")
      }
    }
  }

  /// Resets the clock.
  ///
  /// - Precondition: The clock is not currently running.
  public func reset()
  {
    queue.async
    {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the timer is not running.
      guard !weakself.timer.running else { return }

      logi("setting ticks to 0…")

      // Reset the count for the number of elapsed ticks.
      weakself.ticks = 0
    }
  }

  /// Stops the clock.
  ///
  /// - Precondition: The clock is currently running.
  public func stop()
  {
    queue.async
    {
      [weak self] in

      // Get a strong reference for `self` using the captured weak reference.
      guard let weakself = self else { return }

      // Check that the timer is running.
      guard weakself.timer.running else { return }

      logi("stopping timer and sending stop message…")

      // Stop the timer.
      weakself.timer.stop()

      do
      {
        // Send the MIDI clock stop message.
        try weakself.sendEvent(0b1111_1100)
      }
      catch
      {
        // Just log the error.
        loge("\(error)")
      }
    }
  }
}

// MARK: CustomStringConvertible

extension MIDIClock: CustomStringConvertible
{
  public var description: String
  {
    let (ticks, time) = currentTicks()

    return """
    \(type(of: self).self) {
      name: \(name)
      beatsPerMinute: \(beatsPerMinute)
      resolution: \(resolution)
      ticks: \(ticks)
      tickInterval: \(tickInterval)
      nanosecondsPerBeat: \(nanosecondsPerBeat)
      microsecondsPerBeat: \(microsecondsPerBeat)
      secondsPerBeat: \(secondsPerBeat)
      secondsPerTick: \(secondsPerTick)
      hostInfo: { hostTicks: \(ticks), \
      nanosecondsPerTick: \(nanosecondsPer), \
      hostTime: \(time) }
    }
    """
  }
}

// MARK: Helpers

/// Calculates the current host time.
/// - Returns: A tuple composed of the current host time in ticks and seconds.
private func currentTicks() -> (ticks: UInt64, time: UInt64)
{
  let ticks = mach_absolute_time()
  let time = ticks * nanosecondsPer.numerator.low / nanosecondsPer.denominator.low
  return (ticks, time)
}

/// Fraction representing the number of nanoseconds per host tick
private let nanosecondsPer: Fraction = {
  var info = mach_timebase_info()
  mach_timebase_info(&info)
  return info.numer÷info.denom
}()
