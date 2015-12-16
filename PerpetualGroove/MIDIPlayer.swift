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
      removeTool = RemoveTool(playerNode: node, delete: false)
      deleteTool = RemoveTool(playerNode: node, delete: true)
      existingGeneratorTool = GeneratorTool(playerNode: node, mode: .Existing)
      newGeneratorTool = GeneratorTool(playerNode: node, mode: .New)
      currentTool = .None
    }
  }

  static private(set) var addTool: AddTool?
  static private(set) var removeTool: RemoveTool?
  static private(set) var deleteTool: RemoveTool?
  static private(set) var existingGeneratorTool: GeneratorTool?
  static private(set) var newGeneratorTool: GeneratorTool?

  static var currentTool: Tool = .None {
    willSet {
      guard currentTool != newValue
        && (currentTool.toolType as? ConfigurableToolType)?.isShowingViewController == true else { return }
      playerViewController?.dismissController()
    }
    didSet {
      logDebug("oldValue = \(oldValue)  currentTool = \(currentTool)")
      guard currentTool != oldValue else { return }
      oldValue.toolType?.active = false
      currentTool.toolType?.active = true
      Notification.DidSelectTool.post(userInfo: [.SelectedTool: currentTool.rawValue])
    }
  }

  /**
   placeNew:targetTrack:generator:

   - parameter placement: Placement
   - parameter targetTrack: InstrumentTrack? = nil
   - parameter generator: MIDINoteGenerator
  */
  static func placeNew(placement: Placement,
           targetTrack: InstrumentTrack? = nil,
             generator: MIDINoteGenerator)
  {
    guard let track = targetTrack ?? MIDIDocumentManager.currentDocument?.sequence?.currentTrack else {
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
      Notification.DidAddNode.post(userInfo: [.AddedNode: midiNode, .AddedNodeTrack: track])
      logDebug("added node \(name)")

    } catch {
      logError(error)
    }
  }

  /**
   removeNode:

   - parameter node: MIDINode
  */
  static func removeNode(node: MIDINode) {
    guard node.parent === playerNode else { return }
    node.fadeOut(remove: true)
    Notification.DidRemoveNode.post()
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

// MARK: - Notification
extension MIDIPlayer {

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddNode, DidRemoveNode, DidSelectTool
    var object: AnyObject? { return MIDIPlayer.self }
    enum Key: String, NotificationKeyType { case AddedNode, AddedNodeTrack, SelectedTool }
  }

}

extension NSNotification {
  var addedNode: MIDINode? {
    return userInfo?[MIDIPlayer.Notification.Key.AddedNode.key] as? MIDINode
  }
  var addedNodeTrack: InstrumentTrack? {
    return userInfo?[MIDIPlayer.Notification.Key.AddedNodeTrack.key] as? InstrumentTrack
  }
  var selectedTool: Tool? {
    guard let rawValue = userInfo?[MIDIPlayer.Notification.Key.SelectedTool.key] as? Int else {
      return nil
    }
    return Tool(rawValue)
  }
}
