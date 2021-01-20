//
//  PlayerScene.swift
//  Sequencer
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//
import Common
import MoonDev
import SpriteKit

// MARK: - PlayerScene

/// `SKScene` subclass whose content is an instance of `PlayerNode`.
@available(iOS 14.0, *)
public final class PlayerScene: SKScene
{
  /// The player node for the scene.
  internal private(set) var playerNode: PlayerNode?

  /// Flag indicating whether the scene's content has been created.
  private var isContentCreated = false

  /// Overridden to trip `createContent`.
  override public func didMove(to view: SKView)
  {
    if !isContentCreated { createContent() }
  }

  /// Overridden to update each element in `player.midiNodes`.
  override public func update(_: TimeInterval)
  {
    playerNode?.midiNodes.forEach { $0?.updatePosition() }
  }

  /// A private method for configuring the scene's content.
  private func createContent()
  {
    scaleMode = .aspectFit
    physicsWorld.gravity = .zero
    backgroundColor = .backgroundColor2
    playerNode = PlayerNode(bezierPath: UIBezierPath(rect: frame))
    addChild(playerNode!)
    player.playerNode = playerNode
    isContentCreated = true
  }

  #if os(iOS)
  // Touch-based event handling

  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    logi("\(#fileID) \(#function)")
  }

  override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    logi("\(#fileID) \(#function)")
  }

  override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
  { 
    logi("\(#fileID) \(#function)")
  }

  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    logi("\(#fileID) \(#function)")
  }

  #endif

  #if os(OSX)
  // Mouse-based event handling
  override public func mouseDown(with event: NSEvent)
  {
    logi("\(#fileID) \(#function)")
  }

  override public func mouseDragged(with event: NSEvent)
  {
    logi("\(#fileID) \(#function)")
  }

  override public func mouseUp(with event: NSEvent)
  {
    logi("\(#fileID) \(#function)ß")
  }
  #endif
}
