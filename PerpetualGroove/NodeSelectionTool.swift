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

  private(set) weak var _secondaryContent: SecondaryContent?

  @objc var isShowingContent: Bool { return _secondaryContent != nil }

  @objc func didShowContent(content: SecondaryContent) { _secondaryContent = content }

  @objc func didHideContent(dismissalAction: SecondaryControllerContainer.DismissalAction) {
    assert(active && _secondaryContent != nil, "expected active and valid _secondaryContent")
    if dismissalAction == .Cancel && MIDIPlayer.undoManager.canUndo {
      if MIDIPlayer.undoManager.groupingLevel > 0 { MIDIPlayer.undoManager.endUndoGrouping() }
      MIDIPlayer.undoManager.undo()
    }
    node = nil
  }

  @objc var active = false {
    didSet { guard active != oldValue && active == false else { return }; node = nil }
  }

  weak var node: MIDINode? {
    didSet {
      guard node != oldValue else { return }
      if let node = node { addLightingToNode(node) }
      if let oldNode = oldValue { removeLightingFromNode(oldNode) }
    }
  }

  private static let nodeLightingName = "nodeSelectionToolLighting"

  private func addLightingToNode(node: MIDINode) {
    guard node.childNodeWithName(NodeSelectionTool.nodeLightingName) == nil else { return }
    let light = SKLightNode()
    light.name = NodeSelectionTool.nodeLightingName
    light.categoryBitMask = 1
    node.addChild(light)
    node.lightingBitMask = 1
    node.runAction(SKAction.colorizeWithColor(.whiteColor(), colorBlendFactor: 1, duration: 0.25))

  }

  private func removeLightingFromNode(node: MIDINode) {
    guard let light = node.childNodeWithName(NodeSelectionTool.nodeLightingName) else { return }
    light.removeFromParent()
    node.lightingBitMask = 0
    guard let color = node.dispatch?.color.value else { return }
    node.runAction(SKAction.colorizeWithColor(color, colorBlendFactor: 1, duration: 0.25))
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  init(playerNode: MIDIPlayerNode) {
    player = playerNode
    receptionist.observe(.DidAddNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, NodeSelectionTool.didAddNode))
    receptionist.observe(.DidRemoveNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, NodeSelectionTool.didRemoveNode))
  }

  func didSelectNode() {}

  func didAddNode(notification: NSNotification) {
    guard active && player.midiNodes.count == 2,
      let secondaryContent = _secondaryContent
      where secondaryContent.disabledActions ⚭ [.Previous, .Next] else { return }
    secondaryContent.disabledActions = .None
  }

  func didRemoveNode(notification: NSNotification) {
    guard active && player.midiNodes.count < 2,
      let secondaryContent = _secondaryContent
      where secondaryContent.disabledActions !⚭ [.Previous, .Next] else { return }
    secondaryContent.disabledActions ∪= [.Previous, .Next]
  }

  private func grabNodeForTouch(touch: UITouch?) {
    guard let point = touch?.locationInNode(player) where player.containsPoint(point) else { return }
    node = player.nodesAtPoint(point).flatMap({$0 as? MIDINode}).first
  }

  @objc func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  @objc func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  @objc func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) { node = nil }

  @objc func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node != nil else { return }
    didSelectNode()
  }

  func previousNode() {
    let nodes = player.midiNodes
    guard let node = node, let idx = nodes.indexOf(node) else { return }
    self.node = idx + 1 < nodes.endIndex ? nodes[idx + 1] : nodes[nodes.startIndex]
  }

  func nextNode() {
    let nodes = player.midiNodes
    guard let node = node, let idx = nodes.indexOf(node) else { return }
    self.node = idx - 1 >= nodes.startIndex ? nodes[idx - 1] : nodes[nodes.endIndex - 1]
  }
  

}
