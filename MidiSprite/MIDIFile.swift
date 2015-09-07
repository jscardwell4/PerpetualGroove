//
//  MIDIFile.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime


/** Struct that holds the data for a complete MIDI file */
struct MIDIFile: CustomStringConvertible {

  enum Format: Byte2 { case Zero, One, Two }

  let tracks: [TrackChunk]

  private let header: HeaderChunk

  /**
  initWithFormat:division:tracks:

  - parameter format: Format
  - parameter division: Byte2
  - parameter tracks: [TrackType]
  */
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

