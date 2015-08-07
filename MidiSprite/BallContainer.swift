//
//  BallContainer.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

class BallContainer: SKShapeNode {

  typealias BallType = Ball.BallType

  private var nextBallType = BallType.Concrete

  private var touch: UITouch? {
    didSet {
      timestamp = touch?.timestamp ?? 0
      location = touch?.locationInNode(self) ?? .nullPoint
      velocities = []
    }
  }

  private var timestamp = 0.0
  private var location = CGPoint.nullPoint
  private var velocities: [CGVector] = []

  /** updateData */
  private func updateData() {
    guard let touch = touch where touch.timestamp != timestamp && touch.locationInNode(self) != self.location else { return }
    velocities.append(CGVector((touch.locationInNode(self) - location) / (touch.timestamp - timestamp)))
    timestamp = touch.timestamp
    location = touch.locationInNode(self)
  }

  /** addBall */
  private func addBall() {
    guard velocities.count > 0 && !location.isNull else { return }
    let velocity = sum(velocities) / CGFloat(velocities.count)
    MSLogVerbose("adding new ball with velocity \(velocity) calculated from velocities \(velocities)")
    let ball = Ball(nextBallType, velocity)
    ball.name = "ball" + String(self["ball[0-9]*"].count)
    ball.position = location - (ball.size * 0.5)
    addChild(ball)
  }

  func dropBall() {
    if let ball = self["ball*"].last { ball.removeFromParent() }
  }

  /** init */
  override init() { super.init(); userInteractionEnabled = true }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); userInteractionEnabled = true }

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
    if containsPoint(touch.locationInNode(self)) { updateData(); addBall() }
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

}
