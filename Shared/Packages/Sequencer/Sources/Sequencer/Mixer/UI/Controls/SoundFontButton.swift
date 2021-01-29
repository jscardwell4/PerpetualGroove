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

/// A button for manipulating the sound font used by a track's instrument.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoundFontButton: View
{
  /// The bus for which this button serves as a control.
  @EnvironmentObject var bus: Bus

  var body: some View
  {
    Button
    {
      logw("<\(#fileID) \(#function)> button action not yet implemented.")
    }
    label: { bus.image }
      .frame(minHeight: 44)
  }
}
