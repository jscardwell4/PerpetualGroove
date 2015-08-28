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

// MARK: - The chunk protocol

/** Protocol for types that can produce a valid chunk for a MIDI file where chunk = \<chunk type\> \<length of data\> \<data\> */
protocol Chunk: CustomStringConvertible {
  var type: Byte4 { get }
  var data: ChunkData { get }
}

extension Chunk {
  var bytes: [Byte] { return type.bytes + data.length.bytes + data.bytes }
  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "type: \(String(type, radix: 16, uppercase: true, pad: 2, group: 2))",
      "data: \(data.description.indentedBy(4, preserveFirstLineIndent: true))"
      ) + "\n}"
    return result
  }
}

// MARK: - The chunk data protocol

/** Protocol for types that can produce the data portion of a chunk in a MIDI file */
protocol ChunkData: CustomStringConvertible {
  var length: Byte4 { get }
  var bytes: [Byte] { get }
}

// MARK: - Header chunk and chunk data

/** Struct to hold the header chunk of a MIDI file */
struct HeaderChunk: Chunk {
  let type = Byte4("MThd".utf8)
  let data: ChunkData

  init(data: HeaderChunkData) { self.data = data }
}

/** Struct to hold the data portion of a header chunk in a MIDI file */
struct HeaderChunkData: ChunkData {
  let length: Byte4 = 6
  let numberOfTracks: Byte2
  let format: MIDIFile.Format
  let division: Byte2

  init(format: MIDIFile.Format, numberOfTracks: Int, division: Byte2) {
    self.format = format; self.numberOfTracks = Byte2(numberOfTracks); self.division = division
  }

  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "length: \(length)",
      "format: \(format)",
      "numberOfTracks: \(numberOfTracks)",
      "division: \(division)"
    ) + "\n}"
    return result
  }
  var bytes: [Byte] { return format.rawValue.bytes + numberOfTracks.bytes + division.bytes }
}


// MARK: - Track chunk and chunk data

/** Struct to hold a track chunk for a MIDI file where chunk = \<chunk type\> \<length\> \<track event\>+ */
struct TrackChunk: Chunk {
  let type = Byte4("MTrk".utf8)
  let data: ChunkData
  init(data: TrackChunkData) { self.data = data }
}

/** Struct to hold the data for a track chunk in a MIDI file */
struct TrackChunkData: ChunkData {
  var length: Byte4 { return Byte4(events.map({$0.length}).sum) }
  var bytes: [Byte] { return events.flatMap({$0.data}) }
  let events: [TrackEvent]
  var description: String {
    let result = "\(self.dynamicType.self) {\n\tlength: \(length)\n\tevents: {\n"
        + ",\n".join(events.map({$0.description.indentedBy(8)})) + "\n\t}\n}"
    return result
  }

}

// MARK: - Encoding 'variable length' values

/** 
Struct for converting values to MIDI variable length quanity representation

These numbers are represented 7 bits per byte, most significant bits first. All bytes except the last have bit 7 set, and the 
last byte has bit 7 clear. If the number is between 0 and 127, it is thus represented exactly as one byte.
*/
struct VariableLengthQuantity: CustomStringConvertible {
  let bytes: [Byte]
  static let zero = VariableLengthQuantity(0)

  var description: String {
    let representedValue = self.representedValue
    let byteString = " ".join(bytes.map { String($0, radix: 16, uppercase: true, pad: 2) })
    let representedValueString = " ".join(representedValue.map { String($0, radix: 16, uppercase: true, pad: 2) })
    return "\(self.dynamicType.self) {" + "; ".join(
      "bytes: \(byteString) (\(UInt64(bytes)))",
      "representedValue: \(representedValueString)(\(UInt64(representedValue)))"
    ) + "}"
  }
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
          next = (i < group.count ? group[i++] : 0)
          groupValue = (groupValue << UInt64(7)) + UInt64(next & 0x7F)
        } while next & 0x80 != 0
      }
      resolvedGroups.append(groupValue)
    }
    var resolvedBytes = resolvedGroups.flatMap { $0.bytes }
    while let firstByte = resolvedBytes.first where resolvedBytes.count > 1 && firstByte == 0 { resolvedBytes.removeAtIndex(0) }
    return resolvedBytes
  }

  /**
  Initialize with bytes array already in converted format

  - parameter bytes: [Byte]
  */
  init(bytes: [Byte]) { self.bytes = bytes }

  /**
  Initialize from any `ByteArrayConvertible` type holding the represented value

  - parameter value: B
  */
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
    bytes = result
  }
}

