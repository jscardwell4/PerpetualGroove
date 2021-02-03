//
//  AddTrackButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import func MoonDev.logw
import SwiftUI

// MARK: - AddTrackButton

/// A simple button for creating new tracks in the current sequence.
struct AddTrackButton: View
{
  /// The view's body is composed of a single button.
  var body: some View
  {
    Button
    {
      logw("<\(#fileID) \(#function)> Add track action not yet implemented.")
    }
    label:
    {
      VStack
      {
        Spacer()
        Image("add-selected", bundle: .module).accentColor(.primaryColor1).padding(10)
        Spacer()
      }
    }
  }
}
