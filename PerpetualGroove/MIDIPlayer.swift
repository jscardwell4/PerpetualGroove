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

  static private var toolViewController: UIViewController?

  static func dismissToolViewController() {
    guard let viewController = toolViewController else { return }
    playerViewController?.dismissToolViewController(viewController)
  }

  /** presentToolViewController */
  static func presentToolViewController() {
    guard toolViewController == nil,
      let viewController = (currentTool.toolType as? ConfigurableToolType)?.viewController else { return }

    toolViewController = viewController
    playerViewController?.presentToolViewController(viewController)
    (currentTool.toolType as? ConfigurableToolType)?.didShowViewController(viewController)
  }


  static var currentTool: Tool = .None {
    willSet {
      guard currentTool != newValue && toolViewController != nil else { return }
      dismissToolViewController()
    }
    didSet {
      logDebug("oldValue = \(oldValue)  currentTool = \(currentTool)")
      guard currentTool != oldValue else { return }
      oldValue.toolType?.active = false
      currentTool.toolType?.active = true
    }
  }

  /**
   didDismissViewController:

   - parameter viewController: MIDIPlayerViewController
  */
  static func didDismissViewController(viewController: UIViewController) {
    guard viewController === toolViewController else { return }
    (currentTool.toolType as? ConfigurableToolType)?.didHideViewController(viewController)
    toolViewController = nil
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

extension MIDIPlayerViewController {

  /** dismissToolViewController */
  private func dismissToolViewController(viewController: UIViewController) {
    guard viewController.parentViewController === self else { return }
    viewController.willMoveToParentViewController(nil)
    viewController.removeFromParentViewController()
    if viewController.isViewLoaded() { viewController.view.removeFromSuperview() }
    blurView.hidden = true
    MIDIPlayer.didDismissViewController(viewController)
  }

  /** presentToolViewController */
  private func presentToolViewController(viewController: UIViewController) {
    guard viewController.parentViewController == nil else { return }
    addChildViewController(viewController)
    let controllerView = viewController.view
    controllerView.translatesAutoresizingMaskIntoConstraints = false
    controllerView.backgroundColor = nil
    blurView.contentView.insertSubview(controllerView, atIndex: 0)
    view.constrain(
      controllerView.left => playerView.left + 20,
      controllerView.right => playerView.right - 20,
      controllerView.top => playerView.top + 20,
      controllerView.bottom => playerView.bottom - 20
    )
    viewController.didMoveToParentViewController(self)
    blurView.hidden = false
  }

}

protocol ToolType: class {
  var active: Bool { get set }
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
}

protocol ConfigurableToolType: ToolType {
  func didShowViewController(viewController: UIViewController)
  func didHideViewController(viewController: UIViewController)
  var viewController: UIViewController { get }
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

    init(_ toolType: ToolType?) {
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
    var object: AnyObject? { return MIDIPlayer.self }
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
