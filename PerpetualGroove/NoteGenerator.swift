//
//  NoteGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

/// Structure that encapsulates MIDI information necessary for playing a note
struct NoteGenerator {

  var channel: UInt8 = 0

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

  func receiveNoteOn(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: identifier)
    var packetList = packet.packetList
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note on event"
  }

  func receiveNoteOff(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: identifier)
    var packetList = packet.packetList
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note off event"
  }

  func sendNoteOn(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note on event"
  }

  func sendNoteOff(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
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

extension NoteGenerator: Equatable {

  static func ==(lhs: NoteGenerator, rhs: NoteGenerator) -> Bool {
    return lhs.channel == rhs.channel
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
      && lhs.tone == rhs.tone
  }
  
}

extension NoteGenerator {

  /// An enumeration for specifying a note's pitch and octave
  struct Tone {

    var note: Note
    var octave: Octave

    static func index(for note: Note) -> Int {
      switch note {
        case .`default`(.c), .modified(.b, .sharp), .modified(.d, .doubleFlat):       return 0
        case .modified(.c, .sharp), .modified(.d, .flat):                             return 1
        case .`default`(.d), .modified(.e, .doubleFlat):                              return 2
        case .modified(.d, .sharp), .modified(.e, .flat), .modified(.f, .doubleFlat): return 3
        case .`default`(.e), .modified(.f, .flat):                                    return 4
        case .`default`(.f), .modified(.e, .sharp), .modified(.g, .doubleFlat):       return 5
        case .modified(.f, .sharp), .modified(.g, .flat):                             return 6
        case .`default`(.g), .modified(.a, .doubleFlat):                              return 7
        case .modified(.g, .sharp),.modified(.a, .flat):                              return 8
        case .`default`(.a), .modified(.b, .doubleFlat):                              return 9
        case .modified(.a, .sharp),.modified(.b, .flat), .modified(.c, .doubleFlat):  return 10
        case .`default`(.b), .modified(.c, .flat):                                    return 11
      }
    }

    static func note(for index: Int) -> Note? {
      switch index {
        case 0:  return .`default`(.c)
        case 1:  return .modified(.c, .sharp)
        case 2:  return .`default`(.d)
        case 3:  return .modified(.d, .sharp)
        case 4:  return .`default`(.e)
        case 5:  return .`default`(.f)
        case 6:  return .modified(.f, .sharp)
        case 7:  return .`default`(.g)
        case 8:  return .modified(.g, .sharp)
        case 9:  return .`default`(.a)
        case 10: return .modified(.a, .sharp)
        case 11: return .`default`(.b)
       default: return nil
      }
    }

    init(_ note: Note, _ octave: Octave) {
      self.note = note
      self.octave = octave
    }

    /// Initialize from MIDI value from 0 ... 127
    init(midi value: Byte) {
      note = Tone.note(for: Int(value) % 12)!
      octave = Octave(rawValue: Int(value / 12 - 1)) ?? .four
    }

    var midi: Byte { return UInt8((octave.rawValue + 1) * 12 + Tone.index(for: note)) }

  }

}

extension NoteGenerator.Tone: RawRepresentable, LosslessJSONValueConvertible {

  /// Initialize with string representation
  init?(rawValue: String) {
    guard let captures = (rawValue ~=> ~/"^([A-G]♯?) ?((?:-1)|[0-9])$"),
      let pitch = Note(rawValue: captures.1 ?? ""),
      let rawOctave = Int(captures.2 ?? ""),
      let octave = Octave(rawValue: rawOctave) else { return nil }

    self.note = pitch
    self.octave = octave
  }

  var rawValue: String { return "\(note.rawValue)\(octave.rawValue)" }

}

extension NoteGenerator.Tone: Equatable {

  static func ==(lhs: NoteGenerator.Tone, rhs: NoteGenerator.Tone) -> Bool {
    return lhs.midi == rhs.midi
  }

}

