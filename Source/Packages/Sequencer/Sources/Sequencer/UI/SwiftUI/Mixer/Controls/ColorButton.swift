//
//  ColorButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - ColorButton

/// A view for displaying the color associated with an instrument track and
/// for selecting a track as the current track.
@available(iOS 14.0, *)
struct ColorButton: View
{

  @State var color: Track.Color

  @State var isSelected: Bool

  private static let normalImage = Image("color_swatch", bundle: Bundle.module)
  private static let selectedImage = Image("color_swatch-selected", bundle: Bundle.module)

  var body: some View
  {
    Button(action: {}) {
      isSelected ? ColorButton.selectedImage : ColorButton.normalImage
    }
    .accentColor(Color(color.value))
    .frame(width: 68, height: 14)
  }
}

// MARK: - ColorButton_Previews

@available(iOS 14.0, *)
struct ColorButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    ColorButton(color: .muddyWaters, isSelected: false)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