// MARK: - The track event protocol

/** Protocol for types that produce data for a track event in a track chunk where event = \<delta time\> \<event specific data\> */
protocol TrackEvent: CustomStringConvertible {
  var deltaTime: VariableLengthQuantity { get set }
  var barBeatTime: CABarBeatTime { get  set }
  var bytes: [Byte] { get }
}

extension TrackEvent {
  var length: Byte4 { return Byte4(deltaTime.bytes.count + bytes.count) }
  var data: [Byte] { return deltaTime.bytes + bytes }
}

// MARK: - The track type protocol

protocol TrackType: CustomStringConvertible {
  var chunk: TrackChunk { get }
  var label: String { get }
  var time: BarBeatTime { get }
  var events: [TrackEvent] { get }
}

extension TrackType {
  /** Generates a MIDI file chunk from current track data */
  var chunk: TrackChunk {
    let nameEvent: TrackEvent = MetaEvent(data: .SequenceTrackName(name: label))
    var endEvent: TrackEvent  = MetaEvent(data: .EndOfTrack)
    endEvent.deltaTime = VariableLengthQuantity(time.timeStampForBarBeatTime(time.timeSinceMarker))
    endEvent.barBeatTime = time.time
    return TrackChunk(data: TrackChunkData(events: [nameEvent] + events + [endEvent]))
  }


}

// MARK: - The channel track event

/** Struct to hold data for a channel event where event = \<delta time\> \<status\> \<data1\> \<data2\> */
struct ChannelEvent: TrackEvent {
  var deltaTime: VariableLengthQuantity = .zero
  var barBeatTime: CABarBeatTime = .start
  let status: Byte
  let data1: Byte
  let data2: Byte?
  var bytes: [Byte] { return [status, data1] + (data2 != nil ? [data2!] : []) }
  static func noteOnEvent(channel channel: Byte, note: Byte, velocity: Byte) -> ChannelEvent {
    return ChannelEvent(status: 0x90 | channel, data1: note, data2: velocity)
  }
  static func noteOffEvent(channel channel: Byte, note: Byte, velocity: Byte) -> ChannelEvent {
    return ChannelEvent(status: 0x80 | channel, data1: note, data2: velocity)
  }
  init(status: Byte, data1: Byte, data2: Byte? = nil) {
    self.status = status; self.data1 = data1; self.data2 = data2
  }
  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "deltaTime: \(deltaTime)",
      "barBeatTime: \(barBeatTime)",
      "status: \(String(status, radix: 16, uppercase: true, pad: 2, group: 2))",
      "data1: \(String(data1, radix: 16, uppercase: true, pad: 2, group: 2))",
      "data2: " + (data2 == nil ? "nil" : String(data2!, radix: 16, uppercase: true, pad: 2, group: 2))
    ) + "\n}"
    return result
  }
}

// MARK: - The meta track event

/** Struct to hold data for a meta event where event = \<delta time\> **FF** \<meta type\> \<length of meta\> \<meta\> */
struct MetaEvent: TrackEvent {
  var deltaTime: VariableLengthQuantity = .zero
  var barBeatTime: CABarBeatTime = .start
  let data: MetaEventData
  var bytes: [Byte] { return Byte(0xFF).bytes + [data.type] + data.length.bytes + data.bytes }

  /**
  Initializer takes a timestamp to convert to a `VariableLengthQuantity` as well as the event's data

  - parameter deltaTime: MIDITimeStamp
  - parameter data: MetaEventData
  */
  init(data: MetaEventData) { self.data = data }


  /**
  Initializer that takes a `VariableLengthQuantity` as well as the event's data

  - parameter deltaTime: VariableLengthQuantity
  - parameter data: MetaEventData
  */
  init(deltaTime: VariableLengthQuantity, barBeatTime: CABarBeatTime, data: MetaEventData) { self.deltaTime = deltaTime; self.barBeatTime = barBeatTime; self.data = data }

