//
//  MIDIFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// Struct that holds the data for a complete MIDI file.
struct MIDIFile: ByteArrayConvertible {

  let tracks: [TrackChunk]

  let header: HeaderChunk

  init(file: URL) throws { try self.init(data: try Data(contentsOf: file)) }

  init(data: Data) throws {

    guard data.count > 13 else {
      throw MIDIFileError(type: .fileStructurallyUnsound, reason: "Not enough bytes in file")
    }

    header = try HeaderChunk(data: data.prefix(14))

    var tracksRemaining = header.numberOfTracks
    var unprocessedTracks: [TrackChunk] = []

    var currentIndex = 14

    while tracksRemaining > 0 {
      guard data.endIndex - currentIndex > 8 else {
        throw MIDIFileError(type: .fileStructurallyUnsound,
                            reason: "Not enough bytes for remaining track chunks (\(tracksRemaining))")
      }
      guard String(data[currentIndex +--> 4]) == "MTrk" else {
        throw MIDIFileError(type: .invalidHeader, reason: "Expected chunk header with type 'MTrk'")
      }

      currentIndex += 4

      let chunkLength = Int(Byte4(data[currentIndex +--> 4]))
      currentIndex += 4

      guard currentIndex + chunkLength <= data.endIndex else {
        throw MIDIFileError(type:.fileStructurallyUnsound,
                            reason: "Not enough bytes in track chunk \(unprocessedTracks.count)")
      }

      unprocessedTracks.append(try TrackChunk(data: data[currentIndex +--> chunkLength]))
      currentIndex += chunkLength
      tracksRemaining -= 1
    }

    // TODO: We need to track signature changes to do this properly
    let beatsPerBar = 4
    let subbeatDivisor = Int(header.division)
    var processedTracks: [TrackChunk] = []
    for trackChunk in unprocessedTracks {
      var ticks: UInt64 = 0
      var processedEvents: [AnyMIDIEvent] = []
      for var trackEvent in trackChunk.events {
        guard let delta = trackEvent.delta else {
          throw MIDIFileError(type: .fileStructurallyUnsound, reason: "Track event missing delta value")
        }
        let deltaTicks = UInt64(delta.intValue)
        ticks += deltaTicks
        trackEvent.time = BarBeatTime(tickValue: ticks,
                                      units: BarBeatTime.Units(beatsPerBar: UInt(beatsPerBar),
                                                               beatsPerMinute: Sequencer.beatsPerMinute,
                                                               subbeatDivisor: UInt(subbeatDivisor)))
        processedEvents.append(trackEvent)
      }

      processedTracks.append(MIDIFile.TrackChunk(events: processedEvents))

    }

    tracks = processedTracks
  }

  init(sequence: Sequence) {
    tracks = sequence.tracks.map {$0.chunk}
    header = HeaderChunk(numberOfTracks: Byte2(tracks.count))
  }

