//
//  GrooveFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct that holds data for a 'Groove' sequence */
struct GrooveFile {
  var source: URL?
  var tracks: [GrooveTrack] = []
  var tempoChanges = ObjectJSONValue([BarBeatTime.zero.rawValue: 120.0.jsonValue])
  var endOfFile: BarBeatTime = BarBeatTime.zero

  init(sequence: Sequence) {
    source = sequence.document.fileURL
    tracks = sequence.instrumentTracks.map({GrooveTrack(track: $0)})
    for event in sequence.tempoTrack.metaEvents.filter({
      switch $0.data { case .tempo: return true; default: return false }
      })
    {
      if case .tempo(let bpm) = event.data { tempoChanges[event.time.rawValue] = bpm.jsonValue }
    }
    endOfFile = sequence.sequenceEnd
  }

}

extension GrooveFile: SequenceDataProvider { var storedData: Sequence.Data { return .groove(self) } }

extension GrooveFile: DataConvertible {
  var data: Data { return jsonValue.prettyData }
  init?(data: Data) { self.init(JSONValue(data: data)) }
}

extension GrooveFile: JSONValueConvertible {
  var jsonValue: JSONValue {
    return [
      "source": source?.absoluteString,
      "tracks": tracks,
      "tempoChanges": tempoChanges,
      "endOfFile": endOfFile
    ]
  }
}

extension GrooveFile: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              let tracks = ArrayJSONValue(dict["tracks"]),
              let tempoChanges = ObjectJSONValue(dict["tempoChanges"]),
              let endOfFile = BarBeatTime(dict["endOfFile"]) else { return nil }
    self.tracks = tracks.flatMap({GrooveTrack($0)})
    self.tempoChanges = tempoChanges
    self.endOfFile = endOfFile
    if let sourceString = String(dict["source"]) { source = NSURL(string: sourceString) as URL? }
  }
}

extension GrooveFile: CustomStringConvertible {
  var description: String { return jsonValue.prettyRawValue }
}
