//
//  TrackChunk.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct to hold a track chunk for a MIDI file where chunk = \<chunk type\> \<length\> \<track event\>+ */
struct TrackChunk: Chunk {
  let type = Byte4("MTrk".utf8)
  let events: [TrackEvent]

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "type: MTrk",
      "events: {\n" + ",\n".join(events.map({$0.description.indentedBy(8)}))
    )
    result += "\n\t}\n}"
    return result
  }
}
