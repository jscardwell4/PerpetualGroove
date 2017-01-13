//
//  MIDINodePlayerScene.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import SpriteKit
import MoonKit

/// `SKScene` subclass whose content is an instance of `MIDINodePlayerNode`.
final class MIDINodePlayerScene: SKScene {

  /// The player node for the scene.
  private(set) var player: MIDINodePlayerNode!

  /// Flag indicating whether `player` has been generated and added to the scene.
  private var isContentCreated = false

  /// Overridden to create the scene's content if `isContentCreated == false`.
  override func didMove(to view: SKView) {

    // Check that content has not already been created.
    guard !isContentCreated else { return }

    // Configure the scene's properties.
    scaleMode = .aspectFit
    physicsWorld.gravity = .zero
    backgroundColor = .backgroundColor

    // Create and add the player node.
    player = MIDINodePlayerNode(bezierPath: UIBezierPath(rect: frame))
    addChild(player)

    // Update the content created flag.
    isContentCreated = true

  }

  /// Overridden to update each element in `player.midiNodes`.
  override func update(_ currentTime: TimeInterval) {

    for node in player.midiNodes {

      node?.updatePosition()

    }

  }
  
}
