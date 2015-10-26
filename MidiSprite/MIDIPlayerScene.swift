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

  private(set) var midiPlayer: MIDIPlayerNode!

  private var contentCreated = false

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit

    midiPlayer = MIDIPlayerNode(bezierPath: UIBezierPath(rect: frame))
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

}

extension MIDIPlayerScene: SKPhysicsContactDelegate {
  /**
  didBeginContact:

  - parameter contact: SKPhysicsContact
  */
  func didBeginContact(contact: SKPhysicsContact) {
    guard let midiNode = contact.bodyB.node as? MIDINode else { return }
    // ???: Should we do anything with the impulse and normal values provided by SKPhysicsContact?
    midiNode.pushBreadcrumb()
    midiNode.play()
  }
}
