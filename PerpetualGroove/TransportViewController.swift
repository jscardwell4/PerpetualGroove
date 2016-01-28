//
//  TransportViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class TransportViewController: UIViewController {

  private weak var transport: Transport! {
    didSet {
      guard transport !== oldValue else { return }

      if let oldTransport = oldValue {
        receptionist.stopObserving(Transport.Notification.DidPause,       from: oldTransport)
        receptionist.stopObserving(Transport.Notification.DidStart,       from: oldTransport)
        receptionist.stopObserving(Transport.Notification.DidStop,        from: oldTransport)
        receptionist.stopObserving(Transport.Notification.DidChangeState, from: oldTransport)
      }

      guard let transport = transport else { return }

      state = transport.state

      receptionist.observe(Transport.Notification.DidChangeState,
                      from: transport,
                  callback: weakMethod(self, TransportViewController.didChangeState))
    }
  }

  @IBOutlet weak var transportStack: UIStackView!
  @IBOutlet weak var recordButton: ImageButtonView!
  @IBOutlet weak var playPauseButton: ImageButtonView!
  @IBOutlet weak var stopButton: ImageButtonView!
  @IBOutlet weak var jogWheel: ScrollWheel!

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    transport = Sequencer.transport
  }

  /** record */
  @IBAction func record() { Sequencer.toggleRecord() }

  /** playPause */
  @IBAction func playPause() { if state ∋ .Playing { pause() } else { play() } }

  /** play */
  func play() { transport.play() }

  /** pause */
  func pause() { transport.pause() }

  /** stop */
  @IBAction func stop() { transport.reset() }

  /** beginJog */
  @IBAction private func beginJog(){ transport.beginJog() }

  /** jog */
  @IBAction private func jog() { transport.jog(jogWheel.revolutions, direction: jogWheel.direction) }

  /** endJog */
  @IBAction private func endJog() { transport.endJog() }

  private enum ControlImage {
    case Pause, Play
    func decorateButton(item: ImageButtonView) {
      item.image = image
      item.highlightedImage = selectedImage
    }
    var image: UIImage {
      switch self {
        case .Pause: return UIImage(named: "pause")!
        case .Play: return UIImage(named: "play")!
      }
    }
    var selectedImage: UIImage {
      switch self {
        case .Pause: return UIImage(named: "pause-selected")!
        case .Play: return UIImage(named: "play-selected")!
      }
    }
  }

  // MARK: - Managing state

  var paused:         Bool { return state ∋ .Paused         }
  var playing:        Bool { return state ∋ .Playing        }
  var recording:      Bool { return state ∋ .Recording      }
  var jogging:        Bool { return state ∋ .Jogging        }

  private var state: Transport.State = [] {
    didSet {
      guard isViewLoaded() && state != oldValue else { return }
      guard state ∌ [.Playing, .Paused] else {
        fatalError("State invalid: cannot be both playing and paused")
      }

      logDebug("\(oldValue) ➞ \(state)")

      let modifiedState = state ⊻ oldValue

      // Check if jog status changed
      if modifiedState ∋ .Jogging { transportStack.userInteractionEnabled = !jogging }

      // Check for recording status change
      if modifiedState ∋ .Recording { recordButton.selected = recording }

      // Check if play/pause status changed
      if modifiedState ⚭ [.Playing, .Paused] {
        stopButton.enabled = playing || paused
        (playing ? ControlImage.Pause : ControlImage.Play).decorateButton(playPauseButton)
      }
    }
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  /**
   didChangeState:

   - parameter notification: NSNotification
  */
  private func didChangeState(notification: NSNotification) {
    guard let oldState = notification.previousTransportState, newState = notification.transportState else { return }
    logDebug("\(oldState) ➞ \(newState)")
    state = newState
  }

}