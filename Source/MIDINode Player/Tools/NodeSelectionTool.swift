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
import MIDI

/// An abstract tool for encapsulating node selection behavior.
class NodeSelectionTool: Tool {

  /// The player node to which midi nodes are to be added.
  unowned let player: MIDINodePlayerNode

  /// Whether the tool is currently receiving touch events.
  @objc var active = false {

    didSet {

      // Check that `active` has changed from `true` to `false`.
      guard active != oldValue && !active else { return }

      // Nullify `node`.
      node = nil

    }

  }

  /// The currently tracked touch.
  private var touch: UITouch?

  /// The currently selected node. Setting this property adds/removes a light node to emphasize selection.
  weak var node: MIDINode? {

    didSet {

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
  private func addLighting(to node: MIDINode) {

    // Check that there is not already a light node added by the tool.
    guard node.childNode(withName: NodeSelectionTool.nodeLightingName) == nil else { return }

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
  private func removeLighting(from node: MIDINode) {

    // Retrieve the light node added by the tool.
    guard let light = node.childNode(withName: NodeSelectionTool.nodeLightingName) else { return }

    // Remove the light node.
    light.removeFromParent()

    // Reset the node's lighting mask.
    node.lightingBitMask = 0

    // Get the color used by node's dispatching object.
    guard let color = node.dispatch?.color.value else { return }

    // Animated restoring the original color of the node.
    node.run(SKAction.colorize(with: color, colorBlendFactor: 1, duration: 0.25))
    
  }

  /// Handles registration/reception of notifications from `MIDINodePlayer`.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Initialize with a player node. Registers for node addition/removal notifications from `MIDINodePlayer`.
  init(playerNode: MIDINodePlayerNode) {

    player = playerNode

    receptionist.observe(name: .didAddNode, from: MIDINodePlayer.self,
                         callback: weakCapture(of: self, block:NodeSelectionTool.didAddNode))
    receptionist.observe(name: .didRemoveNode, from: MIDINodePlayer.self,
                         callback: weakCapture(of: self, block:NodeSelectionTool.didRemoveNode))

  }

  /// Handler for node selection. The default implementation does nothing.
  func didSelectNode() {}

  /// Handler for notifications from `MIDINodePlayer` that a nodes has been added. 
  /// The default implementation does nothing.
  func didAddNode(_ notification: Notification) {}

  /// Handler for notifications from `MIDINodePlayer` that a nodes has been removed.
  /// The default implementation does nothing.
  func didRemoveNode(_ notification: Notification) {}

  /// Overwrites `node` with a node located beneath `touch`. Does nothing when `touch == nil` or no
  /// corresponding node is found.
  private func refreshNode() {

    // Check that there is a touch being tracked.
    guard let touch = touch else { return }

    // Get the current location of the touch.
    let point = touch.location(in: player)

    // Check that the point is within bounds and corresponds to a midi node.
    guard player.contains(point),
          let node = player.nodes(at: point).first(where: {$0 is MIDINode}) as? MIDINode
      else
    {
      return
    }

    // Update the selected node.
    self.node = node

  }

  /// Replaces the selected node with its predecessor in `player.midiNodes`.
  func previousNode() {

    // Get the index for the selected node in th player's nodes.
    guard let index = player.midiNodes.firstIndex(where: {$0 === node}) else { return }

    // Calculate the previous index.
    let nodeCount = player.midiNodes.count
    let previousIndex = ((index &- 1) &+ nodeCount) % nodeCount

    // Update `node` with the node at `previousIndex`.
    node = player.midiNodes[previousIndex]

  }

  /// Replaces the selected node with its successor in `player.midiNodes`.
  func nextNode() {

    // Get the index for the selected node in th player's nodes.
    guard let index = player.midiNodes.firstIndex(where: {$0 === node}) else { return }

    // Calculate the next index.
    let nextIndex = ((index &- 1) &+ 1) % player.midiNodes.count

    // Update `node` with the node at `nextIndex`.
    node = player.midiNodes[nextIndex]

  }

  /// Updates `touch` when `active && touch == nil`, attempts to set `node` using the touch's location.
  @objc func touchesBegan(_ touches: Set<UITouch>) {

    // Check that the tool is active and both `node` and `touch` are `nil`.
    guard active && node == nil && touch == nil else { return }

    // Update `touch`.
    touch = touches.first

    // Look for a node beneath `touch`.
    refreshNode()

  }

  /// Updates the selected node when a touch is being tracked and is in contact with a valid node.
  @objc func touchesMoved(_ touches: Set<UITouch>) {

    // Check that the tool is active and tracking a touch contained by `touches`.
    guard active && touch != nil && touches.contains(touch!) else { return }

    // Update `node` if another node is located beneath `touch`.
    refreshNode()

  }

  /// Nullifies `node` and `touch` when `touch != nil` and `touches ∋ touch`.
  @objc func touchesCancelled(_ touches: Set<UITouch>) {

    // Check that the tool is tracking a touch contained by `touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    // Clear the selected node && tracked touch.
    node = nil
    touch = nil

  }

  /// Invokes selection handler when the tool is active, tracking a touch contained by `touches`, and 
  /// `node != nil`.
  @objc func touchesEnded(_ touches: Set<UITouch>) {

    // Check that the tool is active and tracking a touch in `touches`.
    guard active && touch != nil && touches.contains(touch!) else { return }

    // Refresh node one final time.
    refreshNode()

    // Check that a node has been selected.
    guard node != nil else { return }

    // Invoke selection handler.
    didSelectNode()
    
  }


  /// Makes changes to the selected node using the provided closure. This method ensures that the
  /// playback state of the current transport is appropriately managed before and after the changes
  /// are made.
  final func adjustNode(_ makeAdjustments: () -> Void) {

    // Check that there is a node selected.
    guard let node = node else { return }

    // Get the node's start time before any adjustments
    let preadjustedNodeStart = node.initTime

    // Get the transport
    let transport = Transport.current

    // Store whether the transport is initially paused.
    let isPaused = transport.isPaused

    // Make sure the transport is paused before adjusting.
    if !isPaused { transport.isPaused = true }

    // Jog to the node's start time.
    transport.jog(to: preadjustedNodeStart)

    // Perform node adjustements.
    makeAdjustments()

    // Check whether the node's start time has changed.
    if node.initTime != preadjustedNodeStart {

      // Jog to the node's new start time.
      transport.jog(to: node.initTime)

    }

    // Check that the transport was initially playing.
    guard !isPaused else { return }
    
    // Resume playback.
    transport.isPlaying = true

  }

}

/// An abstract tool that expands on `NodeSelectionTool` by encapsulating behavior for presenting 
/// secondary content.
class PresentingNodeSelectionTool: NodeSelectionTool, PresentingTool {

  typealias DismissalAction = SecondaryControllerContainer.DismissalAction

  /// Stores a reference to the secondary content currently displayed.
  private(set) weak var _secondaryContent: SecondaryContent?

  /// The content providing the tool's user interface.
  var secondaryContent: SecondaryContent {
    fatalError("\(#function) must be overridden by subclass")
  }

  /// Whether the tool's interface is being displayed.
  var isShowingContent: Bool { return _secondaryContent != nil }

  /// Handler invoked when the tool's interface has been revealed. Stores a weak reference to `content`.
  func didShow(content: SecondaryContent) { _secondaryContent = content }

  /// Handler invoked when the tool's interface has been dismissed. Rolls back any changes made when
  /// `dismissalAction == .cancel`. Always nullifies the selected node.
  func didHide(content: SecondaryContent, dismissalAction: DismissalAction) {

    if dismissalAction == .cancel { MIDINodePlayer.rollBack() }

    node = nil

  }

  /// Overridden to present the tool's secondary content when `active == true`.
  override func didSelectNode() {

    guard active else { return }

    MIDINodePlayer.playerContainer?.presentContent(for: self, completion: {_ in})

  }

  /// Overridden to clear the list of disabled actions when adding a second node to the player.
  override func didAddNode(_ notification: Notification) {

    // Check that the tool is active and the player has two nodes.
    guard active && player.midiNodes.count == 2 else { return }

    // Clear disabled actions.
    _secondaryContent?.disabledActions = .none

  }

  /// Overridden to disable previous and next actions when the player has less than two nodes.
  override func didRemoveNode(_ notification: Notification) {

    // Check that the tool is active and the player has less than two nodes.
    guard active && player.midiNodes.count < 2 else { return }

    // Disable previous and next actions.
    _secondaryContent?.disabledActions.insert([.previous, .next])

  }

}
