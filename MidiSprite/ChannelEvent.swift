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
struct ChannelEvent: MIDIEvent {

  enum EventType: Byte, IntegerLiteralConvertible {
    case NoteOff               = 0x8
    case NoteOn                = 0x9
    case PolyphonicKeyPressure = 0xA
    case ControlChange         = 0xB
    case ProgramChange         = 0xC
    case ChannelPressure       = 0xD
    case PitchBendChange       = 0xE

    /**
    init:

    - parameter value: Byte
    */
    init(integerLiteral value: Byte) { self.init(value) }

    /**
    init:

    - parameter v: Byte
    */
    init(_ v: Byte) { self = EventType(rawValue: ClosedInterval<Byte>(0x8, 0xE).clampValue(v))! }

    var byteCount: Int {
      switch self {
        case .ControlChange, .ProgramChange, .ChannelPressure: return 2
        default:                                               return 3
      }
    }

  }

  struct Status: IntegerLiteralConvertible {
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

  var time: CABarBeatTime = .start
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
  init<C:CollectionType
    where C.Generator.Element == Byte, C.Index.Distance == Int>(delta: VariableLengthQuantity, bytes: C) throws
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

    data1 = bytes[bytes.startIndex + 1]
    data2 =  t.byteCount == 3 ? bytes[bytes.startIndex + 2] : nil
  }

  /**
  init:channel:d1:d2:t:

  - parameter type: Type
  - parameter channel: Byte
  - parameter d1: Byte
  - parameter d2: Byte? = nil
  - parameter t: CABarBeatTime? = nil
  */
  init(_ type: EventType, _ channel: Byte, _ d1: Byte, _ d2: Byte? = nil, _ t: CABarBeatTime? = nil) {
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
      case .NoteOff:               return "note off"
      case .NoteOn:                return "note on"
      case .PolyphonicKeyPressure: return "polyphonic key pressure"
      case .ControlChange:         return "control change"
      case .ProgramChange:         return "program change"
      case .ChannelPressure:       return "channel pressure"
      case .PitchBendChange:       return "pitch bend change"
    }
  }
}

extension ChannelEvent.Status: CustomStringConvertible { var description: String { return "\(type) (\(channel))" } }

extension ChannelEvent: CustomStringConvertible {
  var description: String {
    var result = "\(status) "
    switch status.type {
      case .NoteOn, .NoteOff:
        result += "\(NoteAttributes.Note(midi: data1)) \(NoteAttributes.Velocity(midi: data2!))"
      default:
        result += "\(data1)"
    }
    return result
  }
}

