//
//  MIDINote.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

/** Structure that encapsulates MIDI information necessary for playing a note */
struct MIDINote {

  var channel: UInt8 = 0

  /// The pitch and octave
  var note: Tone = Tone(midi: 60)

  /// The duration of the played note
  var duration: Duration = .Eighth

  /// The dynmamics for the note
  var velocity: Velocity = .𝑚𝑓

  init() {}
  init(tone: Tone, duration: Duration, velocity: Velocity) {
    self.note = tone
    self.duration = duration
    self.velocity = velocity
  }

}

// MARK: - Tone
extension MIDINote {
  /** An enumeration for specifying a note's pitch and octave */
  struct Tone: RawRepresentable, Equatable, MIDIConvertible, CustomStringConvertible {

    var pitch: Note
    var octave: Octave

    static func indexForNote(note: Note) -> Int {
      switch note {
        case .Default(.C), .Modified(.B, .Sharp):         return 0
        case .Modified(.C, .Sharp), .Modified(.D, .Flat): return 1
        case .Default(.D):                                return 2
        case .Modified(.D, .Sharp), .Modified(.E, .Flat): return 3
        case .Default(.E), .Modified(.F, .Flat):          return 4
        case .Default(.F), .Modified(.E, .Sharp):         return 5
        case .Modified(.F, .Sharp), .Modified(.G, .Flat): return 6
        case .Default(.G):                                return 7
        case .Modified(.G, .Sharp),.Modified(.A, .Flat):  return 8
        case .Default(.A):                                return 9
        case .Modified(.A, .Sharp),.Modified(.B, .Flat):  return 10
        case .Default(.B), .Modified(.C, .Flat):          return 11
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

    - parameter pitch: Pitch
    - parameter octave: Octave
    */
    init(_ pitch: Note, _ octave: Octave) {
      self.pitch = pitch
      self.octave = octave
    }

    /**
    Initialize from MIDI value from 0 ... 127

    - parameter value: Int
    */
    init(midi value: Byte) {
      pitch = Tone.noteForIndex(Int(value) % 12)!
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

      self.pitch = pitch; self.octave = octave
    }

    var rawValue: String { return "\(pitch.rawValue)\(octave.rawValue)" }

    var midi: Byte { return UInt8((octave.rawValue + 1) * 12 + Tone.indexForNote(pitch)) }

    var description: String { return rawValue }
  }
}

// MARK: - MIDINoteGenerator
extension MIDINote: MIDINoteGenerator {

  /**
   receiveNoteOn:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOn(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: note.midi,
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
                        note: note.midi,
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
      note: note.midi,
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
      note: note.midi,
      velocity: velocity.midi,
      identifier: 0)
    var packetList = packet.packetList
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note off event"
  }

}

// MARK: - ByteArrayConvertible
extension MIDINote: ByteArrayConvertible {

  var bytes: [Byte] { return [channel, note.midi, velocity.midi] + duration.rawValue.bytes }

  /**
  init:

  - parameter bytes: [Byte]
  */
  init!(_ bytes: [Byte]) {
    guard bytes.count >= 7 else { return }
    channel  = bytes[0]
    note     = Tone(midi: bytes[1])
    velocity = Velocity(midi: bytes[2])
    duration = Duration(rawValue: String(bytes[3..<])) ?? .Eighth
  }
}

// MARK: - CustomStringConvertible
extension MIDINote: CustomStringConvertible {
  var description: String { return "{\(channel), \(note), \(duration), \(velocity)}" }
}

// MARK: - Equatable
extension MIDINote: Equatable {}

func ==(lhs: MIDINote.Tone, rhs: MIDINote.Tone) -> Bool { return lhs.midi == rhs.midi }

func ==(lhs: MIDINote, rhs: MIDINote) -> Bool {
  return lhs.channel == rhs.channel
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
      && lhs.note == rhs.note
}
