//
//  FontPreviews.swift
//
//
//  Created by Jason Cardwell on 1/18/21.
//
import Foundation
import SwiftUI

// MARK: - FontPreview

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct FontPreview: View
{
  let font: AnySoundFont
  var body: some View
  {
    HStack
    {
      Spacer()
      Text(font.displayName)
        .font(Font.custom("EvelethSlantRegular", size: 34))
        .foregroundColor(Color(#colorLiteral(red: 0.7289999723, green: 0.7020000219, blue: 0.6629999876, alpha: 1)))
      Spacer()
        .frame(width: 44)
      font.image
        .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
    }
    .padding()
  }
}

// MARK: - FontPreview_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct FontPreview_Previews: PreviewProvider
{
  static var previews: some View
  {
    VStack
    {
      FontPreview(font: SoundFont.bundledFonts[0])
      FontPreview(font: SoundFont.bundledFonts[1])
      FontPreview(font: SoundFont.bundledFonts[2])
      FontPreview(font: SoundFont.bundledFonts[3])
      FontPreview(font: SoundFont.bundledFonts[4])
      FontPreview(font: SoundFont.bundledFonts[5])
      FontPreview(font: SoundFont.bundledFonts[6])
    }
    .preferredColorScheme(.dark)
    .previewLayout(.sizeThatFits)
    .fixedSize()
  }
}
