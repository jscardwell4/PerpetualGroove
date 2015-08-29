//
//  HeaderChunk.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct to hold the header chunk of a MIDI file */
struct HeaderChunk: Chunk {
  let type = Byte4("MThd".utf8)
  let length: Byte4 = 6
  let format: MIDIFile.Format
  let numberOfTracks: Byte2
  let division: Byte2

  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "type: MThd",
      "length: \(length)",
      "format: \(format)",
      "numberOfTracks: \(numberOfTracks)",
      "division: \(division)"
    ) + "\n}"
    return result
  }
  var bytes: [Byte] { return type.bytes + length.bytes + format.rawValue.bytes + numberOfTracks.bytes + division.bytes }

}