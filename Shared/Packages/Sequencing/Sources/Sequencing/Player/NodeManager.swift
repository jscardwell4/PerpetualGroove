//
//  NodeManager.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/4/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import CoreMIDI
import Foundation
import MIDI
import MoonDev
import SoundFont
import SwiftUI

// MARK: - NodeManaging

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
protocol NodeManaging
{
  var nodeManager: NodeManager { get }
}

// MARK: - NodeManager

/// Class for managing a collection of `Node` instances.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class NodeManager: NodeDispatch
{

  @Environment(\.player) var player: Player
  @EnvironmentObject var transport: Transport

  /// The track's MIDI client.
  private var client = MIDIClientRef()

  /// The track's MIDI input port.
  private var inputPort = MIDIPortRef()

  /// The track's MIDI output port.
  private var outPort = MIDIPortRef()

  /// The instrument's MIDI end point.
  private let endPoint: MIDIEndpointRef

  /// The MIDI endpoints connected to the track's `inputPort`.
  private var connectedEndPoints: Set<MIDIEndpointRef> = []

  var nextNodeName: String { "\(owner.name) \(nodeManager.nodes.count + 1)" }

  var color: CuratedColor { owner.color }

  var nodeManager: NodeManager { self }

  func connect(node: MIDINode) throws
  {
    // Check that the node's `endPoint` has not already been connected by the track.
    guard connectedEndPoints ∌ node.coordinator.endPoint
    else
    {
      throw NodeDispatchError.nodeAlreadyConnected
    }

    // Connect the node's `endPoint` to the track's `inputPort`.
    try require(MIDIPortConnectSource(inputPort, node.coordinator.endPoint, nil),
                "Failed to connect to node \(node.name!)")

    // Insert the node's `endPoint` into the collection of endpoints connected to the track.
    connectedEndPoints.insert(node.coordinator.endPoint)
  }

  func disconnect(node: MIDINode) throws
  {
    // Check that the node's endpoint was previously connected by the track.
    guard connectedEndPoints ∋ node.coordinator.endPoint
    else
    {
      throw NodeDispatchError.nodeNotFound
    }

    // Disconnect the node's endpoint from the track's input.
    try require(MIDIPortDisconnectSource(inputPort, node.coordinator.endPoint),
                "Failed to disconnect to node \(node.name!)")

    // Remove the node's endpoint from the set of connected endpoints.
    connectedEndPoints.remove(node.coordinator.endPoint)
  }

  var isRecording: Bool { player.currentDispatch === self }

  /// The node dispatching object owning the nodes being managed.
  let owner: EventManaging & Named & ColorCurated

  /// Default initializer.
  init(owner: EventManaging & Named & ColorCurated,
       instrument: Instrument) throws
  {
    self.owner = owner
    endPoint = instrument.endPoint

    // Create the MIDI client for the track.
    try require(MIDIClientCreateWithBlock("track \(instrument.bus)" as CFString,
                                          &client, nil),
                "Failed to create MIDI client.")

    // Create the track's MIDI output port.
    try require(MIDIOutputPortCreate(client, "Output" as CFString, &outPort),
                "Failed to create MIDI output port.")

    // Create the track's MIDI input port.
    try require(MIDIInputPortCreateWithBlock(client, owner.name as CFString,
                                             &inputPort, read),
                "Failed to create MIDI input port.")
  }

  /// The set of nodes currently being managed.
  private(set) var nodes: OrderedSet<NodeRef> = []

  /// Set of node identifiers awaiting callback with a `Node` instance.
  private var pendingNodes: Set<UUID> = []

  /// Fades out all the elements in `nodes`, optionally removing them from the player.
  func stopNodes(remove: Bool = false)
  {
    for nodeRef in nodes { nodeRef.reference?.coordinator.fadeOut(remove: remove) }
  }

  /// Fades in all the elements in `nodes`.
  func startNodes()
  {
    for nodeRef in nodes { nodeRef.reference?.coordinator.fadeIn() }
  }

  /// appends a reference for `node` to `nodes` and generates a `NodeEvent` for the
  /// addition.
  /// - Throws: Any error encountered connecting `node`.
  func add(node: MIDINode) throws
  {
    // Connect the node.
    // Check that the node's `endPoint` has not already been connected by the track.
    guard connectedEndPoints ∌ node.coordinator.endPoint
    else
    {
      throw NodeDispatchError.nodeAlreadyConnected
    }

    // Connect the node's `endPoint` to the track's `inputPort`.
    try require(MIDIPortConnectSource(inputPort, node.coordinator.endPoint, nil),
                "Failed to connect to node \(node.name!)")

    // Insert the node's `endPoint` into the collection of endpoints connected to the track.
    connectedEndPoints.insert(node.coordinator.endPoint)

    // Generate and append the node event on the owner's event queue.
    owner.eventManager.eventQueue.async
    {
      [time = transport.time.barBeatTime, unowned node, weak self] in

      let identifier = NodeEvent.Identifier(nodeIdentifier: node.coordinator.identifier)
      let data = NodeEvent.Data.add(
        identifier: identifier,
        trajectory: node.coordinator.flightPath.initialTrajectory,
        generator: node.coordinator.generator
      )

      self?.owner.eventManager.add(event: .node(NodeEvent(data: data, time: time)))
    }

    // Insert the node into our set
    nodes.append(NodeRef(node))

    // Remove the identifier from `pendingNodes`.
    pendingNodes.remove(node.coordinator.identifier)

    logi("adding node \(node.name!) (\(node.coordinator.identifier))")
  }

  /// Places or removes a `Node` according to `event`.
  func handle(event: NodeEvent)
  {
    switch event.data
    {
      case let .add(eventIdentifier, trajectory, generator):
        // Add a node with using the specified data.

        let identifier = eventIdentifier.nodeIdentifier

        logi("""
        placing node with identifier \(identifier), \
        trajectory \(trajectory), \
        generator \(String(describing: generator))
        """)

        // Make sure a node hasn't already been place for this identifier
        guard nodes
          .first(where: { $0.reference?.coordinator.identifier == identifier }) == nil,
          pendingNodes ∌ identifier
        else
        {
          fatalError("The identifier is pending or already placed.")
        }

        pendingNodes.insert(identifier)

        // Place a node
        player.placeNew(trajectory: trajectory,
                        target: self,
                        generator: generator,
                        identifier: identifier)

      case let .remove(eventIdentifier):
        // Remove the node matching `eventIdentifier`.

        let identifier = eventIdentifier.nodeIdentifier

        logi("removing node with identifier \(identifier)")

        guard let idx = nodes
          .firstIndex(where: { $0.reference?.coordinator.identifier == identifier }),
          let node = nodes[idx].reference
        else
        {
          fatalError("failed to find node with mapped identifier \(identifier)")
        }

        do
        {
          try remove(node: node)
        }
        catch
        {
          loge("\(error as NSObject)")
        }

        player.remove(node: node)
    }
  }

  /// Remove `node` from the player generating a node removal event and leaving any events
  /// generated by `node`.
  func remove(node: MIDINode) throws { try remove(node: node, delete: false) }

  /// Remove `node` from the player deleting any events generated by `node`.
  func delete(node: MIDINode) throws { try remove(node: node, delete: true) }

  /// Performs the actual removal of `node` according to the value of `delete`.
  private func remove(node: MIDINode, delete: Bool) throws
  {
    // Check that `node` is actually an element of `nodes`.
    guard let idx = nodes.firstIndex(where: { $0.reference === node }),
          let node = nodes.remove(at: idx).reference
    else
    {
      throw NodeDispatchError.nodeNotFound
    }

    logi("removing node \(node.name!) \(node.coordinator.identifier)")

    // Disconnect the node.
    // Check that the node's endpoint was previously connected by the track.
    guard connectedEndPoints ∋ node.coordinator.endPoint
    else
    {
      throw NodeDispatchError.nodeNotFound
    }

    // Disconnect the node's endpoint from the track's input.
    try require(MIDIPortDisconnectSource(inputPort, node.coordinator.endPoint),
                "Failed to disconnect to node \(node.name!)")

    // Remove the node's endpoint from the set of connected endpoints.
    connectedEndPoints.remove(node.coordinator.endPoint)

    // Handle event creation/deletion according to the value of `delete`.
    switch delete
    {
      case true:
        // Remove any events generated by the node from the owner's event container.

        owner.eventManager.eventQueue.async
        {
          [identifier = node.coordinator.identifier, weak self] in

          self?.owner.eventManager.container.removeEvents
          {
            if case let .node(event) = $0, event.identifier.nodeIdentifier == identifier
            {
              return true
            }
            else
            {
              return false
            }
          }
        }

      case false:
        // Generate an event for removing the node.

        owner.eventManager.eventQueue.async
        {
          [time = transport.time.barBeatTime,
           identifier = node.coordinator.identifier, weak self] in

          let eventIdentifier = NodeEvent.Identifier(nodeIdentifier: identifier)
          self?.owner.eventManager.add(event:
            .node(NodeEvent(data: .remove(identifier: eventIdentifier),
                            time: time)))
        }
    }
  }

  /// Callback for receiving MIDI packets over the track's `inputPort`.
  ///
  /// - Parameters:
  ///   - packetList: The list of packets to receive
  ///   - context: This parameter is ignored.
  func read(packetList: UnsafePointer<MIDIPacketList>,
            context: UnsafeMutableRawPointer?)
  {
    do
    {
      // Forward the packets to the instrument
      try require(MIDISend(outPort, endPoint, packetList),
                  "Failed to forward packet list to instrument")
    }
    catch
    {
      // Just log the error.
      loge("\(error)")
    }

    // Check whether events need to be processed for MIDI file creation purposes.
    guard nodeManager.isRecording else { return }

    // Process the packet asynchronously on the queue designated for MIDI event operations.
    // Note that the capture list includes the current bar beat time so it is accurate for
    // the time when the closure is created and not the time when the closure is executed.
    owner.eventManager.eventQueue.async
    {
      [weak self, time = transport.time.barBeatTime] in

      // Grab the packet from the list.
      guard let packet = Packet(packetList: packetList) else { return }

      // Create a variable to hold the MIDI event generated from the packet.
      let event: Event?

      // Consider the packet's `status` value.
      switch ChannelEvent.Status.Kind(rawValue: packet.status)
      {
        case .noteOn?:
          // The packet contains a 'note on' event.

          // Initialize `event` with the corresponding channel event.
          event = .channel(try! ChannelEvent(kind: .noteOn,
                                             channel: packet.channel,
                                             data1: packet.note,
                                             data2: packet.velocity,
                                             time: time))
        case .noteOff?:
          // The packet contains a 'note off' event.

          // Initialize `event` with the corresponding channel event.
          event = .channel(try! ChannelEvent(kind: .noteOff,
                                             channel: packet.channel,
                                             data1: packet.note,
                                             data2: packet.velocity,
                                             time: time))
        default:
          // The packet contains an unhandled event.

          // Initialize to `nil`.
          event = nil
      }

      // Check that there is an event to add.
      guard event != nil else { return }

      // Add the event.
      self?.owner.eventManager.add(event: event!)
    }
  }
}
