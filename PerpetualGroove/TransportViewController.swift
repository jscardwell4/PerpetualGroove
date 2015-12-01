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

  @IBOutlet weak var transportStack: UIStackView!
  @IBOutlet weak var recordButton: ImageButtonView!
  @IBOutlet weak var playPauseButton: ImageButtonView!
  @IBOutlet weak var stopButton: ImageButtonView!
  @IBOutlet weak var jogWheel: ScrollWheel!

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    receptionist.observe(Sequencer.Notification.DidPause,
                    from: Sequencer.self,
                callback: weakMethod(self, TransportViewController.didPause))

    receptionist.observe(Sequencer.Notification.DidStart,
                    from: Sequencer.self,
                callback: weakMethod(self, TransportViewController.didStart))

    receptionist.observe(Sequencer.Notification.DidStop,
                    from: Sequencer.self,
                callback: weakMethod(self, TransportViewController.didStop))
  }

  /** record */
  @IBAction func record() { Sequencer.toggleRecord() }

  /** playPause */
  @IBAction func playPause() { if state ∋ .Playing { pause() } else { play() } }

  /** play */
  func play() { Sequencer.play() }

  /** pause */
  func pause() { Sequencer.pause() }

  /** stop */
  @IBAction func stop() { Sequencer.reset() }

  /** beginJog */
  @IBAction private func beginJog(){ Sequencer.beginJog() }

  /** jog */
  @IBAction private func jog() { Sequencer.jog(jogWheel.revolutions) }

  /** endJog */
  @IBAction private func endJog() { Sequencer.endJog() }

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

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Playing        = State(rawValue: 0b0000_0010)
    static let Recording      = State(rawValue: 0b0000_0100)
    static let Paused         = State(rawValue: 0b0000_1000)
    static let Jogging        = State(rawValue: 0b0001_0000)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if self ∋ .Playing        { flagStrings.append("Playing")        }
      if self ∋ .Recording      { flagStrings.append("Recording")      }
      if self ∋ .Paused         { flagStrings.append("Paused")         }
      if self ∋ .Jogging        { flagStrings.append("Jogging")        }

      result += ", ".join(flagStrings)
      result += "]"
      return result
    }
  }

  var paused:         Bool { return state ∋ .Paused         }
  var playing:        Bool { return state ∋ .Playing        }
  var recording:      Bool { return state ∋ .Recording      }
  var jogging:        Bool { return state ∋ .Jogging        }

  private var state: State = [] {
    didSet {
      guard isViewLoaded() && state != oldValue else { return }
      guard state ∌ [.Playing, .Paused] else { fatalError("State invalid: cannot be both playing and paused") }

      logDebug("didSet…old state: \(oldValue); new state: \(state)")

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
  didPause:

  - parameter notification: NSNotification
  */
  private func didPause(notification: NSNotification) { state ⊻= [.Playing, .Paused] }

  /**
  didStart:

  - parameter notification: NSNotification
  */
  private func didStart(notification: NSNotification) { state ⊻= state ∋ .Paused ? [.Playing, .Paused] : [.Playing] }

  /**
  didStop:

  - parameter notification: NSNotification
  */
  private func didStop(notification: NSNotification) { state ∖= [.Playing, .Paused] }

}