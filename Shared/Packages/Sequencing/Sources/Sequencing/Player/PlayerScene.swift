//
//  PlayerScene.swift
//  Sequencer
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//
import Common
import MoonDev
import SwiftUI
import SpriteKit

// MARK: - PlayerScene

/// `SKScene` subclass whose content is an instance of `PlayerNode`.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class PlayerScene: SKScene
{

  @Environment(\.player) var player: Player

  /// The player node for the scene.
  internal private(set) var playerNode: PlayerNode?

  /// Flag indicating whether the scene's content has been created.
  private var isContentCreated = false

  /// Overridden to update each element in `player.midiNodes`.
  override public func update(_ timeInterval: TimeInterval)
  {
    playerNode?.midiNodes.forEach { $0?.coordinator.updatePosition(timeInterval) }
  }

}

/*

 let trajectory = Trajectory(velocity: velocity, position: location)
 player.placeNew(trajectory, target: dispatch, generator: generator, identifier: identifier)

 */

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class BouncingPlayerScene: SKScene
{
  let colors = CuratedColor.allCases.map(UIColor.init(_:))

  var moving = true

  /// Overridden to trip `createContent`.
  override public func didMove(to view: SKView)
  {
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    physicsWorld.gravity = .zero
  }

  func populate()
  {
    for _ in 0 ..< 20
    {
      let texture = SKTexture(image: UIImage(named: "ball",
                                             in: .module,
                                             compatibleWith: nil)!)
      let node = SKSpriteNode(texture: texture,
                              color: colors[children.count % colors.count],
                              size: texture.size() * 0.75)
      node.colorBlendFactor = 1
      node.position = CGPoint(x: .random(in: 0 ... 300), y: .random(in: 0 ... 300))
      node.physicsBody = SKPhysicsBody(circleOfRadius: (texture.size() * 0.75).width / 2)
      addChild(node)
    }

    configureNodes()
  }

  private func configureNodes()
  {
    for node in children
    {
      node.physicsBody?.velocity = moving ? CGVector(
        dx: .random(in: -200 ... 200),
        dy: .random(in: -200 ... 200)
      ) : .zero
      node.physicsBody?.restitution = moving ? 1.0 : 0.0
      node.physicsBody?.linearDamping = moving ? 0.0 : 1.0
      node.physicsBody?.angularDamping = moving ? 0.0 : 1.0
      node.physicsBody?.friction = moving ? 0.0 : 1.0
    }

    physicsWorld.gravity = moving ? .zero : CGVector(dx: 0, dy: -9.8)
  }

}


