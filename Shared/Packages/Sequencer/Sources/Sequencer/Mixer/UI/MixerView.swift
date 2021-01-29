//
//  MixerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import MoonDev
import SoundFont
import SwiftUI

// MARK: - MixerView

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct MixerView: View
{
  @EnvironmentObject var sequence: Sequence
  @EnvironmentObject var sequencer: Controller

  @State private var soloIds: Set<UUID> = []

  public var body: some View
  {
    HStack(spacing: 20)
    {
      MainBus().environmentObject(sequencer.audioEngine)
      ForEach(sequence.instrumentTracks)
      {
        TrackBus(isSoloed: self.soloIds.contains($0.id),
                 isForceMuted: !(self.soloIds.isEmpty
                                  || self.soloIds.contains($0.id))).environmentObject($0)
      }
      AddTrackButton()
    }
    .onPreferenceChange(TrackBus.SoloPreferenceKey.self)
    {
      self.soloIds = $0
      //      [self] uuids in
      //      logi("<\(#fileID) \(#function)> uuids = \(uuids)")
      //      switch (uuids.isEmpty, uuids.contains(track.id))
      //      {
      //        case (true, _):
      //          isForceMuted = false
      //          track.isMute = isMuted
      //
      //        case (false, true):
      //          isForceMuted = false
      //          track.isMute = false
      //          isMuted = false
      //
      //        case (false, false):
      //          isForceMuted = true
      //          track.isMute = true
      //      }
    }
  }

  public init() {}
}
