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

struct ChordGenerator {
  var chord = Chord()
  var octave = Octave.Four
  var duration = Duration.Eighth
  var velocity = Velocity.𝑚𝑓

  var midiNotes: [MIDINote] {
    var result: [MIDINote] = []
    let notes = chord.notes
    guard let rootIndex = notes.indexOf(chord.root) else { return result }

    if rootIndex > 0 {
      for note in notes[0 ..< rootIndex] {
        let octave: Octave?
        if note > chord.root {
          octave = Octave(rawValue: self.octave.rawValue - 1)
        } else {
          octave = self.octave
        }
        guard octave != nil else { continue }
        let tone = MIDINote.Tone(note, octave!)
        result.append(MIDINote(tone: tone, duration: duration, velocity: velocity))
      }
    }

    var currentOctave = octave
    var previousNote = chord.root
    for note in notes[rootIndex..<] {
      if note < previousNote {
        guard let nextOctave = Octave(rawValue: currentOctave.rawValue + 1) else { return result }
        currentOctave = nextOctave
      }
      let tone = MIDINote.Tone(note, currentOctave)
      result.append(MIDINote(tone: tone, duration: duration, velocity: velocity))
      previousNote = note
    }

    return result
  }

}

extension ChordGenerator: MIDINoteGenerator {

  /**
   receiveNoteOn:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOn(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    for note in midiNotes { try note.receiveNoteOn(endPoint, identifier) }
  }

  /**
   receiveNoteOff:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOff(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    for note in midiNotes { try note.receiveNoteOff(endPoint, identifier) }
  }

  /**
   sendNoteOn:endPoint:

   - parameter endPoint: MIDIEndpointRef
   */
  func sendNoteOn(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    for note in midiNotes { try note.sendNoteOn(outPort, endPoint) }
  }

  /**
   sendNoteOff:endPoint:

   - parameter endPoint: MIDIEndpointRef
   */
  func sendNoteOff(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    for note in midiNotes { try note.sendNoteOff(outPort, endPoint) }
  }

}

extension ChordGenerator: Equatable {}

func ==(lhs: ChordGenerator, rhs: ChordGenerator) -> Bool {
  return lhs.chord == rhs.chord
      && lhs.octave == rhs.octave
      && lhs.duration == rhs.duration
      && lhs.velocity == rhs.velocity
}


