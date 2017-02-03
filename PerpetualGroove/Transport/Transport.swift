//
//  Transport.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// A class for managing playback state for the sequencer.
final class Transport: NotificationDispatching {

  /// The transport currently assigned to the sequencer.
  static var current: Transport { return Sequencer.transport }

  /// The label assigned to the transport.
  let name: String

  /// The MIDI clock used by the transport.
  let clock: MIDIClock

  /// The `Time` instance used by the transport.
  let time: Time

  /// The number of beats per minute. This property is simply a wrapper for `clock.beatsPerMinute`.
  var tempo: Double {
    get { return Double(clock.beatsPerMinute) }
    set { clock.beatsPerMinute = UInt16(newValue) }
  }

  /// Initializing with a name.
  init(name: String) {

    // Initialize the transport's name.
    self.name = name

    // Initialize the transport's clock with a new MIDI clock.
    clock = MIDIClock(name: name)

    // Create a new `Time` instance that observes the new MIDI clock.
    time = Time(clockSource: clock.endPoint)

  }

  /// Whether the transport's clock is currently running. Changing the value of this
  /// property from `false` to `true` results in the transport posting a `didStart`
  /// notification and performing one of the following actions:
  /// * Resume the clock and set `isPaused` to `false` if the transport is currently paused.
  /// * Start the clock if the transport is not currently paused.
  /// - TODO: Update to incorporate stopping behavior.
  var isPlaying = false {

    didSet {

      // Check that the transport has started playing.
      guard isPlaying && !oldValue else { return }

      // Post notification that the transport has started playing.
      postNotification(name: .didStart, object: self, userInfo: ["time": time.barBeatTime])

      // Manage clock according to the current state of the transport.
      switch isPaused {

        case true:
          // Resume the clock and unset the pause flag.

          clock.resume()
          isPaused = false

        case false:
          // Start the clock.

          clock.start()

      }

    }

  }

  /// Whether the transport's previously running clock has been paused. Changing the value of this 
  /// property from `false` to `true` when the transport is playing causes the transport to stop its
  /// clock, set `isPlaying` to `false`, and post a `didPause` notification.
  var isPaused = false {

    didSet {

      // Check that the transport is playing and that `isPaused` has toggled from `false` to `true`.
      guard isPlaying && isPaused && !oldValue else { return }

      // Stop the clock.
      clock.stop()

      // Unset the play flag.
      isPlaying = false

      // Post notification that the transport has been paused.
      postNotification(name: .didPause, object: self, userInfo: ["time": time.barBeatTime])

    }

  }

  /// Whether the transport's clock is currently being jogged. Changing the value of this property
  /// causes the transport behave as follows:
  /// * The transport stops its clock, sets `jogTime` to the current bar beat time, and posts a
  ///   `didBeginJogging` notification when this property has been set to `true`.
  /// * The transport sets the current bar beat time to `jogTime`, sets `jogTime` to `null`, resumes
  ///   the clock if previously running, and posts a `didEndJogging` notification when this property
  ///   has been set to `false`.
  var isJogging = false {

    didSet {


      switch (isJogging, oldValue) {

        case (true, true), (false, false):
          // Jogging state has not changed, just return.

          return

        case (true, false):
          // The transport has begun jogging, stop the clock, store the time and post notification.

          // Stop the clock if it is running.
          if clock.isRunning { clock.stop() }

          // Store the bar beat time as jogging begins.
          jogTime = time.barBeatTime

          // Post notification that the transport has begun jogging.
          postNotification(name: .didBeginJogging, object: self, userInfo: ["time": jogTime])

        case (false, true):
          // The transport has stopped jogging, update `time`, nullify `jogTime`, post notification,
          // and resume clock when appropriate.

          // Set the bar beat time using the time to which the transport has jogged.
          time.barBeatTime = jogTime

          // Nullify the jog time.
          jogTime = .null

          // Post notification that the transport is no longer jogging.
          postNotification(name: .didEndJogging, object: self, userInfo: ["time": time.barBeatTime.rawValue])

          // Check that transport is not paused and that the clock has been paused.
          guard !isPaused && clock.paused else { return }

          // Resume the clock.
          clock.resume()

      }

    }

  }

  /// Hint for objects using the transport as to whether they should persist the data they generate.
  /// Changing this property causes the transport to post a `didToggleRecording` notification.
  var isRecording = false {

    didSet {

      // Check that the value has actually changed.
      guard isRecording != oldValue else { return }

      // Post notification that the transport's state has changed with regard to recording.
      postNotification(name: .didToggleRecording, object: self)

    }

  }

