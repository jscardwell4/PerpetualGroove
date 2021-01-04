//
//  MIDINodePlayer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import MoonKit
import MIDI

/// Singleton for coordinating `MIDINode` and `MIDINodePlayerNode` operations.
public final class MIDINodePlayer: NotificationDispatching {

  /// The manager for undoing `MIDINode` operations.
  public static let undoManager: UndoManager = {
    let undoManager = UndoManager()
    undoManager.groupsByEvent = false
    return undoManager
  }()

  /// Invokes `undoManager.undo()` when `undoManager.canUndo`. Returns `true` iff `undo()` was invoked.
  @discardableResult
  public static func rollBack() -> Bool {

    guard undoManager.canUndo else { return false }


    if undoManager.groupingLevel > 0 { undoManager.endUndoGrouping() }

    undoManager.undo()
      
    return true

  }

  /// Handles the receiving of various sequencer notifications.
  private static let receptionist = NotificationReceptionist()

  /// The object through which new node events are dispatched.
  public static weak var currentDispatch: MIDINodeDispatch? {
    willSet {
      guard currentDispatch !== newValue else { return }
      postNotification(name: .willChangeDispatch, object: self)
    }
    didSet {
      guard currentDispatch !== oldValue else { return }
      postNotification(name: .didChangeDispatch, object: self)
    }
  }

  /// Updates the value of `currentDispatch` according to the state of tracks, loops, and sequencer mode.
  static private func updateCurrentDispatch() {

    fatalError("\(#function) not yet implemented.")

//    // Check that there is a current track.
//    guard let track = InstrumentTrack.current else {
//      currentDispatch = nil
//      return
//    }
//
//    // Update according to the current sequencer mode.
//    switch Sequencer.mode {
//
//      case .default:
//        // Default is to dispatch through the track.
//
//        currentDispatch = track
//
//      case .loop:
//        // In loop mode, look for a loop assigned to the track and create if not found.
//
//        if let loop = loops[ObjectIdentifier(track)] {
//          // Dispatch through the existing loop.
//
//          currentDispatch = loop
//
//        } else {
//          // Create a loop assigned to the track and dispatch through the new loop.
//
//          let loop = Loop(track: track)
//          loops[ObjectIdentifier(track)] = loop
//          currentDispatch = loop
//
//        }
//
//    }
    
  }

  /// Flag specifying whether `initialize()` has been invoked.
  public private(set) static var isInitialized = false

//  private static weak var sequence: Sequence? {
//    didSet {
//      guard sequence !== oldValue else { return }
//      if let oldSequence = oldValue { receptionist.stopObserving(object: oldSequence) }
//      if let sequence = sequence {
//        receptionist.observe(name: .didRemoveTrack, from: sequence) {
//          guard let track = $0.removedTrack else { return }
//          MIDINodePlayer.loops[ObjectIdentifier(track)] = nil
//          MIDINodePlayer.updateCurrentDispatch()
//        }
//        receptionist.observe(name: .didChangeTrack, from: sequence) {
//          _ in MIDINodePlayer.updateCurrentDispatch()
//        }
//      }
//      updateCurrentDispatch()
//    }
//  }

  /// Initializes the player by registering for various notifications.
  public static func initialize() {

    fatalError("\(#function) not yet implemented.")

//    guard !isInitialized else { return }
//
//    receptionist.observe(name: .didChangeSequence, from: Sequencer.self, callback: didChangeSequence)
//    receptionist.observe(name: .didEnterLoopMode,  from: Sequencer.self, callback: didEnterLoopMode)
//    receptionist.observe(name: .didExitLoopMode,   from: Sequencer.self, callback: didExitLoopMode)
//    receptionist.observe(name: .willEnterLoopMode, from: Sequencer.self, callback: willEnterLoopMode)
//    receptionist.observe(name: .willExitLoopMode,  from: Sequencer.self, callback: willExitLoopMode)
//
//    isInitialized = true

  }

  /// Handler for sequence change notifications from the sequencer.
//  private static func didChangeSequence(_ notification: Notification) {
//    sequence = Sequence.current
//  }

  /// Handler for will enter loop mode notifications from the sequencer.
//  private static func willEnterLoopMode(_ notification: Notification) {
//    for node in (playerNode?.loopNodes ?? []) {
//      node.fadeOut()
//    }
//  }

  /// Handler for will exit loop mode notifications from the sequencer.
//  private static func willExitLoopMode(_ notification: Notification) {
//    for node in (playerNode?.loopNodes ?? []) {
//      node.fadeOut(remove: true)
//    }
//  }

  /// Handler for did enter loop mode notifications from the sequencer.
//  private static func didEnterLoopMode(_ notification: Notification) {
//    loops.removeAll()
//    updateCurrentDispatch()
//  }

  /// Handler for did exit loop mode notifications from the sequencer.
//  private static func didExitLoopMode(_ notification: Notification) {
//    for node in (playerNode?.defaultNodes ?? []) { node.fadeIn() }
//    insertLoops()
//    resetLoops()
//    updateCurrentDispatch()
//  }

  /// Adds any non-empty loops to their respective tracks.
  static private func insertLoops() {

    fatalError("\(#function) not yet implemented.")

//    logi("inserting loops: \(loops)")
//
//
//    // Calculate the start and end times
//    let currentTime = Time.current?.barBeatTime ?? .zero
//    let startTime = currentTime + loopStart
//    let endTime = currentTime + loopEnd
//
//    // Iterate through non-empty loops to update start/end times and add them to their track.
//    for loop in loops.values where !loop.eventContainer.isEmpty {
//      loop.start = startTime
//      loop.end = endTime
//      loop.track.add(loop: loop)
//    }

  }

