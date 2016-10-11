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

  private func createContent() {
    scaleMode = .aspectFit

    player = MIDIPlayerNode(bezierPath: UIBezierPath(rect: frame))
    addChild(player)

    physicsWorld.gravity = .zero

    backgroundColor = .backgroundColor
    contentCreated = true
  }

  override func didMove(to view: SKView) {
    guard !contentCreated else { return }

    createContent()
  }

  override func update(_ currentTime: TimeInterval) {
    player.midiNodes.makeIterator().forEach({$0?.updatePosition()})
  }
  
}