  var description: String {
    return "\(self.dynamicType.self) {\n\tdeltaTime: \(deltaTime)\n\tdata: \(data)\n\tbarBeatTime: \(barBeatTime)\n}"
  }
}

/** Enumeration for encapsulating a type of meta event */
enum MetaEventData {
  case Text (text: String)
  case CopyrightNotice (notice: String)
  case SequenceTrackName (name: String)
  case InstrumentName (name: String)
  case EndOfTrack
  case Tempo (microseconds: Byte4)
  case TimeSignature (upper: Byte, lower: Byte, clocks: Byte, notes: Byte)
  case NodePlacement(placement: MIDINode.Placement)

  var type: Byte {
    switch self {
      case .Text:                     return 0x01
      case .CopyrightNotice:          return 0x02
      case .SequenceTrackName:        return 0x03
      case .InstrumentName:           return 0x04
      case .EndOfTrack:               return 0x2F
      case .Tempo:                    return 0x51
      case .TimeSignature:            return 0x58
      case .NodePlacement:            return 0x07
    }
  }

  var bytes: [Byte] {
    switch self {
      case let .Text(text):                return Array(text.utf8)
      case let .CopyrightNotice(text):     return Array(text.utf8)
      case let .SequenceTrackName(text):   return Array(text.utf8)
      case let .InstrumentName(text):      return Array(text.utf8)
      case .EndOfTrack:                    return []
      case let .Tempo(tempo):              return Array(tempo.bytes.dropFirst())
      case let .TimeSignature(u, l, n, m): return [u, Byte(log2(Double(l))), n, m]
      case let .NodePlacement(placement):  return placement.bytes
    }
  }

  var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
}

/** Struct that holds the data for a complete MIDI file */
struct MIDIFile: CustomStringConvertible {

  enum Format: Byte2 { case Zero, One, Two }

  let format: MIDIFile.Format

  let division: Byte2

  let tracks: [TrackChunk]

  private let header: HeaderChunk
  private let time = BarBeatTime(clockSource: Sequencer.clockSource)

  init(format: Format, division: Byte2, tracks: [TrackType]) {
    self.format = format; self.division = division; self.tracks = tracks.flatMap({$0.chunk})
    header = HeaderChunk(data: HeaderChunkData(format: .One, numberOfTracks: tracks.count, division: division))

  }

  var bytes: [Byte] { return header.bytes + tracks.flatMap({$0.bytes}) }

  /**
  writeMusicSequenceToFile:

  - parameter file: NSURL
  */
  func writeMusicSequenceToFile(file: NSURL) throws {
    var musicSequence = MusicSequence()
    try NewMusicSequence(&musicSequence) ➤ "Failed to create music sequence"
    if tracks.count > 1 {
      for trackChunk in tracks[1 ..< tracks.count] {
        guard let channelEvents = (trackChunk.data as? TrackChunkData)?.events.filter({$0 is ChannelEvent}).map({$0 as! ChannelEvent})
          where channelEvents.count > 0 else { continue }
        var musicTrack = MusicTrack()
        try MusicSequenceNewTrack(musicSequence, &musicTrack) ➤ "Failed to create new music track"
        for channelEvent in channelEvents {
          var message = MIDIChannelMessage(status: channelEvent.status, data1: channelEvent.data1, data2: channelEvent.data2 ?? 0, reserved: 0)
          try MusicTrackNewMIDIChannelEvent(musicTrack, channelEvent.barBeatTime.doubleValueWithBeatsPerBar(4), &message) ➤ "Failed to add event"
        }
      }
    }
    try MusicSequenceFileCreate(musicSequence, file, .MIDIType, .Default, Int16(division)) ➤ "Failed to create file"
  }


  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "header: \(header.description.indentedBy(4, preserveFirstLineIndent: true))",
      "tracks: {\n" + ",\n".join(tracks.map({$0.description.indentedBy(8)})) + "\n\t}\n}"
    )
    return result
  }
}

