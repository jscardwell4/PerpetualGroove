//
//  ChordGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import CoreMIDI
import Foundation
import MoonDev

// MARK: - ChordGenerator

// TODO: Review file

public struct ChordGenerator: Codable
{
  public var chord: Chord
  public var octave: Octave
  public var duration: Duration
  public var velocity: Velocity
  
  public var root: Note { get { return chord.root } set { chord.root = newValue } }
  
  public var midiNotes: [NoteGenerator]
  {
    var result: [NoteGenerator] = []
    let notes = chord.notes
    guard let rootIndex = notes.firstIndex(of: chord.root) else { return result }
    
    if rootIndex > 0
    {
      for note in notes[0 ..< rootIndex]
      {
        let octave: Octave?
        if note > chord.root
        {
          octave = Octave(rawValue: self.octave.rawValue - 1)
        }
        else
        {
          octave = self.octave
        }
        guard octave != nil else { continue }
        let tone = MIDINote(note, octave!)
        result.append(NoteGenerator(tone: tone, duration: duration, velocity: velocity))
      }
    }
    
    var currentOctave = octave
    var previousNote = chord.root
    for note in notes[rootIndex...]
    {
      if note < previousNote
      {
        guard let nextOctave = Octave(rawValue: currentOctave.rawValue + 1)
        else { return result }
        currentOctave = nextOctave
      }
      let tone = MIDINote(note, currentOctave)
      result.append(NoteGenerator(tone: tone, duration: duration, velocity: velocity))
      previousNote = note
    }
    
    return result
  }
  
  public init(chord: Chord = Chord(),
              octave: Octave = Octave.four,
              duration: Duration = Duration.eighth,
              velocity: Velocity = Velocity.𝑚𝑓)
  {
    self.chord = chord
    self.octave = octave
    self.duration = duration
    self.velocity = velocity
  }
  
  public init(pattern: Chord.Pattern, generator: NoteGenerator)
  {
    chord = Chord(root: generator.tone.note, pattern: pattern)
    octave = generator.octave
    duration = generator.duration
    velocity = generator.velocity
  }
}

//// MARK: LosslessJSONValueConvertible
//
//extension ChordGenerator: LosslessJSONValueConvertible
//{
//  public var jsonValue: JSONValue
//  {
//    return ObjectJSONValue([
//      "chord": chord.jsonValue,
//      "octave": octave.jsonValue,
//      "duration": duration.jsonValue,
//      "velocity": velocity.jsonValue
//    ]).jsonValue
//  }
//
//  public init?(_ jsonValue: JSONValue?)
//  {
//    guard let dict = ObjectJSONValue(jsonValue),
//          let chord = Chord(dict["chord"]),
//          let octave = Octave(dict["octave"]),
//          let duration = Duration(dict["duration"]),
//          let velocity = Velocity(dict["velocity"])
//    else { return nil }
//    self.chord = chord
//    self.octave = octave
//    self.duration = duration
//    self.velocity = velocity
//  }
//}

// MARK: Generator

extension ChordGenerator: Generator
{
  public func receiveNoteOn(
    endPoint: MIDIEndpointRef,
    identifier: UInt,
    ticks: UInt64
  ) throws
  {
    for note in midiNotes
    {
      try note.receiveNoteOn(endPoint: endPoint, identifier: identifier, ticks: ticks)
    }
  }
  
  public func receiveNoteOff(
    endPoint: MIDIEndpointRef,
    identifier: UInt,
    ticks: UInt64
  ) throws
  {
    for note in midiNotes
    {
      try note.receiveNoteOff(endPoint: endPoint, identifier: identifier, ticks: ticks)
    }
  }
  
  public func sendNoteOn(
    outPort: MIDIPortRef,
    endPoint: MIDIEndpointRef,
    ticks: UInt64
  ) throws
  {
    for note in midiNotes
    {
      try note.sendNoteOn(outPort: outPort, endPoint: endPoint, ticks: ticks)
    }
  }
  
  public func sendNoteOff(
    outPort: MIDIPortRef,
    endPoint: MIDIEndpointRef,
    ticks: UInt64
  ) throws
  {
    for note in midiNotes
    {
      try note.sendNoteOff(outPort: outPort, endPoint: endPoint, ticks: ticks)
    }
  }
}

// MARK: Hashable

extension ChordGenerator: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    chord.hash(into: &hasher)
    octave.hash(into: &hasher)
    duration.hash(into: &hasher)
    velocity.hash(into: &hasher)
  }
  
  public static func == (lhs: ChordGenerator, rhs: ChordGenerator) -> Bool
  {
    lhs.chord == rhs.chord
      && lhs.octave == rhs.octave
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
  }
}
