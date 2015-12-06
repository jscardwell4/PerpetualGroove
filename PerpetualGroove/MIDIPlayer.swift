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

  static weak var playerViewController: MIDIPlayerViewController?
  static weak var playerView:           MIDIPlayerView?
  static weak var playerScene:          MIDIPlayerScene?
  static weak var playerNode:           MIDIPlayerNode? {
    didSet {
      guard let node = playerNode else { return }
      addTool = AddTool(playerNode: node)
      removeTool = RemoveTool(playerNode: node)
      generatorTool = GeneratorTool(playerNode: node)
      currentTool = .None
    }
  }

  static private var addTool: AddTool?
  static private var removeTool: RemoveTool?
  static private var generatorTool: GeneratorTool?

  static var currentTool: Tool = .None {
    didSet {
      logDebug("oldValue = \(oldValue)  currentTool = \(currentTool)")
      guard currentTool != oldValue else { return }
      oldValue.toolType?.active = false
      currentTool.toolType?.active = true
    }
  }

  /** configureGenerator */
  static func configureGenerator() {

  }

  /**
   placeNew:targetTrack:generator:

   - parameter placement: Placement
   - parameter targetTrack: InstrumentTrack? = nil
   - parameter generator: MIDINoteGenerator
  */
  static func placeNew(placement: Placement, targetTrack: InstrumentTrack? = nil, generator: MIDINoteGenerator) {
    guard let track = targetTrack ?? Sequencer.sequence?.currentTrack else {
      logWarning("cannot place a node without a track")
      return
    }
    guard let node = playerNode else {
      logWarning("cannot place a node without a player node")
      return
    }

    do {
      let name = "\(track.name) \(generator)"
      let midiNode = try MIDINode(placement: placement, name: name, track: track, note: generator)
      node.addChild(midiNode)
      try track.addNode(midiNode)
      if !Sequencer.playing { Sequencer.play() }
      Notification.DidAddNode.post(
        object: self,
        userInfo: [
          Notification.Key.AddedNode: midiNode,
          Notification.Key.AddedNodeTrack: track
        ]
      )
      logDebug("added node \(name)")

    } catch {
      logError(error)
    }
  }

  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  static func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    currentTool.toolType?.touchesBegan(touches, withEvent: event)
  }

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
   */
  static func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    currentTool.toolType?.touchesCancelled(touches, withEvent: event)
  }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  static func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    currentTool.toolType?.touchesEnded(touches, withEvent: event)
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  static func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    currentTool.toolType?.touchesMoved(touches, withEvent: event)
  }

}

protocol ToolType: class {
  var active: Bool { get set }
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
}

// MARK: - Tool
extension MIDIPlayer {
  enum Tool {
    case None, Add, Remove, Generator

    var toolType: ToolType? {
      switch self {
        case .Add:       return MIDIPlayer.addTool
        case .Remove:    return MIDIPlayer.removeTool
        case .Generator: return MIDIPlayer.generatorTool
        case .None:      return nil
      }
    }

    private init(_ toolType: ToolType?) {
      switch toolType {
        case let t? where MIDIPlayer.addTool === t:       self = .Add
        case let t? where MIDIPlayer.removeTool === t:    self = .Remove
        case let t? where MIDIPlayer.generatorTool === t: self = .Generator
        default:                                          self = .None
      }
    }

  }
}


// MARK: - Notification
extension MIDIPlayer {

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddNode, DidRemoveNode
    var object: AnyObject? { return MIDIPlayerNode.self }
    enum Key: String, NotificationKeyType { case AddedNode, AddedNodeTrack }
  }

}

extension NSNotification {
  var addedNode: MIDINode? {
    return userInfo?[MIDIPlayer.Notification.Key.AddedNode.key] as? MIDINode
  }
  var addedNodeTrack: InstrumentTrack? {
    return userInfo?[MIDIPlayer.Notification.Key.AddedNodeTrack.key] as? InstrumentTrack
  }
}
