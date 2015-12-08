//
//  GeneratorTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class GeneratorTool: ToolType {

  unowned let player: MIDIPlayerNode

  var active = false {
    didSet {
      logDebug("[\(mode)] oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue && mode == .New else { return }
      showViewController()
    }
  }

  let mode: Mode

  private weak var node: MIDINode? {
    didSet {
      guard node != oldValue else { return }
      guard oldValue == nil || node == nil else { fatalError("node should be cleared before being set again") }
      let name = "generatorToolLighting"
      if let node = node {
        guard node.childNodeWithName(name) == nil else {
          fatalError("node already lit")
        }
        let light = SKLightNode()
        light.name = name
        light.categoryBitMask = 1
        node.addChild(light)
        node.lightingBitMask = 1
        node.runAction(SKAction.colorizeWithColor(.whiteColor(), colorBlendFactor: 1, duration: 0.25))
      }
      else if let oldNode = oldValue {
        oldNode.childNodeWithName(name)?.removeFromParent()
        oldNode.lightingBitMask = 0
        if let track = oldNode.track {
          oldNode.runAction(SKAction.colorizeWithColor(track.color.value, colorBlendFactor: 1, duration: 0.25))
        }
      }
    }
  }

  init(playerNode: MIDIPlayerNode, mode: Mode) { player = playerNode; self.mode = mode }

  private typealias NodeRef = Weak<MIDINode>

  /** showViewController */
  private func showViewController() {
    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    guard let viewController = storyboard.instantiateInitialViewController() as? GeneratorViewController else {
      return
    }
    switch mode {
      case .Existing:
        guard let node = node else { fatalError("cannot show view controller when no node has been chosen") }
        viewController.loadGenerator(node.noteGenerator)
        viewController.didChangeGenerator = { [weak self] in self?.node?.noteGenerator = $0 }
      case .New:
        viewController.didChangeGenerator = {
          MIDIPlayer.addTool?.noteGenerator = $0
          Sequencer.soundSetSelectionTarget.playNote($0)
        }
    }
    MIDIPlayer.presentViewController(viewController, forTool: self)
  }

  /** didShowViewController */
  func didShowViewController() {}

  /** didHideViewController */
  func didHideViewController() {
    guard active else { return }
    switch mode {
      case .New: if MIDIPlayer.currentTool.toolType === self { MIDIPlayer.currentTool = .None }
      case .Existing: node = nil
    }
  }

  /**
   nodeAtPoint:

   - parameter point: CGPoint

   - returns: [Weak<MIDINode>]
   */
  private func nodeAtPoint(point: CGPoint?) -> MIDINode? {
    guard let point = point where player.containsPoint(point) else { return nil }
    return player.nodesAtPoint(point).flatMap({$0 as? MIDINode}).first
  }


  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && mode == .Existing && node == nil else { return }
    node = nodeAtPoint(touches.first?.locationInNode(player))
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {}

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
    guard active && mode == .Existing && node != nil else { return }
    showViewController()
  }

}

extension GeneratorTool {
  enum Mode { case New, Existing }
}