//
//  Chord.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

struct Chord {

  var rootNote = Note()

  var pattern = ChordPattern.Major

  var duration: Note.Duration {
    get { return rootNote.duration }
    set { rootNote.duration = newValue }
  }

  var velocity: Note.Velocity {
    get { return rootNote.velocity }
    set { rootNote.velocity = newValue }
  }

  var notes: [Note] { return pattern.notesWithRoot(rootNote) }

}

// MARK: - MIDINoteGenerator
extension Chord: MIDINoteGenerator {

  typealias Packet = MIDINode.Packet

  /**
   receiveNoteOn:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOn(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    for note in pattern.notesWithRoot(rootNote) { try note.receiveNoteOn(endPoint, identifier) }
  }

  /**
   receiveNoteOff:

   - parameter endPoint: MIDIEndpointRef
   */
  func receiveNoteOff(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    for note in pattern.notesWithRoot(rootNote) { try note.receiveNoteOff(endPoint, identifier) }
  }

  /**
   sendNoteOn:endPoint:

   - parameter endPoint: MIDIEndpointRef
   */
  func sendNoteOn(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    for note in pattern.notesWithRoot(rootNote) { try note.sendNoteOn(outPort, endPoint) }
  }

  /**
   sendNoteOff:endPoint:

   - parameter endPoint: MIDIEndpointRef
   */
  func sendNoteOff(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    for note in pattern.notesWithRoot(rootNote) { try note.sendNoteOff(outPort, endPoint) }
  }

}


// MARK: - ChordPattern
extension Chord {
  /** Type for specifying the intervals with which a chord is composed */
  struct ChordPattern: RawRepresentable, CustomStringConvertible {
    var rawValue: String {
      var strings: [String] = []
      for degree in intervals.keys.sort({$0.rawValue < $1.rawValue}) {
        strings.append("\(intervals[degree]!)\(degree)")
      }
      return "-".join(strings)
    }
    enum Degree: Int {
      case Tonic, Supertonic, Mediant, Subdominant, Dominant, Submediant, LeadingNote, Octave
    }

    var intervals: [Degree:Accidental] = [:]

    init?(rawValue: String) {
      for string in "-".split(rawValue) {
        guard let match = (~/"^([♭♯]?)([1-8])").firstMatch(string),
        rawIntervalType = match.captures[1]?.string,
        intervalType = Accidental(rawValue: rawIntervalType),
        rawDegreeString = match.captures[2]?.string,
        rawDegree = Int(rawDegreeString),
        degree = Degree(rawValue: rawDegree) else { continue }

        intervals[degree] = intervalType
      }
    }

    /**
    notesWithRoot:

    - parameter root: Note

    - returns: [Note]
    */
    func notesWithRoot(root: Note) -> [Note] {
      let tonicPitch = root.note.pitch.diatonicPitch
      let octave = root.note.octave
      let duration = root.duration
      let velocity = root.velocity
      var result: [Note] = []
      for (degree, accidental) in intervals {
        let pitch = Note.Tone.Pitch(tonicPitch.advancedBy(degree.rawValue), accidental)
        let tone = Note.Tone(pitch, octave)
        let note = Note(tone: tone, duration: duration, velocity: velocity)
        result.append(note)
      }
      if root.note.pitch.accidental == .Sharp {
        result = result.map { var note = $0; note.note.pitch = note.note.pitch.successor(); return note }
      }
      return result
    }

    static let Major           = ChordPattern(rawValue: "1-3-5")!
    static let Minor           = ChordPattern(rawValue: "1-♭3-5")!
    static let Diminished      = ChordPattern(rawValue: "1-♭3-♭5")!
    static let Dominate7       = ChordPattern(rawValue: "1-3-5-♭7")!
    static let Major7          = ChordPattern(rawValue: "1-3-5-7")!
    static let Minor7          = ChordPattern(rawValue: "1-♭3-5-♭7")!
    static let MinorMajor7     = ChordPattern(rawValue: "1-♭3-5-7")!
    static let Major6          = ChordPattern(rawValue: "1-3-5-6")!
    static let Minor6          = ChordPattern(rawValue: "1-♭3-5-6")!
    static let Diminished7     = ChordPattern(rawValue: "1-♭3-♭5-6")!
    static let Sustained4      = ChordPattern(rawValue: "1-4-5")!
    static let Power           = ChordPattern(rawValue: "1-5")!

    var description: String { return rawValue }
  }
}