  /// Resets the transport's clock and time.
  /// - Precondition: The transport is either playing or paused.
  /// - Postcondition: Both `clock` and `time` have been reset to their initial state.
  /// - Todo: Re-evaluate the use of both `didStop` and `didReset` notifications.
  func reset() {

    // Check that the transport is either playing or paused.
    guard isPlaying || isPaused else { return }

    // Stop the clock.
    clock.stop()

    // Unset the play and pause flags.
    isPlaying = false
    isPaused = false

    // Post notification that the transport has stopped.
    postNotification(name: .didStop, object: self, userInfo: ["time": time.barBeatTime])

    // Reset the clock.
    clock.reset()

    // Reset the time posting notification upon completing the reset.
    time.reset {
      [weak self] in

      // Get a strong reference.
      guard let weakself = self else { return }

      // Post notification that the transport has been reset.
      weakself.postNotification(name: .didReset,
                                object: weakself,
                                userInfo: ["time": weakself.time.barBeatTime])

    }

  }

  /// The bar beat time to which the transport has jogged or null if the transport is not jogging.
  private var jogTime: BarBeatTime = .null

  /// Jogs the transport in the specified direction by the specified amount.
  /// - Parameter 𝝙revolutions: The amount by which the transport is to be jogged specified in wheel
  ///                            revolutions. A negative value moves `jogTime` backward and a positive
  ///                            value moves `jogTime` forward.
  /// - Throws: `Error.notPermitted` when the transport is not currently jogging.
  func jog(by 𝝙revolutions: Double) throws {

    // Check that the transport is jogging.
    guard isJogging else {
      throw Error.notPermitted("The transport is not jogging")
    }

    // Convert the change in revolutions to a change in bar beat time.
    let 𝝙time = BarBeatTime(totalBeats: Double(Sequencer.beatsPerBar) * 𝝙revolutions)

    // Calculate the new jog time with a lower bound of zero.
    let newJogTime = max(jogTime + 𝝙time, BarBeatTime.zero)

    // Check that the new jog time is not the same as the current jog time.
    guard jogTime != newJogTime else { return }

    // Update `jogTime` with the calculated bar beat time.
    jogTime = newJogTime

    // Post notification that the transport has jogged.
    postNotification(name: .didJog, object: self, userInfo: ["time": time.barBeatTime, "jogTime": jogTime])

  }

  /// Jogs the transport directly to the specified time without the need to set the jog flag.
  func jog(to newTime: BarBeatTime) {

    // Store the current bar beat time.
    let currentTime = time.barBeatTime

    // Check that the current time is not equal to the new time.
    guard currentTime != newTime else { return }

    // Stop the clock if it is running.
    if clock.isRunning { clock.stop() }

    // Update the current bar beat time with the new time.
    time.barBeatTime = newTime

    // Post notification that the transport has jogged.
    postNotification(name: .didJog, object: self, userInfo: ["time": currentTime, "jogTime": newTime])

    // Check that the transport is not paused and that the transport's clock is paused.
    guard !isPaused && clock.paused else { return }

    // Resume the clock.
    clock.resume()

  }

  /// An enumeration of possible errors thrown by an instance of `Transport`.
  enum Error: LocalizedError {
    
    case invalidBarBeatTime (String)
    case notPermitted (String)

    var errorDescription: String? {
      switch self {
        case .invalidBarBeatTime: return "Invalid `BarBeatTime`"
        case .notPermitted:       return "Not permitted"
      }
    }

    var failureReason: String? {
      switch self {
        case .invalidBarBeatTime(let reason): return reason
        case .notPermitted(let reason):       return reason
      }
    }

  }

  /// An enumeration of the notification names used by notifications posted by an instance of `Transport`.
  enum NotificationName: String, LosslessStringConvertible {

    case didStart, didPause, didStop, didReset
    case didToggleRecording
    case didBeginJogging, didEndJogging
    case didJog

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }

  }

}

extension Notification {

  /// The bar beat time to which a transport has been jogged.
  var jogTime: BarBeatTime? { return userInfo?["jogTime"] as? BarBeatTime }

  /// The bar beat time associated with a notification posted by an instance of `Transport`.
  var time: BarBeatTime? { return userInfo?["time"] as? BarBeatTime }

}
