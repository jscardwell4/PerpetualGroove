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

  var time: BarBeatTime = BarBeatTime.zero
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
  init<C:Collection>(delta d: VariableLengthQuantity, bytes: C) throws
    where C.Iterator.Element == Byte,
          C.IndexDistance == Int,
          C.SubSequence.Iterator.Element == Byte,
          C.SubSequence:Collection,
          C.SubSequence.IndexDistance == Int,
          C.SubSequence.SubSequence == C.SubSequence
  {
    delta = d
    guard bytes.count >= 3 else { throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes in event") }
    guard bytes[bytes.startIndex] == 0xFF else {
      throw MIDIFileError(type: .invalidHeader, reason: "First byte must be 0xFF")
    }
    var currentIndex = bytes.index(after: bytes.startIndex)
    let typeByte = bytes[currentIndex]
    bytes.formIndex(after: &currentIndex)
    var i = currentIndex
    while bytes[i] & 0x80 != 0 { bytes.formIndex(after: &i) }
    let dataLength = VariableLengthQuantity(bytes: bytes[currentIndex ... i])
    bytes.formIndex(after: &i)
    currentIndex = i
    bytes.formIndex(&i, offsetBy: dataLength.intValue)
    guard bytes.endIndex == i else { throw MIDIFileError(type: .invalidLength, reason: "Specified length does not match actual") }

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
    case text (text: String)
    case copyrightNotice (notice: String)
    case sequenceTrackName (name: String)
    case instrumentName (name: String)
    case marker (name: String)
    case deviceName (name: String)
    case programName (name: String)
    case endOfTrack
    case tempo (bpm: Double)
    case timeSignature (signature: Groove.TimeSignature, clocks: Byte, notes: Byte)

    var type: Byte {
      switch self {
        case .text:              return 0x01
        case .copyrightNotice:   return 0x02
        case .sequenceTrackName: return 0x03
        case .instrumentName:    return 0x04
        case .marker:            return 0x06
        case .programName:       return 0x08
        case .deviceName:        return 0x09
        case .endOfTrack:        return 0x2F
        case .tempo:             return 0x51
        case .timeSignature:     return 0x58
      }
    }

    var bytes: [Byte] {
      switch self {
        case let .text(text):               return text.bytes
        case let .copyrightNotice(text):    return text.bytes
        case let .sequenceTrackName(text):  return text.bytes
        case let .instrumentName(text):     return text.bytes
        case let .marker(text):             return text.bytes
        case let .programName(text):        return text.bytes
        case let .deviceName(text):         return text.bytes
        case .endOfTrack:                   return []
        case let .tempo(tempo):             return Array(Byte4(60_000_000 / tempo).bytes.dropFirst())
        case let .timeSignature(s, n, m):   return s.bytes + [n, m]
      }
    }

    /**
    initWithType:data:

    - parameter type: Byte
    - parameter data: C
    */
    init<C:Collection>(type: Byte, data: C) throws
      where C.Iterator.Element == Byte, C.SubSequence.Iterator.Element == Byte
    {
      switch type {
        case 0x01: self = .text(text: String(data))
        case 0x02: self = .copyrightNotice(notice: String(data))
        case 0x03: self = .sequenceTrackName(name: String(data))
        case 0x04: self = .instrumentName(name: String(data))
        case 0x06: self = .marker(name: String(data))
        case 0x08: self = .programName(name: String(data))
        case 0x09: self = .deviceName(name: String(data))
        case 0x2F:
          guard data.count == 0 else {
            throw MIDIFileError(type: .invalidLength, reason: "EndOfTrack event has no data")
          }
          self = .endOfTrack
        case 0x51:
          guard data.count == 3 else {
            throw MIDIFileError(type: .invalidLength, reason: "Tempo event data should have a 4 byte length")
          }
          self = .tempo(bpm: Double(60_000_000 / Byte4(data)))
        case 0x58:
          guard data.count == 4 else {
            throw MIDIFileError(type: .invalidLength, reason: "TimeSignature event data should have a 4 byte length")
          }
          self = .timeSignature(signature: Groove.TimeSignature(data[<--(data.index(data.startIndex, offsetBy: 2))]),
                                clocks: data[data.index(data.startIndex, offsetBy: 2)],
                                notes: data[data.index(data.startIndex, offsetBy: 3)])
        default:
          throw MIDIFileError(type: .unsupportedEvent,
                              reason: "\(String(hexBytes: [type])) is not a supported meta event type")
      }
    }

    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }

    /**
    withEventPointer:

    - parameter block: (UnsafePointer<MIDIMetaEvent>) throws -> Void
    */
    func withEventPointer(_ block: @escaping (UnsafePointer<MIDIMetaEvent>) throws -> Void) rethrows {
      // Get the bytes to put into the struct
      var bytes = self.bytes

      // Data length will be the length of the byte array
      let dataLength = bytes.count

      // Subtract one from size of struct because the last byte is for the data
      let structSize = MemoryLayout<MIDIMetaEvent>.size - 1

      // Calculate the total size needed in memory
      let totalSize = structSize + dataLength

      // Create a region of bytes in memory and make sure they are all zero
      var eventBytesPointer = UnsafeMutablePointer<Byte>.allocate(capacity: totalSize)
      eventBytesPointer.initialize(from: [Byte](repeating: 0, count: totalSize))

      // Set the `metaEventType` property using `type`
      eventBytesPointer.pointee = type

      // Advance to the `dataLength` property and set it
      eventBytesPointer = eventBytesPointer.advanced(by: 4)
      eventBytesPointer.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee = UInt32(dataLength) }

      // Advance to the first byte of data and copy into memory
      eventBytesPointer = eventBytesPointer.advanced(by: 4)
      eventBytesPointer.assign(from: &bytes, count: bytes.count)

      // Move pointer back to the start of the struct
      eventBytesPointer = eventBytesPointer.advanced(by: -8)

      try eventBytesPointer.withMemoryRebound(to: MIDIMetaEvent.self, capacity: 1) { try block($0) }

      eventBytesPointer.deinitialize()
      eventBytesPointer.deallocate(capacity: totalSize)
    }
  }

}

