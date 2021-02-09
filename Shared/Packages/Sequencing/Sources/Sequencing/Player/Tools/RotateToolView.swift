//
//  RotateToolView.swift
//
//
//  Created by Jason Cardwell on 1/18/21.
//
import Common
import SwiftUI

// MARK: - RotateToolView

/// A view for providing visual feedback for the rotate tool.
struct RotateToolView: View
{
  /// The view's body is composed of an image of a node and the image
  /// of an arrow indicating the edited node's trajectory.
  /// - TODO: Implement rotation gesture.
  var body: some View
  {
    ZStack
    {
      Image("rotate_ball", bundle: Bundle.module)
        .renderingMode(.template)
        .foregroundColor(.highlightColor)
      Image("rotate_arrow", bundle: Bundle.module)
        .renderingMode(.template)
        .foregroundColor(.primaryColor1)
    }
  }
}

