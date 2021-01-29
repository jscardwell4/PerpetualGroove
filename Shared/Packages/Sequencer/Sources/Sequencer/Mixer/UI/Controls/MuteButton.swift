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
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct MuteButton: View
{

  let isDisabled: Bool

  let isMute: Bool

  @Binding var isMuted: Bool

  private var tintColor: Color
  {
    let prefix: String

    switch (isDisabled, isMute, isMuted)
    {
      case (true, true, _):
        prefix = "disabledEngaged"
      case (false, true, _):
        prefix = "engaged"
      default:
        prefix = "disengaged"
    }

    return Color("\(prefix)TintColor", bundle: .module)
  }

  var body: some View
  {
    Button
    {
      self.isMuted.toggle()
    }
    label:
    {
      Text("Mute").evelethFont(family: .normal, weigth: .light, size: 14)
    }
    .frame(width: 68, height: 14)
    .accentColor(tintColor)
    .disabled(isDisabled)
  }
}
