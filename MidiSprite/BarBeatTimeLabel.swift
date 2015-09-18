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

  /**
  didUpdateBarBeatTime:

  - parameter time: CABarBeatTime
  */
  private func didUpdateBarBeatTime(time: CABarBeatTime) { currentTime = time }

  /** setup */
  private func setup() {
    Sequencer.barBeatTime.registerCallback(didUpdateBarBeatTime,
                                 predicate: BarBeatTime.TruePredicate,
                                    forKey: barBeatTimeCallbackKey)
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