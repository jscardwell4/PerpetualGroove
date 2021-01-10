//
//  Scene.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//
import Common
import MoonKit
import SpriteKit

/// `SKScene` subclass whose content is an instance of `PlayerNode`.
public final class Scene: SKScene
{
  /// The player node for the scene.
  public private(set) var playerNode: PlayerNode!

  /// Wrapped property
  @TripOnce<Scene> private var createContent = {
    logi("\(#fileID) \(#function) Creating content for scene: \($0)")

    // Configure the scene's properties.
    $0.scaleMode = .aspectFit
    $0.physicsWorld.gravity = .zero
    $0.backgroundColor = .backgroundColor

    // Create and add the player node.
    $0.playerNode = PlayerNode(bezierPath: UIBezierPath(rect: $0.frame))
    $0.addChild($0.playerNode)

    // Update the controller's node reference.
    player.playerNode = $0.playerNode
  }

  public override init() {
    logi("\(#fileID) \(#function) Creating scene…")
    super.init()
    $createContent = self
  }

  public required init?(coder aDecoder: NSCoder) {
    logi("\(#fileID) \(#function) Creating scene…")
    super.init(coder: aDecoder)
    $createContent = self
  }

  public override init(size: CGSize) {
    logi("\(#fileID) \(#function) Creating scene…")
    super.init(size: size)
    $createContent = self
  }

  /// Overridden to trip `createContent`.
  override public func didMove(to view: SKView) {
    _ = createContent
  }

  /// Overridden to update each element in `player.midiNodes`.
  override public func update(_ currentTime: TimeInterval)
  {
    playerNode.midiNodes.forEach { $0?.updatePosition() }
  }
}
