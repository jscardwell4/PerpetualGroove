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

  var time: CABarBeatTime = .start

  let status: Byte
  let data1: Byte
  let data2: Byte?

  var bytes: [Byte] { return [status, data1] + (data2 != nil ? [data2!] : []) }

  static func noteOnEvent(channel channel: Byte, note: Byte, velocity: Byte) -> ChannelEvent {
    return ChannelEvent(status: 0x90 | channel, data1: note, data2: velocity)
  }

  static func noteOffEvent(channel channel: Byte, note: Byte, velocity: Byte) -> ChannelEvent {
    return ChannelEvent(status: 0x80 | channel, data1: note, data2: velocity)
  }

  init(status: Byte, data1: Byte, data2: Byte? = nil) {
    self.status = status; self.data1 = data1; self.data2 = data2
  }

  /** Computed property for the equivalent `MIDIChannelMessage` struct consumed by the MusicPlayer API */
  var message: MIDIChannelMessage {
    return MIDIChannelMessage(status: status, data1: data1, data2: data2 ?? 0, reserved: 0)
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "time: \(time)(\(time.doubleValue); \(time.tickValue))",
      "status: \(String(hexBytes: status))",
      "data1: \(String(data1, radix: 16, uppercase: true, pad: 2, group: 2))",
      "data2: " + (data2 == nil ? "nil" : String(hexBytes: data2!))
    )
    result += "\n}"
    return result
  }
}

