//
//  MIDINote.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

enum MIDINote: RawRepresentable, Equatable, EnumerableType {

  enum Letter: String, EnumerableType {
    case C      = "C"
    case CSharp = "C♯"
    case D      = "D"
    case DSharp = "D♯"
    case E      = "E"
    case F      = "F"
    case FSharp = "F♯"
    case G      = "G"
    case GSharp = "G♯"
    case A      = "A"
    case ASharp = "A♯"
    case B      = "B"

    init(_ i: UInt8) { self = Letter.allCases[Int(i % 12)] }
    var intValue: Int { return Letter.allCases.indexOf(self)! }

    static let allCases: [Letter] = [C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B]
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

  var rawValue: String { switch self { case let .Pitch(letter, octave): return "\(letter.rawValue)\(octave)" } }

  var midi: UInt8 {  switch self { case let .Pitch(letter, octave): return UInt8((octave + 1) * 12 + letter.intValue) } }

  static let allCases: [MIDINote] =  (0...127).map(MIDINote.init)

}

func ==(lhs: MIDINote, rhs: MIDINote) -> Bool {
  switch (lhs, rhs) {
    case let (.Pitch(l1, o1), .Pitch(l2, o2)) where l1 == l2 && o1 == o2: return true
    default: return false
  }
}

