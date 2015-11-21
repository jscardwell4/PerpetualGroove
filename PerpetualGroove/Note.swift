//
//  Note.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

enum DiatonicPitch: String, EnumerableType {
  case C, D, E, F, G, A, B
  static let allCases: [DiatonicPitch] = [.C, .D, .E, .F, .G, .A, .B]

  enum StepSize { case Half, Whole }


  var next: DiatonicPitch {
    switch self {
      case .C: return .D
      case .D: return .E
      case .E: return .F
      case .F: return .G
      case .G: return .A
      case .A: return .B
      case .B: return .C
    }
  }

  var previous: DiatonicPitch {
    switch self {
      case .C: return .B
      case .D: return .C
      case .E: return .D
      case .F: return .E
      case .G: return .F
      case .A: return .G
      case .B: return .A
    }
  }

  var nextInterval: StepSize {
    switch self {
      case .B, .E: return .Half
      default: return .Whole
    }
  }

  var previousInterval: StepSize {
    switch self {
      case .C, .F: return .Half
      default: return .Whole
    }
  }

}

extension DiatonicPitch: BidirectionalIndexType {
  /**
   successor

   - returns: DiatonicPitch
   */
  func successor() -> DiatonicPitch { return next }

  /**
   predecessor

   - returns: DiatonicPitch
   */
  func predecessor() -> DiatonicPitch { return previous }

}

enum Accidental: String, EnumerableType {
  case Flat = "♭", Natural = "", Sharp = "♯"
  static let allCases: [Accidental] = [.Flat, .Natural, .Sharp]
}

/** Structure that encapsulates MIDI information necessary for playing a note */
struct Note {

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
extension Note {
  /** An enumeration for specifying a note's pitch and octave */
  struct Tone: RawRepresentable, Equatable, EnumerableType, MIDIConvertible, CustomStringConvertible {



    enum Pitch: String, EnumerableType, BidirectionalIndexType {

      case C="C", CSharp="C♯", D="D", DSharp="D♯", E="E", F="F", FSharp="F♯", G="G", GSharp="G♯",
           A="A", ASharp="A♯", B="B"

      static let allCases: [Pitch] = [C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B]

      func successor() -> Pitch {
        switch self {
          case .C:      return .CSharp
          case .CSharp: return .D
          case .D:      return .DSharp
          case .DSharp: return .E
          case .E:      return .F
          case .F:      return .FSharp
          case .FSharp: return .G
          case .G:      return .GSharp
          case .GSharp: return .A
          case .A:      return .ASharp
          case .ASharp: return .B
          case .B:      return .C
        }
      }

      func predecessor() -> Pitch {
        switch self {
          case .C:      return .B
          case .CSharp: return .C
          case .D:      return .CSharp
          case .DSharp: return .D
          case .E:      return .DSharp
          case .F:      return .E
          case .FSharp: return .F
          case .G:      return .FSharp
          case .GSharp: return .G
          case .A:      return .GSharp
          case .ASharp: return .A
          case .B:      return .ASharp
        }
      }

      var diatonicPitch: DiatonicPitch {
        switch self {
          case .C, .CSharp: return .C
          case .D, DSharp:  return .D
          case .E:          return .E
          case .F, .FSharp: return .F
          case .G, .GSharp: return .G
          case .A, .ASharp: return .A
          case .B:          return .B
        }
      }

      var accidental: Accidental {
        switch self {
          case .CSharp, .DSharp, .FSharp, .GSharp, .ASharp: return .Sharp
          default:                                          return .Natural
        }
      }

      /**
      Initialize from a number

      - parameter i: UInt8
      */
      init(_ i: UInt8) { self = Pitch.allCases[Int(i % 12)] }

      /**
      Initialize from an index into `Pitch.allCases`

      - parameter index: Int
      */
      init(var index: Int) { index %= Pitch.allCases.count; self = Pitch.allCases[index] }

      /**
      Initialize from a diatonic pitch and an accidental

      - parameter pitch: DiatonicPitch
      - parameter accidental: Accidental
      */
      init(_ pitch: DiatonicPitch, _ accidental: Accidental) {
        switch pitch {
          case .C where accidental == .Sharp: self = .CSharp
          case .C where accidental == .Flat:  self = .B
          case .C:                            self = .C
          case .D where accidental == .Sharp: self = .DSharp
          case .D where accidental == .Flat:  self = .CSharp
          case .D:                            self = .D
          case .E where accidental == .Sharp: self = .F
          case .E where accidental == .Flat:  self = .DSharp
          case .E:                            self = .E
          case .F where accidental == .Sharp: self = .FSharp
          case .F where accidental == .Flat:  self = .E
          case .F:                            self = .F
          case .G where accidental == .Sharp: self = .GSharp
          case .G where accidental == .Flat:  self = .FSharp
          case .G:                            self = .G
          case .A where accidental == .Sharp: self = .ASharp
          case .A where accidental == .Flat:  self = .GSharp
          case .A:                            self = .A
          case .B where accidental == .Sharp: self = .C
          case .B where accidental == .Flat:  self = .ASharp
          case .B:                            self = .B
        }
      }

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
    init:octave:

    - parameter pitch: Pitch
    - parameter octave: Octave
    */
    init(_ pitch: Pitch, _ octave: Octave) {
      self.pitch = pitch
      self.octave = octave
    }

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

    static let allCases: [Tone] = (0...127).map({Tone(midi: $0)})

    var description: String { return rawValue }
  }
}

// MARK: - Duration
extension Note {
  /** Enumeration for a musical note duration */
  enum Duration: String, EnumerableType, ImageAssetLiteralType, CustomStringConvertible {
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
}

// MARK: - Velocity
extension Note {
  /** Enumeration for musical dynamics 𝑚𝑝𝑚𝑓 */
  enum Velocity: String, EnumerableType, ImageAssetLiteralType, MIDIConvertible, CustomStringConvertible {
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

    var description: String { return rawValue }
  }
}

// MARK: - MIDINoteGenerator
extension Note: MIDINoteGenerator {

  typealias Packet = MIDINode.Packet

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
extension Note: ByteArrayConvertible {

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
extension Note: CustomStringConvertible {
  var description: String { return "{\(channel), \(note), \(duration), \(velocity)}" }
}

// MARK: - Equatable
extension Note: Equatable {}

func ==(lhs: Note.Tone, rhs: Note.Tone) -> Bool { return lhs.midi == rhs.midi }

func ==(lhs: Note, rhs: Note) -> Bool {
  return lhs.channel == rhs.channel && lhs.duration == rhs.duration && lhs.velocity == rhs.velocity && lhs.note == rhs.note
}
