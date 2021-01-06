//
//  View.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import MoonKit
import SpriteKit
import UIKit

public extension Container.ViewController
{
  /// `SKView` subclass that presents a `Scene`.
  final class View: SKView
  {
    /// The player scene being presented.
    public var playerScene: Scene? { scene as? Scene }

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
}
