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

/** Structure that encapsulates MIDI information necessary for playing a note */
struct NoteGenerator {

  var channel: UInt8 = 0

  /// The pitch and octave
  var tone: Tone = Tone(midi: 60)

  /// The duration of the played note
  var duration: Duration = .eighth

  /// The dynmamics for the note
  var velocity: Velocity = .𝑚𝑓

  /// The octave held by `tone`
  var octave: Octave { get { return tone.octave } set { tone.octave = newValue } }

  /// The pitch held by `tone`
  var root: Note { get { return tone.note } set { tone.note = newValue } }

  init() {}
  init(tone: Tone, duration: Duration, velocity: Velocity) {
    self.tone = tone
    self.duration = duration
    self.velocity = velocity
  }

  /**
  initWithGenerator:

  - parameter generator: ChordGenerator
  */
  init(generator: ChordGenerator) {
    self.init(tone: Tone(generator.chord.root, generator.octave),
              duration: generator.duration,
              velocity: generator.velocity)
  }

}

extension NoteGenerator: JSONValueConvertible {
  var jsonValue: JSONValue {
    return ObjectJSONValue([
      "tone": tone.jsonValue,
      "duration": duration.jsonValue,
      "velocity": velocity.jsonValue,
      "octave": octave.jsonValue,
      "root": root.jsonValue
      ]).jsonValue
  }
}

extension NoteGenerator: JSONValueInitializable {
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

// MARK: - Tone
extension NoteGenerator {
  /** An enumeration for specifying a note's pitch and octave */
  struct Tone: RawRepresentable, Equatable, CustomStringConvertible,
               JSONValueConvertible, JSONValueInitializable
  {

    var note: Note
    var octave: Octave

    static func indexForNote(_ note: Note) -> Int {
      switch note {
        case .default(.C), .modified(.B, .Sharp), .modified(.D, .DoubleFlat):         return 0
        case .modified(.C, .Sharp), .modified(.D, .Flat):                             return 1
        case .default(.D), .modified(.E, .DoubleFlat):                                return 2
        case .modified(.D, .Sharp), .modified(.E, .Flat), .modified(.F, .DoubleFlat): return 3
        case .default(.E), .modified(.F, .Flat):                                      return 4
        case .default(.F), .modified(.E, .Sharp), .modified(.G, .DoubleFlat):         return 5
        case .modified(.F, .Sharp), .modified(.G, .Flat):                             return 6
        case .default(.G), .modified(.A, .DoubleFlat):                                return 7
        case .modified(.G, .Sharp),.modified(.A, .Flat):                              return 8
        case .default(.A), .modified(.B, .DoubleFlat):                                return 9
        case .modified(.A, .Sharp),.modified(.B, .Flat), .modified(.C, .DoubleFlat):  return 10
        case .default(.B), .modified(.C, .Flat):                                      return 11
      }
    }

    static func noteForIndex(_ index: Int) -> Note? {
      switch index {
        case 0:  return .default(.C)
        case 1:  return .modified(.C, .Sharp)
        case 2:  return .default(.D)
        case 3:  return .modified(.D, .Sharp)
        case 4:  return .default(.E)
        case 5:  return .default(.F)
        case 6:  return .modified(.F, .Sharp)
        case 7:  return .default(.G)
        case 8:  return .modified(.G, .Sharp)
        case 9:  return .default(.A)
        case 10: return .modified(.A, .Sharp)
        case 11: return .default(.B)
        default: return nil
      }
    }

    /**
    init:octave:

    - parameter note: Note
    - parameter octave: Octave
    */
    init(_ note: Note, _ octave: Octave) {
      self.note = note
      self.octave = octave
    }

    /**
    Initialize from MIDI value from 0 ... 127

    - parameter value: Int
    */
    init(midi value: Byte) {
      note = Tone.noteForIndex(Int(value) % 12)!
      octave = Octave(rawValue: Int(value / 12 - 1)) ?? .four
    }

    /**
    Initialize with string representation

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^([A-G]♯?) ?((?:-1)|[0-9])$").firstMatch(rawValue),
        let rawNote = match.captures[1]?.string,
        let pitch = Note(rawValue: rawNote),
        let rawOctaveString = match.captures[2]?.string,
        let rawOctave = Int(rawOctaveString),
        let octave = Octave(rawValue: rawOctave) else { return nil }

      self.note = pitch; self.octave = octave
    }

    var rawValue: String { return "\(note.rawValue)\(octave.rawValue)" }

    var midi: Byte { return UInt8((octave.rawValue + 1) * 12 + Tone.indexForNote(note)) }

    var description: String { return rawValue }
    var jsonValue: JSONValue { return rawValue.jsonValue }
    init?(_ jsonValue: JSONValue?) {
      guard let rawValue = String(jsonValue) else { return nil }
      self.init(rawValue: rawValue)
    }
  }
}

// MARK: - MIDIGeneratorType
extension NoteGenerator: MIDIGeneratorType {

  /**
   receiveNoteOn:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOn(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: identifier)
    var packetList = packet.packetList
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note on event"
  }

  /**
   receiveNoteOff:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOff(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: identifier)
    var packetList = packet.packetList
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note off event"
  }

  /**
   sendNoteOn:endPoint:

   - parameter endPoint: MIDIEndpointRef
   */
  func sendNoteOn(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    let packet = Packet(status: 0x90,
      channel: channel,
      note: tone.midi,
      velocity: velocity.midi,
      identifier: 0)
    var packetList = packet.packetList
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note on event"
  }

  /**
   sendNoteOff:endPoint:

   - parameter endPoint: MIDIEndpointRef
   */
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

// MARK: - ByteArrayConvertible
extension NoteGenerator: ByteArrayConvertible {

  var bytes: [Byte] { return [channel, tone.midi, velocity.midi] + duration.rawValue.bytes }

  /**
  init:

  - parameter bytes: [Byte]
  */
  init!(_ bytes: [Byte]) {
    guard bytes.count >= 7 else { return }
    channel  = bytes[0]
    tone     = Tone(midi: bytes[1])
    velocity = Velocity(midi: bytes[2])
    duration = Duration(rawValue: String(bytes[3|->])) ?? .eighth
  }
}

// MARK: - CustomStringConvertible
extension NoteGenerator: CustomStringConvertible {
  var description: String { return "{\(channel), \(tone), \(duration), \(velocity)}" }
}

// MARK: - Equatable
extension NoteGenerator: Equatable {}

func ==(lhs: NoteGenerator.Tone, rhs: NoteGenerator.Tone) -> Bool { return lhs.midi == rhs.midi }

func ==(lhs: NoteGenerator, rhs: NoteGenerator) -> Bool {
  return lhs.channel == rhs.channel
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
      && lhs.tone == rhs.tone
}
