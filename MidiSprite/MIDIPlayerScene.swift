//
//  MIDIPlayerScene.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import SpriteKit
import CoreImage
import MoonKit
import Chameleon
import AVFoundation

class MIDIPlayerScene: SKScene {

  var midiPlayer: MIDIPlayerNode!

  static let defaultBackgroundColor = UIColor(red: 0.202, green: 0.192, blue: 0.192, alpha: 1.0)

  private var contentCreated = false

  /** revert */
  func revert() { midiPlayer.dropLast() }

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit
    let w = frame.width - 20
    let containerRect = CGRect(x: 10, y: frame.midY - w * 0.5, width: w, height: w)

    midiPlayer = MIDIPlayerNode(bezierPath: UIBezierPath(rect: containerRect))
    addChild(midiPlayer)

    physicsWorld.contactDelegate = self
  }

  /**
  didMoveToView:

  - parameter view: SKView
  */
  override func didMoveToView(view: SKView) { guard !contentCreated else { return }; createContent(); contentCreated = true }


  /**
  update:

  - parameter currentTime: CFTimeInterval
  */
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
//    backgroundDispatch {print("scene time = \(currentTime)")}
  }
}

extension MIDIPlayerScene: SKPhysicsContactDelegate {
  /**
  didBeginContact:

  - parameter contact: SKPhysicsContact
  */
  func didBeginContact(contact: SKPhysicsContact) {
    guard let midiNode = contact.bodyB.node as? MIDINode else { return }
    midiNode.play()
  }
}
