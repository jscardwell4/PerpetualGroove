//
//  Note.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct NoteAttributes {

  var channel: UInt8 = 0

  enum Note: RawRepresentable, Equatable, EnumerableType {

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

    static let allCases: [Note] =  (0...127).map(Note.init)

  }

  var note: Note = Note(midi: 60)

  enum Duration: String, EnumerableType {
    case DoubleWhole                = "Double Whole Note"
    case DottedWhole                = "Dotted Whole Note"
    case Whole                      = "Whole Note"
    case DottedHalf                 = "Dotted Half Note"
    case Half                       = "Half Note"
    case DottedQuarter              = "Dotted Quarter Note"
    case Quarter                    = "Quarter Note"
    case DottedEighth               = "Dotted Eighth Note"
    case Eighth                     = "Eighth Note"
    case DottedSixteenth            = "Dotted Sixteenth Note"
    case Sixteenth                  = "Sixteenth Note"
    case DottedThirtySecond         = "Dotted Thirty-Second Note"
    case ThirtySecond               = "Thirty-Second Note"
    case DottedSixtyFourth          = "Dotted Sixty-Fourth Note"
    case SixtyFourth                = "Sixty-Fourth Note"
    case DottedHundredTwentyEighth  = "Dotted Hundred Twenty-Eighth Note"
    case HundredTwentyEighth        = "Hundred Twenty-Eighth Note"
    case DottedTwoHundredFiftySixth = "Dotted Two Hundred Fifty-Sixth Note"
    case TwoHundredFiftySixth       = "Two Hundred Fifty-Sixth Note"

    var seconds: Double {
      let secondsPerBeat = 60 / Sequencer.tempo
      switch self {
        case .DoubleWhole:                return secondsPerBeat * 8
        case .DottedWhole:                return secondsPerBeat * 6
        case .Whole:                      return secondsPerBeat * 4
        case .DottedHalf:                 return secondsPerBeat * 3
        case .Half:                       return secondsPerBeat * 2
        case .DottedQuarter:              return secondsPerBeat * 3╱2
        case .Quarter:                    return secondsPerBeat
        case .DottedEighth:               return secondsPerBeat * 3╱4
        case .Eighth:                     return secondsPerBeat * 1╱2
        case .DottedSixteenth:            return secondsPerBeat * 3╱8
        case .Sixteenth:                  return secondsPerBeat * 1╱4
        case .DottedThirtySecond:         return secondsPerBeat * 3╱16
        case .ThirtySecond:               return secondsPerBeat * 1╱8
        case .DottedSixtyFourth:          return secondsPerBeat * 3╱32
        case .SixtyFourth:                return secondsPerBeat * 1╱16
        case .DottedHundredTwentyEighth:  return secondsPerBeat * 3╱64
        case .HundredTwentyEighth:        return secondsPerBeat * 1╱32
        case .DottedTwoHundredFiftySixth: return secondsPerBeat * 3╱128
        case .TwoHundredFiftySixth:       return secondsPerBeat * 1╱64
      }
    }

    

    var image: UIImage { return UIImage(named: rawValue)! }

    static let allCases: [Duration] = [.DoubleWhole, .DottedWhole, .Whole, .DottedHalf, .Half, .DottedQuarter, .Quarter,
                                           .DottedEighth, .Eighth, .DottedSixteenth, .Sixteenth, .DottedThirtySecond, 
                                           .ThirtySecond, .DottedSixtyFourth, .SixtyFourth, .DottedHundredTwentyEighth, 
                                           .HundredTwentyEighth, .DottedTwoHundredFiftySixth, .TwoHundredFiftySixth ]
  }

  var duration: Duration = .Eighth



  enum Velocity: String, EnumerableType {
    case Pianississimo
    case Pianissimo
    case Piano
    case MezzoPiano
    case MezzoForte
    case Forte
    case Fortissimo
    case Fortississimo
    var midi: UInt8 {
      switch self {
        case .Pianississimo: return 16
        case .Pianissimo:    return 33
        case .Piano:         return 49
        case .MezzoPiano:    return 64
        case .MezzoForte:    return 80
        case .Forte:         return 96
        case .Fortissimo:    return 112
        case .Fortississimo: return 126
      }
    }
    static let allCases: [Velocity] = [.Pianississimo, .Pianissimo, .Piano, .MezzoPiano, .MezzoForte, 
                                       .Forte, .Fortissimo, .Fortississimo]
  }

  var velocity: Velocity = .MezzoForte
}


func ==(lhs: NoteAttributes.Note, rhs: NoteAttributes.Note) -> Bool {
  switch (lhs, rhs) {
  case let (.Pitch(l1, o1), .Pitch(l2, o2)) where l1 == l2 && o1 == o2: return true
  default: return false
  }
}


