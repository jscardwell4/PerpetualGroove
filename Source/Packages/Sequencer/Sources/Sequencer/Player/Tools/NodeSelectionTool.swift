//
//  NodeSelectionTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/24/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import MIDI
import MoonDev
import SpriteKit
import UIKit

// MARK: - NodeSelectionTool

/// An abstract tool for encapsulating node selection behavior.
@available(iOS 14.0, *)
public class NodeSelectionTool: Tool
{
  /// The player node to which midi nodes are to be added.
  public unowned let playerNode: PlayerNode

  /// Whether the tool is currently receiving touch events.
  @objc public var active = false
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
  public weak var node: Node?
  {
    didSet
    {
      // Check that `node` has actually changed.
      guard node != oldValue else { return }

      // Add lighting to the new value.
      if let node = node { addLighting(to: node) }

      // Remove lighting from the old value.
      if let oldNode = oldValue { removeLighting(from: oldNode) }
    }
  }

  /// The name for lighting nodes added by the tool.
  private static let nodeLightingName = "nodeSelectionToolLighting"

  /// Adds a light node to `node` to indicate that the node is selected.
  private func addLighting(to node: Node)
  {
    // Check that there is not already a light node added by the tool.
    guard node.childNode(withName: NodeSelectionTool.nodeLightingName) == nil
    else
    {
      return
    }

    // Add a new light node to `node`.
    node.addChild({
      let light = SKLightNode()
      light.name = NodeSelectionTool.nodeLightingName
      light.categoryBitMask = 1
      return light
    }())

    // Update the node's lighting mask.
    node.lightingBitMask = 1

    // Animated the node's color to emphasize selection.
    node.run(SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.25))
  }

  /// Removes the light node added via `addLighting(to:)`.
  private func removeLighting(from node: Node)
  {
    // Retrieve the light node added by the tool.
    guard let light = node.childNode(withName: NodeSelectionTool.nodeLightingName)
    else
    {
      return
    }

    // Remove the light node.
    light.removeFromParent()

    // Reset the node's lighting mask.
    node.lightingBitMask = 0

    // Get the color used by node's dispatching object.
    guard let color = node.dispatch?.color.value else { return }

    // Animated restoring the original color of the node.
    node.run(SKAction.colorize(with: color, colorBlendFactor: 1, duration: 0.25))
  }

  private var playerDidAddNodeSubscription: Cancellable?
  private var playerDidRemoveNodeSubscription: Cancellable?

  /// Initialize with a player node. Registers for node addition/removal notifications.
  public init(playerNode: PlayerNode)
  {
    self.playerNode = playerNode

    playerDidAddNodeSubscription = NotificationCenter.default
      .publisher(for: .playerDidAddNode, object: player)
      .sink { self.didAddNode(notification: $0) }
    playerDidRemoveNodeSubscription = NotificationCenter.default
      .publisher(for: .playerDidRemoveNode, object: player)
      .sink { self.didRemoveNode(notification: $0) }
  }

  /// Handler for node selection. The default implementation does nothing.
  public func didSelectNode() {}

  /// Handler for notifications from `NodePlayer` that a nodes has been added.
  /// The default implementation does nothing.
  public func didAddNode(notification: Notification) {}

  /// Handler for notifications from `NodePlayer` that a nodes has been removed.
  /// The default implementation does nothing.
  public func didRemoveNode(notification: Notification) {}

  /// Overwrites `node` with a node located beneath `touch`. Does nothing when
  /// `touch == nil` or no corresponding node is found.
  private func refreshNode()
  {
    // Check that there is a touch being tracked.
    guard let touch = touch else { return }

    // Get the current location of the touch.
    let point = touch.location(in: playerNode)

    // Check that the point is within bounds and corresponds to a midi node.
    guard playerNode.contains(point),
          let node = playerNode.nodes(at: point).first(where: { $0 is Node }) as? Node
    else
    {
      return
    }

    // Update the selected node.
    self.node = node
  }

  /// Replaces the selected node with its predecessor in `player.midiNodes`.
  public func previousNode()
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
  public func nextNode()
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
  @objc public func touchesBegan(_ touches: Set<UITouch>)
  {
    // Check that the tool is active and both `node` and `touch` are `nil`.
    guard active, node == nil, touch == nil else { return }

    // Update `touch`.
    touch = touches.first

    // Look for a node beneath `touch`.
    refreshNode()
  }

  /// Updates the selected node when a touch is being tracked and is in contact
  /// with a valid node.
  @objc public func touchesMoved(_ touches: Set<UITouch>)
  {
    // Check that the tool is active and tracking a touch contained by `touches`.
    guard active, touch != nil, touches.contains(touch!) else { return }

    // Update `node` if another node is located beneath `touch`.
    refreshNode()
  }

  /// Nullifies `node` and `touch` when `touch != nil` and `touches ∋ touch`.
  @objc public func touchesCancelled(_ touches: Set<UITouch>)
  {
    // Check that the tool is tracking a touch contained by `touches`.
    guard touch != nil, touches.contains(touch!) else { return }

    // Clear the selected node && tracked touch.
    node = nil
    touch = nil
  }

  /// Invokes selection handler when the tool is active, tracking a touch
  /// contained by `touches`, and `node != nil`.
  @objc public func touchesEnded(_ touches: Set<UITouch>)
  {
    // Check that the tool is active and tracking a touch in `touches`.
    guard active, touch != nil, touches.contains(touch!) else { return }

    // Refresh node one final time.
    refreshNode()

    // Check that a node has been selected.
    guard node != nil else { return }

    // Invoke selection handler.
    didSelectNode()
  }

  /// Makes changes to the selected node using the provided closure. This
  /// method ensures that the playback state of the current transport is
  /// appropriately managed before and after the changes are made.
  public final func adjustNode(_ makeAdjustments: () -> Void)
  {
    // Check that there is a node selected.
    guard let node = node else { return }

    // Get the node's start time before any adjustments
    let preadjustedNodeStart = node.initTime

    // Store whether the transport is initially paused.
    let isPaused = transport.paused

    // Make sure the transport is paused before adjusting.
    if !isPaused { transport.paused = true }

    // Jog to the node's start time.
    transport.jog(to: preadjustedNodeStart)

    // Perform node adjustements.
    makeAdjustments()

    // Check whether the node's start time has changed.
    if node.initTime != preadjustedNodeStart
    {
      // Jog to the node's new start time.
      transport.jog(to: node.initTime)
    }

    // Check that the transport was initially playing.
    guard !isPaused else { return }

    // Resume playback.
    transport.playing = true
  }
}

