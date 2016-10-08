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

/// Struct to hold data for a meta event where 
/// event = \<delta time\> **FF** \<meta type\> \<length of meta\> \<meta\>
struct MetaEvent: MIDIEvent {

  var time: BarBeatTime = BarBeatTime.zero
  var data: Data
  var delta: MIDIFile.VariableLengthQuantity?

  var bytes: [Byte] { return [0xFF, data.type] + data.length.bytes + data.bytes }

  ///Initializer that takes the event's data and, optionally, the event's time
  init(_ d: Data, _ t: BarBeatTime? = nil) { data = d; if let t = t { time = t } }

  init(delta: MIDIFile.VariableLengthQuantity, data: Foundation.Data.SubSequence) throws {
    self.delta = delta
    guard data.count >= 3 else { throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes in event") }
    guard data[data.startIndex] == 0xFF else {
      throw MIDIFileError(type: .invalidHeader, reason: "First byte must be 0xFF")
    }
    var currentIndex = data.startIndex + 1

    let typeByte = data[currentIndex]
    currentIndex += 1

    var i = currentIndex
    while data[i] & 0x80 != 0 { i += 1 }

    let dataLength = MIDIFile.VariableLengthQuantity(bytes: data[currentIndex ... i])
    currentIndex = i + 1
    i += dataLength.intValue + 1

    guard data.endIndex == i else {
      throw MIDIFileError(type: .invalidLength,
                          reason: "Specified length does not match actual")
    }

    self.data = try Data(type: typeByte, data: data[currentIndex ..< i])
  }
  
  /// Initializer that takes a `VariableLengthQuantity` as well as the event's data.
  init(time: BarBeatTime, data: Data) { self.time = time; self.data = data }

  /// Enumeration for encapsulating a type of meta event.
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

    var type: UInt8 {
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

    init(type: UInt8, data: Foundation.Data.SubSequence) throws {
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
          self = .timeSignature(signature: Groove.TimeSignature(data.prefix(2)),
                                clocks: data[data.startIndex + 2],
                                notes: data[data.startIndex + 3])
        default:
          throw MIDIFileError(type: .unsupportedEvent,
                              reason: "\(String(hexBytes: [type])) is not a supported meta event type")
      }
    }

    var length: MIDIFile.VariableLengthQuantity { return MIDIFile.VariableLengthQuantity(bytes.count) }

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

extension MetaEvent: CustomStringConvertible { var description: String { return "\(time) \(data)" } }

extension MetaEvent: Equatable {

  static func ==(lhs: MetaEvent, rhs: MetaEvent) -> Bool { return lhs.bytes == rhs.bytes }

}

extension MetaEvent.Data: Equatable {

  static func ==(lhs: MetaEvent.Data, rhs: MetaEvent.Data) -> Bool {
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

}
