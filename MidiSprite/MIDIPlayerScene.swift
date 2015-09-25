//
//  MIDIPlayerScene.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import SpriteKit
import MoonKit

final class MIDIPlayerScene: SKScene {

  /** reset */
  func reset() { midiPlayer.reset() }

  private(set) var midiPlayer: MIDIPlayerNode!

  private var contentCreated = false

  /** revert */
  func revert() { midiPlayer.dropLast() }

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit
//    let w = frame.width - 20
//    let containerRect = CGRect(x: 10, y: frame.midY - w * 0.5, width: w, height: w)

    midiPlayer = MIDIPlayerNode(bezierPath: UIBezierPath(rect: frame)) //containerRect))
    addChild(midiPlayer)

    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self

    backgroundColor = .backgroundColor
    contentCreated = true
  }

  /**
  didMoveToView:

  - parameter view: SKView
  */
  override func didMoveToView(view: SKView) { guard !contentCreated else { return }; createContent() }


  /**
  update:

  - parameter currentTime: CFTimeInterval
  */
//  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
//    backgroundDispatch {print("scene time = \(currentTime)")}
//  }
}

extension MIDIPlayerScene: SKPhysicsContactDelegate {
  /**
  didBeginContact:

  - parameter contact: SKPhysicsContact
  */
  func didBeginContact(contact: SKPhysicsContact) {
    guard let midiNode = contact.bodyB.node as? MIDINode else { return }
    // ???: Should we do anything with the impulse and normal values provided by SKPhysicsContact?
    midiNode.mark()
    midiNode.play()
  }
}
