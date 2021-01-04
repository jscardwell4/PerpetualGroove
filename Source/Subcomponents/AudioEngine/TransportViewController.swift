//
//  TransportViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonKit

/// A view controller for providing a user interface to an instance of `Transport`.
public final class TransportViewController: UIViewController {

  /// The transport instance for which the controller is providing an interface. Changing the value
  /// of this property causes the controller to stop observing notifications from the old value and
  /// register to receive notifications from the new value.
  private weak var transport: Transport! {

    didSet {

      // Check that the value actually changed.
      guard transport !== oldValue else { return }

      // If registered to receive notifications from another transport, stop observing.
      if let oldTransport = oldValue {
        receptionist.stopObserving(object: oldTransport)
      }

      // Check that there is a new transport from which to receive notifications.
      guard let transport = transport else { return }

      // Register to receive notifications from the new transport.
      receptionist.observe(name: .didStart, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didStart))
      receptionist.observe(name: .didStop, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didStop))
      receptionist.observe(name: .didPause, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didPause))
      receptionist.observe(name: .didReset, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didReset))
      receptionist.observe(name: .didBeginJogging, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didBeginJogging))
      receptionist.observe(name: .didEndJogging, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didEndJogging))
      receptionist.observe(name: .didToggleRecording, from: transport,
                           callback: weakCapture(of: self, block:TransportViewController.didToggleRecording))

    }

  }

  /// A stack view containing the transport buttons: '⬤', '▶︎/❙❙', '⬛︎'.
  @IBOutlet public weak var transportStack: UIStackView!

  /// The button used to toggle whether the transport is recording. Displays '⬤'.
  @IBOutlet public weak var recordButton: ImageButtonView!

  /// The button used to begin/pause playback for the transport. When the transport is not playing
  /// this button displays '▶︎'. Pressing the button while it displays '▶︎' begins playback of the
  /// transport and changes this button to display '❙❙'. Pressing this button while it displays '❙❙'
  /// pauses the transport and changes this button to display '▶︎'. If at any time the transport
  /// stops or reset, this button goes back to displaying '▶︎'.
  @IBOutlet public weak var playPauseButton: ImageButtonView!

  /// The button used to stop and reset the transport. Displays '⬛︎'.
  @IBOutlet public weak var stopButton: ImageButtonView!

  /// The scroll wheel used to scrub the transport forward and backward.
  @IBOutlet public weak var jogWheel: ScrollWheel!

  /// Overridden to upate `transport` with the sequencer's current transport.
  public override func viewDidLoad() {

    super.viewDidLoad()

    transport = Sequencer.transport

  }

  /// The action assigned to the record button. Toggles `transport.isRecording`.
  @IBAction
  public func record() { transport.isRecording.toggle() }

  /// The action assigned to the play/pause button. Pauses the transport when the transport is playing
  /// and begins playback for the transport otherwise.
  @IBAction
  public func playPause() {

    // Pause if the transport is playing.
    if transport.isPlaying {

      transport.isPaused = true

    }

    // Otherwise begin playback.
    else {

      transport.isPlaying = true

    }

  }

  /// The action assigned to the stop button. Stops and resets the transport. If the transport is not
  /// playing or paused then this button is disabled.
  @IBAction
  public func stop() {

    transport.reset()

  }

  /// Handles touch down events for the jog wheel. Sets `transport.isJogging` to `true`.
  @IBAction
  private func beginJog(){

    transport.isJogging = true

  }

  /// Handles scroll wheel value changes. Jogs the transport by the scroll wheel's `𝝙revolutions`.
  @IBAction
  private func jog() {

    do {

      try transport.jog(by: jogWheel.𝝙revolutions)

    } catch {

      // Just log the error.
      loge("\(error)")

    }

  }

  /// Handles touch up events for the jog wheel. Sets `transport.isJogging` to `false`.
  @IBAction
  private func endJog() {

    transport.isJogging = false

  }

  /// Handles notification that the transport has begun playing. Enables the stop button and updates
  /// the play/pause button to display '❙❙'.
  private func didStart(_ notification: Notification) {

    // Enable the stop button.
    stopButton.isEnabled = true

    // Update the images used by the play/pause button.
    playPauseButton.image = #imageLiteral(resourceName: "pause")
    playPauseButton.selectedImage = #imageLiteral(resourceName: "pause-selected")

  }

  /// Handles notification that the transport has stopped playback. Disables the stop button and updates
  /// the play/pause button to display '▶︎'.
  private func didStop(_ notification: Notification) {

    // Disable the stop button.
    stopButton.isEnabled = false

    // Update the images used by the play/pause button.
    playPauseButton.image = #imageLiteral(resourceName: "play")
    playPauseButton.selectedImage = #imageLiteral(resourceName: "play-selected")

  }

  /// Handles notification that the transport has paused playback. Updates the play/pause button to
  /// display '❙❙'.
  private func didPause(_ notification: Notification) {

    // Update the images used by the play/pause button.
    playPauseButton.image = #imageLiteral(resourceName: "play")
    playPauseButton.selectedImage = #imageLiteral(resourceName: "play-selected")

  }

  /// Handles notification that the transport has been reset. Disables the stop button and updates
  /// the play/pause button to display '▶︎'.
  private func didReset(_ notification: Notification) {

    // Disable the stop button.
    stopButton.isEnabled = false

    // Update the images used by the play/pause button.
    playPauseButton.image = #imageLiteral(resourceName: "play")
    playPauseButton.selectedImage = #imageLiteral(resourceName: "play-selected")

  }

  /// Handles notification that the transport has started jogging. Disables the stack of transport buttons.
  private func didBeginJogging(_ notification: Notification) {

    // Disable the stack of transport buttons.
    transportStack.isUserInteractionEnabled = false

  }

  /// Handles notification that the transport has stopped jogging. Re-enables the stack of transport
  /// buttons disabled when the transport started jogging.
  private func didEndJogging(_ notification: Notification) {

    // Enable the stack of transport buttons.
    transportStack.isUserInteractionEnabled = true

  }

  /// Handles notification that the transport's recording state has changed. Updates the state of the
  /// record button to match the state of the transport.
  private func didToggleRecording(_ notification: Notification) {

    // Set the state of selection for the record button to match the state of recording in the transport.
    recordButton.isSelected = transport.isRecording

  }

  /// Handles registration/reception of notifications from `transport`.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

}
