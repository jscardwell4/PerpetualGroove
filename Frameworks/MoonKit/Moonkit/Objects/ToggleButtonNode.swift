//
//  ToggleButtonNode.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/7/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit
import SpriteKit

public class ToggleButtonNode: ButtonNode {

  public var on = false { didSet { guard on != oldValue else { return }; updateTexture() } }

  /** updateTexture */
  override func updateTexture() {
    if on, let texture = defaultTextures?.defaultTexture { sprite.texture = texture }
    else if let texture = defaultTextures?.pressedTexture { sprite.texture = texture }
  }

  /**
  invokeAction:

  - parameter code: Int?
  */
  override func invokeAction(code: Int? = nil) { on = !on; super.invokeAction(code) }

}
