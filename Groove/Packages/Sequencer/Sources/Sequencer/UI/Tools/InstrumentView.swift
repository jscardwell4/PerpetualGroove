//
//  InstrumentView.swift
//
//
//  Created by Jason Cardwell on 1/18/21.
//
import Common
import MoonDev
import SwiftUI
import CoreText
import SoundFont

// MARK: - InstrumentView

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct InstrumentView: View
{
  /*
   Eveleth light 13
   SoundFontSelector
   ProgramSelector
   Channel Stepper
   highlighted tint #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
   normal tint #colorLiteral(red: 0.8745099902, green: 0.8274499774, blue: 0.7607799768, alpha: 1)
   */

  @State var soundFontSelection: Int = 1

  private static let labelFont = Font.custom("EvelethLight", size: 24)

  var body: some View
  {
    VStack
    {
      HStack
      {
        Text("Sound Set")
          .foregroundColor(Color(#colorLiteral(red: 0.5725490451, green: 0.5294117928, blue: 0.470588237, alpha: 1)))
          .font(InstrumentView.labelFont)
        Spacer()
        SoundFontPicker(selection: $soundFontSelection)
          .frame(minWidth: 600)
      }
      .padding()
      HStack
      {
        Text("Program")
          .foregroundColor(Color(#colorLiteral(red: 0.5725490451, green: 0.5294117928, blue: 0.470588237, alpha: 1)))
          .font(InstrumentView.labelFont)
        Spacer()
        Text("Program Picker")
      }
      .padding()
      HStack
      {
        Text("Channel")
          .foregroundColor(Color(#colorLiteral(red: 0.5725490451, green: 0.5294117928, blue: 0.470588237, alpha: 1)))
          .font(InstrumentView.labelFont)
        Spacer()
        Text("Channel Picker")
      }
      .padding()
    }
  }
}

// MARK: - InstrumentView_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct InstrumentView_Previews: PreviewProvider
{
  static var previews: some View
  {
    InstrumentView()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
