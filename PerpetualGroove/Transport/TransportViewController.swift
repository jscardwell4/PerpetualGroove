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
        receptionist.stopObserving(name: .didPause,       from: oldTransport)
        receptionist.stopObserving(name: .didStart,       from: oldTransport)
        receptionist.stopObserving(name: .didStop,        from: oldTransport)
        receptionist.stopObserving(name: .didChangeState, from: oldTransport)
      }

      guard let transport = transport else { return }

      state = transport.state

      receptionist.observe(name: .didChangeState,
                           from: transport,
                           callback: weakMethod(self, TransportViewController.didChangeState))
    }
  }

  @IBOutlet weak var transportStack: UIStackView!
  @IBOutlet weak var recordButton: ImageButtonView!
  @IBOutlet weak var playPauseButton: ImageButtonView!
  @IBOutlet weak var stopButton: ImageButtonView!
  @IBOutlet weak var jogWheel: ScrollWheel!

  override func viewDidLoad() {
    super.viewDidLoad()

    transport = Sequencer.transport
  }

  @IBAction func record() { Sequencer.toggleRecord() }

  @IBAction func playPause() { if state ∋ .Playing { pause() } else { play() } }

  func play() { transport.play() }

  func pause() { transport.pause() }

  @IBAction func stop() { transport.reset() }

  @IBAction private func beginJog(){ transport.beginJog(jogWheel) }

  @IBAction private func jog() { transport.jog(jogWheel) }

  @IBAction private func endJog() { transport.endJog(jogWheel) }

  private enum ControlImage {
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

  var paused:    Bool { return state ∋ .Paused    }
  var playing:   Bool { return state ∋ .Playing   }
  var recording: Bool { return state ∋ .Recording }
  var jogging:   Bool { return state ∋ .Jogging   }

  private var state: Transport.State = [] {
    didSet {
      guard isViewLoaded && state != oldValue else { return }
      guard state ∌ [.Playing, .Paused] else {
        fatalError("State invalid: cannot be both playing and paused")
      }

      Log.debug("\(oldValue) ➞ \(state)")

      let modifiedState = state.symmetricDifference(oldValue)

      // Check if jog status changed
      if modifiedState ∋ .Jogging { transportStack.isUserInteractionEnabled = !jogging }

      // Check for recording status change
      if modifiedState ∋ .Recording { recordButton.isSelected = recording }

      // Check if play/pause status changed
      if !modifiedState.isDisjoint(with: [.Playing, .Paused]) {
        stopButton.isEnabled = playing || paused
        (playing ? ControlImage.pause : ControlImage.play).decorateButton(playPauseButton)
      }
    }
  }

  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  private func didChangeState(_ notification: Notification) {
    guard let oldState = notification.previousTransportState,
          let newState = notification.transportState
      else
    {
      return
    }
    Log.debug("\(oldState) ➞ \(newState)")
    state = newState
  }

}
