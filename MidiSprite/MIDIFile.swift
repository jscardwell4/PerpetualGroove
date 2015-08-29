//
//  MIDIFile.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI
import AudioToolbox


// MARK: - The meta track event

/** Struct that holds the data for a complete MIDI file */
struct MIDIFile: CustomStringConvertible {

  enum Format: Byte2 { case Zero, One, Two }

  let tracks: [TrackChunk]

  private let header: HeaderChunk
  private let time = BarBeatTime(clockSource: Sequencer.clockSource)

  init(format: Format, division: Byte2, tracks: [TrackType]) {
    self.tracks = tracks.flatMap({$0.chunk})
    header = HeaderChunk(format: .One, numberOfTracks: Byte2(tracks.count), division: division)
  }

  var bytes: [Byte] {
    var bytes = header.bytes
    var trackData: [[Byte]] = []
    for track in tracks {
      var previousTime: CABarBeatTime = .start
      var trackBytes: [Byte] = []
      for event in track.events {
        let eventTime = event.time
        let eventTimeTicks = eventTime.tickValue
        let previousTimeTicks = previousTime.tickValue
        let delta = eventTimeTicks > previousTimeTicks ? eventTimeTicks - previousTimeTicks : 0
        previousTime = eventTime
        let deltaTime = VariableLengthQuantity(delta)
        let eventBytes = deltaTime.bytes + event.bytes
        trackBytes.appendContentsOf(eventBytes)
      }
      trackData.append(trackBytes)
    }

    for trackBytes in trackData {
      bytes.appendContentsOf(Array("MTrk".utf8))
      bytes.appendContentsOf(Byte4(trackBytes.count).bytes)
      bytes.appendContentsOf(trackBytes)
    }

    return bytes
  }

  /**
  writeMusicSequenceToFile:

  - parameter file: NSURL
  */
  func writeMusicSequenceToFile(file: NSURL) throws {
    // Make sure there are tracks to write first
    guard tracks.count > 1 else {
      logWarning("Written track would consist of only the tempo track, cancelling write…"); return
    }

    // Create a music sequence for the tracks
    var musicSequence = MusicSequence()
    try NewMusicSequence(&musicSequence) ➤ "Failed to create music sequence"

    // Create a variable to hold created tracks
    var musicTrack = MusicTrack()

    // The first track will be the tempo track, so get the music sequence's tempo track
    try MusicSequenceGetTempoTrack(musicSequence, &musicTrack) ➤ "Failed to get tempo track from sequence"

    // Iterate through the chunk's events, which should all be `MetaEvent` types
    for event in tracks[0].events.filter({$0 is MetaEvent}).map({$0 as! MetaEvent}) {
      guard event.data != .EndOfTrack else { continue }
      try event.data.withEventPointer {
        try MusicTrackNewMetaEvent(musicTrack, event.time.doubleValue, $0) ➤ "Failed to add meta event"
      }
    }

    // Iterate through the track chunks, skipping the tempo track
    for trackChunk in tracks[1 ..< tracks.count] {

      // Make sure we have events to add before creating the track
      let events = trackChunk.events
      guard  events.count > 0 else { continue }

      // Create a new track for the events
      musicTrack = MusicTrack()
      try MusicSequenceNewTrack(musicSequence, &musicTrack) ➤ "Failed to create new music track"

      // Iterate through the events and add the corresponding event/message to the new track
      for event in events {

        switch event {
          case let meta as MetaEvent where meta.data != MetaEvent.Data.EndOfTrack:
            try meta.data.withEventPointer {
              try MusicTrackNewMetaEvent(musicTrack, event.time.doubleValue, $0) ➤ "Failed to add meta event"
            }

          case let channel as ChannelEvent:
            var channelMessage = channel.message
            try MusicTrackNewMIDIChannelEvent(musicTrack, channel.time.doubleValue, &channelMessage)
              ➤ "Failed to add channel event"

          default: continue
        }
      }

    }

    // Write the sequence to file
    try MusicSequenceFileCreate(musicSequence, file, .MIDIType, .Default, Int16(header.division)) ➤ "Failed to create file"
  }


  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "header: \(header.description.indentedBy(4, true))",
      "tracks: {\n" + ",\n".join(tracks.map({$0.description.indentedBy(8)}))
    )
    result += "\n\t}\n}"
    return result
  }
}

