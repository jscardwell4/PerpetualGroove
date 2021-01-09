//
//  Player.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import Foundation
import MIDI
import MoonKit
import SpriteKit
import UIKit

// MARK: - Player

/// Coordinates `Node` and `PlayerNode` operations.
public final class Player
{
  // MARK: Stored Properties

  /// The manager for undoing `Node` operations.
  public let undoManager = UndoManager()

  /// The object through which new node events are dispatched.
  @Published public var currentDispatch: NodeDispatch?

  /// Reference to the view controller owning the player scene.
  public weak var playerContainer: PlayerContainer?

  /// Reference to the player node in the player scene. Setting this property to
  /// a non-nil value triggers the creation of the player's tools.
  public internal(set) weak var playerNode: PlayerNode?
  {
    didSet
    {
      guard let node = playerNode else { return }
      addTool = AddTool(playerNode: node)
      removeTool = RemoveTool(playerNode: node, delete: false)
      deleteTool = RemoveTool(playerNode: node, delete: true)
      existingGeneratorTool = GeneratorTool(playerNode: node, mode: .existing)
      newGeneratorTool = GeneratorTool(playerNode: node, mode: .new)
      rotateTool = RotateTool(playerNode: node)
      currentTool = .none
    }
  }

  /// Tool for adding a new node to the player.
  public private(set) var addTool: AddTool?

  /// Tool for removing an existing node from the player
  public private(set) var removeTool: RemoveTool?

  /// Tool for deleting any trace of a node from the player.
  public private(set) var deleteTool: RemoveTool?

  /// Tool for changing the generator attached to an existing node in the player.
  public private(set) var existingGeneratorTool: GeneratorTool?

  /// Tool for configuring the generator to attach to the new nodes added by `addTool`.
  public private(set) var newGeneratorTool: GeneratorTool?

  /// Tool for changing the initial trajectory of an existing node in the player.
  public private(set) var rotateTool: RotateTool?

  /// Tool currently handling user touches.
  @Published public var currentTool: AnyTool = .none
  {
    willSet
    {
      // Check that the current tool has not simply been reassigned.
      guard currentTool != newValue else { return }

      // Close undo grouping if open.
      if undoManager.groupingLevel > 0 { undoManager.endUndoGrouping() }

      // Check that the current tool is showing its content.
      guard (currentTool.tool as? PresentingTool)?.isShowingContent == true else { return }

      // Dismiss the current tool's content.
      playerContainer?.dismiss(completion: { _ in })
    }

    didSet
    {
      // Check that the previous tool was not simply reassigned.
      guard currentTool != oldValue else { return }

      // Open a fresh undo grouping if a new tool has been assigned.
      if currentTool != .none { undoManager.beginUndoGrouping() }

      // Toggle activation of the previous and current tools.
      oldValue.tool?.active = false
      currentTool.tool?.active = true

      // Update the player node's touch handler.
      playerNode?.touchReceiver = currentTool.tool
    }
  }

  // MARK: Undo Support

  /// Invokes `undoManager.undo()` when `undoManager.canUndo`.
  /// Returns `true` iff `undo()` was invoked.
  @discardableResult
  public func rollBack() -> Bool
  {
    guard undoManager.canUndo else { return false }
    if undoManager.groupingLevel > 0 { undoManager.endUndoGrouping() }
    undoManager.undo()
    return true
  }

  /// Initializes the player by registering for various notifications.
  public init()
  {
    undoManager.groupsByEvent = false
  }

  /// Creates a new `Node` object using the specified parameters and adds it
  /// to `playerNode`.
  public func placeNew(_ trajectory: Node.Trajectory,
                       target: NodeDispatch,
                       generator: AnyGenerator,
                       identifier: UUID = UUID())
  {
    dispatchToMain
    { [self] in
      // Check that there is a player node to which a node may be added.
      guard let playerNode = playerNode
      else
      {
        log.warning("cannot place a node without a player node")
        return
      }

      do
      {
        // Generate a name for the node composed of the current sequencer mode
        // and the name provided by target.
        let name = "<\(controller.mode.rawValue)> \(target.nextNodeName)"

        // Create and add the node to the player node.
        let node = try Node(trajectory: trajectory,
                            name: name,
                            dispatch: target,
                            generator: generator,
                            identifier: identifier)
        playerNode.addChild(node)

        // Hand off the newly created node to the target's manager to handle
        // connecting, etc.
        try target.nodeManager.add(node: node)

        // Initiate playback if the transport is not currently playing.
        if !controller.transport.isPlaying
        {
          controller.transport.isPlaying = true
        }

        // Post notification that the node has been added.
        postNotification(name: .playerDidAddNode,
                         object: self,
                         userInfo: ["addedNode": node, "addedNodeDispatch": target])

        log.info("added node \(name)")
      }
      catch
      {
        log.error("\(error as NSObject)")
      }
    }
  }

  /// Removes `node` from the player node.
  public func remove(node: Node)
  {
    dispatchToMain
    { [self] in
      // Check that `node` is a child of `playerNode`.
      guard node.parent === playerNode else { return }

      // Fade out and remove `node`.
      node.fadeOut(remove: true)

      // Post notification that a node has been removed.
      postNotification(name: .playerDidRemoveNode, object: self)
    }
  }
}

// MARK: NotificationDispatching

extension Player: NotificationDispatching
{
  static let didAddNodeNotification = Notification.Name(rawValue: "didAddNode")
  static let didRemoveNodeNotification = Notification.Name(rawValue: "didRemoveNode")
}

public extension Notification.Name
{
  static let playerDidAddNode = Player.didAddNodeNotification
  static let playerDidRemoveNode = Player.didRemoveNodeNotification
}

public extension Notification
{
  var addedNode: Node? { userInfo?["addedNode"] as? Node }

  var addedNodeDispatch: NodeDispatch?
  {
    userInfo?["addedNodeDispatch"] as? NodeDispatch
  }
}
