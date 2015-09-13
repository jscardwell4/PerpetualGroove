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
protocol MIDIChunk : CustomStringConvertible {
  var type: Byte4 { get }
}

// MARK: - The track event protocol

/**  Protocol for types that produce data for a track event in a track chunk */
protocol MIDITrackEvent: CustomStringConvertible {
  var time: CABarBeatTime { get set }
  var delta: VariableLengthQuantity? { get set }
  var bytes: [Byte] { get }
}

// MARK: - The track type protocol

/** Protocol for types that provide a collection of `MIDITrackEvent` values for a chunk and can produce that chunk */
protocol MIDITrackType: CustomStringConvertible {
  var chunk: MIDIFileTrackChunk { get }
  var name: String { get }
  var events: [MIDITrackEvent] { get }
  var playbackMode: Bool { get }
}

extension MIDITrackType {

  /** Generates a MIDI file chunk from current track data */
  var chunk: MIDIFileTrackChunk {
    var trackEvents = events
    trackEvents.insert(MetaEvent(.SequenceTrackName(name: name)), atIndex: 0)
    var eotEvent = MetaEvent(.EndOfTrack)
    if let lastEvent = trackEvents.last { eotEvent.time = lastEvent.time }
    trackEvents.append(eotEvent)
    return MIDIFileTrackChunk(events: trackEvents)
  }

}
