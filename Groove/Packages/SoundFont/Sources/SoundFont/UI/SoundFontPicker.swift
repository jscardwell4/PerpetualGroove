//
//  SoundFontPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MoonDev
import SwiftUI

// MARK: - SoundFontPicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct SoundFontPicker: View
{
  @Binding public var selection: Int

  public var body: some View
  {
    Picker("SoundFontPicker", selection: $selection)
    {
      ForEach(0 ..< SoundFont.bundledFonts.count, id: \.self)
      {index in
        Row(soundFont: SoundFont.bundledFonts[index])
          .tag(index)
      }
    }
  }

  public init(selection: Binding<Int>) { _selection = selection }

  struct Row: View
  {
    let soundFont: AnySoundFont

    var body: some View
    {
      HStack
      {
        Spacer()
        Text(soundFont.displayName)
          .font(Font.custom("EvelethLight", size: 24))
          .foregroundColor(Color(#colorLiteral(red: 0.7289999723, green: 0.7020000219, blue: 0.6629999876, alpha: 1)))
          .padding(.trailing, 8)
        soundFont.image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 24, alignment: .center)
          .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
          .padding(.trailing, 24)
      }
    }
  }
}

// MARK: - SoundFontPicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoundFontPicker_Previews: PreviewProvider
{
  @State static var selection: Int = 1
  static var previews: some View
  {
    SoundFontPicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .frame(minWidth: 600)
      .fixedSize()
  }
}
