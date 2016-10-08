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

final class RemoveTool: ToolType {

  unowned let player: MIDIPlayerNode

  @objc var active = false {
    didSet {
      logDebug("oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue else { return }
      switch active {
        case true:
          sequence = Sequencer.sequence
          refreshAllNodeLighting()
        case false:
          sequence = nil
          player.midiNodes.forEach { if $0 != nil { removeLightingFromNode($0!) } }
      }
    }
  }

  fileprivate var touch: UITouch? { didSet { if touch == nil { nodesToRemove.removeAll() } } }
  fileprivate var nodesToRemove: Set<MIDINodeRef> = [] {
    didSet {
      logDebug("old count = \(oldValue.count)  new count = \(nodesToRemove.count)")
      nodesToRemove.flatMap({$0.reference}).forEach {
        guard let light = $0.childNode(withName: "removeToolLighting") as? SKLightNode
                , light.categoryBitMask != 1 else { return }
        light.lightColor = UIColor.black
      }
    }
  }

  fileprivate static var categoryShift: UInt32 = 1 {
    didSet { categoryShift = (1 ... 31).clampValue(categoryShift) }
  }

  fileprivate static var foregroundLightNode: SKLightNode  {
    let node = SKLightNode()
    node.name = lightNodeName
    node.categoryBitMask = 1 << categoryShift
    categoryShift += 1
    node.lightColor = foregroundLightColor
    node.falloff = 1
    return node
  }

  fileprivate static let lightNodeName = "removeToolLighting"
  fileprivate static let foregroundLightColor = UIColor.white
  fileprivate static let backgroundLightColor = UIColor.clear

  fileprivate static var backgroundLightNode: SKLightNode {
    let node = SKLightNode()
    node.name = lightNodeName
    node.categoryBitMask = 1
    node.lightColor = backgroundLightColor
    return node
  }

  fileprivate weak var sequence: Sequence? {
    didSet {
      logDebug("oldValue: \(oldValue?.document?.localizedName ?? "nil")  sequence: \(sequence?.document?.localizedName ?? "nil")")
      guard oldValue !== sequence else { return }
      if let oldSequence = oldValue {
        receptionist.stopObserving(name: Sequence.NotificationName.didChangeTrack.rawValue, from: oldSequence)
      }
      if let sequence = sequence {
        receptionist.observe(name: Sequence.NotificationName.didChangeTrack.rawValue, from: sequence) {
          [weak self] _ in self?.track = self?.sequence?.currentTrack
        }
      }
      track = sequence?.currentTrack
    }
  }

  fileprivate func lightNodeForBackground(_ node: MIDINode) {
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

  fileprivate func lightNodeForForeground(_ node: MIDINode) {
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

  fileprivate func refreshAllNodeLighting() {
    guard let track = track else { return }
    let trackNodes = track.nodes.flatMap({$0.elements.1.reference})
    let (foregroundNodes, backgroundNodes) = player.midiNodes.flatMap({$0}).bisect { trackNodes.contains($0) }
    foregroundNodes.forEach { lightNodeForForeground($0) }
    backgroundNodes.forEach { lightNodeForBackground($0) }
  }

  fileprivate func removeLightingFromNode(_ node: MIDINode) {
    node.childNode(withName: "removeToolLighting")?.removeFromParent()
    node.lightingBitMask = 0
  }

  fileprivate weak var track: InstrumentTrack? {
    didSet {
      logDebug("oldValue: \(oldValue?.name ?? "nil")  track: \(track?.name ?? "nil")")
      if touch != nil { touch = nil }
      guard active && oldValue !== track else { return }
      oldValue?.nodes.flatMap({$0.elements.1.reference}).forEach { lightNodeForBackground($0) }
      track?.nodes.flatMap({$0.elements.1.reference}).forEach { lightNodeForForeground($0) }
    }
  }

  let deleteFromTrack: Bool

  init(playerNode: MIDIPlayerNode, delete: Bool = false) {
    deleteFromTrack = delete
    player = playerNode
    receptionist.observe(name: Sequencer.NotificationName.didChangeSequence.rawValue,
      from: Sequencer.self,
      callback: {[weak self] _ in self?.sequence = Sequencer.sequence})
    receptionist.observe(name: MIDIPlayer.NotificationName.didAddNode.rawValue,
      from: MIDIPlayer.self,
      callback: {[weak self] notification in
        guard self?.active == true, let node = notification.addedNode, let track = notification.addedNodeTrack else { return }
        if self?.track === track { self?.lightNodeForForeground(node) }
        else { self?.lightNodeForBackground(node) }
      })
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

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  fileprivate func trackNodesAtPoint(_ point: CGPoint) -> [MIDINodeRef] {
    let midiNodes = player.nodes(at: point).flatMap({$0 as? MIDINode}).map({MIDINodeRef($0)})
    return midiNodes.filter({
      guard let identifier = $0.reference?.identifier else { return false }
      return track?.nodeManager.nodeIdentifiers.contains(identifier) == true
      }
    )
  }

  @objc func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard active && self.touch == nil else { return }
    touch = touches.first
    guard let point = touch?.location(in: player) , player.contains(point) else { return }
    nodesToRemove ∪= trackNodesAtPoint(point)
  }

  @objc func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) { touch = nil }

  @objc func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    removeMarkedNodes()
    touch = nil
  }

  @objc func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    guard let point = touch?.location(in: player) , player.contains(point) else {
      touch = nil
      return
    }
    nodesToRemove ∪= trackNodesAtPoint(point)
  }

}
