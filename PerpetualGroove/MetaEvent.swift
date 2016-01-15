//
//  MetaEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.MIDIMetaEvent

/** Struct to hold data for a meta event where event = \<delta time\> **FF** \<meta type\> \<length of meta\> \<meta\> */
struct MetaEvent: MIDIEventType {

  var time: BarBeatTime = .start
  var data: Data
  var delta: VariableLengthQuantity?
  var bytes: [Byte] { return [0xFF, data.type] + data.length.bytes + data.bytes }

  /**
  Initializer that takes the event's data and, optionally, the event's time

  - parameter d: Data
  - paramter t: BarBeatTime? = nil
  */
  init(_ d: Data, _ t: BarBeatTime? = nil) { data = d; if let t = t { time = t } }

  /**
  initWithDelta:bytes:

  - parameter d: VariableLengthQuantity
  - parameter bytes: C
  */
  init<C:CollectionType
    where C.Generator.Element == Byte,
          C.Index.Distance == Int,
          C.SubSequence.Generator.Element == Byte,
          C.SubSequence:CollectionType,
          C.SubSequence.Index.Distance == Int,
          C.SubSequence.SubSequence == C.SubSequence>(delta d: VariableLengthQuantity, bytes: C) throws
  {
    delta = d
    guard bytes.count >= 3 else { throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes in event") }
    guard bytes[bytes.startIndex] == 0xFF else {
      throw MIDIFileError(type: .InvalidHeader, reason: "First byte must be 0xFF")
    }
    var currentIndex = bytes.startIndex + 1
    let typeByte = bytes[currentIndex++]
    var i = currentIndex
    while bytes[i] & 0x80 != 0 { i++ }
    let dataLength = VariableLengthQuantity(bytes: bytes[currentIndex ... i++])
    currentIndex = i
    i += dataLength.intValue
    guard bytes.endIndex == i else { throw MIDIFileError(type: .InvalidLength, reason: "Specified length does not match actual") }

    data = try Data(type: typeByte, data: bytes[currentIndex ..< i])
  }
  
  /**
  Initializer that takes a `VariableLengthQuantity` as well as the event's data

  - parameter barBeatTime: CABarBeatTiime
  - parameter data: Data
  */
  init(_ t: BarBeatTime, _ d: Data) { time = t; data = d }

  /** Enumeration for encapsulating a type of meta event */
  enum Data {
    case Text (text: String)
    case CopyrightNotice (notice: String)
    case SequenceTrackName (name: String)
    case InstrumentName (name: String)
    case Marker (name: String)
    case DeviceName (name: String)
    case ProgramName (name: String)
    case EndOfTrack
    case Tempo (bpm: Double)
    case TimeSignature (signature: Groove.TimeSignature, clocks: Byte, notes: Byte)

    var type: Byte {
      switch self {
        case .Text:              return 0x01
        case .CopyrightNotice:   return 0x02
        case .SequenceTrackName: return 0x03
        case .InstrumentName:    return 0x04
        case .Marker:            return 0x06
        case .ProgramName:       return 0x08
        case .DeviceName:        return 0x09
        case .EndOfTrack:        return 0x2F
        case .Tempo:             return 0x51
        case .TimeSignature:     return 0x58
      }
    }

    var bytes: [Byte] {
      switch self {
        case let .Text(text):               return text.bytes
        case let .CopyrightNotice(text):    return text.bytes
        case let .SequenceTrackName(text):  return text.bytes
        case let .InstrumentName(text):     return text.bytes
        case let .Marker(text):             return text.bytes
        case let .ProgramName(text):        return text.bytes
        case let .DeviceName(text):         return text.bytes
        case .EndOfTrack:                   return []
        case let .Tempo(tempo):             return Array(Byte4(60_000_000 / tempo).bytes.dropFirst())
        case let .TimeSignature(s, n, m):   return s.bytes + [n, m]
      }
    }

    /**
    initWithType:data:

    - parameter type: Byte
    - parameter data: C
    */
    init<C:CollectionType
      where C.Generator.Element == Byte, C.SubSequence.Generator.Element == Byte>(type: Byte, data: C) throws
    {
      switch type {
        case 0x01: self = .Text(text: String(data))
        case 0x02: self = .CopyrightNotice(notice: String(data))
        case 0x03: self = .SequenceTrackName(name: String(data))
        case 0x04: self = .InstrumentName(name: String(data))
        case 0x06: self = .Marker(name: String(data))
        case 0x08: self = .ProgramName(name: String(data))
        case 0x09: self = .DeviceName(name: String(data))
        case 0x2F:
          guard data.count == 0 else {
            throw MIDIFileError(type: .InvalidLength, reason: "EndOfTrack event has no data")
          }
          self = .EndOfTrack
        case 0x51:
          guard data.count == 3 else {
            throw MIDIFileError(type: .InvalidLength, reason: "Tempo event data should have a 4 byte length")
          }
          self = .Tempo(bpm: Double(60_000_000 / Byte4(data)))
        case 0x58:
          guard data.count == 4 else {
            throw MIDIFileError(type: .InvalidLength, reason: "TimeSignature event data should have a 4 byte length")
          }
          self = .TimeSignature(signature: Groove.TimeSignature(data[..<(data.startIndex + 2)]),
                                clocks: data[data.startIndex + 2],
                                notes: data[data.startIndex + 3])
        default:
          throw MIDIFileError(type: .UnsupportedEvent,
                              reason: "\(String(hexBytes: [type])) is not a supported meta event type")
      }
    }

    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }

    /**
    withEventPointer:

    - parameter block: (UnsafePointer<MIDIMetaEvent>) throws -> Void
    */
    func withEventPointer(@noescape block: (UnsafePointer<MIDIMetaEvent>) throws -> Void) rethrows {
      // Get the bytes to put into the struct
      var bytes = self.bytes

      // Data length will be the length of the byte array
      let dataLength = bytes.count

      // Subtract one from size of struct because the last byte is for the data
      let structSize = sizeof(MIDIMetaEvent.self) - 1

      // Calculate the total size needed in memory
      let totalSize = structSize + dataLength

      // Create a region of bytes in memory and make sure they are all zero
      var eventBytesPointer = UnsafeMutablePointer<Byte>.alloc(totalSize)
      eventBytesPointer.initializeFrom([Byte](count: totalSize, repeatedValue: 0))

      // Set the `metaEventType` property using `type`
      eventBytesPointer.memory = type

      // Advance to the `dataLength` property and set it
      eventBytesPointer = eventBytesPointer.advancedBy(4)
      UnsafeMutablePointer<UInt32>(eventBytesPointer).memory = UInt32(dataLength)

      // Advance to the first byte of data and copy into memory
      eventBytesPointer = eventBytesPointer.advancedBy(4)
      eventBytesPointer.assignFrom(&bytes, count: bytes.count)

      // Move pointer back to the start of the struct
      eventBytesPointer = eventBytesPointer.advancedBy(-8)

      let eventPointer = UnsafePointer<MIDIMetaEvent>(eventBytesPointer)

      try block(eventPointer)

      eventBytesPointer.destroy()
      eventBytesPointer.dealloc(totalSize)
    }
  }

}

