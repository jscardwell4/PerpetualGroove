//
//  PlayerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright (c) 2021 Moondeer Studios. All rights reserved.
//
import SpriteKit

/// `SKView` subclass that presents a `Scene`.
@available(iOS 14.0, *)
public final class PlayerSKView: SKView
{
  /// The player scene being presented.
  public var playerScene: Scene? {
    scene as? Scene
  }

  /// Configures various properties and presents a new `Scene` instance.
  private func setup()
  {
    ignoresSiblingOrder = true
    shouldCullNonVisibleNodes = false
    showsFPS = true
    showsNodeCount = true
    presentScene(Scene(size: bounds.size))
  }

  /// Overridden to run `setup()`.
  override public init(frame: CGRect)
  {
    super.init(frame: frame)
    setup()
  }

  /// Overridden to run `setup()`.
  public required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    setup()
  }
}
