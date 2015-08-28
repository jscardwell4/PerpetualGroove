//
//  MIDIFile.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import typealias CoreMIDI.MIDITimeStamp
import struct AudioToolbox.MIDINoteMessage

/*
<MIDI Stream>             ::= <MIDI msg> < MIDI Stream>
<MIDI msg>                ::= <sys msg> | <chan msg>
<chan msg>                ::= <chan 1byte msg> | <chan 2byte msg>
<chan 1byte msg>          ::= <chan stat1 byte> <data singlet> <running singlets> 
<chan 2byte msg>          ::= <chan stat2 byte> <data pair> <running pairs>
<chan stat1 byte>         ::= <chan voice stat1 nibble> <hex nibble>
<chan stat2 byte>         ::= <chan voice stat2 nibble> <hex nibble>
<chan voice stat1 nyble>  ::= C | D
<chan voice stat2 nyble>  ::= 8 | 9 | A | B | E
<hex nyble>               ::=  0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F
<data pair>               ::= <data singlet> <data singlet>
<data singlet>            ::= <realtime byte> <data singlet> | <data byte>
<running pairs>           ::= <empty> | <data pair> <running pairs>
<running singlets>        ::= <empty> | <data singlet> <running singlets>
<data byte>               ::= <data MSD> <hex nyble>
<data MSD>                ::=  0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
<realtime byte>           ::=  F8 | FA | FB | FC | FE | FF
<sys msg>                 ::= <sys common msg> | <sysex msg> | <sys realtime msg>
<sys realtime msg>        ::= <realtime byte>
<sysex msg>               ::= <sysex data byte> <data singlet> <running singlets> <eox byte>
<sysex stat byte>         ::=  F0
<eox byte>                ::=  F7
<sys common msg>          ::= <song position msg> | <song select msg> | <tune request> 
<tune request>            ::=  F6
<song position msg>       ::= <song position stat byte> <data pair>
<song select msg>         ::= <song select stat byte> <data singlet>
<song position stat byte> ::= F2
<song select stat byte>   ::= F3
*/

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
    let byteString = " ".join(bytes.map { String($0, radix: 16, uppercase: true, pad: 2) })
    let representedValueString = " ".join(representedValue.map { String($0, radix: 16, uppercase: true, pad: 2) })
    return "\(self.dynamicType.self) {bytes: \(byteString); representedValue: \(representedValueString)}"
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
  var deltaTime: VariableLengthQuantity { get }
  var bytes: [Byte] { get }
}

extension TrackEvent {
  var length: Byte4 { return Byte4(deltaTime.bytes.count + bytes.count) }
  var data: [Byte] { return deltaTime.bytes + bytes }
}

// MARK: - The track type protocol

protocol TrackType: CustomStringConvertible {
  var events: [TrackEvent] { get }
  var label: String { get }
}


// MARK: - The channel track event

/** Struct to hold data for a channel event where event = \<delta time\> \<status\> \<data1\> \<data2\> */
struct ChannelEvent: TrackEvent {
  let deltaTime: VariableLengthQuantity
  let status: Byte
  let data1: Byte
  let data2: Byte?
  var bytes: [Byte] { return [status, data1] + (data2 != nil ? [data2!] : []) }
  static func noteOnEvent(timestamp: MIDITimeStamp, channel: Byte, note: Byte, velocity: Byte) -> ChannelEvent {
    return ChannelEvent(deltaTime: VariableLengthQuantity(timestamp), status: 0x90 | channel, data1: note, data2: velocity)
  }
  static func noteOffEvent(timestamp: MIDITimeStamp, channel: Byte, note: Byte, velocity: Byte) -> ChannelEvent {
    return ChannelEvent(deltaTime: VariableLengthQuantity(timestamp), status: 0x80 | channel, data1: note, data2: velocity)
  }
  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "deltaTime: \(deltaTime)",
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
  let deltaTime: VariableLengthQuantity
  let data: MetaEventData
  var bytes: [Byte] { return Byte(0xFF).bytes + [data.type] + data.length.bytes + data.bytes }

  /**
  Initializer takes a timestamp to convert to a `VariableLengthQuantity` as well as the event's data

  - parameter deltaTime: MIDITimeStamp
  - parameter data: MetaEventData
  */
  init(deltaTime: MIDITimeStamp, data: MetaEventData) { self.deltaTime = VariableLengthQuantity(deltaTime); self.data = data }


  /**
  Initializer that takes a `VariableLengthQuantity` as well as the event's data

  - parameter deltaTime: VariableLengthQuantity
  - parameter data: MetaEventData
  */
  init(deltaTime: VariableLengthQuantity, data: MetaEventData) { self.deltaTime = deltaTime; self.data = data }

  var description: String { return "\(self.dynamicType.self) {\n\tdeltaTime: \(deltaTime)\n\tdata: \(data)\n}" }
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

  let tracks: [TrackType]

  private let header: HeaderChunk
  private let time = BarBeatTime(clockSource: Sequencer.clockSource)

  init(format: Format, division: Byte2, tracks: [TrackType]) {
    self.format = format; self.division = division; self.tracks = tracks
    header = HeaderChunk(data: HeaderChunkData(format: .One, numberOfTracks: tracks.count, division: division))

  }

  var bytes: [Byte] {
    let chunks = tracks.map {
      (track: TrackType) -> TrackChunk in

      var events = track.events
      let nameEvent = MetaEvent(deltaTime: .zero, data: .SequenceTrackName(name: track.label))
      events.insert(nameEvent, atIndex: 0)

      let deltaTime: VariableLengthQuantity
      if case let tempoTrack as TempoTrack = track where tempoTrack.includesTempoChange == false { deltaTime = .zero }
      else { deltaTime = VariableLengthQuantity(time.timeStamp) }

      let endOfTrackEvent = MetaEvent(deltaTime: deltaTime, data: .EndOfTrack)
      events.append(endOfTrackEvent)

      return TrackChunk(data: TrackChunkData(events: events))
    }
    return header.bytes + chunks.flatMap({$0.bytes})
  }


  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "header: \(header.description.indentedBy(4, preserveFirstLineIndent: true))",
      "tracks: {\n" + ",\n".join(tracks.map({$0.description.indentedBy(8)})) + "\n\t}\n}"
    )
    return result
  }
}

