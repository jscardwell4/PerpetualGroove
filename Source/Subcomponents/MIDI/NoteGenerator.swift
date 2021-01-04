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
public struct NoteGenerator {

  public var channel: UInt8 = 0

  public typealias Tone = MIDINote
  
  /// The pitch and octave
  public var tone: Tone

  /// The duration of the played note
  public var duration: Duration

  /// The dynmamics for the note
  public var velocity: Velocity

  /// The octave held by `tone`
  public var octave: Octave { get { return tone.octave } set { tone.octave = newValue } }

  /// The pitch held by `tone`
  public var root: Note { get { return tone.note } set { tone.note = newValue } }

  public init(tone: Tone = Tone(midi: 60), duration: Duration = .eighth, velocity: Velocity = .𝑚𝑓) {
    self.tone = tone
    self.duration = duration
    self.velocity = velocity
  }

  public init(generator: ChordGenerator) {
    self.init(tone: Tone(generator.chord.root, generator.octave),
              duration: generator.duration,
              velocity: generator.velocity)
  }

}

extension NoteGenerator: LosslessJSONValueConvertible {

  public var jsonValue: JSONValue {
    return ObjectJSONValue([
      "tone": tone.jsonValue,
      "duration": duration.jsonValue,
      "velocity": velocity.jsonValue,
      "octave": octave.jsonValue,
      "root": root.jsonValue
      ]).jsonValue
  }

  public init?(_ jsonValue: JSONValue?) {
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

  public func receiveNoteOn(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: UInt64(identifier))
    var packetList = packet.packetList(ticks: ticks)
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note on event"
  }

  public func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: UInt64(identifier))
    var packetList = packet.packetList(ticks: ticks)
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note off event"
  }

  public func sendNoteOn(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList(ticks: ticks)
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note on event"
  }

  public func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList(ticks: ticks)
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note off event"
  }

}

extension NoteGenerator: ByteArrayConvertible {

  public var bytes: [UInt8] { return [channel, tone.midi, velocity.midi] + duration.rawValue.bytes }

  public init(_ bytes: [UInt8]) {
    guard bytes.count >= 7 else { self = NoteGenerator(); return }
    channel  = bytes[0]
    tone     = Tone(midi: bytes[1])
    velocity = Velocity(midi: bytes[2])
    duration = Duration(rawValue: String(bytes: bytes[3|->])) ?? .eighth
  }
}

extension NoteGenerator: CustomStringConvertible {
  public var description: String { return "{\(channel), \(tone), \(duration), \(velocity)}" }
}

extension NoteGenerator: Hashable {

  public func hash(into hasher: inout Hasher) {
    channel.hash(into: &hasher)
    duration.hash(into: &hasher)
    velocity.hash(into: &hasher)
    tone.hash(into: &hasher)
  }

  public static func ==(lhs: NoteGenerator, rhs: NoteGenerator) -> Bool {
    return lhs.channel == rhs.channel
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
      && lhs.tone == rhs.tone
  }
  
}
