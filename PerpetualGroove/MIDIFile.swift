//
//  MIDIFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct that holds the data for a complete MIDI file */
struct MIDIFile: ByteArrayConvertible {

//  enum Format: Byte2 { case Zero, One, Two }

//  static let emptyFile = MIDIFile(tracks: [])

  let tracks: [MIDIFileTrackChunk]

  let header: MIDIFileHeaderChunk

  /**
  initWithFile:

  - parameter file: NSURL
  */
  init(file: URL) throws {
    guard let fileData = try? Data(contentsOf: file) else {
      throw MIDIFileError(type: .readFailure, reason: "Failed to get data from '\(file)'")
    }
    try self.init(data: fileData)
  }

  /**
  initWithData:

  - parameter data: NSData
  */
  init(data: Data) throws {

    let totalBytes = data.count
    guard totalBytes > 13 else {
      throw MIDIFileError(type: .fileStructurallyUnsound, reason: "Not enough bytes in file")
    }

    // Get a pointer to the underlying memory buffer
    let bytes = UnsafeBufferPointer<Byte>(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: totalBytes)

    let headerBytes = bytes[bytes.startIndex..<bytes.startIndex + 14]
//    let headerBytes = bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(14)]
    let h = try MIDIFileHeaderChunk(bytes: headerBytes)

    var tracksRemaining = h.numberOfTracks
    var t: [MIDIFileTrackChunk] = []

    var currentIndex = bytes.startIndex + 14

    while tracksRemaining > 0 {
      guard currentIndex.distance(to: bytes.endIndex) > 8 else {
        throw MIDIFileError(type: .fileStructurallyUnsound,
                            reason: "Not enough bytes for remaining track chunks (\(tracksRemaining))")
      }
      guard bytes[currentIndex..<currentIndex + 4].elementsEqual("MTrk".utf8) else {
        throw MIDIFileError(type: .invalidHeader, reason: "Expected chunk header with type 'MTrk'")
      }
      currentIndex += 4
      let chunkLength = Int(Byte4(bytes[currentIndex..<currentIndex + 4]))
      currentIndex += 4
      guard currentIndex + chunkLength <= bytes.endIndex else {
        throw MIDIFileError(type:.fileStructurallyUnsound, reason: "Not enough bytes in track chunk \(t.count)")
      }

      let trackBytes = bytes[currentIndex..<currentIndex + chunkLength]

      t.append(try MIDIFileTrackChunk(bytes: trackBytes))
      currentIndex += chunkLength
      tracksRemaining -= 1
    }

    // TODO: We need to track signature changes to do this properly
    let beatsPerBar = 4
    let subbeatDivisor = Int(h.division)
    var processedTracks: [MIDIFileTrackChunk] = []
    for trackChunk in t {
      var ticks: UInt64 = 0
      var processedEvents: [MIDIEvent] = []
      for var trackEvent in trackChunk.events {
        guard let delta = trackEvent.delta else {
          throw MIDIFileError(type: .fileStructurallyUnsound, reason: "Track event missing delta value")
        }
        let deltaTicks = UInt64(delta.intValue)
        ticks += deltaTicks
        trackEvent.time = BarBeatTime(tickValue: ticks, beatsPerBar: UInt(beatsPerBar), subbeatDivisor: UInt(subbeatDivisor))
        processedEvents.append(trackEvent)
      }
      processedTracks.append(MIDIFileTrackChunk(events: processedEvents))
    }

    header = h
    tracks = processedTracks
  }

  init(sequence: Sequence) {
    tracks = sequence.tracks.map {$0.chunk}
    header = MIDIFileHeaderChunk(numberOfTracks: Byte2(tracks.count))
  }

  var bytes: [Byte] {
    var bytes = header.bytes
    var trackData: [[Byte]] = []
    for track in tracks {
      var previousTime: BarBeatTime = .start1
      var trackBytes: [Byte] = []
      for event in track.events {
        let eventTime = event.time
        let eventTimeTicks = eventTime.ticks
        let previousTimeTicks = previousTime.ticks
        let delta = eventTimeTicks > previousTimeTicks ? eventTimeTicks - previousTimeTicks : 0
        previousTime = eventTime
        let deltaTime = VariableLengthQuantity(delta)
        let eventBytes = deltaTime.bytes + event.bytes
        trackBytes.append(contentsOf: eventBytes)
      }
      trackData.append(trackBytes)
    }

    for trackBytes in trackData {
      bytes.append(contentsOf: Array("MTrk".utf8))
      bytes.append(contentsOf: Byte4(trackBytes.count).bytes)
      bytes.append(contentsOf: trackBytes)
    }

    return bytes
  }
}

extension MIDIFile: SequenceDataProvider { var storedData: Sequence.Data { return .midi(self) } }

extension MIDIFile: CustomStringConvertible {
  var description: String { return "\(header)\n\("\n".join(tracks.map({$0.description})))" }
}

extension MIDIFile: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

