//
//  RotateTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/17/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import UIKit

final class RotateTool: PresentingNodeAdjustmentTool {

  override var secondaryContent: SecondaryControllerContent {
    guard _secondaryContent == nil else { return _secondaryContent! }

    return RotateViewController.viewController(withNode: node, didRotate: weakMethod(self, RotateTool.didRotate))
  }

  fileprivate func didRotate(_ rotation: CGFloat) {
    guard let node = node , node.initialTrajectory.angle != rotation else { return }
    let oldTrajectory = node.initialTrajectory
    let newTrajectory = node.initialTrajectory.rotatedTo(angle: rotation)
    MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
      node in
      node.initialTrajectory = oldTrajectory
      MIDINodePlayer.undoManager.registerUndo(withTarget: node) { $0.initialTrajectory = newTrajectory }
    }
    adjustNode{ node.initialTrajectory.formRotatedTo(angle: rotation) }
  }

  override func didSelectNode() {
    guard active else { return }
    MIDINodePlayer.playerContainer?.presentContent(for: self)
  }

}

final class RotateViewController: UIViewController, SecondaryControllerContent {

  fileprivate static func viewController(withNode node: MIDINode?,
                                         didRotate: ((CGFloat) -> Void)?) -> RotateViewController
  {
    let storyboard = UIStoryboard(name: "Rotate", bundle: nil)
    let viewController = storyboard.instantiateInitialViewController() as! RotateViewController
    viewController.node = node
    viewController.didRotate = didRotate
    return viewController
  }

  weak var node: MIDINode?

  var supportedActions: SecondaryControllerContainer.SupportedActions = [.cancel, .confirm]

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    guard let node = node else { return }

    ball.tintColor = node.dispatch?.color.value
    arrow.tintColor = .quaternaryColor

    let angle = node.initialTrajectory.v.angle
    arrow.transform = CGAffineTransform(rotationAngle: angle)
    rotationGesture.rotation = angle
  }

  @IBOutlet private weak var ball:  TemplateImageView!
  @IBOutlet private weak var arrow: TemplateImageView!
  @IBOutlet private weak var rotationGesture: UIRotationGestureRecognizer!

  var didRotate: ((CGFloat) -> Void)?

  @IBAction private func handleRotation(_ sender: UIRotationGestureRecognizer) {

    switch sender.state {

      case .began:
        arrow.transform.rotation = sender.rotation

      case .changed:
        arrow.transform.rotation = sender.rotation
        didRotate?(sender.rotation)

      case .cancelled, .failed, .possible, .ended:
        break
    }
    
  }

}
