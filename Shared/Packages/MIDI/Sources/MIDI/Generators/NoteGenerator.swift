//
//  NoteGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonDev

// TODO: Review file
import CoreMIDI

// MARK: - NoteGenerator

/// Structure that encapsulates MIDI information necessary for playing a note
public struct NoteGenerator
{
  public var channel: UInt8 = 0

  /// The pitch and octave
  public var tone: MIDINote

  /// The duration of the played note
  public var duration: Duration

  /// The dynmamics for the note
  public var velocity: Velocity

  /// The octave held by `tone`
  public var octave: Octave { get { tone.octave } set { tone.octave = newValue } }

  /// The pitch held by `tone`
  public var root: Note { get { tone.note } set { tone.note = newValue } }

  public init(
    tone: MIDINote = MIDINote(midi: 60),
    duration: Duration = .eighth,
    velocity: Velocity = .𝑚𝑓
  )
  {
    self.tone = tone
    self.duration = duration
    self.velocity = velocity
  }

  public init(generator: ChordGenerator)
  {
    self.init(tone: MIDINote(generator.chord.root, generator.octave),
              duration: generator.duration,
              velocity: generator.velocity)
  }
}

// MARK: Codable

extension NoteGenerator: Codable
{
  private enum CodingKeys: String, CodingKey
  {
    case tone, duration, velocity, octave, root
  }

  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(tone, forKey: .tone)
    try container.encode(duration, forKey: .duration)
    try container.encode(velocity, forKey: .velocity)
    try container.encode(octave, forKey: .octave)
    try container.encode(root, forKey: .root)
  }

  public init(from decoder: Decoder) throws
  {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    tone = try container.decode(MIDINote.self, forKey: .tone)
    duration = try container.decode(Duration.self, forKey: .tone)
    velocity = try container.decode(Velocity.self, forKey: .tone)
    octave = try container.decode(Octave.self, forKey: .tone)
    root = try container.decode(Note.self, forKey: .tone)
  }
}

// MARK: Generator

extension NoteGenerator: Generator
{
  public func receiveNoteOn(
    endPoint: MIDIEndpointRef,
    identifier: UInt,
    ticks: UInt64
  ) throws
  {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: UInt64(identifier))
    var packetList = packet.packetList(ticks: ticks)
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note on event"
  }

  public func receiveNoteOff(
    endPoint: MIDIEndpointRef,
    identifier: UInt,
    ticks: UInt64
  ) throws
  {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: UInt64(identifier))
    var packetList = packet.packetList(ticks: ticks)
    try MIDIReceived(endPoint, &packetList) ➤ "Unable to send note off event"
  }

  public func sendNoteOn(
    outPort: MIDIPortRef,
    endPoint: MIDIEndpointRef,
    ticks: UInt64
  ) throws
  {
    let packet = Packet(status: 0x90,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList(ticks: ticks)
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note on event"
  }

  public func sendNoteOff(
    outPort: MIDIPortRef,
    endPoint: MIDIEndpointRef,
    ticks: UInt64
  ) throws
  {
    let packet = Packet(status: 0x80,
                        channel: channel,
                        note: tone.midi,
                        velocity: velocity.midi,
                        identifier: 0)
    var packetList = packet.packetList(ticks: ticks)
    try MIDISend(outPort, endPoint, &packetList) ➤ "Unable to send note off event"
  }
}

// MARK: ByteArrayConvertible

extension NoteGenerator: ByteArrayConvertible
{
  public var bytes: [UInt8]
  {
    return [channel, tone.midi, velocity.midi] + duration.rawValue.bytes
  }

  public init(_ bytes: [UInt8])
  {
    guard bytes.count >= 7 else { self = NoteGenerator(); return }
    channel = bytes[0]
    tone = MIDINote(midi: bytes[1])
    velocity = Velocity(midi: bytes[2])
    duration = Duration(rawValue: String(bytes: bytes[3|->])) ?? .eighth
  }
}

// MARK: CustomStringConvertible

extension NoteGenerator: CustomStringConvertible
{
  public var description: String
  {
    return "{\(channel), \(tone), \(duration), \(velocity)}"
  }
}

// MARK: Hashable

extension NoteGenerator: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    channel.hash(into: &hasher)
    duration.hash(into: &hasher)
    velocity.hash(into: &hasher)
    tone.hash(into: &hasher)
  }

  public static func == (lhs: NoteGenerator, rhs: NoteGenerator) -> Bool
  {
    return lhs.channel == rhs.channel
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
      && lhs.tone == rhs.tone
  }
}
