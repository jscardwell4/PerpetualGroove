//
//  NodeSelectionTool.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/8/21.
//
import Combine
import Foundation
import MoonDev
import SpriteKit
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
class NodeSelectionTool: TouchReceiver
{
  @Environment(\.player) var player: Player
  @Environment(\.currentTransport) var currentTransport: Transport

  var playerNode: PlayerNode { player.playerNode }

  /// Whether the tool is currently receiving touch events.
  var active = false
  {
    didSet
    {
      // Check that `active` has changed from `true` to `false`.
      guard active != oldValue, !active else { return }

      // Nullify `node`.
      node = nil
    }
  }

  /// The currently tracked touch.
  private var touch: UITouch?

  /// The currently selected node. Setting this property adds/removes a
  /// light node to emphasize selection.
  var node: MIDINode?
  {
    willSet { if let oldNode = node { removeLighting(from: oldNode) } }
    didSet { if let node = node { addLighting(to: node) } }
  }

  /// The name for lighting nodes added by the tool.
  let nodeLightingName = "nodeSelectionToolLighting"

  /// Adds a light node to `node` to indicate that the node is selected.
  func addLighting(to node: MIDINode)
  {
    // Check that there is not already a light node added by the tool.
    guard node.childNode(withName: nodeLightingName) == nil else { return }

    // Add a new light node to `node`.
    let light = SKLightNode()
    light.name = nodeLightingName
    light.categoryBitMask = 1
    node.addChild(light)

    // Update the node's lighting mask.
    node.lightingBitMask = 1

    // Animated the node's color to emphasize selection.
    node.run(SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.25))
  }

  /// Removes the light node added via `addLighting(to:)`.
  private func removeLighting(from node: MIDINode)
  {
    // Retrieve the light node added by the tool.
    guard let light = node.childNode(withName: nodeLightingName) else { return }

    // Remove the light node.
    light.removeFromParent()

    // Reset the node's lighting mask.
    node.lightingBitMask = 0

    // Get the color used by node's dispatching object.
    guard let color = node.dispatch?.color else { return }

    // Animated restoring the original color of the node.
    node.run(SKAction.colorize(with: UIColor(color), colorBlendFactor: 1, duration: 0.25))
  }

  /// Holds the subscriptions for added and removed nodes.
  private var subscriptions: Set<AnyCancellable> = []

  /// Default initializer configures `subscriptions`.
  init()
  {
    defer
    {
      subscriptions.store
      {
        player.publisher(for: .lastAdded).receive(on: RunLoop.main).sink
        {
          guard let addedNode = $0 else { return }
          self.didAdd(node: addedNode)
        }
        player.publisher(for: .lastRemoved).receive(on: RunLoop.main).sink
        {
          guard let removed = $0 else { return }
          self.didRemove(node: removed)
        }
      }
    }
  }

  /// Hook for subclasses to handle node selection.
  /// The default implementation does nothing.
  func didSelectNode() {}

  /// Hook for subclasses to handle node addition.
  /// The default implementation does nothing.
  func didAdd(node: MIDINode) {}

  /// Hook for subclasses to handle node removal.
  /// The default implementation does nothing.
  func didRemove(node: MIDINode) {}

  /// Updates the value of `node` with the node located beneath `touch`.
  /// Does nothing when `touch == nil` or no corresponding node is found.
  private func updateNode()
  {
    // Check that there is a touch being tracked.
    guard let touch = touch else { return }

    // Get the current location of the touch.
    let point = touch.location(in: playerNode)

    // Check that the point is within bounds and corresponds to a midi node.
    guard playerNode.contains(point),
          let node = playerNode.nodes(at: point).compactMap({ $0 as? MIDINode }).first
    else
    {
      return
    }

    // Update the selected node.
    self.node = node
  }

  /// Replaces the selected node with its predecessor in `player.midiNodes`.
  func previousNode()
  {
    // Get the index for the selected node in th player's nodes.
    guard let index = playerNode.midiNodes.firstIndex(where: { $0 === node })
    else
    {
      return
    }

    // Calculate the previous index.
    let nodeCount = playerNode.midiNodes.count
    let previousIndex = ((index &- 1) &+ nodeCount) % nodeCount

    // Update `node` with the node at `previousIndex`.
    node = playerNode.midiNodes[previousIndex]
  }

  /// Replaces the selected node with its successor in `player.midiNodes`.
  func nextNode()
  {
    // Get the index for the selected node in th player's nodes.
    guard let index = playerNode.midiNodes.firstIndex(where: { $0 === node })
    else
    {
      return
    }

    // Calculate the next index.
    let nextIndex = ((index &- 1) &+ 1) % playerNode.midiNodes.count

    // Update `node` with the node at `nextIndex`.
    node = playerNode.midiNodes[nextIndex]
  }

  /// Updates `touch` when `active && touch == nil`, attempts to set `node` using
  /// the touch's location.
  @objc func touchesBegan(_ touches: Set<UITouch>)
  {
    // Check that the tool is active and both `node` and `touch` are `nil`.
    guard active, node == nil, touch == nil else { return }

    // Update `touch`.
    touch = touches.first

    // Look for a node beneath `touch`.
    updateNode()
  }

  /// Updates the selected node when a touch is being tracked and is in contact
  /// with a valid node.
  @objc func touchesMoved(_ touches: Set<UITouch>)
  {
    // Check that the tool is active and tracking a touch contained by `touches`.
    guard active, touch != nil, touches.contains(touch!) else { return }

    // Update `node` if another node is located beneath `touch`.
    updateNode()
  }

  /// Nullifies `node` and `touch` when `touch != nil` and `touches ∋ touch`.
  @objc func touchesCancelled(_ touches: Set<UITouch>)
  {
    // Check that the tool is tracking a touch contained by `touches`.
    guard touch != nil, touches.contains(touch!) else { return }

    // Clear the selected node && tracked touch.
    node = nil
    touch = nil
  }

  /// Invokes selection handler when the tool is active, tracking a touch
  /// contained by `touches`, and `node != nil`.
  @objc func touchesEnded(_ touches: Set<UITouch>)
  {
    // Check that the tool is active and tracking a touch in `touches`.
    guard active, touch != nil, touches.contains(touch!) else { return }

    // Refresh node one final time.
    updateNode()

    // Check that a node has been selected.
    guard node != nil else { return }

    // Invoke selection handler.
    didSelectNode()
  }

  /// Makes changes to the selected node using the provided closure. This
  /// method ensures that the playback state of the current transport is
  /// appropriately managed before and after the changes are made.
  final func adjustNode(_ makeAdjustments: () -> Void)
  {
    // Check that there is a node selected.
    guard let node = node else { return }

    // Get the node's start time before any adjustments
    let preadjustedNodeStart = node.coordinator.initTime

    // Store whether the transport is initially paused.
    let isPaused = currentTransport.isPaused

    // Make sure the transport is paused before adjusting.
    if !isPaused { currentTransport.isPaused = true }

    // Jog to the node's start time.
    currentTransport.jog(to: preadjustedNodeStart)

    // Perform node adjustements.
    makeAdjustments()

    // Check whether the node's start time has changed.
    if node.coordinator.initTime != preadjustedNodeStart
    {
      // Jog to the node's new start time.
      currentTransport.jog(to: node.coordinator.initTime)
    }

    // Check that the transport was initially playing.
    guard !isPaused else { return }

    // Resume playback.
    currentTransport.isPlaying = true
  }
}
