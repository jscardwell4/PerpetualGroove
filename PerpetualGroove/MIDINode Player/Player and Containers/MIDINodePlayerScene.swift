//
//  MIDINodePlayerScene.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import SpriteKit
import MoonKit

final class MIDINodePlayerScene: SKScene {

  private(set) var player: MIDINodePlayerNode!

  private var contentCreated = false

  override func didMove(to view: SKView) {
    guard !contentCreated else { return }

    scaleMode = .aspectFit

    player = MIDINodePlayerNode(bezierPath: UIBezierPath(rect: frame))
    addChild(player)

    physicsWorld.gravity = .zero

    backgroundColor = .backgroundColor
    contentCreated = true
  }

  override func update(_ currentTime: TimeInterval) {
    player.midiNodes.forEach({$0?.updatePosition()})
  }
  
}
