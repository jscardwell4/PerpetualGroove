//
//  TransportViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import MoonKit
import UIKit

/// A view controller for providing a user interface to an instance of `Transport`.
public final class TransportViewController: UIViewController
{
  /// The button used to begin/pause playback for the transport.
  ///
  /// When the transport is not playing this button displays '▶︎'. Pressing the
  /// button while it displays '▶︎' begins playback of the transport and changes
  /// this button to display '❙❙'. Pressing this button while it displays '❙❙'
  /// pauses the transport and changes this button to display '▶︎'. If at any time
  /// the transport stops or reset, this button goes back to displaying '▶︎'.
  @IBOutlet public var playPauseButton: ImageButtonView!

  /// The button used to stop and reset the transport.
  @IBOutlet public var stopButton: ImageButtonView!

  /// The scroll wheel used to scrub the transport forward and backward.
  @IBOutlet public var jogWheel: ScrollWheel!

  /// A stack view containing the transport buttons.
  @IBOutlet public var transportStack: UIStackView!

  /// The button used to toggle whether the transport is recording.
  @IBOutlet public var recordButton: ImageButtonView!

  /// Subscription for `didStart` notifications.
  private var didStartSubscription: Cancellable?

  /// Subscription for `didStop` notifications.
  private var didStopSubscription: Cancellable?

  /// Subscription for `didPause` notifications.
  private var didPauseSubscription: Cancellable?

  /// Subscription for `didReset` notifications.
  private var didResetSubscription: Cancellable?

  /// Subscription for `didBeginJogging` notifications.
  private var didBeginJoggingSubscription: Cancellable?

  /// Subscription for `didEndJogging` notifications.
  private var didEndJoggingSubscription: Cancellable?

  /// Subscription for `didToggleRecording` notifications.
  private var didToggleRecordingSubscription: Cancellable?

  /// The transport instance for which the controller is providing an interface.
  /// Changing the value of this property causes the controller to stop observing
  /// notifications from the old value and register to receive notifications from
  /// the new value.
  private weak var transport: Transport!
  {
    willSet
    {
      didStartSubscription?.cancel()
      didStopSubscription?.cancel()
      didPauseSubscription?.cancel()
      didResetSubscription?.cancel()
      didBeginJoggingSubscription?.cancel()
      didEndJoggingSubscription?.cancel()
      didToggleRecordingSubscription?.cancel()
    }
    didSet
    {
      // Check that there is a new transport from which to receive notifications.
      guard let transport = transport, transport !== oldValue else { return }

      didStartSubscription = NotificationCenter.default
        .publisher(for: .transportDidStart, object: transport)
        .sink
        { _ in
          self.stopButton.isEnabled = true
          self.playPauseButton.image = #imageLiteral(resourceName: "pause")
          self.playPauseButton.selectedImage = #imageLiteral(resourceName: "pause-selected")
        }

      didStopSubscription = NotificationCenter.default
        .publisher(for: .transportDidStop, object: transport)
        .sink
        { _ in
          self.stopButton.isEnabled = false
          self.playPauseButton.image = #imageLiteral(resourceName: "play")
          self.playPauseButton.selectedImage = #imageLiteral(resourceName: "play-selected")
        }

      didPauseSubscription = NotificationCenter.default
        .publisher(for: .transportDidPause, object: transport)
        .sink
        { _ in
          self.playPauseButton.image = #imageLiteral(resourceName: "play")
          self.playPauseButton.selectedImage = #imageLiteral(resourceName: "play-selected")
        }

      didResetSubscription = NotificationCenter.default
        .publisher(for: .transportDidReset, object: transport)
        .sink
        { _ in
          self.stopButton.isEnabled = false
          self.playPauseButton.image = #imageLiteral(resourceName: "play")
          self.playPauseButton.selectedImage = #imageLiteral(resourceName: "play-selected")
        }

      didBeginJoggingSubscription = NotificationCenter.default
        .publisher(for: .transportDidBeginJogging, object: transport)
        .sink { _ in self.transportStack.isUserInteractionEnabled = false }

      didEndJoggingSubscription = NotificationCenter.default
        .publisher(for: .transportDidEndJogging, object: transport)
        .sink { _ in self.transportStack.isUserInteractionEnabled = true }

      didToggleRecordingSubscription = NotificationCenter.default
        .publisher(for: .transportDidToggleRecording, object: transport)
        .sink { _ in self.recordButton.isSelected = self.transport.isRecording }
    }
  }

  /// Overridden to upate `transport` with the sequencer's current transport.
  override public func viewDidLoad()
  {
    super.viewDidLoad()

    transport = controller.transport
  }

  /// The action assigned to the record button. Toggles `transport.isRecording`.
  @IBAction public func record() { transport.isRecording.toggle() }

  /// The action assigned to the play/pause button. Pauses the transport
  /// when the transport is playing and begins playback for the transport otherwise.
  @IBAction public func playPause()
  {
    if transport.isPlaying { transport.isPaused = true }
    else { transport.isPlaying = true }
  }

  /// The action assigned to the stop button. Stops and resets the transport.
  /// If the transport is not playing or paused then this button is disabled.
  @IBAction public func stop() { transport.reset() }

  /// Handles touch down events for the jog wheel. Sets `transport.isJogging` to `true`.
  @IBAction private func beginJog() { transport.isJogging = true }

  /// Action invoked by the value changes of `jogWheel`.
  /// Jogs the transport by the scroll wheel's `𝝙revolutions`.
  @IBAction private func jog()
  {
    do { try transport.jog(by: jogWheel.𝝙revolutions) }
    catch { log.error("\(error as NSObject)") }
  }

  /// Action invoked when `jogWheel` has finished.
  /// Sets `transport.isJogging` to `false`.
  @IBAction private func endJog() { transport.isJogging = false }
}
