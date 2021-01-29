//
//  SoundFontButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import func MoonDev.logw
import SoundFont
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoundFontButton: View
{
  @EnvironmentObject var track: InstrumentTrack

  var body: some View
  {
    Button
    {
      logw("<\(#fileID) \(#function)> button action not yet implemented.")
    }
    label:
    {
      track.instrument.soundFont.image
    }
    .frame(minHeight: 44)
  }
}
