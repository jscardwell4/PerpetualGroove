//
//  ChannelEvent.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioToolbox

/** Struct to hold data for a channel event where event = \<delta time\> \<status\> \<data1\> \<data2\> */
struct ChannelEvent: MIDITrackEvent {

  enum EventType: Byte, IntegerLiteralConvertible, CustomStringConvertible {
    case NoteOff               = 0x8
    case NoteOn                = 0x9
    case PolyphonicKeyPressure = 0xA
    case ControlChange         = 0xB
    case ProgramChange         = 0xC
    case ChannelPressure       = 0xD
    case PitchBendChange       = 0xE
    init(integerLiteral value: Byte) { self.init(value) }
    init(_ v: Byte) { self = EventType(rawValue: ClosedInterval<Byte>(0x8, 0xE).clampValue(v))! }
    var byteCount: Int {
      switch self {
        case .ControlChange, .ProgramChange, .ChannelPressure: return 2
        default: return 3
      }
    }
    var description: String {
      switch self {
        case .NoteOff:               return "NoteOff (0x8)"
        case .NoteOn:                return "NoteOn (0x9)"
        case .PolyphonicKeyPressure: return "PolyphonicKeyPressure (0xA)"
        case .ControlChange:         return "ControlChange (0xB)"
        case .ProgramChange:         return "ProgramChange (0xC)"
        case .ChannelPressure:       return "ChannelPressure (0xD)"
        case .PitchBendChange:       return "PitchBendChange (0xE)"
      }
    }
  }

  struct Status: IntegerLiteralConvertible {
    var value: Byte { return (type.rawValue << 4) | channel }
    let type: EventType
    let channel: Byte
    init(integerLiteral value: Byte) { self.init(value) }
    init(_ v: Byte) { self.init(EventType(v >> 4), v & 0xF) }
    init(_ t: EventType, _ c: Byte) { type = t; channel = (0 ... 15).clampValue(c) }
  }

  var time: CABarBeatTime = .start
  var delta: VariableLengthQuantity?
  let status: Status
  let data1: Byte
  let data2: Byte?

  var bytes: [Byte] { return [status.value, data1] + (data2 != nil ? [data2!] : []) }

  /**
  initWithDelta:bytes:

  - parameter delta: VariableLengthQuantity
  - parameter bytes: C
  */
  init<C:CollectionType where C.Generator.Element == Byte,
    C.Index.Distance == Int>(delta: VariableLengthQuantity, bytes: C) throws
  {
    self.delta = delta
    guard let t = EventType(rawValue: bytes[bytes.startIndex] >> 4) else {
      throw MIDIFileError(type: .UnsupportedEvent, reason: "\(bytes[bytes.startIndex] >> 4) is not a supported channel event")
    }
    guard bytes.count == t.byteCount else {
      throw MIDIFileError(type: .InvalidLength, reason: "\(t) events expect a total byte count of \(t.byteCount)")
    }
    status = Status(bytes[bytes.startIndex])

    data1 = bytes[bytes.startIndex.successor()]
    data2 =  t.byteCount == 3 ? bytes[bytes.startIndex.successor().successor()] : nil
  }

  /**
  init:channel:d1:d2:

  - parameter type: Type
  - parameter channel: Byte
  - parameter d1: Byte
  - parameter d2: Byte? = nil
  */
  init(_ type: EventType, _ channel: Byte, _ d1: Byte, _ d2: Byte? = nil) {
    status = Status(type, channel); data1 = d1; data2 = d2
  }

  /** Computed property for the equivalent `MIDIChannelMessage` struct consumed by the MusicPlayer API */
  var message: MIDIChannelMessage {
    return MIDIChannelMessage(status: status.value, data1: data1, data2: data2 ?? 0, reserved: 0)
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "time: \(time)",
      "delta: " + (delta?.description ?? "nil"),
      "status: \(String(hexBytes: status.value))",
      "data1: \(String(data1, radix: 16, uppercase: true, pad: 2, group: 2))",
      "data2: " + (data2 == nil ? "nil" : String(hexBytes: data2!))
    )
    result += "\n}"
    return result
  }
}

