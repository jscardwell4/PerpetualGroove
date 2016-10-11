//
//  MIDINodeManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/4/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class MIDINodeManager {

  unowned let owner: MIDINodeDispatch

  init(owner: MIDINodeDispatch) { self.owner = owner }

  /// The nodes currently being managed
  fileprivate(set) var nodes: OrderedSet<HashableTuple<BarBeatTime,MIDINodeRef>> = []

  var nodeIdentifiers: Set<UUID> { return Set(nodes.flatMap({$0.elements.1.reference?.identifier})) }


  fileprivate var pendingNodes: Set<UUID> = []

  func addNode(identifier: UUID, trajectory: Trajectory, generator: AnyMIDIGenerator) {

    owner.logDebug(", ".join("placing node with identifier \(identifier)",
                             "trajectory \(trajectory)",
                             "generator \(generator)"))

    // Make sure a node hasn't already been place for this identifier
    guard nodeIdentifiers ∌ identifier && pendingNodes ∌ identifier else { return }

    pendingNodes.insert(identifier)

    // Place a node
    MIDIPlayer.placeNew(trajectory, target: owner, generator: generator, identifier: identifier)
  }

  func removeNode(identifier: UUID, delete: Bool = false) throws {
    logDebug("removing node with identifier \(identifier)")

    guard let idx = nodes.index(where: {$0.elements.1.reference?.identifier == identifier}),
              let node = nodes[idx].elements.1.reference else
    {
      fatalError("failed to find node with mapped identifier \(identifier)")
    }

    try remove(node: node, delete: delete)
    MIDIPlayer.removeNode(node)
  }

  func stopNodes(remove: Bool = false) {
    nodes.forEach {$0.elements.1.reference?.fadeOut(remove: remove)}
    owner.logDebug("nodes stopped\(remove ? " and removed" : "")")
  }

  func startNodes() {
    nodes.forEach {$0.elements.1.reference?.fadeIn()}
    owner.logDebug("nodes started")
  }

  func remove(node: MIDINode) throws { try remove(node: node, delete: false) }

  func delete(node: MIDINode) throws { try remove(node: node, delete: true) }


  func add(node: MIDINode) throws {
    try owner.connect(node: node)

//    guard owner.recording else { owner.logDebug("not recording…skipping event creation"); return }

    owner.eventQueue.async {
      [time = Sequencer.time.barBeatTime, unowned node, weak self] in

      let identifier = MIDIEvent.MIDINodeEvent.Identifier(nodeIdentifier: node.identifier)
      let data = MIDIEvent.MIDINodeEvent.Data.add(identifier: identifier,
                                        trajectory: node.path.initialTrajectory,
                                        generator: node.generator)
      let event = MIDIEvent.MIDINodeEvent(data: data, time: time)
      self?.owner.add(event: .node(event))
    }

    // Insert the node into our set
    nodes.append(HashableTuple((Sequencer.time.barBeatTime, Weak(node))))
    pendingNodes.remove(node.identifier)
    owner.logDebug("adding node \(node.name!) (\(node.identifier))")

//    Notification.DidAddNode.post(object: owner)

  }

  func remove(node: MIDINode, delete: Bool) throws {
    guard
      let idx = nodes.index(where: {$0.elements.1.reference === node}),
      let node = nodes.remove(at: idx).elements.1.reference
      else
    {
        throw MIDINodeDispatchError.NodeNotFound
    }
    
    let id = node.identifier
    owner.logDebug("removing node \(node.name!) \(id)")

    node.sendNoteOff()
    try owner.disconnect(node: node)
//    Notification.DidRemoveNode.post(object: owner)

    switch delete {
      case true:
        owner.eventContainer.removeEvents {
          if case .node(let event) = $0,
            event.identifier.nodeIdentifier == id
          {
            return true
          } else {
            return false
          }
        }
      case false:
//        guard owner.recording else { owner.logDebug("not recording…skipping event creation"); return }
        owner.eventQueue.async {
          [time = Sequencer.time.barBeatTime, weak self] in
          let event = MIDIEvent.MIDINodeEvent(data: .remove(identifier: MIDIEvent.MIDINodeEvent.Identifier(nodeIdentifier: id)),
                                    time: time)
          self?.owner.add(event: .node(event))
        }
    }
  }

}

//extension MIDINodeManager {
//  enum Notification: String, NotificationType, NotificationNameType {
//    enum Key: String, KeyType { case OldValue, NewValue }
//    case DidAddNode, DidRemoveNode
//  }
//
//}