// MARK: - PresentingNodeSelectionTool

/// An abstract tool that expands on `NodeSelectionTool` by encapsulating
/// behavior for presenting secondary content.
@available(iOS 14.0, *)
public class PresentingNodeSelectionTool: NodeSelectionTool, PresentingTool
{
  public typealias DismissalAction = SecondaryControllerContainer.DismissalAction

  /// Stores a reference to the secondary content currently displayed.
  public private(set) weak var _secondaryContent: SecondaryContent?

  /// The content providing the tool's user interface.
  public var secondaryContent: SecondaryContent
  {
    fatalError("\(#function) must be overridden by subclass")
  }

  /// Whether the tool's interface is being displayed.
  public var isShowingContent: Bool { return _secondaryContent != nil }

  /// Handler invoked when the tool's interface has been revealed.
  /// Stores a weak reference to `content`.
  public func didShow(content: SecondaryContent) { _secondaryContent = content }

  /// Handler invoked when the tool's interface has been dismissed.
  /// Rolls back any changes made when `dismissalAction == .cancel`.
  /// Always nullifies the selected node.
  public func didHide(content: SecondaryContent, dismissalAction: DismissalAction)
  {
    if dismissalAction == .cancel { player.rollBack() }

    node = nil
  }

  /// Overridden to present the tool's secondary content when `active == true`.
  override public func didSelectNode()
  {
//    guard active else { return }
//
//    player.playerContainer?.presentContent(for: self, completion: { _ in })
  }

  /// Overridden to clear the list of disabled actions when adding a second node
  /// to the player.
  override public func didAddNode(notification: Notification)
  {
    // Check that the tool is active and the player has two nodes.
    guard active, playerNode.midiNodes.count == 2 else { return }

    // Clear disabled actions.
    _secondaryContent?.disabledActions = .none
  }

  /// Overridden to disable previous and next actions when the player has less
  /// than two nodes.
  override public func didRemoveNode(notification: Notification)
  {
    // Check that the tool is active and the player has less than two nodes.
    guard active, playerNode.midiNodes.count < 2 else { return }

    // Disable previous and next actions.
    _secondaryContent?.disabledActions.insert([.previous, .next])
  }
}
