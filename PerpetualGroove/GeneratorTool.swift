//
//  GeneratorTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class GeneratorTool: ConfigurableToolType {

  unowned let player: MIDIPlayerNode

  var active = false {
    didSet {
      logDebug("[\(mode)] oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue && active && mode == .New else { return }
      MIDIPlayer.playerContainer?.presentControllerForTool(self)
    }
  }

  let mode: Mode

  private weak var node: MIDINode? {
    didSet {
      guard node != oldValue else { return }

      let name = "generatorToolLighting"

      if let node = node {
        guard node.childNodeWithName(name) == nil else { fatalError("node already lit") }

        let light = SKLightNode()
        light.name = name
        light.categoryBitMask = 1
        node.addChild(light)
        node.lightingBitMask = 1
        node.runAction(SKAction.colorizeWithColor(.whiteColor(), colorBlendFactor: 1, duration: 0.25))
      }

      if let oldNode = oldValue {
        oldNode.childNodeWithName(name)?.removeFromParent()
        oldNode.lightingBitMask = 0
        if let track = oldNode.track {
          oldNode.runAction(SKAction.colorizeWithColor(track.color.value, colorBlendFactor: 1, duration: 0.25))
        }
      }

    }
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()


  init(playerNode: MIDIPlayerNode, mode: Mode) {
    player = playerNode
    self.mode = mode
    receptionist.observe(MIDIPlayer.Notification.DidAddNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, GeneratorTool.didAddNode))
        receptionist.observe(MIDIPlayer.Notification.DidRemoveNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, GeneratorTool.didRemoveNode))

  }

  private typealias NodeRef = Weak<MIDINode>

  /**
   didAddNode:

   - parameter notification: NSNotification
  */
  private func didAddNode(notification: NSNotification) {
    guard active && mode == .Existing && player.midiNodes.count == 2 else { return }
    _viewController?.navigationArrows = [.Previous, .Next]
  }

  /**
   didRemoveNode:

   - parameter notification: NSNotification
   */
  private func didRemoveNode(notification: NSNotification) {
    guard active && mode == .Existing && player.midiNodes.count < 2 else { return }
    _viewController?.navigationArrows = [.None]
  }

  /** previousNode */
  private func previousNode() {
    let nodes = player.midiNodes
    guard let node = node, var idx = nodes.indexOf(node) else { return }
    self.node = ++idx < nodes.endIndex ? nodes[idx] : nodes[nodes.startIndex]
  }

  /** nextNode */
  private func nextNode() {
    let nodes = player.midiNodes
    guard let node = node, var idx = nodes.indexOf(node) else { return }
    self.node = --idx >= nodes.startIndex ? nodes[idx] : nodes[nodes.endIndex - 1]
  }

  var isShowingViewController: Bool { return _viewController != nil }

  private weak var _viewController: GeneratorViewController?
  var viewController: UIViewController {
    guard _viewController == nil else { return _viewController! }

    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let viewController: GeneratorViewController

    switch mode {

      case .Existing:
        guard let node = node else { fatalError("cannot show view controller when no node has been chosen") }
        viewController = storyboard.instantiateViewControllerWithIdentifier("GeneratorWithArrows") as! GeneratorViewController
        viewController.loadGenerator(node.noteGenerator)
        viewController.didChangeGenerator = { [weak self] in self?.node?.noteGenerator = $0 }
        viewController.previousAction = weakMethod(self, GeneratorTool.previousNode)
        viewController.nextAction = weakMethod(self, GeneratorTool.nextNode)

      case .New:
        viewController = storyboard.instantiateViewControllerWithIdentifier("Generator") as! GeneratorViewController
        viewController.didChangeGenerator = {
          MIDIPlayer.addTool?.noteGenerator = $0
          MIDIDocumentManager.currentDocument?.sequence?.currentTrack?.instrument.playNote($0)
        }

    }

    viewController.navigationArrows = player.midiNodes.count > 1 ? [.Previous, .Next] : [.None]
    return viewController
  }

  /** didShowViewController */
  func didShowViewController(viewController: UIViewController) {
    _viewController = viewController as? GeneratorViewController
  }

  /** didHideViewController */
  func didHideViewController(viewController: UIViewController) {
    guard active && viewController === _viewController else { return }
    switch mode {
      case .New: if MIDIPlayer.currentTool.toolType === self { MIDIPlayer.currentTool = .None }
      case .Existing: node = nil
    }
  }

  /**
   nodeAtPoint:

   - parameter point: CGPoint

   - returns: [Weak<MIDINode>]
   */
  private func nodeAtPoint(point: CGPoint?) -> MIDINode? {
    guard let point = point where player.containsPoint(point) else { return nil }
    return player.nodesAtPoint(point).flatMap({$0 as? MIDINode}).first
  }


  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && mode == .Existing && node == nil else { return }
    node = nodeAtPoint(touches.first?.locationInNode(player))
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {}

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
  */
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) { node = nil }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard active && mode == .Existing && node != nil else { return }
    MIDIPlayer.playerContainer?.presentControllerForTool(self)
  }

}

extension GeneratorTool {
  enum Mode { case New, Existing }
}