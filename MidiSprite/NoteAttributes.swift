//
//  Note.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Protocol for types that can be converted to and from a value within the range of 0 ... 127  */
protocol MIDIConvertible: Hashable, Equatable {
  var midi: Byte { get }
  init(midi: Byte)
}

extension MIDIConvertible {
  var hashValue: Int { return midi.hashValue }
}

func ==<M:MIDIConvertible>(lhs: M, rhs: M) -> Bool { return lhs.midi == rhs.midi }

/** Structure that encapsulates MIDI information necessary for playing a note */
struct NoteAttributes {

  var channel: UInt8 = 0

  /** An enumeration for specifying a note's pitch and octave */
  struct Note: RawRepresentable, Equatable, EnumerableType, MIDIConvertible {

    enum Pitch: String, EnumerableType {
      case C="C", CSharp="C♯", D="D", DSharp="D♯", E="E", F="F", FSharp="F♯", G="G", GSharp="G♯",
           A="A", ASharp="A♯", B="B"

      init(_ i: UInt8) { self = Pitch.allCases[Int(i % 12)] }
      init(var index: Int) { index %= Pitch.allCases.count; self = Pitch.allCases[index] }
      static let allCases: [Pitch] = [C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B]
    }

    enum Octave: String, EnumerableType {
      case NegativeOne = "-1", Zero = "0", One = "1", Two = "2", Three = "3",
           Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9"
      static let allCases: [Octave] = [.NegativeOne, .Zero, .One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight, .Nine]

      var intValue: Int { return Int(rawValue)! }
    }

    var pitch: Pitch
    var octave: Octave

    /**
    Initialize from MIDI value from 0 ... 127

    - parameter value: Int
    */
    init(var midi value: Byte) {
      value %= 128;  pitch = Pitch(value); octave = Octave(rawValue: "\((Int(value) / 12) - 1)") ?? .Four
    }

    /**
    Initialize with string representation

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^([A-G]♯?) ?((?:-1)|[0-9])$").firstMatch(rawValue),
        rawPitch = match.captures[1]?.string,
        pitch = Pitch(rawValue: rawPitch),
        rawOctave = match.captures[2]?.string,
        octave = Octave(rawValue: rawOctave) else { return nil }

      self.pitch = pitch; self.octave = octave
    }

    var rawValue: String { return "\(pitch.rawValue)\(octave.rawValue)" }

    var midi: Byte { return UInt8((octave.intValue + 1) * 12 + pitch.index) }

    static let allCases: [Note] = (0...127).map({Note(midi: $0)})

  }

  /// The pitch and octave
  var note: Note = Note(midi: 60)

  /** Enumeration for a musical note duration */
  enum Duration: String, EnumerableType, ImageAssetLiteralType {
    case DoubleWhole, DottedWhole, Whole, DottedHalf, Half, DottedQuarter, Quarter, DottedEighth,
         Eighth, DottedSixteenth, Sixteenth, DottedThirtySecond, ThirtySecond, DottedSixtyFourth,
         SixtyFourth, DottedHundredTwentyEighth, HundredTwentyEighth, DottedTwoHundredFiftySixth,
         TwoHundredFiftySixth

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

    static let allCases: [Duration] = [
      .DoubleWhole, .DottedWhole, .Whole, .DottedHalf, .Half, .DottedQuarter, .Quarter,
      .DottedEighth, .Eighth, .DottedSixteenth, .Sixteenth, .DottedThirtySecond,
      .ThirtySecond, .DottedSixtyFourth, .SixtyFourth, .DottedHundredTwentyEighth,
      .HundredTwentyEighth, .DottedTwoHundredFiftySixth, .TwoHundredFiftySixth
    ]

  }

  /// The duration of the played note
  var duration: Duration = .Eighth

  /** Enumeration for musical dynamics 𝑚𝑝𝑚𝑓 */
  enum Velocity: String, EnumerableType, ImageAssetLiteralType, MIDIConvertible {
    case 𝑝𝑝𝑝, 𝑝𝑝, 𝑝, 𝑚𝑝, 𝑚𝑓, 𝑓, 𝑓𝑓, 𝑓𝑓𝑓

