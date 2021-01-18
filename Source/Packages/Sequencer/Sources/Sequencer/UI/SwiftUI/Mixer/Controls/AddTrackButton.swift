//
//  AddTrackButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import Common

// MARK: - AddTrackButton

struct AddTrackButton: View
{
  var body: some View
  {
    Button(action: {})
    {
      VStack
      {
      Spacer()
      Image("add-selected", bundle: bundle)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 34, alignment: .center)
        .accentColor(.primaryColor1)
        .padding()
      Spacer()
      }
    }
  }
}

// MARK: - AddTrackButton_Previews

struct AddTrackButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    AddTrackButton()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
  }
}
