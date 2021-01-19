//
//  SoundFontButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import SoundFont

@available(iOS 14.0, *)
struct SoundFontButton: View {

  @State var soundFont: SoundFont2

    var body: some View {
      Button(action: {}) {
        soundFont.image
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
      .frame(width: 56, height: 56)
      .accentColor(.white)
    }
}

@available(iOS 14.0, *)
struct SoundFontButton_Previews: PreviewProvider {
    static var previews: some View {
      SoundFontButton(soundFont: SoundFont.bundledFonts[0])
          .previewLayout(.sizeThatFits)
          .preferredColorScheme(.dark)
          .padding()
    }
}
