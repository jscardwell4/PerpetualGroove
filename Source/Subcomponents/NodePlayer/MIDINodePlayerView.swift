//
//  MIDINodePlayerView.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import UIKit
import SpriteKit
import MoonKit

/// `SKView` subclass that presents a `MIDINodePlayerScene`.
public final class MIDINodePlayerView: SKView {

  /// The player scene being presented.
  public var playerScene: MIDINodePlayerScene? { scene as? MIDINodePlayerScene }

  /// Configures various properties and presents a new `MIDINodePlayerScene` instance.
  private func setup() {
    ignoresSiblingOrder = true
    shouldCullNonVisibleNodes = false
    showsFPS = true
    showsNodeCount = true
    presentScene(MIDINodePlayerScene(size: bounds.size))
  }

  /// Overridden to run `setup()`.
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  /// Overridden to run `setup()`.
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
}
