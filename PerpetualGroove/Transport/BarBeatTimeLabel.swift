//
//  BarBeatTimeLabel.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import UIKit

@IBDesignable
final class BarBeatTimeLabel: UIView {

  private weak var transport: Transport! {
    didSet {
      guard transport !== oldValue else { return }
      currentTime = transport.time.barBeatTime

      if let oldTransport = oldValue {
        oldTransport.time.removePredicatedCallback(with: callbackIdentifier)
        receptionist.stopObserving(name: Transport.NotificationName.didJog.rawValue, from: oldValue)
        receptionist.stopObserving(name: Transport.NotificationName.didReset.rawValue, from: oldValue)
      }

      guard let transport = transport else { return }

      guard transport.time.callbackRegistered(with: callbackIdentifier) == false else { return }
      transport.time.register(callback: { [weak self] in self?.currentTime = $0 },
                              predicate: {_ in true},
                              identifier: callbackIdentifier)
      receptionist.observe(name: Transport.NotificationName.didBeginJogging.rawValue, from: transport) {
        [weak self] _ in self?.jogging = true
      }
      receptionist.observe(name: Transport.NotificationName.didEndJogging.rawValue, from: transport) {
        [weak self] _ in self?.jogging = false
      }
      receptionist.observe(name: Transport.NotificationName.didJog.rawValue, from: transport) {
        [weak self] in
        guard self?.jogging == true, let time = $0.jogTime, let _ = $0.jogDirection else { return }
        self?.currentTime = time
      }
      receptionist.observe(name: Transport.NotificationName.didReset.rawValue, from: transport) {
        [weak self] in guard let time = $0.time else { return }; self?.currentTime = time
      }
    }
  }

  private var jogging = false

  @IBInspectable var font: UIFont = .largeDisplayFont { didSet { updateFont() } }
  private var _font: UIFont = .largeDisplayFont { didSet { setNeedsDisplay() } }

  @IBInspectable var fontColor: UIColor = .primaryColor

  @IBInspectable var bar: Int = 1 {
    didSet {
      guard bar != oldValue else { return }
      barString = String(bar, radix: 10, pad: 3)
    }
  }

  @IBInspectable var beat: Int = 1 {
    didSet {
      guard beat != oldValue else { return }
      beatString = String(beat)
    }
  }

  @IBInspectable var subbeat: Int = 1 {
    didSet {
      guard subbeat != oldValue else { return }
      subbeatString = String(subbeat, radix: 10, pad: 3)
    }
  }

  private var barString: String = "001" { didSet { setNeedsDisplay(barFrame) } }
  private var beatString: String = "1" { didSet { setNeedsDisplay(beatFrame) } }
  private var subbeatString: String = "001" { didSet { setNeedsDisplay(subbeatFrame) } }
  private let barBeatDividerString: String = ":"
  private let beatSubbeatDividerString: String = "."

  private var barFrame: CGRect = .zero
  private var barBeatDividerFrame: CGRect = .zero
  private var beatFrame: CGRect = .zero
  private var beatSubbeatDividerFrame: CGRect = .zero
  private var subbeatFrame: CGRect = .zero

  override var bounds: CGRect { didSet { calculateFrames() } }

  private func calculateFrames() {
    guard !bounds.isEmpty else {
      barFrame = .zero
      barBeatDividerFrame = .zero
      beatFrame = .zero
      beatSubbeatDividerFrame = .zero
      subbeatFrame = .zero
      return
    }
    let w = bounds.width / 9
    let height = bounds.height
    barFrame                = CGRect(x: 0,     y: 0, width: w * 3, height: height)
    barBeatDividerFrame     = CGRect(x: w * 3, y: 0, width: w,     height: height)
    beatFrame               = CGRect(x: w * 4, y: 0, width: w,     height: height)
    beatSubbeatDividerFrame = CGRect(x: w * 5, y: 0, width: w,     height: height)
    subbeatFrame            = CGRect(x: w * 6, y: 0, width: w * 3, height: height)
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    let attributes: [String:AnyObject] = [
      NSFontAttributeName: _font,
      NSForegroundColorAttributeName: fontColor
    ]
    switch rect {
    case barFrame:                  barString.draw(in: rect, withAttributes: attributes)
      case barBeatDividerFrame:     barBeatDividerString.draw(in: rect, withAttributes: attributes)
      case beatFrame:               beatString.draw(in: rect, withAttributes: attributes)
      case beatSubbeatDividerFrame: beatSubbeatDividerString.draw(in: rect, withAttributes: attributes)
      case subbeatFrame:            subbeatString.draw(in: rect, withAttributes: attributes)
      default: 
        barString.draw(in: barFrame, withAttributes: attributes)
        barBeatDividerString.draw(in: barBeatDividerFrame, withAttributes: attributes)
        beatString.draw(in: beatFrame, withAttributes: attributes)
        beatSubbeatDividerString.draw(in: beatSubbeatDividerFrame, withAttributes: attributes)
        subbeatString.draw(in: subbeatFrame, withAttributes: attributes)      
    }
  }

  private var currentTime: BarBeatTime = BarBeatTime.zero {
    didSet {
      guard currentTime != oldValue else { return }
//      logSyncDebug("currentTime = \(currentTime.debugDescription)")
      dispatchToMain {
        [unowned self, newValue = currentTime] in

        if oldValue.bar != newValue.bar         { self.bar = Int(newValue.bar)         }
        if oldValue.beat != newValue.beat       { self.beat = Int(newValue.beat)       }
        if oldValue.subbeat != newValue.subbeat { self.subbeat = Int(newValue.subbeat) }
      }
    }
  }
  private let callbackIdentifier = UUID()

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  private var characterSize: CGSize {
    return "0123456789:.".characters.reduce(.zero) {[attributes = [NSFontAttributeName: font]] in
      let s = (String($1) as NSString).size(attributes: attributes)
      return CGSize(width: max($0.width, s.width), height: max($0.height, s.height))
    }
  }

  private func updateFont() {
    _font = font.withSize((characterSize.width / (bounds.width / 9)) * font.pointSize)
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: characterSize.width * 9, height: characterSize.height).integralSize
  }

  private func didChangeTransport(_ notification: Notification) {
    guard Sequencer.time.callbackRegistered(with: callbackIdentifier) == false else { return }
    Sequencer.time.register(callback: { [weak self] in self?.currentTime = $0 },
                            predicate: {_ in true},
                            identifier: callbackIdentifier)
    currentTime = Sequencer.time.barBeatTime
  }

  private func setup() {

    calculateFrames()

    #if !TARGET_INTERFACE_BUILDER
      receptionist.observe(name: Sequencer.NotificationName.didChangeTransport.rawValue, from: Sequencer.self) {
        [weak self] _ in self?.transport = Sequencer.transport
      }
      transport = Sequencer.transport
    #endif

  }

  override init(frame: CGRect) { super.init(frame: frame); setup() }

  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

}