  /// Removes all loops and resets loop start and end to `.zero`.
  static private func resetLoops() {
    fatalError("\(#function) not yet implemented.")
//    loops.removeAll()
//    loopStart = .zero
//    loopEnd = .zero
  }

  /// Reference to the view controller owning the player scene.
  public static weak var playerContainer: MIDINodePlayerContainer?

  /// Reference to the player node in the player scene. Setting this property to a non-nil value
  /// triggers the creation of the player's tools.
  public static weak var playerNode: MIDINodePlayerNode? {
    didSet {
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
  public static private(set) var addTool: AddTool?

  /// Tool for removing an existing node from the player
  public static private(set) var removeTool: RemoveTool?

  /// Tool for deleting any trace of a node from the player.
  public static private(set) var deleteTool: RemoveTool?

  /// Tool for changing the generator attached to an existing node in the player.
  public static private(set) var existingGeneratorTool: GeneratorTool?

  /// Tool for configuring the generator to attach to the new nodes added by `addTool`.
  public static private(set) var newGeneratorTool: GeneratorTool?

  /// Tool for changing the initial trajectory of an existing node in the player.
  public static private(set) var rotateTool: RotateTool?

  /// Tool currently handling user touches.
  public static var currentTool: AnyTool = .none {

    willSet {

      // Check that the current tool is not simply been reassigned.
      guard currentTool != newValue else { return }

      // Close undo grouping if open.
      if undoManager.groupingLevel > 0 { undoManager.endUndoGrouping() }

      // Check that the current tool is showing its content.
      guard (currentTool.tool as? PresentingTool)?.isShowingContent == true else { return }

      // Dismiss the current tool's content.
      playerContainer?.dismiss(completion: {_ in })

    }

    didSet {

      // Check that the previous tool was not simply reassigned.
      guard currentTool != oldValue else { return }

      // Open a fresh undo grouping if a new tool has been assigned.
      if currentTool != .none { undoManager.beginUndoGrouping() }

      // Toggle activation of the previous and current tools.
      oldValue.tool?.active = false
      currentTool.tool?.active = true

      // Update the player node's touch handler.
      playerNode?.touchReceiver = currentTool.tool

      // Post notification of the new tool selection.
      postNotification(name: .didSelectTool, object: self, userInfo: ["selectedTool": currentTool])

    }

  }

  /// Collection of active loops.
//  static private var loops: [ObjectIdentifier:Loop] = [:]

  /// The start time for active loops.
  public static var loopStart: BarBeatTime = .zero

  /// The end time for active loops.
  public static var loopEnd: BarBeatTime = .zero

  /// Creates a new `MIDINode` object using the specified parameters and adds it to `playerNode`.
  public static func placeNew(_ trajectory: MIDINode.Trajectory,
                       target: MIDINodeDispatch,
                       generator: AnyMIDIGenerator,
                       identifier: UUID = UUID())
  {

    fatalError("\(#function) not yet implemented.")

//    dispatchToMain {
//
//      // Check that there is a player node to which a node may be added.
//      guard let playerNode = playerNode else {
//        logw("cannot place a node without a player node")
//        return
//      }
//
//      do {
//
//        // Generate a name for the node composed of the current sequencer mode
//        // and the name provided by target.
//        let name = "<\(Sequencer.mode.rawValue)> \(target.nextNodeName)"
//
//        // Create and add the node to the player node.
//        let node = try MIDINode(trajectory: trajectory,
//                                name: name,
//                                dispatch: target,
//                                generator: generator,
//                                identifier: identifier)
//        playerNode.addChild(node)
//
//        // Hand off the newly created node to the target's manager to handle connecting, etc.
//        try target.nodeManager.add(node: node)
//
//        // Initiate playback if the transport is not currently playing.
//        if !Transport.current.isPlaying { Transport.current.isPlaying = true }
//
//        // Post notification that the node has been added.
//        postNotification(name: .didAddNode,
//                         object: self,
//                         userInfo: ["addedNode": node, "addedNodeDispatch": target])
//
//        logi("added node \(name)")
//
//      } catch {
//
//        loge("\(error)")
//
//      }
//
//    }

  }

  /// Removes `node` from the player node.
  public static func remove(node: MIDINode) {

    dispatchToMain {

      // Check that `node` is a child of `playerNode`.
      guard node.parent === playerNode else { return }

      // Fade out and remove `node`.
      node.fadeOut(remove: true)

      // Post notification that a node has been removed.
      postNotification(name: .didRemoveNode, object: self)

    }

  }

  /// Enumeration of the notification names used in notifications posted by `MIDINodePlayer`.
  public enum NotificationName: String, LosslessStringConvertible {

    case didAddNode, didRemoveNode, didSelectTool, willChangeDispatch, didChangeDispatch

    public var description: String { return rawValue }

    public init?(_ description: String) { self.init(rawValue: description) }

  }

}

extension Notification {

  public var addedNode: MIDINode? { return userInfo?["addedNode"] as? MIDINode }

  public var addedNodeDispatch: MIDINodeDispatch? { return userInfo?["addedNodeDispatch"] as? MIDINodeDispatch }

  public var selectedTool: AnyTool? { return userInfo?["selectedTool"] as? AnyTool }

}
