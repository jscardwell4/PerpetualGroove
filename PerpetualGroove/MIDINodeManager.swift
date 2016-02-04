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

  /**
   initWithOwner:

   - parameter owner: MIDINodeDispatch
  */
  init(owner: MIDINodeDispatch) { self.owner = owner }

  /// The nodes currently being managed
  private(set) var nodes: OrderedSet<HashableTuple<BarBeatTime,MIDINodeRef>> = []

  var nodeIdentifiers: Set<MIDINode.Identifier> { return Set(nodes.flatMap({$0.element2.reference?.identifier})) }


  private var pendingNodes: Set<MIDINode.Identifier> = []

  /**
   addNodeWithIdentifier:trajectory:generator:

   - parameter identifier: MIDINode.Identifier
   - parameter trajectory: Trajectory
   - parameter generator: MIDIGenerator
  */
  func addNodeWithIdentifier(identifier: MIDINode.Identifier,
                  trajectory: Trajectory,
                   generator: MIDIGenerator)
  {
    owner.logDebug(", ".join("placing node with identifier \(identifier)",
                             "trajectory \(trajectory)",
                             "generator \(generator)"))

    // Make sure a node hasn't already been place for this identifier
    guard nodeIdentifiers ∌ identifier && pendingNodes ∌ identifier else { return }

    pendingNodes.insert(identifier)

    // Place a node
    MIDIPlayer.placeNew(trajectory, target: owner, generator: generator, identifier: identifier)
  }

  /**
   removeNodeWithIdentifier:delete:

   - parameter identifier: NodeIdentifier
   - parameter delete: Bool = false
  */
  func removeNodeWithIdentifier(identifier: MIDINode.Identifier, delete: Bool = false) throws {
    logDebug("removing node with identifier \(identifier)")
    guard let idx = nodes.indexOf({$0.element2.reference?.identifier == identifier}),
              node = nodes[idx].element2.reference else
    {
      fatalError("failed to find node with mapped identifier \(identifier)")
    }

    try removeNode(node, delete: delete)
    MIDIPlayer.removeNode(node)
  }

  /** stopNodes */
  func stopNodes(remove remove: Bool = false) {
    nodes.forEach {$0.element2.reference?.fadeOut(remove: remove)}
    owner.logDebug("nodes stopped\(remove ? " and removed" : "")")
  }

  /** startNodes */
  func startNodes() { nodes.forEach {$0.element2.reference?.fadeIn()}; owner.logDebug("nodes started") }

  /**
   removeNode:

   - parameter node: MIDINode
  */
  func removeNode(node: MIDINode) throws { try removeNode(node, delete: false) }

  /**
   deleteNode:

   - parameter node: MIDINode
  */
  func deleteNode(node: MIDINode) throws { try removeNode(node, delete: true) }


  /**
   addNode:

   - parameter node: MIDINode
  */
  func addNode(node: MIDINode) throws {
    try owner.connectNode(node)

//    guard owner.recording else { owner.logDebug("not recording…skipping event creation"); return }

    owner.eventQueue.async {
      [time = Sequencer.time.barBeatTime, unowned node, weak self] in
      let identifier = MIDINodeEvent.Identifier(nodeIdentifier: node.identifier)
      let data = MIDINodeEvent.Data.Add(identifier: identifier,
                                        trajectory: node.path.initialTrajectory,
                                        generator: node.generator)
      let event = MIDINodeEvent(data, time)
      self?.owner.addEvent(.Node(event))
    }

    // Insert the node into our set
    nodes.append(HashableTuple(Sequencer.time.barBeatTime, Weak(node)))
    pendingNodes.remove(node.identifier)
    owner.logDebug("adding node \(node.name!) (\(node.identifier))")

//    Notification.DidAddNode.post(object: owner)

  }

  /**
   removeNode:delete:

   - parameter node: MIDINode
   - parameter delete: Bool
  */
  func removeNode(node: MIDINode, delete: Bool) throws {
    guard let idx = nodes.indexOf({$0.element2.reference === node}),
              node = nodes.removeAtIndex(idx).element2.reference else
    {
        throw MIDINodeDispatchError.NodeNotFound
    }
    
    let id = node.identifier
    owner.logDebug("removing node \(node.name!) \(id)")

    node.sendNoteOff()
    try owner.disconnectNode(node)
//    Notification.DidRemoveNode.post(object: owner)

    switch delete {
      case true:
        owner.events.removeEventsMatching {
          if case .Node(let event) = $0 where event.identifier.nodeIdentifier == id { return true }
          else { return false }
        }
      case false:
//        guard owner.recording else { owner.logDebug("not recording…skipping event creation"); return }
        owner.eventQueue.async {
          [time = Sequencer.time.barBeatTime, weak self] in
          let event = MIDINodeEvent(.Remove(identifier: MIDINodeEvent.Identifier(nodeIdentifier: id)), time)
          self?.owner.addEvent(.Node(event))
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
