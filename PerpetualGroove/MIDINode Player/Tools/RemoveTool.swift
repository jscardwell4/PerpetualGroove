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

/// A tool for generating a node removal event.
final class RemoveTool: Tool {

  /// The player node to which midi nodes are to be added.
  unowned let player: MIDINodePlayerNode

  /// Whether the tool is currently receiving touch events.
  @objc var active = false {

    didSet {

      // Check that the value actually changed.
      guard active != oldValue else { return }

      switch active {
        case true:  refreshLighting()
        case false: removeAllLights()
      }

    }

  }

  /// The currently tracked touch. Setting this properties removes any elements in `nodesToRemove`.
  private var touch: UITouch? { didSet { nodesToRemove.removeAll() } }

  /// Collection of nodes contacted by `touch`.
  private var nodesToRemove: Set<MIDINodeRef> = []

  /// The next open category to assign for foreground lighting.
  private static var categoryShift: UInt32 = 1 {
    didSet { categoryShift = (1 ... 31).clampValue(categoryShift) }
  }

  /// The name assigned to light nodes added by the tool.
  private static let lightNodeName = "removeToolLighting"

  /// Removes all light nodes attached to a midi node resetting the midi node's `lightingBitMask` to `0`.
  private func removeAllLights() {
    for node in player.midiNodes {
      node?.childNode(withName: "removeToolLighting")?.removeFromParent()
      node?.lightingBitMask = 0
    }
  }

  /// Adds a light to `node` configured to make `node` less prominent.
  private func addBackgroundLight(to node: MIDINode) {

    let lightNode: SKLightNode

    // Switch on the light attached to `node`.
    switch node.childNode(withName: "removeToolLighting") as? SKLightNode {

      case let light? where light.categoryBitMask != 1:
        // The node already has a light but it is configured for foreground. Configure it for background.

        light.categoryBitMask = 1
        light.lightColor = .clear
        lightNode = light

      case nil:
        // The node has no light. Create and attach one configured for background.

        lightNode = {
          let node = SKLightNode()
          node.name = RemoveTool.lightNodeName
          node.categoryBitMask = 1
          node.lightColor = .clear
          return node
        }()
        node.addChild(lightNode)

      default:
        // The node already has a light configured for background. Nothing to do.

        return

    }

    // Configure the node to use the background light.
    node.lightingBitMask = lightNode.categoryBitMask

  }

  /// Adds a light to `node` configured to make `node` more prominent.
  private func addForegroundLight(to node: MIDINode) {

    let lightNode: SKLightNode

    // Switch on the light attached to `node`.
    switch node.childNode(withName: "removeToolLighting") as? SKLightNode {

      case let light? where light.categoryBitMask == 1:
        // The node has a light but it is configured for background. Configure for foreground.

        light.categoryBitMask = 1 << RemoveTool.categoryShift
        RemoveTool.categoryShift += 1
        light.lightColor = .white
        lightNode = light

      case nil:
        // The node has no light, configure a new instance and add it as a child of `node`.

        lightNode = {
          let node = SKLightNode()
          node.name = RemoveTool.lightNodeName
          node.categoryBitMask = 1 << RemoveTool.categoryShift
          RemoveTool.categoryShift += 1
          node.lightColor = .white
          node.falloff = 1
          return node
        }()
        node.addChild(lightNode)

      default:
        // The node already has a light configured for foreground. Nothing to do.

        return

    }

    // Configure `node` to use `lightNode`.
    node.lightingBitMask = lightNode.categoryBitMask

  }

  /// Inserts references for `nodes` into `nodesToRemove` and colors the light of each node black.
  private func markNodesForRemoval(_ nodes: [MIDINode]) {
    for node in nodes {
      (node.childNode(withName: RemoveTool.lightNodeName) as? SKLightNode)?.lightColor = .black
      nodesToRemove.insert(MIDINodeRef(node))
    }
  }

  /// Handler for notifications that the player's current dispatch will change.
  private func willChangeDispatch(_ notification: Foundation.Notification) {
    guard active else { return }
    MIDINodePlayer.currentDispatch?.nodes.forEach(addBackgroundLight)
  }

  /// Handler for notifications that the player's current dispatch did change.
  private func didChangeDispatch(_ notification: Foundation.Notification) {
    touch = nil
    guard active else { return }
    MIDINodePlayer.currentDispatch?.nodes.forEach(addForegroundLight)
  }

  /// Adds foreground or background light to each node for the current dispatch.
  private func refreshLighting() {

    guard let dispatch = MIDINodePlayer.currentDispatch else { return }

    let dispatchNodes = dispatch.nodeManager.nodes.flatMap({$0.reference})

    let (foregroundNodes, backgroundNodes) = player.midiNodes.flatMap({$0}).bisect {
      dispatchNodes.contains($0)
    }

    foregroundNodes.forEach(addForegroundLight)
    backgroundNodes.forEach(addBackgroundLight)
    
  }

