//
//  MIDIPlayerFieldNode.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

class MIDIPlayerFieldNode: SKShapeNode {

  unowned let delegate: MIDIPlayerNode

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(bezierPath: UIBezierPath, delegate: MIDIPlayerNode) {
    self.delegate = delegate
    super.init()
    name = "midiPlayerField"
    path = bezierPath.CGPath
    userInteractionEnabled = true
    strokeColor = .primaryColor
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Touch handling

  private var timestamp = 0.0
  private var location = CGPoint.null
  private var velocities: [CGVector] = []

  private var touch: UITouch? {
    didSet {
      velocities = []
      if let touch = touch {
        timestamp = touch.timestamp
        location = touch.locationInNode(self)
        let image = UIImage(named: "ball")!
        let color = (TrackColor.currentColor ?? TrackColor.nextColor).value
        let size = image.size * 0.75
        touchNode = SKSpriteNode(texture: SKTexture(image: image), color: color, size: size)
        touchNode!.position = location
        touchNode!.name = "touchNode"
        touchNode!.colorBlendFactor = 1
        addChild(touchNode!)
      } else {
        timestamp = 0
        location = .null
        touchNode?.removeFromParent()
        touchNode = nil
      }
    }
  }

  private var touchNode: SKSpriteNode?

  /** updateData */
  private func updateData() {
    guard let timestamp = touch?.timestamp, location = touch?.locationInNode(self)
      where timestamp != self.timestamp && location != self.location else { return }

    velocities.append(CGVector((location - self.location) / (timestamp - self.timestamp)))
    self.timestamp = timestamp
    self.location = location
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) { if touch == nil { touch = touches.first } }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) { touch = nil }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    updateData()
    generate()
    touch = nil
  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    guard let p = touch?.locationInNode(self) where containsPoint(p) else { touch = nil; return }
    updateData()
    touchNode?.position = p
  }

  // MARK: - MIDINode generation

  /** generate */
  private func generate() {
    guard velocities.count > 0 && !location.isNull else { return }
    delegate.placeNew(Placement(position: location, vector: sum(velocities) / CGFloat(velocities.count)))
  }
}
