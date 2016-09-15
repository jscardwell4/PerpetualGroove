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

/** Struct to hold data for a channel event where event = \<delta time\> \<status\> \<data1\> \<data2\> */
struct ChannelEvent: MIDIEventType {

  enum EventType: Byte, ExpressibleByIntegerLiteral {
    case noteOff               = 0x8
    case noteOn                = 0x9
    case polyphonicKeyPressure = 0xA
    case controlChange         = 0xB
    case programChange         = 0xC
    case channelPressure       = 0xD
    case pitchBendChange       = 0xE

    /**
    init:

    - parameter value: Byte
    */
    init(integerLiteral value: Byte) { self.init(value) }

    /**
    init:

    - parameter v: Byte
    */
    init(_ v: Byte) { self = EventType(rawValue: (0x8 ... 0xE).clampValue(v))! }

    var byteCount: Int {
      switch self {
        case .controlChange, .programChange, .channelPressure: return 2
        default:                                               return 3
      }
    }

  }

  struct Status: ExpressibleByIntegerLiteral {
    var type: EventType
    var channel: Byte

    var value: Byte { return (type.rawValue << 4) | channel }

    /**
    init:

    - parameter value: Byte
    */
    init(integerLiteral value: Byte) { self.init(value) }

    /**
    init:

    - parameter v: Byte
    */
    init(_ v: Byte) { self.init(EventType(v >> 4), v & 0xF) }

    /**
    init:c:

    - parameter t: EventType
    - parameter c: Byte
    */
    init(_ t: EventType, _ c: Byte) { type = t; channel = (0 ... 15).clampValue(c) }
  }

  var time: BarBeatTime = .start1
  var delta: VariableLengthQuantity?
  var status: Status
  var data1: Byte
  var data2: Byte?

  var bytes: [Byte] { return [status.value, data1] + (data2 != nil ? [data2!] : []) }

  /**
  initWithDelta:bytes:

  - parameter delta: VariableLengthQuantity
  - parameter bytes: C
  */
  init<C:Collection>(delta: VariableLengthQuantity, bytes: C) throws
    where C.Iterator.Element == Byte, C.IndexDistance == Int
  {
    self.delta = delta
    guard let t = EventType(rawValue: bytes[bytes.startIndex] >> 4) else {
      throw MIDIFileError(type: .UnsupportedEvent,
                          reason: "\(bytes[bytes.startIndex] >> 4) is not a supported channel event")
    }
    guard bytes.count == t.byteCount else {
      throw MIDIFileError(type: .InvalidLength, reason: "\(t) events expect a total byte count of \(t.byteCount)")
    }
    status = Status(bytes[bytes.startIndex])

    data1 = bytes[bytes.index(after: bytes.startIndex)]
    data2 =  t.byteCount == 3 ? bytes[bytes.index(bytes.startIndex, offsetBy: 2)] : nil
  }

  /**
  init:channel:d1:d2:t:

  - parameter type: Type
  - parameter channel: Byte
  - parameter d1: Byte
  - parameter d2: Byte? = nil
  - parameter t: BarBeatTime? = nil
  */
  init(_ type: EventType, _ channel: Byte, _ d1: Byte, _ d2: Byte? = nil, _ t: BarBeatTime? = nil) {
    status = Status(type, channel); data1 = d1; data2 = d2
    if let t = t { time = t }
  }

  /** Computed property for the equivalent `MIDIChannelMessage` struct consumed by the MusicPlayer API */
  var message: MIDIChannelMessage {
    return MIDIChannelMessage(status: status.value, data1: data1, data2: data2 ?? 0, reserved: 0)
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

extension ChannelEvent.Status: CustomStringConvertible { var description: String { return "\(type) (\(channel))" } }

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

extension ChannelEvent: Equatable {}

func ==(lhs: ChannelEvent, rhs: ChannelEvent) -> Bool {
  return lhs.bytes == rhs.bytes
}
