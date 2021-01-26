//
//  TransportViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import UIKit

/// A view controller for providing a user interface to an instance of `Transport`.
@available(iOS 14.0, *)
public final class TransportViewController: UIViewController
{
  /// The button used to begin/pause playback for the transport.
  ///
  /// When the transport is not playing this button displays '▶︎'. Pressing the
  /// button while it displays '▶︎' begins playback of the transport and changes
  /// this button to display '❙❙'. Pressing this button while it displays '❙❙'
  /// pauses the transport and changes this button to display '▶︎'. If at any time
  /// the transport stops or reset, this button goes back to displaying '▶︎'.
  @IBOutlet public var playPauseButton: ImageButtonView?

  /// The button used to stop and reset the transport.
  @IBOutlet public var stopButton: ImageButtonView?

  /// The scroll wheel used to scrub the transport forward and backward.
  @IBOutlet public var jogWheel: ScrollWheel?

  /// A stack view containing the transport buttons.
  @IBOutlet public var transportStack: UIStackView?

  /// The button used to toggle whether the transport is recording.
  @IBOutlet public var recordButton: ImageButtonView?

  /// Image for the play button.
  private let playImage = unwrapOrDie(UIImage(named: "play", in: Bundle.module, with: nil))

  /// Image for the play button when selected.
  private let playSelectedImage = unwrapOrDie(UIImage(named: "play-selected",
                                                      in: Bundle.module, with: nil))

  /// Image for the play button.
  private let pauseImage = unwrapOrDie(UIImage(named: "pause", in: Bundle.module, with: nil))

  /// Image for the play button when selected.
  private let pauseSelectedImage = unwrapOrDie(UIImage(named: "pause-selected",
                                                       in: Bundle.module, with: nil))

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
        .receive(on: DispatchQueue.main)
        .sink
        { _ in
          self.stopButton?.isEnabled = true
          self.playPauseButton?.image = self.pauseImage
          self.playPauseButton?.selectedImage = self.pauseSelectedImage
        }

      didStopSubscription = NotificationCenter.default
        .publisher(for: .transportDidStop, object: transport)
        .receive(on: DispatchQueue.main)
        .sink
        { _ in
          self.stopButton?.isEnabled = false
          self.playPauseButton?.image = self.playImage
          self.playPauseButton?.selectedImage = self.playSelectedImage
        }

      didPauseSubscription = NotificationCenter.default
        .publisher(for: .transportDidPause, object: transport)
        .receive(on: DispatchQueue.main)
        .sink
        { _ in
          self.playPauseButton?.image = self.playImage
          self.playPauseButton?.selectedImage = self.playSelectedImage
        }

      didResetSubscription = NotificationCenter.default
        .publisher(for: .transportDidReset, object: transport)
        .receive(on: DispatchQueue.main)
        .sink
        { _ in
          self.stopButton?.isEnabled = false
          self.playPauseButton?.image = self.playImage
          self.playPauseButton?.selectedImage = self.playSelectedImage
        }

      didBeginJoggingSubscription = NotificationCenter.default
        .publisher(for: .transportDidBeginJogging, object: transport)
        .sink { _ in self.transportStack?.isUserInteractionEnabled = false }

      didEndJoggingSubscription = NotificationCenter.default
        .publisher(for: .transportDidEndJogging, object: transport)
        .sink { _ in self.transportStack?.isUserInteractionEnabled = true }

      didToggleRecordingSubscription = NotificationCenter.default
        .publisher(for: .transportDidToggleRecording, object: transport)
        .sink { _ in self.recordButton?.isSelected = self.transport.recording }
    }
  }

  /// Overridden to upate `transport` with the sequencer's current transport.
  override public func viewDidLoad()
  {
    super.viewDidLoad()

    transport = sequencer.transport
  }

  /// The action assigned to the record button. Toggles `transport.isRecording`.
  @IBAction public func record() {
    transport.recording.toggle()
    logi("""
      <\(#fileID) \(#function)> \
      transport.isRecording = \(self.transport.recording)
      """)
  }

  /// The action assigned to the play/pause button. Pauses the transport
  /// when the transport is playing and begins playback for the transport otherwise.
  @IBAction public func playPause()
  {
    if transport.playing {
      transport.paused = true
      logi("<\(#fileID) \(#function)> transport.isPaused = true")
    }
    else {
      transport.playing = true
      logi("<\(#fileID) \(#function)> transport.isPlaying = true")
    }
  }

  /// The action assigned to the stop button. Stops and resets the transport.
  /// If the transport is not playing or paused then this button is disabled.
  @IBAction public func stop() {
    transport.reset()
    logi("<\(#fileID) \(#function)> transport has been reset.")
  }

  /// Handles touch down events for the jog wheel. Sets `transport.jogging` to `true`.
  @IBAction private func beginJog() {
    transport.jogging = true
    logi("<\(#fileID) \(#function)> transport.jogging = true")
  }

  /// Action invoked by the value changes of `jogWheel`.
  /// Jogs the transport by the scroll wheel's `𝝙revolutions`.
  @IBAction private func jog(scrollWheel: ScrollWheel)
  {
    do { try transport.jog(by: scrollWheel.𝝙revolutions) }
    catch { loge("\(error as NSObject)") }
  }

  /// Action invoked when `jogWheel` has finished.
  /// Sets `transport.jogging` to `false`.
  @IBAction private func endJog() {
    transport.jogging = false
    logi("<\(#fileID) \(#function)> transport.jogging = false")
  }
}
