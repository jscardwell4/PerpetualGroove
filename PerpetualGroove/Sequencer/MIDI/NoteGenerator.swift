//
//  NoteGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import CoreMIDI

/// Structure that encapsulates MIDI information necessary for playing a note
struct NoteGenerator {

  var channel: UInt8 = 0

  typealias Tone = MIDINote
  
  /// The pitch and octave
  var tone: Tone

  /// The duration of the played note
  var duration: Duration

  /// The dynmamics for the note
  var velocity: Velocity

  /// The octave held by `tone`
  var octave: Octave { get { return tone.octave } set { tone.octave = newValue } }

  /// The pitch held by `tone`
  var root: Note { get { return tone.note } set { tone.note = newValue } }

  init(tone: Tone = Tone(midi: 60), duration: Duration = .eighth, velocity: Velocity = .𝑚𝑓) {
    self.tone = tone
    self.duration = duration
    self.velocity = velocity
  }

  init(generator: ChordGenerator) {
    self.init(tone: Tone(generator.chord.root, generator.octave),
              duration: generator.duration,
              velocity: generator.velocity)
  }

}

extension NoteGenerator: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return ObjectJSONValue([
      "tone": tone.jsonValue,
      "duration": duration.jsonValue,
      "velocity": velocity.jsonValue,
      "octave": octave.jsonValue,
      "root": root.jsonValue
      ]).jsonValue
  }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              let tone = Tone(dict["tone"]),
              let duration = Duration(dict["duration"]),
              let velocity = Velocity(dict["velocity"]),
              let octave = Octave(dict["octave"]),
              let root = Note(dict["root"]) else { return nil }
    self.tone = tone
    self.duration = duration
    self.velocity = velocity
    self.octave = octave
    self.root = root
  }

}

extension NoteGenerator: MIDIGenerator {

  func receiveNoteOn(endPoint: MIDIEndpointRef, identifier: UInt) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: UInt64(identifier))
    var packetList = packet.packetList
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note on event"
  }

  func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt) throws {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: UInt64(identifier))
    var packetList = packet.packetList
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note off event"
  }

  func sendNoteOn(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note on event"
  }

  func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note off event"
  }

}

extension NoteGenerator: ByteArrayConvertible {

  var bytes: [Byte] { return [channel, tone.midi, velocity.midi] + duration.rawValue.bytes }

  init(_ bytes: [Byte]) {
    guard bytes.count >= 7 else { self = NoteGenerator(); return }
    channel  = bytes[0]
    tone     = Tone(midi: bytes[1])
    velocity = Velocity(midi: bytes[2])
    duration = Duration(rawValue: String(bytes[3|->])) ?? .eighth
  }
}

extension NoteGenerator: CustomStringConvertible {
  var description: String { return "{\(channel), \(tone), \(duration), \(velocity)}" }
}

extension NoteGenerator: Hashable {

  var hashValue: Int {
    return channel.hashValue ^ duration.hashValue ^ velocity.hashValue ^ tone.hashValue
  }

  static func ==(lhs: NoteGenerator, rhs: NoteGenerator) -> Bool {
    return lhs.channel == rhs.channel
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
      && lhs.tone == rhs.tone
  }
  
}
