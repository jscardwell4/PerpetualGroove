//
//  MIDINodeDispatch.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

typealias MIDINodeRef = Weak<MIDINode>

// MARK: - MIDINodeDispatch
protocol MIDINodeDispatch: class, MIDIEventDispatch, Loggable, Named {
  var nodes: OrderedSet<MIDINodeRef> { get set }
  var nodeIdentifiers: Set<MIDINode.Identifier> { get }
  var nextNodeName: String { get }
  var color: TrackColor { get }
  func addNode(node: MIDINode) throws
  func addNodeWithIdentifier(identifier: MIDINode.Identifier, trajectory: Trajectory, generator: MIDIGenerator)
  func removeNodeWithIdentifier(identifier: MIDINode.Identifier, delete: Bool) throws
  func removeNode(node: MIDINode, delete: Bool) throws
  func removeNode(node: MIDINode) throws
  func deleteNode(node: MIDINode) throws
  func connectNode(node: MIDINode) throws
  func disconnectNode(node: MIDINode) throws

  var recording: Bool { get }
  func startNodes()
  func stopNodes()
}

extension MIDINodeDispatch {
  var nodeIdentifiers: Set<MIDINode.Identifier> { return Set(nodes.flatMap({$0.reference?.identifier})) }
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
    logDebug("placing node with identifier \(identifier), trajectory \(trajectory), generator \(generator)")

    // Make sure a node hasn't already been place for this identifier
    guard nodeIdentifiers ∌ identifier else { return }

    // Place a node
    MIDIPlayer.placeNew(trajectory, target: self, generator: generator, identifier: identifier)
  }

  /**
   removeNodeWithIdentifier:delete:

   - parameter identifier: NodeIdentifier
   - parameter delete: Bool = false
  */
  func removeNodeWithIdentifier(identifier: MIDINode.Identifier, delete: Bool = false) throws {
    logDebug("removing node with identifier \(identifier)")
    guard let idx = nodes.indexOf({$0.reference?.identifier == identifier}), node = nodes[idx].reference else {
      fatalError("failed to find node with mapped identifier \(identifier)")
    }

    try removeNode(node, delete: delete)
    MIDIPlayer.removeNode(node)
  }

  /** stopNodes */
  func stopNodes() { nodes.forEach {$0.reference?.fadeOut()}; logDebug("nodes stopped") }

  /** startNodes */
  func startNodes() { nodes.forEach {$0.reference?.fadeIn()}; logDebug("nodes started") }

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
    try connectNode(node)

    guard recording else { logDebug("not recording…skipping event creation"); return }

    eventQueue.async {
      [time = Sequencer.time.barBeatTime, unowned node, weak self] in
      let identifier = MIDINodeEvent.Identifier(nodeIdentifier: node.identifier)
      let data = MIDINodeEvent.Data.Add(identifier: identifier,
                                        trajectory: node.path.initialTrajectory,
                                        generator: node.generator)
      let event = MIDINodeEvent(data, time)
      self?.addEvent(.Node(event))
    }

    // Insert the node into our set
    nodes.append(Weak(node))
    logDebug("adding node \(node.name!) (\(node.identifier))")

    MIDINodeDispatchNotification.DidAddNode.post(object: self)

  }

  /**
   removeNode:delete:

   - parameter node: MIDINode
   - parameter delete: Bool
  */
  func removeNode(node: MIDINode, delete: Bool) throws {
    guard let idx = nodes.indexOf({$0.reference === node}),
      node = nodes.removeAtIndex(idx).reference else { throw MIDINodeDispatchError.NodeNotFound }
    
    let id = node.identifier
    logDebug("removing node \(node.name!) \(id)")

    node.sendNoteOff()
    try disconnectNode(node)
    MIDINodeDispatchNotification.DidRemoveNode.post(object: self)

    switch delete {
      case true:
        events.removeEventsMatching {
          if case .Node(let event) = $0 where event.identifier.nodeIdentifier == id { return true }
          else { return false }
        }
      case false:
        guard recording else { logDebug("not recording…skipping event creation"); return }
        eventQueue.async {
          [time = Sequencer.time.barBeatTime, weak self] in
          let event = MIDINodeEvent(.Remove(identifier: MIDINodeEvent.Identifier(nodeIdentifier: id)), time)
          self?.addEvent(.Node(event))
        }
    }
  }

}

// MARK: - MIDINodeDispatchNotification
enum MIDINodeDispatchNotification: String, NotificationType, NotificationNameType {
  enum Key: String, KeyType { case OldValue, NewValue }
  case DidAddNode, DidRemoveNode
}

// MARK: - MIDINodeDispatchError
enum MIDINodeDispatchError: String, ErrorType, CustomStringConvertible {
  case NodeNotFound = "The specified node was not found among the track's nodes"
  case NodeAlreadyConnected = "The specified node has already been connected"
}
