//
//  BarBeatTimeLabel.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import UIKit

@IBDesignable
final class BarBeatTimeLabel: UIView {

  private enum Component {
    case bar
    case barBeatDivider
    case beat
    case beatSubbeatDivider
    case subbeat

    static let characterWidth: CGFloat = 26
    static let characterHeight: CGFloat = 43

    static let sumWidths: CGFloat = Component.characterWidth * 9

    static func originTransform(for bounds: CGRect) -> CGAffineTransform {
      let 𝝙width = bounds.size.width - Component.characterWidth * 9
      let 𝝙height = bounds.size.height - Component.characterHeight
      return CGAffineTransform(translationX: 𝝙width, y: 𝝙height)
    }

    var characterCount: Int { switch self { case .bar, .subbeat: return 3; default: return 1 } }

    var characterIndex: Int {
      switch self {
        case .bar:                return 0
        case .barBeatDivider:     return 3
        case .beat:               return 4
        case .beatSubbeatDivider: return 5
        case .subbeat:            return 6
      }
    }

    var frame: CGRect {
      return CGRect(x: Component.characterWidth * CGFloat(characterIndex),
                    y: 0,
                    width: Component.characterWidth * CGFloat(characterCount),
                    height: Component.characterHeight)
    }

    static let characterAttributes: [String:Any] = [
      NSFontAttributeName: UIFont.largeDisplayFont,
      NSForegroundColorAttributeName: UIColor.primaryColor,
      NSParagraphStyleAttributeName: NSParagraphStyle.paragraphStyleWithAttributes(alignment: .center)
    ]

    static func components(for rect: CGRect) -> [Component] {
      switch rect {
        case Component.bar.frame: return [.bar]
        case Component.barBeatDivider.frame: return [.barBeatDivider]
        case Component.beat.frame: return [.beat]
        case Component.beatSubbeatDivider.frame: return [.beatSubbeatDivider]
        case Component.subbeat.frame: return [.subbeat]
        default: return [.bar, .barBeatDivider, .beat, .beatSubbeatDivider, .subbeat]
      }
    }

    func string(for time: BarBeatTime) -> String {
      switch self {
        case .bar:                return String(time.bar + 1, radix: 10, pad: 3)
        case .barBeatDivider:     return ":"
        case .beat:               return String(time.beat + 1)
        case .beatSubbeatDivider: return "."
        case .subbeat:            return String(time.subbeat + 1, radix: 10, pad: 3)
      }
    }

    func draw(_ time: BarBeatTime) {

      let string = self.string(for: time)

      switch characterCount {
        case 3:
          let (frame1, frame2_3) = frame.divided(atDistance: Component.characterWidth, from: .minXEdge)
          let (frame2, frame3) = frame2_3.divided(atDistance: Component.characterWidth, from: .minXEdge)

          for (character, frame) in zip(string.characters, [frame1, frame2, frame3]) {
            String(character).draw(in: frame, withAttributes: Component.characterAttributes)
          }

        default:
          string.draw(in: frame, withAttributes: Component.characterAttributes)
      }
    }

  }

  private weak var transport: Transport! {
    didSet {
      guard transport !== oldValue else { return }
      currentTime = transport.time.barBeatTime

      if let oldTransport = oldValue {
        oldTransport.time.removePredicatedCallback(with: callbackIdentifier)
        receptionist.stopObserving(name: .didJog, from: oldValue)
        receptionist.stopObserving(name: .didReset, from: oldValue)
      }

      guard let transport = transport else { return }

      guard transport.time.callbackRegistered(with: callbackIdentifier) == false else { return }

      transport.time.register(callback: { [weak self] in self?.currentTime = $0 },
                              predicate: {_ in true},
                              identifier: callbackIdentifier)

      receptionist.observe(name: .didBeginJogging, from: transport) {
        [weak self] _ in self?.jogging = true
      }

      receptionist.observe(name: .didEndJogging, from: transport) {
        [weak self] _ in self?.jogging = false
      }

      receptionist.observe(name: .didJog, from: transport) {
        [weak self] in
        guard self?.jogging == true, let time = $0.jogTime, let _ = $0.jogDirection else { return }
        self?.currentTime = time
      }

      receptionist.observe(name: .didReset, from: transport) {
        [weak self] in guard let time = $0.time else { return }; self?.currentTime = time
      }

    }

  }

  private var jogging = false

  override func draw(_ rect: CGRect) {

    guard let context = UIGraphicsGetCurrentContext() else { return }

    UIGraphicsPushContext(context)

    let transform = Component.originTransform(for: rect)
    let components = Component.components(for: rect.applying(transform))

    context.concatenate(transform)

    for component in components {
      component.draw(currentTime)
    }

    UIGraphicsPopContext()

  }

  private func refresh(component: Component) {
    let transform = Component.originTransform(for: bounds).inverted()
    let rect = component.frame.applying(transform)
    setNeedsDisplay(rect)
  }

  private func refresh(for time: BarBeatTime, oldTime: BarBeatTime) {

    var components: [Component] = []

    if time.bar != oldTime.bar { components.append(.bar) }
    if time.beat != oldTime.beat { components.append(.beat) }
    if time.subbeat != oldTime.subbeat { components.append(.subbeat) }

    guard components.count > 0 else { return }

    dispatchToMain { [unowned self] in for component in components { self.refresh(component: component) } }

  }

  private var currentTime: BarBeatTime = BarBeatTime.zero {
    didSet {
      guard currentTime != oldValue else { return }
      refresh(for: currentTime, oldTime: oldValue)
    }
  }
  
  private let callbackIdentifier = UUID()

  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  override var intrinsicContentSize: CGSize {
    return CGSize(width: Component.sumWidths, height: Component.characterHeight)
  }

  private func didChangeTransport(_ notification: Notification) {
    guard Time.current.callbackRegistered(with: callbackIdentifier) == false else { return }
    Time.current.register(callback: { [weak self] in self?.currentTime = $0 },
                          predicate: {_ in true},
                          identifier: callbackIdentifier)
    currentTime = Time.current.barBeatTime
  }

  private func setup() {

    #if !TARGET_INTERFACE_BUILDER

      receptionist.observe(name: .didChangeTransport, from: Sequencer.self) {
        [weak self] _ in self?.transport = Sequencer.transport
      }

      transport = Sequencer.transport

    #endif

  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

}
