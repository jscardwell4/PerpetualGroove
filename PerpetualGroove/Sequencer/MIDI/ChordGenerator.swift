//
//  ChordGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import MoonKit

// TODO: Review file

struct ChordGenerator {

  var chord: Chord
  var octave: Octave
  var duration: Duration
  var velocity: Velocity

  var root: Note { get { return chord.root } set { chord.root = newValue } }

  var midiNotes: [NoteGenerator] {
    var result: [NoteGenerator] = []
    let notes = chord.notes
    guard let rootIndex = notes.firstIndex(of: chord.root) else { return result }

    if rootIndex > 0 {
      for note in notes[0 ..< rootIndex] {
        let octave: Octave?
        if note > chord.root {
          octave = Octave(rawValue: self.octave.rawValue - 1)
        } else {
          octave = self.octave
        }
        guard octave != nil else { continue }
        let tone = NoteGenerator.Tone(note, octave!)
        result.append(NoteGenerator(tone: tone, duration: duration, velocity: velocity))
      }
    }

    var currentOctave = octave
    var previousNote = chord.root
    for note in notes[rootIndex...] {
      if note < previousNote {
        guard let nextOctave = Octave(rawValue: currentOctave.rawValue + 1) else { return result }
        currentOctave = nextOctave
      }
      let tone = NoteGenerator.Tone(note, currentOctave)
      result.append(NoteGenerator(tone: tone, duration: duration, velocity: velocity))
      previousNote = note
    }

    return result
  }

  init(chord: Chord = Chord(),
       octave: Octave = Octave.four,
       duration: Duration = Duration.eighth,
       velocity: Velocity = Velocity.𝑚𝑓)
  {
    self.chord = chord
    self.octave = octave
    self.duration = duration
    self.velocity = velocity
  }

  init(pattern: Chord.Pattern, generator: NoteGenerator) {
    chord = Chord(root: generator.tone.note, pattern: pattern)
    octave = generator.octave
    duration = generator.duration
    velocity = generator.velocity
  }
  
}

extension ChordGenerator: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return ObjectJSONValue([
      "chord": chord.jsonValue,
      "octave": octave.jsonValue,
      "duration": duration.jsonValue,
      "velocity": velocity.jsonValue
      ]).jsonValue
  }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
          let chord = Chord(dict["chord"]),
          let octave = Octave(dict["octave"]),
          let duration = Duration(dict["duration"]),
          let velocity = Velocity(dict["velocity"]) else { return nil }
    self.chord = chord
    self.octave = octave
    self.duration = duration
    self.velocity = velocity
  }

}
 

extension ChordGenerator: MIDIGenerator {

  func receiveNoteOn(endPoint: MIDIEndpointRef, identifier: UInt) throws {
    for note in midiNotes { try note.receiveNoteOn(endPoint: endPoint, identifier: identifier) }
  }

  func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt) throws {
    for note in midiNotes { try note.receiveNoteOff(endPoint: endPoint, identifier: identifier) }
  }

  func sendNoteOn(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws {
    for note in midiNotes { try note.sendNoteOn(outPort: outPort, endPoint: endPoint) }
  }

  func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws {
    for note in midiNotes { try note.sendNoteOff(outPort: outPort, endPoint: endPoint) }
  }

}

extension ChordGenerator: Hashable {

  var hashValue: Int { return chord.hashValue ^ octave.hashValue ^ duration.hashValue ^ velocity.hashValue }

  func hash(into hasher: inout Hasher) {
    chord.hash(into: &hasher)
    octave.hash(into: &hasher)
    duration.hash(into: &hasher)
    velocity.hash(into: &hasher)
  }

  static func ==(lhs: ChordGenerator, rhs: ChordGenerator) -> Bool {
    return lhs.chord == rhs.chord
        && lhs.octave == rhs.octave
        && lhs.duration == rhs.duration
        && lhs.velocity == rhs.velocity
  }

}