extension MetaEvent: Hashable {
  var hashValue: Int {
    let bytesHash = Int(_mixUInt64(bytes.segment(8).map({UInt64($0)}).reduce(0) { $0 ^ $1 }))
    let deltaHash = _mixInt(delta?.intValue ?? 0)
    let timeHash = time.totalBeats.hashValue
    return bytesHash ^ deltaHash ^ timeHash
  }
}

extension MetaEvent.Data: CustomStringConvertible {
  var description: String {
    switch self {
      case .text(let text):              return "text '\(text)'"
      case .copyrightNotice(let text):   return "copyright '\(text)'"
      case .sequenceTrackName(let text): return "sequence/track name '\(text)'"
      case .instrumentName(let text):    return "instrument name '\(text)'"
      case .marker(let text):            return "marker '\(text)'"
      case .programName(let text):       return "program name '\(text)'"
      case .deviceName(let text):        return "device name '\(text)'"
      case .endOfTrack:                  return "end of track"
      case .tempo(let bpm):              return "tempo \(bpm)"
      case .timeSignature(let s, _ , _): return "time signature \(s.beatsPerBar)╱\(s.beatUnit)"
    }
  }
}

extension MetaEvent.Data: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

extension MetaEvent: CustomStringConvertible { var description: String { return "\(time) \(data)" } }

extension MetaEvent: Equatable {}

func ==(lhs: MetaEvent, rhs: MetaEvent) -> Bool { return lhs.bytes == rhs.bytes }

extension MetaEvent.Data: Equatable {}

func ==(lhs: MetaEvent.Data, rhs: MetaEvent.Data) -> Bool {
  switch (lhs, rhs) {
    case let (.text(text1), .text(text2)) where text1 == text2: return true
    case let (.copyrightNotice(notice1), .copyrightNotice(notice2)) where notice1 == notice2: return true
    case let (.sequenceTrackName(name1), .sequenceTrackName(name2)) where name1 == name2: return true
    case let (.instrumentName(name1), .instrumentName(name2)) where name1 == name2: return true
    case (.endOfTrack, .endOfTrack): return true
    case let (.tempo(microseconds1), .tempo(microseconds2)) where microseconds1 == microseconds2: return true
    case let (.timeSignature(signature1, clocks1, notes1), .timeSignature(signature2, clocks2, notes2))
      where signature1.beatsPerBar == signature2.beatsPerBar
         && signature1.beatUnit == signature2.beatUnit
         && clocks1 == clocks2
         && notes1 == notes2: return true
    default: return false
  }
}
