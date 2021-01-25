//
//  ColorButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev
import SwiftUI

// MARK: - ColorButton

/// A view for displaying the color associated with an instrument track and
/// for selecting a track as the current track.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ColorButton: View
{
  @Binding var color: Track.Color

  @State var isSelected: Bool

  static let buttonSize = CGSize(width: 68, height: 14)

  var body: some View
  {
    Button
    {
      logi("\(#fileID) \(#function) button action not yet implemented.")
    }
    label:
    {
      Image("color_swatch\(isSelected ? "-selected" : "")", bundle: .module)
    }
    .accentColor(color.color)
    .frame(width: ColorButton.buttonSize.width,
           height: ColorButton.buttonSize.height,
           alignment: .center)
  }
}

// MARK: - ColorButton_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ColorButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    ColorButton(color: .constant(.muddyWaters), isSelected: false)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
