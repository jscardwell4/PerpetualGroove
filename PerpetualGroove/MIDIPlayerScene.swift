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

  fileprivate(set) var player: MIDIPlayerNode!

  fileprivate var contentCreated = false

  /** createContent */
  fileprivate func createContent() {
    scaleMode = .aspectFit

    player = MIDIPlayerNode(bezierPath: UIBezierPath(rect: frame))
    addChild(player)

    physicsWorld.gravity = .zero

    backgroundColor = .backgroundColor
    contentCreated = true
  }

  /**
  didMoveToView:

  - parameter view: SKView
  */
  override func didMove(to view: SKView) { guard !contentCreated else { return }; createContent() }

  /**
   update:

   - parameter currentTime: NSTimeInterval
  */
  override func update(_ currentTime: TimeInterval) {
    player.midiNodes.makeIterator().forEach({$0?.updatePosition()})
  }
}
