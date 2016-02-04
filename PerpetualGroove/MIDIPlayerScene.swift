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

  private(set) var player: MIDIPlayerNode!

  private var contentCreated = false

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit

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
  override func didMoveToView(view: SKView) { guard !contentCreated else { return }; createContent() }

  /**
   update:

   - parameter currentTime: NSTimeInterval
  */
  override func update(currentTime: NSTimeInterval) {
    player.midiNodes.forEach({$0.updatePosition()})
  }
}
