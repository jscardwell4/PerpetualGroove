//
//  RemoveTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/1/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class RemoveTool: Tool {

  unowned let player: MIDIPlayerNode

  @objc var active = false {
    didSet {
      guard active != oldValue else { return }

      switch active {
        case true:
          sequence = Sequencer.sequence
          refreshLighting()
        case false:
          sequence = nil
          player.midiNodes.forEach(removeLighting)
      }
    }
  }

  fileprivate var touch: UITouch? {
    didSet {
      if touch == nil {
        nodesToRemove.removeAll()
      }
    }
  }

  fileprivate var nodesToRemove: Set<MIDINodeRef> = [] {
    didSet {
      nodesToRemove.flatMap({$0.reference?.childNode(withName: RemoveTool.lightNodeName) as? SKLightNode}).forEach {
        $0.lightColor = .black
      }
    }
  }

  private static var categoryShift: UInt32 = 1 {
    didSet { categoryShift = (1 ... 31).clampValue(categoryShift) }
  }

  private static var foregroundLightNode: SKLightNode  {
    let node = SKLightNode()
    node.name = lightNodeName
    node.categoryBitMask = 1 << categoryShift
    categoryShift += 1
    node.lightColor = foregroundLightColor
    node.falloff = 1
    return node
  }

  private static let lightNodeName = "removeToolLighting"
  private static let foregroundLightColor = UIColor.white
  private static let backgroundLightColor = UIColor.clear

  private static var backgroundLightNode: SKLightNode {
    let node = SKLightNode()
    node.name = lightNodeName
    node.categoryBitMask = 1
    node.lightColor = backgroundLightColor
    return node
  }

  private weak var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }
      if let oldSequence = oldValue {
        receptionist.stopObserving(name: .didChangeTrack, from: oldSequence)
      }
      if let sequence = sequence {
        receptionist.observe(name: .didChangeTrack, from: sequence) {
          [weak self] _ in self?.track = self?.sequence?.currentTrack
        }
      }
      track = sequence?.currentTrack
    }
  }

  private func addBackgroundLight(to node: MIDINode) {
    let lightNode: SKLightNode
    switch node.childNode(withName: "removeToolLighting") as? SKLightNode {
      case let light? where light.categoryBitMask != 1:
        light.categoryBitMask = 1
        light.lightColor = RemoveTool.backgroundLightColor
        lightNode = light
      case nil:
        lightNode = RemoveTool.backgroundLightNode
        node.addChild(lightNode)
      default:
        return
    }

    node.lightingBitMask = lightNode.categoryBitMask
  }

  private func addForegroundLight(to node: MIDINode) {
    let lightNode: SKLightNode
    switch node.childNode(withName: "removeToolLighting") as? SKLightNode {
      case let light? where light.categoryBitMask == 1:
        light.categoryBitMask = 1 << RemoveTool.categoryShift
        RemoveTool.categoryShift += 1
        light.lightColor = RemoveTool.foregroundLightColor
        lightNode = light
      case nil:
        lightNode = RemoveTool.foregroundLightNode
        node.addChild(lightNode)
      default:
        return
    }

    node.lightingBitMask = lightNode.categoryBitMask
  }

  private func refreshLighting() {
    guard let track = track else { return }
    let trackNodes = track.nodes.flatMap({$0.elements.1.reference})
    let (foregroundNodes, backgroundNodes) = player.midiNodes.flatMap({$0}).bisect { trackNodes.contains($0) }
    foregroundNodes.forEach(addForegroundLight)
    backgroundNodes.forEach(addBackgroundLight)
  }

  private func removeLighting(from node: MIDINode?) {
    node?.childNode(withName: "removeToolLighting")?.removeFromParent()
    node?.lightingBitMask = 0
  }

  fileprivate weak var track: InstrumentTrack? {
    didSet {
      if touch != nil { touch = nil }
      guard active && oldValue !== track else { return }

      oldValue?.nodes.flatMap({$0.elements.1.reference}).forEach(addBackgroundLight)
      track?.nodes.flatMap({$0.elements.1.reference}).forEach(addForegroundLight)
    }
  }

  let deleteFromTrack: Bool

  init(playerNode: MIDIPlayerNode, delete: Bool = false) {
    deleteFromTrack = delete
    player = playerNode

    receptionist.observe(name: .didChangeSequence, from: Sequencer.self) {
      [weak self] _ in self?.sequence = Sequencer.sequence
    }

    receptionist.observe(name: .didAddNode,
                         from: MIDIPlayer.self,
                         callback: weakMethod(self, RemoveTool.didAddNode))
  }

  private func didAddNode(_ notification: Foundation.Notification) {
    guard active,
      let node = notification.addedNode,
      let track = notification.addedNodeTrack
      else
    {
      return
    }

    if self.track === track { addForegroundLight(to: node) }
    else { addBackgroundLight(to: node) }
  }

  fileprivate func removeMarkedNodes() {
    do {
      guard let manager = track?.nodeManager else { return }
      let remove = deleteFromTrack ? MIDINodeManager.delete : MIDINodeManager.remove
      for node in nodesToRemove.flatMap({$0.reference}) {
        try remove(manager)(node)
        node.fadeOut(remove: true)
      }
    } catch {
      logError(error)
    }
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  fileprivate func trackNodes(at point: CGPoint) -> [MIDINodeRef] {
    let midiNodes = player.nodes(at: point).flatMap({$0 as? MIDINode}).map({MIDINodeRef($0)})
    return midiNodes.filter({
      guard let identifier = $0.reference?.identifier else { return false }
      return track?.nodeManager.nodeIdentifiers.contains(identifier) == true
      }
    )
  }

}

extension RemoveTool: TouchReceiver {

  @objc func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard active && self.touch == nil else { return }
    touch = touches.first
    guard let point = touch?.location(in: player), player.contains(point) else { return }
    nodesToRemove ∪= trackNodes(at: point)
  }

  @objc func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) { touch = nil }

  @objc func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    removeMarkedNodes()
    touch = nil
  }

  @objc func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard
      let point = touch?.location(in: player),
      touches.contains(touch!) && player.contains(point)
      else
    {
      touch = nil
      return
    }
    nodesToRemove ∪= trackNodes(at: point)
  }

}
