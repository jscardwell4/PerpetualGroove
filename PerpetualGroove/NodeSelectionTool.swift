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

  fileprivate(set) weak var _secondaryContent: SecondaryContent?

  @objc var isShowingContent: Bool { return _secondaryContent != nil }

  @objc func didShowContent(_ content: SecondaryContent) { _secondaryContent = content }

  @objc func didHideContent(_ dismissalAction: SecondaryControllerContainer.DismissalAction) {
    assert(active && _secondaryContent != nil, "expected active and valid _secondaryContent")
    if dismissalAction == .cancel && MIDIPlayer.undoManager.canUndo {
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

  fileprivate static let nodeLightingName = "nodeSelectionToolLighting"

  fileprivate func addLightingToNode(_ node: MIDINode) {
    guard node.childNode(withName: NodeSelectionTool.nodeLightingName) == nil else { return }
    let light = SKLightNode()
    light.name = NodeSelectionTool.nodeLightingName
    light.categoryBitMask = 1
    node.addChild(light)
    node.lightingBitMask = 1
    node.run(SKAction.colorize(with: .white(), colorBlendFactor: 1, duration: 0.25))

  }

  fileprivate func removeLightingFromNode(_ node: MIDINode) {
    guard let light = node.childNode(withName: NodeSelectionTool.nodeLightingName) else { return }
    light.removeFromParent()
    node.lightingBitMask = 0
    guard let color = node.dispatch?.color.value else { return }
    node.run(SKAction.colorize(with: color, colorBlendFactor: 1, duration: 0.25))
  }

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  init(playerNode: MIDIPlayerNode) {
    player = playerNode
    receptionist.observe(notification: .DidAddNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, NodeSelectionTool.didAddNode))
    receptionist.observe(notification: .DidRemoveNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, NodeSelectionTool.didRemoveNode))
  }

  func didSelectNode() {}

  func didAddNode(_ notification: Notification) {
    guard active && player.midiNodes.count == 2,
      let secondaryContent = _secondaryContent
      , !secondaryContent.disabledActions.intersection([.Previous, .Next]).isEmpty else { return }
    secondaryContent.disabledActions = .None
  }

  func didRemoveNode(_ notification: Notification) {
    guard active && player.midiNodes.count < 2,
      let secondaryContent = _secondaryContent
      , secondaryContent.disabledActions.intersection([.Previous, .Next]).isEmpty else { return }
    secondaryContent.disabledActions ∪= [.Previous, .Next]
  }

  fileprivate func grabNodeForTouch(_ touch: UITouch?) {
    guard let point = touch?.location(in: player) , player.contains(point) else { return }
    node = player.nodes(at: point).flatMap({$0 as? MIDINode}).first
  }

  @objc func touchesBegan(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  @objc func touchesMoved(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  @objc func touchesCancelled(_ touches: Set<UITouch>?, withEvent event: UIEvent?) { node = nil }

  @objc func touchesEnded(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
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
