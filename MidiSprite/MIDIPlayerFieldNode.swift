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

  weak var delegate: MIDIPlayerNode?

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(bezierPath: UIBezierPath, delegate: MIDIPlayerNode? = nil) {
    super.init()
    name = "midiPlayerField"
    self.delegate = delegate
    path = bezierPath.CGPath
    userInteractionEnabled = true
  }

  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Touch handling

  private var timestamp = 0.0
  private var location = CGPoint.nullPoint
  private var velocities: [CGVector] = []

  private var touch: UITouch? {
    didSet {
      timestamp = touch?.timestamp ?? 0
      location = touch?.locationInNode(self) ?? .nullPoint
      velocities = []
    }
  }

  /** updateData */
  private func updateData() {
    guard let touch = touch where touch.timestamp != timestamp && touch.locationInNode(self) != self.location else { return }
    velocities.append(CGVector((touch.locationInNode(self) - location) / (touch.timestamp - timestamp)))
    timestamp = touch.timestamp
    location = touch.locationInNode(self)
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    let containedTouches = touches.filter({containsPoint($0.locationInNode(self))})
    if containedTouches.count == 1 { touch = containedTouches.first }
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touches = touches, touch = touch where touches.contains(touch) { self.touch = nil }
  }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = touch where touches.contains(touch) else { return }
    updateData()
    generate()
    self.touch = nil
  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = touch where touches.contains(touch) else { return }
    if containsPoint(touch.locationInNode(self)) { updateData() }
    else { self.touch = nil }
  }

  // MARK: - MIDINode generation

  /** generate */
  private func generate() {
    guard velocities.count > 0 && !location.isNull else { return }
    let velocity = sum(velocities) / CGFloat(velocities.count)
    let placement = MIDINode.Placement(position: location, vector: velocity)
    delegate?.placeNew(placement)
  }
}
