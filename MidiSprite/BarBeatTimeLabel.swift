//
//  BarBeatTimeLabel.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

@IBDesignable final class BarBeatTimeLabel: UIView {

  @IBInspectable var bar: Int = 1 { didSet { barLabel.text = String(bar, radix: 10, pad: 3) } }
  @IBInspectable var beat: Int = 1 { didSet { beatLabel.text = String(beat) } }
  @IBInspectable var subbeat: Int = 1 { didSet { subbeatLabel.text = String(subbeat, radix: 10, pad: 3) } }

  @IBOutlet weak var barLabel: UILabel!
  @IBOutlet weak var barBeatDivider: UILabel!
  @IBOutlet weak var beatLabel: UILabel!
  @IBOutlet weak var beatSubbeatDivider: UILabel!
  @IBOutlet weak var subbeatLabel: UILabel!

  private var currentTime: CABarBeatTime = .start {
    didSet {
      guard currentTime != oldValue else { return }
      dispatchToMain {
        [unowned self, newValue = currentTime] in

        if oldValue.bar != newValue.bar         { self.bar = Int(newValue.bar)         }
        if oldValue.beat != newValue.beat       { self.beat = Int(newValue.beat)       }
        if oldValue.subbeat != newValue.subbeat { self.subbeat = Int(newValue.subbeat) }
      }
    }
  }
  private var barBeatTimeCallbackKey: String { return String(ObjectIdentifier(self).uintValue) }

  private var notificationReceptionist: NotificationReceptionist!

  /**
  didUpdateBarBeatTime:

  - parameter time: CABarBeatTime
  */
  private func didUpdateBarBeatTime(time: CABarBeatTime) { currentTime = time }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
    guard let time = (notification.userInfo?[Sequencer.Notification.Key.JogTime.rawValue] as? NSValue)?.barBeatTimeValue else {
      logError("notification does not contain a time for updating")
      return
    }
    didUpdateBarBeatTime(time)
  }

  /**
  didReset:

  - parameter notification: NSNotification
  */
  private func didReset(notification: NSNotification) {
    guard let time = (notification.userInfo?[Sequencer.Notification.Key.Time.rawValue] as? NSValue)?.barBeatTimeValue else {
      logError("notification does not contain a time for updating")
      return
    }
    didUpdateBarBeatTime(time)
  }

  /** setup */
  private func setup() {
    Sequencer.time.registerCallback(didUpdateBarBeatTime,
                                 predicate: BarBeatTime.TruePredicate,
                                    forKey: barBeatTimeCallbackKey)
    let queue = NSOperationQueue.mainQueue()
    let object = Sequencer.self
    let didJogCallback: NotificationReceptionist.Callback = (object, queue, didJog)
    let didResetCallback: NotificationReceptionist.Callback = (object, queue, didReset)
    notificationReceptionist = NotificationReceptionist(callbacks:[
      Sequencer.Notification.DidJog.name.value:   didJogCallback,
      Sequencer.Notification.DidReset.name.value: didResetCallback
    ])
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

}