extension MetaEvent.Data: CustomStringConvertible {
  var description: String {
    switch self {
      case .Text(let text):              return "text '\(text)'"
      case .CopyrightNotice(let text):   return "copyright '\(text)'"
      case .SequenceTrackName(let text): return "sequence/track name '\(text)'"
      case .InstrumentName(let text):    return "instrument name '\(text)'"
      case .Marker(let text):            return "marker '\(text)'"
      case .ProgramName(let text):       return "program name '\(text)'"
      case .DeviceName(let text):        return "device name '\(text)'"
      case .EndOfTrack:                  return "end of track"
      case .Tempo(let bpm):              return "tempo \(bpm)"
      case .TimeSignature(let s, _ , _): return "time signature \(s.beatsPerBar)╱\(s.beatUnit)"
    }
  }
}

extension MetaEvent.Data: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension MetaEvent: CustomStringConvertible { var description: String { return "\(time) \(data)" } }

extension MetaEvent: Equatable {}

func ==(lhs: MetaEvent, rhs: MetaEvent) -> Bool { return lhs.bytes == rhs.bytes }

extension MetaEvent.Data: Equatable {}

func ==(lhs: MetaEvent.Data, rhs: MetaEvent.Data) -> Bool {
  switch (lhs, rhs) {
    case let (.Text(text1), .Text(text2)) where text1 == text2: return true
    case let (.CopyrightNotice(notice1), .CopyrightNotice(notice2)) where notice1 == notice2: return true
    case let (.SequenceTrackName(name1), .SequenceTrackName(name2)) where name1 == name2: return true
    case let (.InstrumentName(name1), .InstrumentName(name2)) where name1 == name2: return true
    case (.EndOfTrack, .EndOfTrack): return true
    case let (.Tempo(microseconds1), .Tempo(microseconds2)) where microseconds1 == microseconds2: return true
    case let (.TimeSignature(signature1, clocks1, notes1), .TimeSignature(signature2, clocks2, notes2))
      where signature1.beatsPerBar == signature2.beatsPerBar
         && signature1.beatUnit == signature2.beatUnit
         && clocks1 == clocks2
         && notes1 == notes2: return true
    default: return false
  }
}
