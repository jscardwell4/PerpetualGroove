//
//  SoundFontRow.swift
//
//
//  Created by Jason Cardwell on 1/18/21.
//
import SwiftUI
import Common

// MARK: - SoundFontRow

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoundFontRow: View
{
  @State var soundFont: AnySoundFont

  var body: some View
  {
    HStack
    {
      Spacer()
      Text(soundFont.displayName)
        .font(Font.custom("EvelethLight", size: 24))
        .foregroundColor(Color(#colorLiteral(red: 0.7289999723, green: 0.7020000219, blue: 0.6629999876, alpha: 1)))
      Spacer()
        .frame(width: 20)
      soundFont.image
        .frame(width: 54, height: 54, alignment: .center)
        .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
    }
  }
}

// MARK: - SoundFontRow_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoundFontRow_Previews: PreviewProvider
{
  static var previews: some View
  {
    SoundFontRow(soundFont: SoundFont.orchestral)
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()
      .fixedSize()
  }
}
