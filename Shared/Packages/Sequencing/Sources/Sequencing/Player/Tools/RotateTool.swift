//
//  RotateTool.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/9/21.
//
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class RotateTool: NodeSelectionTool
{
  /// Handler for rotation values reported by the tool's user interface.
  func didRotate(_ rotation: CGFloat)
  {
    // Check that there is a node selected and that the angle of its intial trajectory
    // does not equal `rotation`.
    guard let node = node, node.coordinator.initialTrajectory.angle != rotation
    else { return }

    // Store the original initial trajectory.
    let oldTrajectory = node.coordinator.initialTrajectory

    // Calculate the modified trajectory whose angle is `rotation`.
    let newTrajectory = oldTrajectory.withAngle(rotation)

    // Register an action for undoing the changes to the node's intial trajectory.
    player.undoManager.registerUndo(withTarget: node)
    {
      [self] node in

      node.coordinator.initialTrajectory = oldTrajectory

      // Register an action for redoing the changes to the node's intial trajectory.
      player.undoManager.registerUndo(withTarget: node)
      {
        $0.coordinator.initialTrajectory = newTrajectory
      }
    }

    // Actually change node's initial trajectory.
    adjustNode { node.coordinator.initialTrajectory = newTrajectory }
  }

}