  var bytes: [Byte] {
    var bytes = header.bytes
    var trackData: [[Byte]] = []
    for track in tracks {
      var previousTime: BarBeatTime = BarBeatTime.zero
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

extension MIDIFile {

  /// Struct to hold the header chunk of a MIDI file.
  struct HeaderChunk {
    let type = Byte4("MThd".utf8)
    let format: Byte2 = 1
    let length: Byte4 = 6
    let numberOfTracks: Byte2
    let division: Byte2 = 480

    var bytes: [Byte] {
      var result = type.bytes
      result.append(contentsOf: format.bytes)
      result.append(contentsOf: numberOfTracks.bytes)
      result.append(contentsOf: division.bytes)
      return result
    }

    init(numberOfTracks n: Byte2) { numberOfTracks = n }

    init(data: Data.SubSequence) throws {
      guard data.count == 14 else {
        throw MIDIFileError(type: .invalidLength, reason: "Header chunk must be 14 bytes")
      }
      guard String(data[data.startIndex +--> 4]) == "MThd" else {
        throw MIDIFileError(type: .invalidHeader, reason: "Expected chunk header with type 'MThd'")
      }
      guard Byte4(6) == Byte4(data[(data.startIndex + 4) +--> 4]) else {
        throw MIDIFileError(type: .invalidLength, reason: "Header must specify length of 6")
      }
      guard 1 == Byte2(data[(data.startIndex + 8) +--> 2]) else {
        throw MIDIFileError(type: .fileStructurallyUnsound,
                            reason: "Format must be 00 00 00 00, 00 00 00 01, 00 00 00 02")
      }
      numberOfTracks = Byte2(data[(data.startIndex + 10) +--> 2])
    }
  }

}

extension MIDIFile.HeaderChunk: CustomStringConvertible {
  var description: String {
    return "MThd\n\tformat: \(format)\n\tnumber of tracks: \(numberOfTracks)\n\tdivision: \(division)"
  }
}

extension MIDIFile {

  /// Struct to hold a track chunk for a MIDI file where chunk = \<chunk type\> \<length\> \<track event\>+
  struct TrackChunk {
    let type = Byte4("MTrk".utf8)
    var events: [AnyMIDIEvent] = []

    init() {}

    init(events: [AnyMIDIEvent]) { self.events = events }

    init(eventContainer: MIDIEventContainer) { events = Array<AnyMIDIEvent>(eventContainer) }

    init(data: Data.SubSequence) throws {
      guard data.count > 8 else { throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes in chunk") }
      guard String(data[data.startIndex +--> 4]) == "MTrk" else {
        throw MIDIFileError(type: .invalidHeader, reason: "Track chunk header must be of type 'MTrk'")
      }

      let chunkLength = Byte4(data[(data.startIndex + 4) +--> 4])
      guard data.count == Int(chunkLength) + 8 else {
        throw MIDIFileError(type: .invalidLength,
                            reason: "Length specified in bytes and the length of the bytes do not match")
      }

      var currentIndex = data.startIndex + 8
      var events: [AnyMIDIEvent] = []

      while currentIndex < data.endIndex {
        var i = currentIndex

        while data[i] & 0x80 != 0 { i += 1 }

        let delta = VariableLengthQuantity(bytes: data[currentIndex ... i])

        i += 1
        currentIndex = i

        let eventStart = currentIndex

        switch data[currentIndex] {

          case 0xFF:
            i = currentIndex + 1
            let type = data[i]
            i += 1
            currentIndex = i

            while data[i] & 0x80 != 0 { i += 1 }

            let dataLength = VariableLengthQuantity(bytes: data[currentIndex ... i])
            i += dataLength.intValue + 1

            if type == 0x07 {
              events.append(.node(try MIDINodeEvent(delta: delta, data: data[eventStart ..< i])))
            } else {
              events.append(.meta(try MetaEvent(delta: delta, data: data[eventStart ..< i])))
            }

            currentIndex = i

          default:
            guard let type = ChannelEvent.EventType(rawValue: data[currentIndex] >> 4) else {
              throw MIDIFileError(type: .unsupportedEvent,
                                  reason: "\(data[currentIndex] >> 4) is not a supported ChannelEvent")
            }
            i = currentIndex + type.byteCount
            events.append(.channel(try ChannelEvent(delta: delta, data: data[currentIndex ..< i])))
            currentIndex = i

        }

      }

      self.events = events
    }
  }

}

extension MIDIFile.TrackChunk: CustomStringConvertible {
  var description: String {
    return "MTrk\n\(events.map({$0.description.indentedBy(1, useTabs: true)}).joined(separator: "\n"))"
  }
}

extension MIDIFile {
  /// Struct for converting values to MIDI variable length quanity representation
  ///
  /// These numbers are represented 7 bits per byte, most significant bits first.
  /// All bytes except the last have bit 7 set, and the last byte has bit 7 clear.
  /// If the number is between 0 and 127, it is thus represented exactly as one byte.
  struct VariableLengthQuantity {

    let bytes: [Byte]
    static let zero = VariableLengthQuantity(0)

    var representedValue: [Byte] {
      let groups = bytes.segment(8)
      var resolvedGroups: [UInt64] = []
      for group in groups {
        guard group.count > 0 else { continue }
        var groupValue = UInt64(group[0])
        if groupValue & 0x80 != 0 {
          groupValue &= UInt64(0x7F)
          var i = 1
          var next = Byte(0)
          repeat {
            next = (i < group.count ? {let n = group[i]; i += 1; return n}() : 0)
            groupValue = (groupValue << UInt64(7)) + UInt64(next & 0x7F)
          } while next & 0x80 != 0
        }
        resolvedGroups.append(groupValue)
      }
      var resolvedBytes = resolvedGroups.flatMap { $0.bytes }
      while resolvedBytes.count > 1 && resolvedBytes.first == 0 { resolvedBytes.remove(at: 0) }

      return resolvedBytes
    }

    var intValue: Int { return Int(representedValue) }

    init<S:Swift.Sequence>(bytes b: S) where S.Iterator.Element == Byte { bytes = Array(b) }

    /// Initialize from any `ByteArrayConvertible` type holding the represented value
    init<B:ByteArrayConvertible>(_ value: B) {
      var v = UInt64(value.bytes)
      var buffer = v & 0x7F
      while v >> 7 > 0 {
        v = v >> 7
        buffer <<= 8
        buffer |= 0x80
        buffer += v & 0x7F
      }
      var result: [Byte] = []
      repeat {
        result.append(UInt8(buffer & 0xFF))
        guard buffer & 0x80 != 0 else { break }
        buffer = buffer >> 8
      } while true
      while let firstByte = result.first , result.count > 1 && firstByte == 0 { result.remove(at: 0) }
      bytes = result
    }
  }

}

extension MIDIFile.VariableLengthQuantity: CustomStringConvertible, CustomDebugStringConvertible {

  var description: String { return "\(UInt64(representedValue))" }

  var paddedDescription: String { return description.pad(" ", count: 6) }

  var debugDescription: String {
    let representedValue = self.representedValue
    return "\(type(of: self).self) {" + "; ".join(
      "bytes (hex, decimal): (\(String(hexBytes: bytes)), \(UInt64(bytes)))",
      "representedValue (hex, decimal): (\(String(hexBytes: representedValue)), \(UInt64(representedValue)))"
      ) + "}"
  }
  
}