  /// Flag specifying whether removal generates an event (`deleteFromTrack == false`) or deletes
  /// any trace of removed nodes (`deleteFromTrack == true`).
  let deleteFromTrack: Bool

  /// Initialize with the player node and whether removal generates events or deletes.
  init(playerNode: MIDINodePlayerNode, delete: Bool = false) {

    // Set the property values.
    deleteFromTrack = delete
    player = playerNode

    // Register for notifications from `MIDINodePlayer`.
    receptionist.observe(name: .willChangeDispatch, from: MIDINodePlayer.self,
                         callback: weakMethod(self, RemoveTool.willChangeDispatch))
    receptionist.observe(name: .didChangeDispatch, from: MIDINodePlayer.self,
                         callback: weakMethod(self, RemoveTool.didChangeDispatch))
    receptionist.observe(name: .didAddNode, from: MIDINodePlayer.self,
                         callback: weakMethod(self, RemoveTool.didAddNode))

  }

  /// Handler for player notifications that a node has been added.
  private func didAddNode(_ notification: Foundation.Notification) {

    // Check that the tool is active and notification contains the node and dispatch.
    guard active, let node = notification.addedNode, let dispatch = notification.addedNodeDispatch else {
      return
    }

    // Add a foreground or background light depending on the node's dispatch.
    if MIDINodePlayer.currentDispatch === dispatch {
      addForegroundLight(to: node)
    } else {
      addBackgroundLight(to: node)
    }

  }

  /// Removes each node referenced in `nodesToRemove` from `player`, generating a node removal event
  /// if `deleteFromTrack == false` and deleting any event including or generated by the node when
  /// `deleteFromTrack == true`.
  private func removeMarkedNodes() {

    do {

      // Check that the current dispatch's node manager can be accessed.
      guard let manager = MIDINodePlayer.currentDispatch?.nodeManager else { return }

      // The removal action is determined by the value of `deleteFromTrack`.
      let remove = deleteFromTrack ? MIDINodeManager.delete : MIDINodeManager.remove

      // Iterate the nodes to remove performing the determined action, fading out and removing the node.
      for node in nodesToRemove.flatMap({$0.reference}) {

        try remove(manager)(node)
        node.fadeOut(remove: true)

      }

    } catch {

      Log.error(error)

    }

  }

  /// Handles registration and reception of notifications posted by `MIDINodePlayer`.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Returns all the nodes of the current dispatch whose body contains `point`.
  private func dispatchNodes(at point: CGPoint) -> [MIDINode] {

    // Retrieve all the nodes for the current dispatch.
    guard let dispatchNodes = MIDINodePlayer.currentDispatch?.nodes else { return [] }

    // Get the identifiers for all the midi nodes located at `point`.
    let identifiers = Set(player.nodes(at: point).flatMap({($0 as? MIDINode)?.identifier}))

    // Return all the midi nodes whose identifier is an element of `identifiers`.
    return dispatchNodes.filter { return $0.identifier ∈ identifiers }

  }

  /// Updates `touch` when `active && touch == nil` adding any nodes beneath the touch 
  /// to `nodesToRemove`.
  @objc func touchesBegan(_ touches: Set<UITouch>) {

    guard active && touch == nil else { return }

    touch = touches.first

    // Check that the touch is within the bounding box.
    guard let point = touch?.location(in: player), player.contains(point) else { return }

    // Append any nodes beneath `touch`.
    markNodesForRemoval(dispatchNodes(at: point))

  }

  /// Nullifies `touch` when `touch ∈ touches`.
  @objc func touchesCancelled(_ touches: Set<UITouch>) {

    // Check that `touch ∈ touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    // Stop tracking `touch`.
    touch = nil

  }

  /// Removes marked nodes and nullifies `touch` when `touch ∈ touches`.
  @objc func touchesEnded(_ touches: Set<UITouch>) {

    // Check that `touch ∈ touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    // Remove the marked nodes.
    removeMarkedNodes()

    // Stop tracking `touch`.
    touch = nil

  }

  /// Stops tracking `touch` if it has moved outside `player`; otherwise, marks nodes for the current
  /// location of `touch`. Does nothing if `touches ∌ touch`.
  @objc func touchesMoved(_ touches: Set<UITouch>) {

    // Check that `touch ∈ touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    // Get the touch's location in the player.
    let point = touch!.location(in: player)

    // Check that the player contains the point; otherwise, stop tracking `touch`.
    guard player.contains(point) else {
      touch = nil
      return
    }

    // Mark nodes for the current dispatch located by `point`.
    markNodesForRemoval(dispatchNodes(at: point))

  }

}
