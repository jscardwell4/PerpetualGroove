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
  @EnvironmentObject var track: InstrumentTrack

  private var isDisabled: Bool { track.isForceMuted || track.isSoloed }

  private var isEngaged: Bool { track.isMute }

  private var tintColor: Color
  {
    let prefix: String

    switch (isEngaged, isDisabled)
    {
      case (true, true):
        prefix = "disabledEngaged"
      case (false, true):
        prefix = track.isSoloed ? "disengaged" : "engaged"
      case (true, false):
        prefix = "engaged"
      case (false, false):
        prefix = "disengaged"
    }

    return Color("\(prefix)TintColor", bundle: .module)
  }

  var body: some View
  {
    Button(action: { track.isMuted.toggle() })
    {
      Text("Mute").evelethFont(family: .normal, weigth: .light, size: 14)
    }
    .frame(width: 68, height: 14)
    .accentColor(tintColor)
    .disabled(isDisabled)
  }
}
