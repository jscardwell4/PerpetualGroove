//
//  Transport.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import Foundation
import MIDI
import MoonDev

// MARK: - Transport

/// A class for managing playback state for the Controller.shared.
@available(iOS 14.0, *)
public final class Transport: ObservableObject
{
  // MARK: Stored Properties

  /// The label assigned to the transport.
  public let name: String

  /// The MIDI clock used by the transport.
  public let clock: MIDIClock

  /// The `Time` instance connected to `clock.endPoint` by the transport.
  public let time: Time

  // MARK: Transport State

  /// Whether the transport's clock is currently running. Changing the value of this
  /// property from `false` to `true` results in the transport posting a `didStart`
  /// notification and performing one of the following actions:
  /// * Resume the clock and set `isPaused` to `false` if the transport is paused.
  /// * Start the clock if the transport is not currently paused.
  @Published public var isPlaying = false
  {
    willSet
    {
      logi("""
        <\(#fileID) \(#function)> \
        isPlaying = \(newValue)
        """)
    }
    didSet
    {
      // Check that the transport has started playing.
      guard isPlaying, !oldValue else { return }

      // Post notification that the transport has started playing.
      postNotification(name: .transportDidStart,
                       object: self,
                       userInfo: ["time": time.barBeatTime])

      // Manage clock according to the current state of the transport.
      switch isPaused
      {
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

  /// Whether the transport's previously running clock has been paused. Changing the
  /// value of this property from `false` to `true` when the transport is playing causes
  /// the transport to stop its clock, set `isPlaying` to `false`, and post a `didPause`
  /// notification.
  @Published public var isPaused = false
  {
    willSet
    {
      logi("""
        <\(#fileID) \(#function)> \
        isPaused = \(newValue)
        """)
    }
    didSet
    {
      // Check that the transport is playing and that `isPaused` has toggled from
      // `false` to `true`.
      guard isPlaying, isPaused, !oldValue else { return }

      // Stop the clock.
      clock.stop()

      // Unset the play flag.
      isPlaying = false

      // Post notification that the transport has been paused.
      postNotification(name: .transportDidPause,
                       object: self,
                       userInfo: ["time": time.barBeatTime])
    }
  }

  /// Whether the transport's clock is currently being jogged. Changing the value of this
  /// property causes the transport behave as follows:
  /// * The transport stops its clock, sets `jogTime` to the current bar beat time, and
  ///   posts a `didBeginJogging` notification when this property has been set to `true`.
  /// * The transport sets the current bar beat time to `jogTime`, sets `jogTime` to
  ///   `null`, resumes the clock if previously running, and posts a `didEndJogging`
  ///   notification when this property has been set to `false`.
  @Published public var isJogging = false
  {
    willSet
    {
      logi("""
        <\(#fileID) \(#function)> \
        isJogging = \(newValue)
        """)
    }

    didSet
    {
      switch (isJogging, oldValue)
      {
        case (true, true),
             (false, false):
          // Jogging state has not changed, just return.

          return

        case (true, false):
          // The transport has begun jogging, stop the clock,
          // store the time and post notification.

          // Stop the clock if it is running.
          if clock.isRunning { clock.stop() }

          // Store the bar beat time as jogging begins.
          previousJogTime = time.barBeatTime

          // Post notification that the transport has begun jogging.
          postNotification(name: .transportDidBeginJogging,
                           object: self,
                           userInfo: ["time": previousJogTime])

        case (false, true):
          // The transport has stopped jogging, update `time`, nullify `jogTime`,
          // post notification, and resume clock when appropriate.

          // Set the bar beat time using the time to which the transport has jogged.
          time.barBeatTime = previousJogTime

          // Nullify the jog time.
          previousJogTime = .zero

          // Post notification that the transport is no longer jogging.
          postNotification(name: .transportDidEndJogging,
                           object: self,
                           userInfo: ["time": time.barBeatTime.rawValue])

          // Check whether the clock needs to be resumed.
          if !isPaused, clock.isPaused { clock.resume() }
      }
    }
  }

  /// The bar beat time to which the transport has jogged or `.zero` if the
  /// transport is not jogging.
  private var previousJogTime: BarBeatTime = .zero

  /// Hint for objects using the transport as to whether they should persist the data
  /// they generate. Changing this property causes the transport to post a
  /// `didToggleRecording` notification.
  @Published public var isRecording = false
  {
    willSet
    {
      logi("""
        <\(#fileID) \(#function)> \
        isRecording = \(newValue)
        """)
    }
  }

  private let didResetSubject = PassthroughSubject<Void, Never>()
  private let didJogSubject = PassthroughSubject<(time: BarBeatTime,
                                                  jogTime: BarBeatTime), Never>()

  // MARK: Initializer

  /// Initializing with a name.
  /// - Parameter name: The name to use for this transport and its `clock` property.
  public init(name: String, beatsPerMinute: UInt16 = 120)
  {
    // Initialize the transport's name.
    self.name = name

    // Initialize the transport's clock with a new MIDI clock.
    clock = MIDIClock(name: name, beatsPerMinute: beatsPerMinute)

    // Create a new `Time` instance that observes the new MIDI clock.
    time = Time(clockSource: clock.endPoint)
  }

  // MARK: Computed Properties

  /// The number of beats per minute. This property is simply a wrapper for
  /// `clock.beatsPerMinute`.
  @Published public var tempo: UInt16 = 120
  {
    willSet
    {
      logi("""
        <\(#fileID) \(#function)> \
        tempo = \(newValue)
        """)
    }

    didSet { clock.beatsPerMinute = tempo }
  }

  // MARK: Jogging and Resetting

  /// Jogs the transport in the specified direction by the specified amount.
  ///
  /// - Parameter revolutions: The amount by which the transport is to be jogged
  ///                          specified in wheel revolutions. A negative value moves
  ///                          `jogTime` backward and a positive value moves `jogTime`
  ///                          forward.
  /// - Throws: `Error.notPermitted` when the transport is not currently jogging.
  public func jog(by revolutions: Double) throws
  {
    // Check that the transport is jogging.
    guard isJogging
    else
    {
      throw Error.notPermitted("The transport is not jogging")
    }

    // Convert the change in revolutions to a change in bar beat time.
    let 𝝙time =
      BarBeatTime(totalBeats: Double(Sequencer.shared.beatsPerBar) * revolutions)

    // Calculate the new jog time with a lower bound of zero.
    let newJogTime = max(previousJogTime + 𝝙time, BarBeatTime.zero)

    // Check that the new jog time is not the same as the current jog time.
    guard previousJogTime != newJogTime else { return }

    // Publish the new time.
    didJogSubject.send((time: time.barBeatTime, jogTime: newJogTime))

    // Update `jogTime` with the calculated bar beat time.
    previousJogTime = newJogTime

    // Post notification that the transport has jogged.
    postNotification(name: .transportDidJog,
                     object: self,
                     userInfo: ["time": time.barBeatTime, "jogTime": previousJogTime])
  }

  /// Jogs the transport directly to the specified time without the need to set the
  /// jog flag.
  public func jog(to newTime: BarBeatTime)
  {
    // Store the current bar beat time.
    let currentTime = time.barBeatTime

    // Check that the current time is not equal to the new time.
    guard currentTime != newTime else { return }

    // Stop the clock if it is running.
    if clock.isRunning { clock.stop() }

    // Update the current bar beat time with the new time.
    time.barBeatTime = newTime

    // Publish the new time.
    didJogSubject.send((time: currentTime, jogTime: newTime))

    // Post notification that the transport has jogged.
    postNotification(name: .transportDidJog,
                     object: self,
                     userInfo: ["time": currentTime, "jogTime": newTime])

    // Check whether the clock needs to be resumed.
    if !isPaused, clock.isPaused { clock.resume() }
  }

  /// Resets the transport's clock and time.
  /// - Precondition: The transport is either playing or paused.
  /// - Postcondition: Both `clock` and `time` have been reset to their initial state.
  /// - Todo: Re-evaluate the use of both `didStop` and `didReset` notifications.
  public func reset()
  {
    // Check that the transport is either playing or paused.
    guard isPlaying || isPaused else { return }

    // Stop the clock.
    clock.stop()

    // Unset the play and pause flags.
    isPlaying = false
    isPaused = false

    // Post notification that the transport has stopped.
    postNotification(
      name: .transportDidStop,
      object: self,
      userInfo: ["time": time.barBeatTime]
    )

    // Reset the clock.
    clock.reset()

    // Reset the time posting notification upon completing the reset.
    time.reset
    {
      [weak self] in

      // Get a strong reference.
      guard let weakself = self else { return }

      // Publish the reset.
      weakself.didResetSubject.send()

      // Post notification that the transport has been reset.
      weakself.postNotification(name: .transportDidReset,
                                object: weakself,
                                userInfo: ["time": weakself.time.barBeatTime])
    }
  }
}

// MARK: - Publishers

@available(iOS 14.0, *)
public extension Transport
{
  /// 
  var didResetPublisher: AnyPublisher<Void, Never>
  {
    didResetSubject.eraseToAnyPublisher()
  }

  var didJogPublisher: AnyPublisher<(time: BarBeatTime, jogTime: BarBeatTime), Never>
  {
    didJogSubject.eraseToAnyPublisher()
  }
}

@available(iOS 14.0, *)
public extension Transport
{
  /// An enumeration of possible errors thrown by an instance of `Transport`.
  enum Error: LocalizedError
  {
    case invalidBarBeatTime(String)
    case notPermitted(String)

    public var errorDescription: String?
    {
      switch self
      {
        case .invalidBarBeatTime: return "Invalid `BarBeatTime`"
        case .notPermitted: return "Not permitted"
      }
    }

    public var failureReason: String?
    {
      switch self
      {
        case let .invalidBarBeatTime(reason): return reason
        case let .notPermitted(reason): return reason
      }
    }
  }
}

// MARK: NotificationDispatching

@available(iOS 14.0, *)
extension Transport: NotificationDispatching
{
  public static let didStartNotification =
    Notification.Name("didStart")

  public static let didPauseNotification =
    Notification.Name("didPause")

  public static let didStopNotification =
    Notification.Name("didStop")

  public static let didResetNotification =
    Notification.Name("didReset")

  public static let didToggleRecordingNotification =
    Notification.Name("didToggleRecording")

  public static let didBeginJoggingNotification =
    Notification.Name("didBeginJogging")

  public static let didEndJoggingNotification =
    Notification.Name("didEndJogging")

  public static let didJogNotification =
    Notification.Name("didJog")
}

@available(iOS 14.0, *)
public extension Notification.Name
{
  static let transportDidStart = Transport.didStartNotification
  static let transportDidPause = Transport.didPauseNotification
  static let transportDidStop = Transport.didStopNotification
  static let transportDidReset = Transport.didResetNotification
  static let transportDidToggleRecording = Transport.didToggleRecordingNotification
  static let transportDidBeginJogging = Transport.didBeginJoggingNotification
  static let transportDidEndJogging = Transport.didEndJoggingNotification
  static let transportDidJog = Transport.didJogNotification
}

@available(iOS 14.0, *)
public extension Notification
{
  /// The bar beat time to which a transport has been jogged.
  var jogTime: BarBeatTime? { return userInfo?["jogTime"] as? BarBeatTime }

  /// The bar beat time associated with a notification posted by an instance of `Transport`.
  var time: BarBeatTime? { return userInfo?["time"] as? BarBeatTime }
}
