//
//  ControlNode.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/6/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit
import SpriteKit

public class ControlNode: SKNode {

  public var enabled = true { didSet { userInteractionEnabled = enabled } }
  public var dim = false

  public typealias ControlNodeAction = (Int?) -> Void

  public var action: ControlNodeAction?

  /**
  invokeAction:

  - parameter code: Int? = nil
  */
  func invokeAction(code: Int? = nil) { action?(code) }

  public var size: CGSize { return calculateAccumulatedFrame().size }

  /**
  init:

  - parameter a: ControlNodeAction?
  */
  public init(action a: ControlNodeAction?) { super.init(); action = a  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

}