    var midi: Byte {
      switch self {
        case .𝑝𝑝𝑝:	return 16
        case .𝑝𝑝:		return 33
        case .𝑝:		return 49
        case .𝑚𝑝:		return 64
        case .𝑚𝑓:		return 80
        case .𝑓:			return 96
        case .𝑓𝑓:		return 112
        case .𝑓𝑓𝑓:		return 126
      }
    }
    init(midi value: Byte) {
      switch value {
        case 0 ... 22:    self = .𝑝𝑝𝑝
        case 23 ... 40:   self = .𝑝𝑝
        case 41 ... 51:   self = .𝑝
        case 52 ... 70:   self = .𝑚𝑝
        case 71 ... 88:   self = .𝑚𝑓
        case 81 ... 102:  self = .𝑓
        case 103 ... 119: self = .𝑓𝑓
        default:          self = .𝑓𝑓𝑓
      }
    }
    static let allCases: [Velocity] = [.𝑝𝑝𝑝, .𝑝𝑝, .𝑝, .𝑚𝑝, .𝑚𝑓, .𝑓, .𝑓𝑓, .𝑓𝑓𝑓]
  }

  /// The dynmamics for the note
  var velocity: Velocity = .𝑚𝑓
}

// MARK: - ByteArrayConvertible
extension NoteAttributes: ByteArrayConvertible {

  var bytes: [Byte] { return [channel, note.midi, velocity.midi] + duration.rawValue.bytes }

  /**
  init:

  - parameter bytes: [Byte]
  */
  init!(_ bytes: [Byte]) {
    guard bytes.count >= 7 else { return }
    channel  = bytes[0]
    note     = Note(midi: bytes[1])
    velocity = Velocity(midi: bytes[2])
    duration = Duration(rawValue: String(bytes[3..<])) ?? .Eighth
  }
}

extension NoteAttributes.Note: CustomStringConvertible {
  var description: String { return rawValue }
}

extension NoteAttributes.Note: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension NoteAttributes.Duration: CustomStringConvertible {
  var description: String {
    switch self {
      case .DoubleWhole:                return "double-whole note"
      case .DottedWhole:                return "dotted whole note"
      case .Whole:                      return "whole note"
      case .DottedHalf:                 return "dotted half note"
      case .Half:                       return "half note"
      case .DottedQuarter:              return "dotted quarter note"
      case .Quarter:                    return "quarter note"
      case .DottedEighth:               return "dotted eighth note"
      case .Eighth:                     return "eighth note"
      case .DottedSixteenth:            return "dotted sixteenth note"
      case .Sixteenth:                  return "sixteenth note"
      case .DottedThirtySecond:         return "dotted thirty-second note"
      case .ThirtySecond:               return "thirty-second note"
      case .DottedSixtyFourth:          return "dotted sixty-fourth note"
      case .SixtyFourth:                return "sixty-fourth note"
      case .DottedHundredTwentyEighth:  return "dotted hundred twenty-eighth note"
      case .HundredTwentyEighth:        return "hundred twenty-eighth note"
      case .DottedTwoHundredFiftySixth: return "dotted two hundred-fifty-sixth note"
      case .TwoHundredFiftySixth:       return "two hundred fifty-sixth note"
    }
  }  
}

extension NoteAttributes.Duration: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension NoteAttributes.Velocity: CustomStringConvertible {
  var description: String { return rawValue }
}

extension NoteAttributes.Velocity: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - CustomStringConvertible

extension NoteAttributes: CustomStringConvertible {
  var description: String { return "{\(channel), \(note), \(duration), \(velocity)}" }
}

extension NoteAttributes: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Equatable
extension NoteAttributes: Equatable {}

func ==(lhs: NoteAttributes.Note, rhs: NoteAttributes.Note) -> Bool { return lhs.midi == rhs.midi }

func ==(lhs: NoteAttributes, rhs: NoteAttributes) -> Bool {
  return lhs.channel == rhs.channel && lhs.duration == rhs.duration && lhs.velocity == rhs.velocity && lhs.note == rhs.note
}
