//
//  MuteButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - MuteButton

struct MuteButton: View
{
  @Binding var isEngaged: Bool

  @Binding var isEnabled: Bool

  var body: some View
  {
    Button(action: {})
    {
      Text("Mute")
        .font(.style(FontStyle(font: EvelethFont.light, size: 14, style: .title)))
    }
    .frame(width: 68, height: 14)
    .accentColor(Color(isEngaged && !isEnabled
                        ? "disabledEngagedTintColor"
                        : (isEnabled && !isEngaged
                            ? "disengagedTintColor"
                            : (isEnabled
                                ? "engagedTintColor"
                                : "disabledTintColor")),
                       bundle: bundle))
  }
}

// MARK: - MuteButton_Previews

struct MuteButton_Previews: PreviewProvider
{
  @State static var isEngaged: Bool = false
  @State static var isEnabled: Bool = false
  static var previews: some View
  {
    MuteButton(isEngaged: $isEngaged, isEnabled: $isEnabled)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
