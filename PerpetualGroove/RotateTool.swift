//
//  RotateTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/17/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class RotateTool: NodeAdjustmentTool, SecondaryControllerContentDelegate {//, ConfigurableToolType {

  var secondaryContent: SecondaryControllerContent {
    guard _secondaryContent == nil else { return _secondaryContent! }
    let storyboard = UIStoryboard(name: "Rotate", bundle: nil)
    let viewController = storyboard.instantiateInitialViewController() as! RotateViewController
    viewController.node = node
    viewController.didRotate = weakMethod(self, RotateTool.didRotate)
    return viewController
  }

  private func didRotate(rotation: CGFloat) {
    guard let node = node where node.initialTrajectory.angle != rotation else { return }
    let oldTrajectory = node.initialTrajectory
    let newTrajectory = node.initialTrajectory.rotateTo(rotation)
    MIDIPlayer.undoManager.registerUndoWithTarget(node) {
      node in
      node.initialTrajectory = oldTrajectory
      MIDIPlayer.undoManager.registerUndoWithTarget(node) { $0.initialTrajectory = newTrajectory }
    }
    adjustNode{ node.initialTrajectory.rotateToInPlace(rotation) }
  }

  /** didSelectNode */
  override func didSelectNode() {
    guard active else { return }
    MIDIPlayer.playerContainer?.presentContentForDelegate(self)
  }

}

final class RotateViewController: SecondaryContent {

  weak var node: MIDINode?

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    guard let node = node else { return }
    ball.tintColor = node.dispatch?.color.value
    arrow.tintColor = .quaternaryColor
    let angle = node.initialTrajectory.v.angle
    arrow.transform = CGAffineTransform(angle: angle)
    rotationGesture.rotation = angle
  }

  @IBOutlet private weak var ball:  TemplateImageView!
  @IBOutlet private weak var arrow: TemplateImageView!
  @IBOutlet private weak var rotationGesture: UIRotationGestureRecognizer!

  var didRotate: ((CGFloat) -> Void)?

  /**
   handleRotation:

   - parameter sender: UIRotationGestureRecognizer
  */
  @IBAction private func handleRotation(sender: UIRotationGestureRecognizer) {

    switch sender.state {
      case .Began:
        arrow.transform.rotation = sender.rotation
      case .Changed:
        arrow.transform.rotation = sender.rotation
        didRotate?(sender.rotation)

      case .Cancelled, .Failed: break
      case .Possible: break
      case .Ended: break
    }
  }

}