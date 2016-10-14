//
//  MIDIPlayer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import MoonKit

final class MIDIPlayer {

  static let undoManager: UndoManager = {
    let undoManager = UndoManager()
    undoManager.groupsByEvent = false
    return undoManager
  }()

  private static let receptionist = NotificationReceptionist()

  static weak var currentDispatch: MIDINodeDispatch? {
    didSet {
      guard currentDispatch !== oldValue else { return }
      logDebug("\(oldValue?.name ?? "nil") ➞ \(currentDispatch?.name ?? "nil")")
    }
  }

  static fileprivate func updateCurrentDispatch() {
    guard let track = Sequencer.sequence?.currentTrack else { currentDispatch = nil; return }
    switch Sequencer.mode {
      case .default: currentDispatch = track
      case .loop:
        if let loop = loops[ObjectIdentifier(track)] { currentDispatch = loop }
        else {
          let loop = Loop(track: track)
          loops[ObjectIdentifier(track)] = loop
          currentDispatch = loop
        }
    }
  }

  fileprivate(set) static var initialized = false

  fileprivate static weak var sequence: Sequence? {
    didSet {
      guard sequence !== oldValue else { return }
      if let oldSequence = oldValue { receptionist.stopObserving(object: oldSequence) }
      if let sequence = sequence {
        receptionist.observe(name: Sequence.NotificationName.didRemoveTrack.rawValue, from: sequence, callback: MIDIPlayer.didRemoveTrack)
        receptionist.observe(name: Sequence.NotificationName.didChangeTrack.rawValue, from: sequence, callback: MIDIPlayer.didChangeTrack)
      }
      updateCurrentDispatch()
    }
  }

  static func initialize() {
    guard !initialized else { return }

    receptionist.logContext = LogManager.SceneContext

    receptionist.observe(name: .didChangeSequence, from: Sequencer.self,
                         callback: MIDIPlayer.didChangeSequence)
    receptionist.observe(name: .didEnterLoopMode, from: Sequencer.self,
                         callback: MIDIPlayer.didEnterLoopMode)
    receptionist.observe(name: .didExitLoopMode, from: Sequencer.self,
                         callback: MIDIPlayer.didExitLoopMode)
    receptionist.observe(name: .willEnterLoopMode, from: Sequencer.self,
                         callback: MIDIPlayer.willEnterLoopMode)
    receptionist.observe(name: .willExitLoopMode, from: Sequencer.self,
                         callback: MIDIPlayer.willExitLoopMode)

    initialized = true
  }

  static fileprivate func didChangeSequence(_ notification: Foundation.Notification) { sequence = Sequencer.sequence }

  static fileprivate func didRemoveTrack(_ notification: Foundation.Notification) {
    guard let track = notification.removedTrack else { return }
    loops[ObjectIdentifier(track)] = nil
    updateCurrentDispatch()
  }

  static fileprivate func didChangeTrack(_ notification: Foundation.Notification) { updateCurrentDispatch() }
  
  static fileprivate func willEnterLoopMode(_ notification: Foundation.Notification) {
    playerNode?.defaultNodes.forEach { $0.fadeOut() }
  }

  static fileprivate func didEnterLoopMode(_ notification: Foundation.Notification) {
    loops.removeAll()
    updateCurrentDispatch()
  }

  static fileprivate func willExitLoopMode(_ notification: Foundation.Notification) {
    playerNode?.loopNodes.forEach { $0.fadeOut(remove: true) }
  }

  static fileprivate func didExitLoopMode(_ notification: Foundation.Notification) {
    playerNode?.defaultNodes.forEach { $0.fadeIn() }
    insertLoops()
    resetLoops()
    updateCurrentDispatch()
  }

  static var shouldInsertLoops = false

  static fileprivate func insertLoops() {
    logDebug("inserting loops: \(loops)")
    let startTime = Sequencer.time.barBeatTime + loopStart
    let endTime = Sequencer.time.barBeatTime + loopEnd
    for loop in loops.values where !loop.eventContainer.isEmpty {
      loop.start = startTime
      loop.end = endTime
      loop.track.add(loop: loop)
    }
  }

  static fileprivate func resetLoops() {
    loops.removeAll()
    loopStart = BarBeatTime.zero
    loopEnd = BarBeatTime.zero
    shouldInsertLoops = false
  }

  static weak var playerContainer: MIDIPlayerContainerViewController?
  
  static weak var playerNode: MIDIPlayerNode? {
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

  static fileprivate(set) var addTool: AddTool?
  static fileprivate(set) var removeTool: RemoveTool?
  static fileprivate(set) var deleteTool: RemoveTool?
  static fileprivate(set) var existingGeneratorTool: GeneratorTool?
  static fileprivate(set) var newGeneratorTool: GeneratorTool?
  static fileprivate(set) var rotateTool: RotateTool?

  static var currentTool: AnyTool = .none {
    willSet {
      logDebug("willSet: \(currentTool) ➞ \(newValue)")
      guard currentTool != newValue else { return }
      if undoManager.groupingLevel > 0 { undoManager.endUndoGrouping() }
      guard (currentTool.tool as? PresentingTool)?.isShowingContent == true else { return }
      playerContainer?.dismiss(completion: {_ in })
    }
    didSet {
      logDebug("didSet: \(oldValue) ➞ \(currentTool)")
      guard currentTool != oldValue else { return }
      if currentTool != .none { undoManager.beginUndoGrouping() }
      oldValue.tool?.active = false
      currentTool.tool?.active = true
      playerNode?.touchReceiver = currentTool.tool
      postNotification(name: .didSelectTool, object: self, userInfo: ["selectedTool": currentTool.rawValue])
    }
  }

  static fileprivate var loops: [ObjectIdentifier:Loop] = [:]

  static var loopStart: BarBeatTime = BarBeatTime.zero
  static var loopEnd: BarBeatTime = BarBeatTime.zero

  static func placeNew(_ trajectory: Trajectory,
                target: MIDINodeDispatch,
             generator: AnyMIDIGenerator,
            identifier: UUID = UUID())
  {
    dispatchToMain {
      guard let playerNode = playerNode else {
        logWarning("cannot place a node without a player node")
        return
      }

      do {
        let name = "<\(Sequencer.mode.rawValue)> \(target.nextNodeName)"
        let node = try MIDINode(trajectory: trajectory,
                                    name: name,
                                    dispatch: target,
                                    generator: generator,
                                    identifier: identifier)
        playerNode.addChild(node)

        try target.nodeManager.add(node: node)


        if !Sequencer.playing { Sequencer.play() }
        postNotification(name: .didAddNode, object: self, userInfo: ["addedNode": node, "addedNodeTrack": target])
        logDebug("added node \(name)")

      } catch {
        logError(error)
      }
    }
  }

  static func removeNode(_ node: MIDINode) {
    dispatchToMain {
      guard node.parent === playerNode else { return }
      node.fadeOut(remove: true)
      postNotification(name: .didRemoveNode, object: self, userInfo: nil)
    }
  }

}

// MARK: - Notification
extension MIDIPlayer: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didAddNode, didRemoveNode, didSelectTool

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }

}

extension Notification {

  var addedNode: MIDINode? { return userInfo?["addedNode"] as? MIDINode }

  var addedNodeTrack: InstrumentTrack? { return userInfo?["addedNodeTrack"] as? InstrumentTrack }

  var selectedTool: AnyTool? {
    guard let rawValue = userInfo?["selectedTool"] as? Int else { return nil }
    return AnyTool(rawValue)
  }

}
