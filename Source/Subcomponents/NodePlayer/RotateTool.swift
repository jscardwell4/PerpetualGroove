//
//  RotateTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/17/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import UIKit
import Common

/// A tool for adjusting the intial angle of a midi node.
public final class RotateTool: PresentingNodeSelectionTool {

  /// Overridden to return an instance of `RotateViewController` for manipulating the selected node.
  public override var secondaryContent: SecondaryContent {

    guard _secondaryContent == nil else { return _secondaryContent! }

    let ballColor = node?.dispatch?.color.value ?? .lightGray
    let initialAngle = node?.initialTrajectory.angle ?? 0

    return RotateViewController.viewController(withBallColor: ballColor,
                                               initialAngle: initialAngle,
                                               didRotate: weakCapture(of: self, block:RotateTool.didRotate))

  }

  /// Handler for rotation values reported by the tool's user interface.
  private func didRotate(_ rotation: CGFloat) {

    // Check that there is a node selected and that the angle of its intial trajectory 
    // does not equal `rotation`.
    guard let node = node,
          node.initialTrajectory.angle != rotation else { return }

    // Store the original initial trajectory.
    let oldTrajectory = node.initialTrajectory


    // Calculate the modified trajectory whose angle is `rotation`.
    let newTrajectory = oldTrajectory.withAngle(rotation)

    // Register an action for undoing the changes to the node's intial trajectory.
    MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
      node in

      node.initialTrajectory = oldTrajectory

      // Register an action for redoing the changes to the node's intial trajectory.
      MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
        $0.initialTrajectory = newTrajectory
      }

    }

    // Actually change node's initial trajectory.
    adjustNode { node.initialTrajectory = newTrajectory }

  }

}

/// `UIViewController` subclass providing an interface for specifying an angle of rotation.
public final class RotateViewController: UIViewController, SecondaryContent {

  /// Returns a new instance of `RotateViewController` instantiated from `Rotate.storyboard`
  /// configured with the specified ball color, initial angle, and rotation callback.
  fileprivate static func viewController(withBallColor color: UIColor,
                                         initialAngle: CGFloat,
                                         didRotate: ((CGFloat) -> Void)?) -> RotateViewController
  {

    let storyboard = UIStoryboard(name: "Rotate", bundle: nil)
    let viewController = storyboard.instantiateInitialViewController() as! RotateViewController

    viewController.ballColor = color
    viewController.initialAngle = initialAngle
    viewController.didRotate = didRotate

    return viewController

  }

  /// The color to tint the ball representing the midi node being adjusted.
  public var ballColor: UIColor = .lightGray

  /// The initial angle used to setup the arrow's transform and the rotation gesture.
  public var initialAngle: CGFloat = 0

  /// Actions supported by the controller. The default is to support the `cancel` and `confirm` actions.
  public var supportedActions: SecondaryControllerContainer.SupportedActions = [.cancel, .confirm]


  /// Overridden to configure colors and angles of rotation.
  public override func viewWillAppear(_ animated: Bool) {

    super.viewWillAppear(animated)

    ball.tintColor = ballColor
    arrow.tintColor = .quaternaryColor

    arrow.transform = CGAffineTransform(rotationAngle: initialAngle)
    rotationGesture.rotation = initialAngle

  }

  /// The image representing the midi node being adjusted.
  @IBOutlet private weak var ball:  TemplateImageView!

  /// The arrow indicating the angle of rotation.
  @IBOutlet private weak var arrow: TemplateImageView!

  /// The gesture used to change the angle of rotation.
  @IBOutlet private weak var rotationGesture: UIRotationGestureRecognizer!

  /// The callback invoked when `rotationGesture` indicates a change to the angle of rotation.
  /// - Parameter rotation: The new angle of rotation.
  public var didRotate: ((_ rotation: CGFloat) -> Void)?

  /// Handler for `rotationGesture`.
  @IBAction
  private func handleRotation(_ sender: UIRotationGestureRecognizer) {

    switch sender.state {

      case .began:
        // The gesture has just begun. Synchronize the arrow's transform with the gesture's rotation.

        arrow.transform.rotation = sender.rotation

      case .changed:
        // The gesture's rotation has been updated. Synchronize the arrow's transform with the 
        // gesture's rotation and invoke the callback using the updated value.

        arrow.transform.rotation = sender.rotation
        didRotate?(sender.rotation)

      case .cancelled, .failed, .possible, .ended:
        // Nothing to do since there is either nothing to report or the callback has already been
        // invoked when the gesture reported the changed rotation.

        break

      @unknown default:
        break
    }
    
  }

}
