//
//  SoloButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - SoloButton

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoloButton: View
{
  @Binding var isEngaged: Bool

  var body: some View
  {
    Button(action: { self.isEngaged.toggle() })
    {
      Text("Solo")
        .font(.style(FontStyle(font: EvelethFont.light, size: 14, style: .title)))
    }
    .frame(width: 68, height: 14)
    .accentColor(Color(isEngaged
        ? "engagedTintColor"
        : "disengagedTintColor",
      bundle: Bundle.module))
  }
}

// MARK: - SoloButton_Previews

@available(iOS 14.0, *)
struct SoloButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    SoloButton(isEngaged: .constant(false))
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
