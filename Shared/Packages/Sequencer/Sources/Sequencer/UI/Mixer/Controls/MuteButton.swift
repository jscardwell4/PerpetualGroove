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

@available(iOS 14.0, *)
struct MuteButton: View
{

  let isEngaged: Bool
  let isEnabled: Bool

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
                       bundle: Bundle.module))
  }
}

// MARK: - MuteButton_Previews

@available(iOS 14.0, *)
struct MuteButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    MuteButton(isEngaged: false, isEnabled: false)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
