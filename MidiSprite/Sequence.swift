//
//  Sequence.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AudioToolbox
import MoonKit

final class Sequence: CustomStringConvertible {

  var description: String { return "Sequence {\n" + "\n".join(tracks.map({$0.description.indentedBy(4)})) + "\n}" }

  private var tempoEvents: [TrackEvent] = []

  /** Collection of all the tracks in the composition */
  private(set) var tracks: [Track] = []

  /** init */
  init() {
    tempoEvents.append(MetaEvent(deltaTime: .Zero, metaEventData: .SequenceTrackName("Tempo")))
    tempoEvents.append(MetaEvent(deltaTime: .Zero, metaEventData: .TimeSignature(0x04, 0x02, 0x24, 0x08)))
    tempoEvents.append(MetaEvent(deltaTime: .Zero, metaEventData: .Tempo(Byte4(60_000_000 / Sequencer.tempo))))
    tempoEvents.append(MetaEvent(deltaTime: .Zero, metaEventData: .EndOfTrack))
    logDebug("tempo events = \(tempoEvents)")
  }

  var tempoTrack: Chunk {
    var events: [TrackEvent] = tempoEvents
    events.append(MetaEvent(deltaTime: VariableLengthQuantity(Sequencer.currentTime), metaEventData: .EndOfTrack))
    return TrackChunk(data: TrackChunkData(events: events))
  }

  var chunks: [Chunk] {
    let headerChunkData = HeaderChunkData(format: .One, numberOfTracks: tracks.count + 1, division: 480)
    let headerChunk: Chunk = HeaderChunk(data: headerChunkData)
    let trackChunks: [Chunk] = tracks.map {$0.chunk}
    return [headerChunk, tempoTrack] + trackChunks
  }

  var bytes: [Byte] { return chunks.flatMap {$0.bytes} }

  /**
  newTrackOnBus:

  - parameter bus: Bus
  */
  func newTrackOnBus(bus: Bus) throws -> Track {
    let track = try Track(bus: bus)
    tracks.append(track)
    return track
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) throws {
    tempoEvents.removeLast()
    tempoEvents.append(MetaEvent(deltaTime: VariableLengthQuantity(Sequencer.currentTime), metaEventData: .Tempo(Byte4(60_000_000 / tempo))))
    tempoEvents.append(MetaEvent(deltaTime: .Zero, metaEventData: .EndOfTrack))
  }

  /**
  writeToFile:

  - parameter file: NSURL
  */
  func writeToFile(file: NSURL, overwrite: Bool = false) throws {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [bytes = self.bytes] in
      let data = NSData(bytes: bytes, length: bytes.count)
      do { try data.writeToURL(file, options: overwrite ? [.DataWritingAtomic] : [.DataWritingWithoutOverwriting]) }
      catch { logError(error) }
    }
  }

}