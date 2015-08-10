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
import AVFoundation

class BallContainer: SKShapeNode {

  struct BallTemplate {
    var soundSet = Instrument.SoundSet.PureOscillators
    var program: UInt8 = 0
    var channel: UInt8 = 0
    var note = Instrument.Note()
    var type = Ball.BallType.Concrete
  }

  typealias BallType = Ball.BallType

  var template = BallTemplate()

  private var balls: [(CGPoint, CGVector)] = []

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
    let instrument = Instrument(soundSet: template.soundSet, program: template.program, channel: template.channel)
    let ball = Ball(ballType: template.type, vector: velocity, instrument: instrument, note: template.note)
    ball.name = "ball" + String(self["ball[0-9]*"].count)
    ball.position = location - (ball.size * 0.5)
    addChild(ball)
    balls.append((ball.position, velocity))
  }

  /** dropBall */
  func dropBall() { guard balls.count > 0 else { return }; self["ball*"].last?.removeFromParent(); balls.removeLast() }

  private func setup() {
    userInteractionEnabled = true
    strokeColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0)
    guard let path = path else { return }
    physicsBody = SKPhysicsBody(edgeLoopFromPath: path)
    physicsBody?.categoryBitMask = 1
    physicsBody?.contactTestBitMask = 0xFFFFFFFF
  }

  /** init */
  override init() { super.init(); setup() }

  /**
  initWithRect:

  - parameter rect: CGRect
  */
  init(rect: CGRect) {
    super.init()
    path = UIBezierPath(rect: rect).CGPath
    setup()
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

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
    addBall()
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

extension BallContainer: SKPhysicsContactDelegate {
  /**
  didBeginContact:

  - parameter contact: SKPhysicsContact
  */
  func didBeginContact(contact: SKPhysicsContact) {
    guard let ball = contact.bodyB.node as? Ball else { return }
    ball.instrument.playNote(ball.note)
  }
}