//
//  MIDIFileProtocols.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

// MARK: - The chunk protocol

/** Protocol for types that can produce a valid chunk for a MIDI file */
protocol Chunk : CustomStringConvertible {
  var type: Byte4 { get }
}

// MARK: - The track event protocol

/**  Protocol for types that produce data for a track event in a track chunk */
protocol TrackEvent: CustomStringConvertible {
  var time: CABarBeatTime { get set }
  var bytes: [Byte] { get }
}

// MARK: - The track type protocol

/** Protocol for types that provide a collection of `TrackEvent` values for a chunk and can produce that chunk */
protocol TrackType: CustomStringConvertible {
  var chunk: TrackChunk { get }
  var label: String { get }
  var time: BarBeatTime { get }
  var events: [TrackEvent] { get }
}

extension TrackType {

  /** Generates a MIDI file chunk from current track data */
  var chunk: TrackChunk {
    let nameEvent: TrackEvent = MetaEvent(data: .SequenceTrackName(name: label))
    let endEvent: TrackEvent  = MetaEvent(data: .EndOfTrack)
    return TrackChunk(events: [nameEvent] + events + [endEvent])
  }

}
