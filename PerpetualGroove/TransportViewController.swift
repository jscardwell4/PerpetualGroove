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

  fileprivate weak var transport: Transport! {
    didSet {
      guard transport !== oldValue else { return }

      if let oldTransport = oldValue {
        receptionist.stopObserving(notification: .DidPause,       from: oldTransport)
        receptionist.stopObserving(notification: .DidStart,       from: oldTransport)
        receptionist.stopObserving(notification: .DidStop,        from: oldTransport)
        receptionist.stopObserving(notification: .DidChangeState, from: oldTransport)
      }

      guard let transport = transport else { return }

      state = transport.state

      receptionist.observe(notification: .DidChangeState,
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
  @IBAction fileprivate func beginJog(){ transport.beginJog(jogWheel) }

  /** jog */
  @IBAction fileprivate func jog() { transport.jog(jogWheel) }

  /** endJog */
  @IBAction fileprivate func endJog() { transport.endJog(jogWheel) }

  fileprivate enum ControlImage {
    case pause, play
    func decorateButton(_ item: ImageButtonView) {
      item.image = image
      item.highlightedImage = selectedImage
    }
    var image: UIImage {
      switch self {
        case .pause: return UIImage(named: "pause")!
        case .play: return UIImage(named: "play")!
      }
    }
    var selectedImage: UIImage {
      switch self {
        case .pause: return UIImage(named: "pause-selected")!
        case .play: return UIImage(named: "play-selected")!
      }
    }
  }

  // MARK: - Managing state

  var paused:         Bool { return state ∋ .Paused         }
  var playing:        Bool { return state ∋ .Playing        }
  var recording:      Bool { return state ∋ .Recording      }
  var jogging:        Bool { return state ∋ .Jogging        }

  fileprivate var state: Transport.State = [] {
    didSet {
      guard isViewLoaded && state != oldValue else { return }
      guard state ∌ [.Playing, .Paused] else {
        fatalError("State invalid: cannot be both playing and paused")
      }

      logDebug("\(oldValue) ➞ \(state)")

      let modifiedState = state ⊻ oldValue

      // Check if jog status changed
      if modifiedState ∋ .Jogging { transportStack.isUserInteractionEnabled = !jogging }

      // Check for recording status change
      if modifiedState ∋ .Recording { recordButton.isSelected = recording }

      // Check if play/pause status changed
      if modifiedState ⚭ [.Playing, .Paused] {
        stopButton.isEnabled = playing || paused
        (playing ? ControlImage.pause : ControlImage.play).decorateButton(playPauseButton)
      }
    }
  }

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  /**
   didChangeState:

   - parameter notification: NSNotification
  */
  fileprivate func didChangeState(_ notification: Notification) {
    guard let oldState = notification.previousTransportState, let newState = notification.transportState else { return }
    logDebug("\(oldState) ➞ \(newState)")
    state = newState
  }

}
