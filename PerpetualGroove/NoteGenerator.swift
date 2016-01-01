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
  var duration: Duration = .Eighth

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
              tone = Tone(dict["tone"]),
              duration = Duration(dict["duration"]),
              velocity = Velocity(dict["velocity"]),
              octave = Octave(dict["octave"]),
              root = Note(dict["root"]) else { return nil }
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
  struct Tone: RawRepresentable, Equatable, MIDIConvertible, CustomStringConvertible,
               JSONValueConvertible, JSONValueInitializable
  {

    var note: Note
    var octave: Octave

    static func indexForNote(note: Note) -> Int {
      switch note {
        case .Default(.C), .Modified(.B, .Sharp), .Modified(.D, .DoubleFlat):         return 0
        case .Modified(.C, .Sharp), .Modified(.D, .Flat):                             return 1
        case .Default(.D), .Modified(.E, .DoubleFlat):                                return 2
        case .Modified(.D, .Sharp), .Modified(.E, .Flat), .Modified(.F, .DoubleFlat): return 3
        case .Default(.E), .Modified(.F, .Flat):                                      return 4
        case .Default(.F), .Modified(.E, .Sharp), .Modified(.G, .DoubleFlat):         return 5
        case .Modified(.F, .Sharp), .Modified(.G, .Flat):                             return 6
        case .Default(.G), .Modified(.A, .DoubleFlat):                                return 7
        case .Modified(.G, .Sharp),.Modified(.A, .Flat):                              return 8
        case .Default(.A), .Modified(.B, .DoubleFlat):                                return 9
        case .Modified(.A, .Sharp),.Modified(.B, .Flat), .Modified(.C, .DoubleFlat):  return 10
        case .Default(.B), .Modified(.C, .Flat):                                      return 11
      }
    }

    static func noteForIndex(index: Int) -> Note? {
      switch index {
        case 0:  return .Default(.C)
        case 1:  return .Modified(.C, .Sharp)
        case 2:  return .Default(.D)
        case 3:  return .Modified(.D, .Sharp)
        case 4:  return .Default(.E)
        case 5:  return .Default(.F)
        case 6:  return .Modified(.F, .Sharp)
        case 7:  return .Default(.G)
        case 8:  return .Modified(.G, .Sharp)
        case 9:  return .Default(.A)
        case 10: return .Modified(.A, .Sharp)
        case 11: return .Default(.B)
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
      octave = Octave(rawValue: Int(value / 12 - 1)) ?? .Four
    }

    /**
    Initialize with string representation

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^([A-G]♯?) ?((?:-1)|[0-9])$").firstMatch(rawValue),
        rawNote = match.captures[1]?.string,
        pitch = Note(rawValue: rawNote),
        rawOctaveString = match.captures[2]?.string,
        rawOctave = Int(rawOctaveString),
        octave = Octave(rawValue: rawOctave) else { return nil }

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

// MARK: - MIDINoteGenerator
extension NoteGenerator: MIDINoteGenerator {

  /**
   receiveNoteOn:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOn(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
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
  func receiveNoteOff(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
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
  func sendNoteOn(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
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
  func sendNoteOff(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
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
    duration = Duration(rawValue: String(bytes[3..<])) ?? .Eighth
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
