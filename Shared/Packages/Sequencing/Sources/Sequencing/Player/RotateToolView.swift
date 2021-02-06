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
        .foregroundColor(Color(#colorLiteral(red: 0.6816637516, green: 0.3820425868, blue: 0.2524854839, alpha: 1)))
      Image("rotate_arrow", bundle: Bundle.module)
        .renderingMode(.template)
        .foregroundColor(Color(#colorLiteral(red: 0.8856705427, green: 0.846001327, blue: 0.787083149, alpha: 1)))
    }
  }
}

// MARK: - RotateToolView_Previews

struct RotateToolView_Previews: PreviewProvider
{
  static var previews: some View
  {
    RotateToolView()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()
  }
}
