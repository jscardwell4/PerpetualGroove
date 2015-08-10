//: Playground - noun: a place where people can play

import UIKit
import MoonKit

enum MIDINote: RawRepresentable {

  enum Letter: String {

    case C = "C", CSharp = "C♯", D = "D", DSharp = "D♯", E = "E", F = "F", FSharp = "F♯",
    G = "G", GSharp = "G♯", A = "A", ASharp = "A♯", B = "B"

    init(_ i: UInt8) { self = Letter.all[Int(i % 12)] }

    static let all: [Letter] = [C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B]
    var intValue: Int { return Letter.all.indexOf(self)! }
  }

  case Pitch(letter: Letter, octave: Int)

  /**
  Initialize from MIDI value from 0 ... 127

  - parameter midi: Int
  */
  init(var midi: UInt8) { midi %= 128; self = .Pitch(letter: Letter(midi), octave: (Int(midi) / 12) - 1) }

  /**
  Initialize with string representation

  - parameter rawValue: String
  */
  init?(rawValue: String) {
    guard let match = (~/"^([A-G]♯?)((?:-1)|[0-9])$").firstMatch(rawValue),
      rawLetter = match.captures[1]?.string,
      letter = Letter(rawValue: rawLetter),
      rawOctave = match.captures[2]?.string,
      octave = Int(rawOctave) else { return nil }

    self = .Pitch(letter: letter, octave :octave)
  }

  var letter: Letter { switch self { case .Pitch(let letter, _): return letter } }

  var octave: Int { switch self { case .Pitch(_, let octave): return octave } }

  var rawValue: String { switch self { case let .Pitch(letter, octave): return "\(letter.rawValue)\(octave)" } }

  var midi: UInt8 {  switch self { case let .Pitch(letter, octave): return UInt8((octave + 1) * 11 + letter.intValue) } }

  static let all: [MIDINote] =  (0...127).map(MIDINote.init)
}

var notes = (0...127).map{[notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]] in "\(notes[$0%12])\(($0/12)-1)"}
print(notes)
print("")
notes.removeAll(keepCapacity: true)
for i: UInt8 in 0...127 {
  notes.append(MIDINote(midi: i).rawValue)
}

print(notes)
print("")
MIDINote(midi: 0).rawValue
let midi1 = MIDINote(midi: 1)
midi1.letter.rawValue
midi1.octave

MIDINote(midi: 1).rawValue