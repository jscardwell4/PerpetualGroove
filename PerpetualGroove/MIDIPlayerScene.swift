//
//  MIDIPlayerScene.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import SpriteKit
import MoonKit

final class MIDIPlayerScene: SKScene {

  /** setup */
  private func setup() {
    MIDIPlayer.playerScene = self
  }

  /**
   initWithSize:

   - parameter size: CGSize
  */
  override init(size: CGSize) {
    super.init(size: size)
    setup()
  }

  /**
   init:

   - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private(set) var player: MIDIPlayerNode!

  private var contentCreated = false

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit

    player = MIDIPlayerNode(bezierPath: UIBezierPath(rect: frame))
    addChild(player)

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
    guard let midiNode = contact.bodyB.node as? MIDINode,
              edge = MIDIPlayerNode.Edge(rawValue: contact.bodyA.categoryBitMask) else { return }

    midiNode.edges = MIDIPlayerNode.Edges.All ∖ MIDIPlayerNode.Edges(edge)

    logVerbose("edge: \(edge); midiNode: \(midiNode.name!)")

    // ???: Should we do anything with the impulse and normal values provided by SKPhysicsContact?
    midiNode.pushBreadcrumb()
    midiNode.playForEdge(edge)
  }
}
