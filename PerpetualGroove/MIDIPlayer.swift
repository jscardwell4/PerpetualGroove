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
      existingGeneratorTool = GeneratorTool(playerNode: node, mode: .Existing)
      newGeneratorTool = GeneratorTool(playerNode: node, mode: .New)
      currentTool = .None
    }
  }

  static private(set) var addTool: AddTool?
  static private(set) var removeTool: RemoveTool?
  static private(set) var existingGeneratorTool: GeneratorTool?
  static private(set) var newGeneratorTool: GeneratorTool?

  static var currentTool: Tool = .None {
    didSet {
      logDebug("oldValue = \(oldValue)  currentTool = \(currentTool)")
      guard currentTool != oldValue else { return }
      oldValue.toolType?.active = false
      currentTool.toolType?.active = true

      if let tools = playerViewController?.tools
        where currentTool == .None && tools.selectedSegmentIndex != ImageSegmentedControl.NoSegment
      {
        tools.selectedSegmentIndex = ImageSegmentedControl.NoSegment
      }
    }
  }

  static private var toolControllerIndex: [ObjectIdentifier:Tool] = [:]

  /**
   presentViewController:forTool:

   - parameter viewController: UIViewController
   - parameter tool: ToolTyp
  */
  static func presentViewController(viewController: UIViewController, forTool tool: ToolType) {
    guard currentTool.toolType === tool else { return }
    playerViewController?.toolViewController = viewController
    toolControllerIndex[ObjectIdentifier(viewController)] = Tool(tool)
    currentTool.toolType?.didShowViewController()
  }

  /**
   didDismissToolControllerForPlayerViewController:

   - parameter controller: MIDIPlayerViewController
  */
  static func didDismissViewController(controller: UIViewController) {
    toolControllerIndex.removeValueForKey(ObjectIdentifier(controller))?.toolType?.didHideViewController()
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

  func didShowViewController()
  func didHideViewController()
}

// MARK: - Tool
extension MIDIPlayer {
  enum Tool: Int {
    case None = -1, NewGenerator, Add, Remove, ExistingGenerator

    var toolType: ToolType? {
      switch self {
        case .None:              return nil
        case .NewGenerator:      return MIDIPlayer.newGeneratorTool
        case .Add:               return MIDIPlayer.addTool
        case .Remove:            return MIDIPlayer.removeTool
        case .ExistingGenerator: return MIDIPlayer.existingGeneratorTool
      }
    }

    var isCurrentTool: Bool { return MIDIPlayer.currentTool == self }

    private init(_ toolType: ToolType?) {
      switch toolType {
        case let t? where MIDIPlayer.newGeneratorTool === t:      self = .NewGenerator
        case let t? where MIDIPlayer.addTool === t:               self = .Add
        case let t? where MIDIPlayer.removeTool === t:            self = .Remove
        case let t? where MIDIPlayer.existingGeneratorTool === t: self = .ExistingGenerator
        default:                                                  self = .None
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
