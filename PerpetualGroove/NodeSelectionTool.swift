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

class NodeSelectionTool: Tool {

  unowned let player: MIDIPlayerNode

  @objc var active = false {
    didSet {
      guard active != oldValue && active == false else { return }

      node = nil
    }
  }

  weak var node: MIDINode? {
    didSet {
      guard node != oldValue else { return }

      if let node = node { addLighting(to: node) }
      if let oldNode = oldValue { removeLighting(from: oldNode) }
    }
  }

  fileprivate static let nodeLightingName = "nodeSelectionToolLighting"

  fileprivate func addLighting(to node: MIDINode) {
    guard node.childNode(withName: NodeSelectionTool.nodeLightingName) == nil else { return }

    node.addChild({
      let light = SKLightNode()
      light.name = NodeSelectionTool.nodeLightingName
      light.categoryBitMask = 1
      return light
      }())
    node.lightingBitMask = 1
    node.run(SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.25))

  }

  fileprivate func removeLighting(from node: MIDINode) {
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
    receptionist.observe(name: .didAddNode,
                         from: MIDIPlayer.self,
                         callback: weakMethod(self, NodeSelectionTool.didAddNode))
    receptionist.observe(name: .didRemoveNode,
                         from: MIDIPlayer.self,
                         callback: weakMethod(self, NodeSelectionTool.didRemoveNode))
  }

  func didSelectNode() {}

  func didAddNode(_ notification: Notification) {}

  func didRemoveNode(_ notification: Notification) {}

  fileprivate func grabNodeForTouch(_ touch: UITouch?) {
    guard
      let point = touch?.location(in: player),
      player.contains(point)
      else
    {
      return
    }

    node = player.nodes(at: point).first(where: {$0 is MIDINode}) as? MIDINode
  }

  func previousNode() {
    guard let idx = player.midiNodes.index(where: {$0 === node}) else { return }

    node = player.midiNodes[((idx &- 1) &+ player.midiNodes.count) % player.midiNodes.count]
  }

  func nextNode() {
    guard let idx = player.midiNodes.index(where: {$0 === node}) else { return }

    node = player.midiNodes[(idx &+ 1) % player.midiNodes.count]
  }

}

extension NodeSelectionTool: TouchReceiver {

  @objc func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  @objc func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard active && node == nil else { return }
    grabNodeForTouch(touches.first)
  }

  @objc func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
    node = nil
  }

  @objc func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard active && node != nil else { return }
    didSelectNode()
  }
  
}

class PresentingNodeSelectionTool: NodeSelectionTool, PresentingTool {

  private(set) weak var _secondaryContent: SecondaryControllerContent?

  var secondaryContent: SecondaryControllerContent { fatalError("\(#function) must be overridden by subclass") }

  var isShowingContent: Bool { return _secondaryContent != nil }

  func didShow(content: SecondaryControllerContent) { _secondaryContent = content }

  func didHide(content: SecondaryControllerContent,
               dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    if dismissalAction == .cancel && MIDIPlayer.undoManager.canUndo {
      if MIDIPlayer.undoManager.groupingLevel > 0 { MIDIPlayer.undoManager.endUndoGrouping() }
      MIDIPlayer.undoManager.undo()
    }
    node = nil
  }
  
  override func didAddNode(_ notification: Notification) {
    guard
      active && player.midiNodes.count == 2,
      let secondaryContent = _secondaryContent,
      !secondaryContent.disabledActions.intersection([.Previous, .Next]).isEmpty
      else
    {
      return
    }

    secondaryContent.disabledActions = .None
  }

  override func didRemoveNode(_ notification: Notification) {
    guard
      active && player.midiNodes.count < 2,
      let secondaryContent = _secondaryContent,
      secondaryContent.disabledActions.intersection([.Previous, .Next]).isEmpty
      else
    {
      return
    }
    secondaryContent.disabledActions ∪= [.Previous, .Next]
  }

}
