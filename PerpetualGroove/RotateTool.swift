//
//  RotateTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/17/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class RotateTool: NodeAdjustmentTool {//, ConfigurableToolType {

  private weak var _viewController: RotateViewController?

  var secondaryContent: SecondaryContent {
    guard _viewController == nil else { return _viewController! }
    let storyboard = UIStoryboard(name: "Rotate", bundle: nil)
    let viewController = storyboard.instantiateInitialViewController() as! RotateViewController
    viewController.node = node
    return viewController
  }

  var isShowingContent: Bool { return _viewController != nil }

  func didShowContent(content: SecondaryContent) {
    _viewController = content as? RotateViewController
  }

  func didHideContent(viewController: SecondaryContent) {

  }

  /** didSelectNode */
  override func didSelectNode() {
    guard active else { return }
    MIDIPlayer.playerContainer?.presentContentForTool(self)
  }

}

final class RotateViewController: SecondaryContent {

  weak var node: MIDINode?

  private weak var tool: RotateTool?

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
        tool?.adjustNode{ node?.initialTrajectory.rotateToInPlace(sender.rotation) }

      case .Cancelled, .Failed: break
      case .Possible: break
      case .Ended: break
    }
  }

}