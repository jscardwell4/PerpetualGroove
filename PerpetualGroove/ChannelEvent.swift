//
//  ChannelEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioToolbox

/// Struct to hold data for a channel event where 
/// event = \<delta time\> \<status\> \<data1\> \<data2\>
struct ChannelEvent: MIDIEvent {

  var time: BarBeatTime
  var delta: MIDIFile.VariableLengthQuantity?
  var status: Status
  var data1: Byte
  var data2: Byte?

  var bytes: [Byte] { return [status.value, data1] + (data2 != nil ? [data2!] : []) }

  init(delta: MIDIFile.VariableLengthQuantity,
       data: Foundation.Data.SubSequence,
       time: BarBeatTime = BarBeatTime.zero) throws
  {

    self.delta = delta

    guard let type = EventType(rawValue: data[data.startIndex] >> 4) else {
      throw MIDIFileError(type: .unsupportedEvent,
                          reason: "\(data[data.startIndex] >> 4) is not a supported channel event")
    }

    guard data.count == type.byteCount else {
      throw MIDIFileError(type: .invalidLength,
                          reason: "\(type) events expect a total byte count of \(type.byteCount)")
    }

    status = Status(data[data.startIndex])

    data1 = data[data.startIndex + 1]
    data2 =  type.byteCount == 3 ? data[data.startIndex + 2] : nil

    self.time = time

  }

  init(type: EventType, channel: Byte, data1: Byte, data2: Byte? = nil, time: BarBeatTime = BarBeatTime.zero) {

    status = Status(type: type, channel: channel)
    self.data1 = data1
    self.data2 = data2
    self.time = time

  }

}

extension ChannelEvent: CustomStringConvertible {

  var description: String {
    var result = "\(time) \(status) "
    switch status.type {
      case .noteOn, .noteOff:
        result += "\(NoteGenerator.Tone(midi: data1)) \(Velocity(midi: data2!))"
      default:
        result += "\(data1)"
    }
    return result
  }

}

extension ChannelEvent: Equatable {

  static func ==(lhs: ChannelEvent, rhs: ChannelEvent) -> Bool {
    return lhs.bytes == rhs.bytes
  }

}

extension ChannelEvent {

  enum EventType: UInt8, ExpressibleByIntegerLiteral {
    case noteOff               = 0x8
    case noteOn                = 0x9
    case polyphonicKeyPressure = 0xA
    case controlChange         = 0xB
    case programChange         = 0xC
    case channelPressure       = 0xD
    case pitchBendChange       = 0xE

    init(integerLiteral value: Byte) { self.init(value) }

    init(_ v: Byte) { self = EventType(rawValue: (0x8 ... 0xE).clampValue(v))! }

    var byteCount: Int {
      switch self {
        case .controlChange, .programChange, .channelPressure: return 2
        default:                                               return 3
      }
    }

  }

}

extension ChannelEvent.EventType: CustomStringConvertible {

  var description: String {
    switch self {
      case .noteOff:               return "note off"
      case .noteOn:                return "note on"
      case .polyphonicKeyPressure: return "polyphonic key pressure"
      case .controlChange:         return "control change"
      case .programChange:         return "program change"
      case .channelPressure:       return "channel pressure"
      case .pitchBendChange:       return "pitch bend change"
    }
  }

}

extension ChannelEvent {

  struct Status: ExpressibleByIntegerLiteral {
    var type: EventType
    var channel: Byte

    var value: Byte { return (type.rawValue << 4) | channel }

    init(integerLiteral value: Byte) { self.init(value) }

    init(_ v: Byte) { self.init(type: EventType(v >> 4), channel: v & 0xF) }

    init(type: EventType, channel: Byte) {
      self.type = type
      self.channel = (0 ... 15).clampValue(channel)
    }
  }

}

extension ChannelEvent.Status: CustomStringConvertible {

  var description: String { return "\(type) (\(channel))" }

}
