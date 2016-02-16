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

final class GeneratorTool: NodeSelectionTool, ConfigurableToolType {

  override var active: Bool  {
    didSet {
      logDebug("[\(mode)] oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue && active && mode == .New else { return }
      MIDIPlayer.playerContainer?.presentControllerForTool(self)
    }
  }

  enum Mode { case New, Existing }
  let mode: Mode

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()


  /**
   initWithPlayerNode:mode:

   - parameter playerNode: MIDIPlayerNode
   - parameter mode: Mode
  */
  init(playerNode: MIDIPlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
    receptionist.observe(MIDIPlayer.Notification.DidAddNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, GeneratorTool.didAddNode))
        receptionist.observe(MIDIPlayer.Notification.DidRemoveNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, GeneratorTool.didRemoveNode))

  }

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
    guard let node = node, let idx = Array(nodes.generate()).indexOf(node) else { return }
    self.node = idx + 1 < nodes.endIndex ? nodes[idx + 1] : nodes[nodes.startIndex]
  }

  /** nextNode */
  private func nextNode() {
    let nodes = player.midiNodes
    guard let node = node, let idx = Array(nodes.generate()).indexOf(node) else { return }
    self.node = idx - 1 >= nodes.startIndex ? nodes[idx - 1] : nodes[nodes.endIndex - 1]
  }

  var isShowingViewController: Bool { return _viewController != nil }

  private weak var _viewController: GeneratorViewController?
  var viewController: UIViewController {
    guard _viewController == nil else { return _viewController! }

    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let viewController: GeneratorViewController

    switch mode {

      case .Existing:
        guard let node = node else {
          fatalError("cannot show view controller when no node has been chosen")
        }
        viewController = storyboard.instantiateViewControllerWithIdentifier("GeneratorWithArrows")
                           as! GeneratorViewController
        viewController.loadGenerator(node.generator)
        viewController.didChangeGenerator = { [weak self] in self?.node?.generator = $0 }
        viewController.previousAction = weakMethod(self, GeneratorTool.previousNode)
        viewController.nextAction = weakMethod(self, GeneratorTool.nextNode)

      case .New:
        viewController = storyboard.instantiateViewControllerWithIdentifier("Generator")
                           as! GeneratorViewController
        viewController.didChangeGenerator = {
          MIDIPlayer.addTool?.generator = $0
          Sequencer.sequence?.currentTrack?.instrument.playNote($0)
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
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard mode == .Existing else { return }
    super.touchesBegan(touches, withEvent: event)
  }

  /** didSelectNode */
  override func didSelectNode() {
    guard active && mode == .Existing && node != nil else { return }
    MIDIPlayer.playerContainer?.presentControllerForTool(self)
  }
}
