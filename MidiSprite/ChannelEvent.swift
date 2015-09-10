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
struct ChannelEvent: TrackEvent {

  enum Type: Byte, IntegerLiteralConvertible {
    case NoteOff               = 0x8
    case NoteOn                = 0x9
    case PolyphonicKeyPressure = 0xA
    case ControlChange         = 0xB
    case ProgramChange         = 0xC
    case ChannelPressure       = 0xD
    case PitchBendChange       = 0xE
    init(integerLiteral value: Byte) { self.init(value) }
    init(_ v: Byte) { self = Type(rawValue: ClosedInterval<Byte>(0x8, 0xE).clampValue(v))! }
  }

  struct Status: IntegerLiteralConvertible {
    var value: Byte { return (type.rawValue << 4) | channel }
    let type: Type
    let channel: Byte
    init(integerLiteral value: Byte) { self.init(value) }
    init(_ v: Byte) { self.init(Type(v >> 4), v & 0xF) }
    init(_ t: Type, _ c: Byte) { type = t; channel = (0 ... 15).clampValue(c) }
  }

  var time: CABarBeatTime = .start

  let status: Status
  let data1: Byte
  let data2: Byte?

  var bytes: [Byte] { return [status.value, data1] + (data2 != nil ? [data2!] : []) }

  init(_ type: Type, _ channel: Byte, _ d1: Byte, _ d2: Byte? = nil) {
    status = Status(type, channel); data1 = d1; data2 = d2
  }

  /** Computed property for the equivalent `MIDIChannelMessage` struct consumed by the MusicPlayer API */
  var message: MIDIChannelMessage {
    return MIDIChannelMessage(status: status.value, data1: data1, data2: data2 ?? 0, reserved: 0)
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "time: \(time)(\(time.doubleValue); \(time.tickValue))",
      "status: \(String(hexBytes: status.value))",
      "data1: \(String(data1, radix: 16, uppercase: true, pad: 2, group: 2))",
      "data2: " + (data2 == nil ? "nil" : String(hexBytes: data2!))
    )
    result += "\n}"
    return result
  }
}

