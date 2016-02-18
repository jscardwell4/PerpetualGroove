//
//  NodeSelectionTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/24/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

class NodeSelectionTool: ToolType {

  unowned let player: MIDIPlayerNode

  var active = false {
    didSet { guard active != oldValue && active == false else { return }; node = nil }
  }

  weak var node: MIDINode? {
    didSet {
      guard node != oldValue else { return }

      let name = "nodeSelectionToolLighting"

      if let node = node {
        guard node.childNodeWithName(name) == nil else { fatalError("node already lit") }

        let light = SKLightNode()
        light.name = name
        light.categoryBitMask = 1
        node.addChild(light)
        node.lightingBitMask = 1
        node.runAction(SKAction.colorizeWithColor(.whiteColor(), colorBlendFactor: 1, duration: 0.25))
      }

      if let oldNode = oldValue {
        oldNode.childNodeWithName(name)?.removeFromParent()
        oldNode.lightingBitMask = 0
        if let dispatch = oldNode.dispatch {
          oldNode.runAction(SKAction.colorizeWithColor(dispatch.color.value,
                                      colorBlendFactor: 1,
                                              duration: 0.25))
        }
      }

    }
  }

  init(playerNode: MIDIPlayerNode) {
    player = playerNode
  }

  /** didSelectNode */
  func didSelectNode() {}

  /**
   grabNodeForTouch:

   - parameter touch: UITouch?
  */
  private func grabNodeForTouch(touch: UITouch?) {
    guard let point = touch?.locationInNode(player) where player.containsPoint(point) else { return }
    node = player.nodesAtPoint(point).flatMap({$0 as? MIDINode}).first
  }

  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
  */
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) { node = nil }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node != nil else { return }
    didSelectNode()
  }

}
