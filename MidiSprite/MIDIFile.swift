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
    return " ".join((type.bytes + data.length.bytes + data.bytes).map{ String($0, radix: 16, uppercase: true, pad: 2) })
  }
}

// MARK: - The chunk data protocol

/** Protocol for types that can produce the data portion of a chunk in a MIDI file */
protocol ChunkData {
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
  let format: MIDIFile.Format
  let numberOfTracks: Byte2
  let division: Byte2

  init(format: MIDIFile.Format, numberOfTracks: Int, division: Byte2) {
    self.format = format; self.numberOfTracks = Byte2(numberOfTracks); self.division = division
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
}

// MARK: - Encoding 'variable length' values

/** 
Struct for converting values to MIDI variable length quanity representation

These numbers are represented 7 bits per byte, most significant bits first. All bytes except the last have bit 7 set, and the 
last byte has bit 7 clear. If the number is between 0 and 127, it is thus represented exactly as one byte.
*/
struct VariableLengthQuantity: CustomStringConvertible {
  let bytes: [Byte]
  static let Zero = VariableLengthQuantity(0)

  var description: String { return " ".join(bytes.map { String($0, radix: 16, uppercase: true, pad: 2) }) }

  /**
  Initialize from any `ByteArrayConvertible` type

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
  var description: String { return " ".join(data.map { String($0, radix: 16, uppercase: true, pad: 2) }) }
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
}

// MARK: - The sysex track event

/* 
Master Volume:  F0 7F <device id> 04 01 vv vv F7 where vv vv has LSB first
Master Balance: F0 7F <device id> 04 01 bb bb F7 where bb bb has LSB first
*/

/** Struct to hold data for a sysex event where event = \<delta time\> **F0** \<length of sysex\> \<sysex\> **F7** */
struct SystemExclusiveEvent: TrackEvent {
  let deltaTime: VariableLengthQuantity
  let sysExData: SystemExclusiveEventData
  var bytes: [Byte] { return Byte(0xF0).bytes + sysExData.length.bytes + sysExData.bytes + Byte(0xF7).bytes }
  static func nodePlacementEvent(timestamp: MIDITimeStamp, placement: MIDINode.Placement) -> SystemExclusiveEvent {
    return SystemExclusiveEvent(deltaTime: VariableLengthQuantity(timestamp), sysExData: .NodePlacement(placement))
  }
}

/** An enumeration for encapsulating a type of sysex event */
enum SystemExclusiveEventData {
  case Other ([Byte])
  case NodePlacement(MIDINode.Placement)

  var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }

  var bytes: [Byte] {
    switch self {
      case .Other(let bytes):             return bytes
      case .NodePlacement(let placement): return placement.bytes
    }
  }
}

// MARK: - The meta track event

/** Struct to hold data for a meta event where event = \<delta time\> **FF** \<meta type\> \<length of meta\> \<meta\> */
struct MetaEvent: TrackEvent {
  let deltaTime: VariableLengthQuantity
  let metaEventData: MetaEventData
  var bytes: [Byte] { return Byte(0xFF).bytes + [metaEventData.type] + metaEventData.length.bytes + metaEventData.bytes }
}

/** Enumeration for encapsulating a type of meta event */
enum MetaEventData: CustomStringConvertible {
  case Other (Byte, [Byte])
  case Text (String)
  case CopyrightNotice (String)
  case SequenceTrackName (String)
  case InstrumentName (String)
  case EndOfTrack
  case Tempo (Byte4)
  case TimeSignature (Byte, Byte, Byte, Byte)
  case SequencerSpecific ([Byte])

  var type: Byte {
    switch self {
      case .Other(let type, _):       return type
      case .Text:                     return 0x01
      case .CopyrightNotice:          return 0x02
      case .SequenceTrackName:        return 0x03
      case .InstrumentName:           return 0x04
      case .EndOfTrack:               return 0x2F
      case .Tempo:                    return 0x51
      case .TimeSignature:            return 0x58
      case .SequencerSpecific:        return 0x7F
    }
  }

  var bytes: [Byte] {
    switch self {
      case .Other(_, let bytes):           return bytes
      case .Text(let text):                return Array(text.utf8)
      case .CopyrightNotice(let text):     return Array(text.utf8)
      case .SequenceTrackName(let text):   return Array(text.utf8)
      case .InstrumentName(let text):      return Array(text.utf8)
      case .EndOfTrack:                    return []
      case .Tempo(let tempo):              return Array(tempo.bytes.dropFirst())
      case let .TimeSignature(u, l, n, m): return [u, l, n, m]
      case .SequencerSpecific(let bytes):  return bytes
    }
  }

  var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
  var description: String {
    return " ".join(([type] + length.bytes + bytes).map{ String($0, radix: 16, uppercase: true, pad: 2) })
  }
}

/** Struct that holds the data for a complete MIDI file */
struct MIDIFile: CustomStringConvertible {
  enum Format: Byte2 { case Zero, One, Two }
  let header: HeaderChunk
  let tracks: [TrackChunk]
  var bytes: [Byte] { return header.bytes + tracks.flatMap({$0.bytes}) }
  var description: String { return " ".join(bytes.map({ String($0, radix: 16, uppercase: true, pad: 2) })) }
}

