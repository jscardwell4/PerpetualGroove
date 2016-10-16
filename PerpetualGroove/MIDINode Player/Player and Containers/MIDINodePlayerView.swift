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

final class MIDINodePlayerView: SKView {

  var playerScene: MIDINodePlayerScene? { return scene as? MIDINodePlayerScene }

  fileprivate func setup() {
    ignoresSiblingOrder = true
    shouldCullNonVisibleNodes = false
    showsFPS = true
    showsNodeCount = true
    presentScene(MIDINodePlayerScene(size: bounds.size))
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
}
