//
//  GrooveFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

/** Struct that holds data for a 'Groove' sequence */
struct GrooveFile {
  var source: NSURL?
  var tracks: [GrooveTrack] = []
  var tempoChanges = ObjectJSONValue([CABarBeatTime.start.rawValue: 120.0.jsonValue])
  var endOfFile: CABarBeatTime = .start

  init(sequence: Sequence) {
    source = sequence.document.fileURL
    tracks = sequence.instrumentTracks.map({GrooveTrack(track: $0)})
    for event in sequence.tempoTrack.metaEvents.filter({
      switch $0.data { case .Tempo: return true; default: return false }
      })
    {
      if case .Tempo(let bpm) = event.data { tempoChanges[event.time.rawValue] = bpm.jsonValue }
    }
    endOfFile = sequence.sequenceEnd
  }

}

extension GrooveFile: DataConvertible {
  var data: NSData { return jsonValue.prettyData }
  init?(data: NSData) { self.init(JSONValue(data: data)) }
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
              tracks = ArrayJSONValue(dict["tracks"]),
              tempoChanges = ObjectJSONValue(dict["tempoChanges"]),
              endOfFile = CABarBeatTime(dict["endOfFile"]) else { return nil }
    self.tracks = tracks.flatMap({GrooveTrack($0)})
    self.tempoChanges = tempoChanges
    self.endOfFile = endOfFile
    if let sourceString = String(dict["source"]) { source = NSURL(string: sourceString) }
  }
}