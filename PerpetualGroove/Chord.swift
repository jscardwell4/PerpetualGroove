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


struct Chord: RawRepresentable {
  var root = Note.Default(.C)
  var pattern = ChordPattern(.Major)

  var rawValue: String { return "\(root.rawValue):\(pattern.rawValue)" }

  init?(rawValue: String) {
    let components = ":".split(rawValue)
    guard components.count == 2,
      let root = Note(rawValue: components[0]),
      pattern = ChordPattern(rawValue: components[1]) else { return nil }

    self.root = root
    self.pattern = pattern
  }

  var notes: [Note] { return pattern.notesWithRoot(root) }

  init(_ root: Note, _ pattern: ChordPattern) {
    self.root = root
    self.pattern = pattern
  }

  init() {}
}

extension Chord: CustomStringConvertible {
  var description: String { return " ".join(notes.map({$0.rawValue})) }
}

extension Chord: CustomDebugStringConvertible {
  var debugDescription: String { return String(reflecting: self) }
}

extension Chord: Equatable {}

func ==(lhs: Chord, rhs: Chord) -> Bool {
  return lhs.root == rhs.root && lhs.pattern == rhs.pattern
}

extension Chord {

  struct ChordPattern: RawRepresentable {

    /** 
     The lowest note in the pattern. When this does not correspond to the abstract 'root' note,
     the pattern represents an 'inversion'. 
     */
    let bass: Degree

    /** The collection of 'notes' of which the chord consists */
    let components: [Degree]

    var rawValue: String {
      var result = "(\(",".join(components.map({$0.rawValue}))))"
      if bass != .Default(.One) { result += "/\(bass.rawValue)" }
      return result
    }

    /**
     Initialize from a string with the following syntax:
     '(' <degree> ( ',' <degree> )* ')' ( '/' <degree> )?

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^\\(([^)]+)\\)(?:/(.+))?").firstMatch(rawValue),
        componentsList = match.captures[1]?.string else { return nil }

      components = ",".split(componentsList).flatMap({Degree(rawValue: $0)})
      bass = Degree(rawValue: match.captures[2]?.string ?? "") ?? .Default(.One)
    }

    /**
    Initialize using one of the pre-defined standard patterns

    - parameter standard: StandardChordPattern
    */
    init(_ standard: StandardChordPattern) { self.init(rawValue: standard.rawValue)! }

    /**
    Initialize with an optional bass degree and the list of component degrees

    - parameter bass: Degree? = nil
    - parameter components: [Degree]
    */
    init(bass: Degree? = nil, components: [Degree]) {
      self.bass = bass ?? .Default(.One)
      self.components = components
    }

    /**
    notesWithRoot:

    - parameter root: Note

    - returns: [Note]
    */
    func notesWithRoot(root: Note) -> [Note] {
      var result: [Note] = []
      let natural = root.natural
      let modifier = root.modifier

      var degrees: [Degree] = [Degree.Default(.One)] + components
      if degrees.contains(bass) {
        while degrees.first != bass { let degree = degrees.removeAtIndex(0); degrees.append(degree) }
      }

      for degree in degrees {
        let note: Note
        switch degree {
          case let .Default(i):
            note = Note.Default(natural.advancedBy(i.rawValue - 1))
          case let .Modified(i, .Flat):
            note = Note.Default(natural.advancedBy(i.rawValue - 1)).flattened()
          case let .Modified(i, .Sharp):
            note = Note.Default(natural.advancedBy(i.rawValue - 1)).sharpened()
          case let .TwiceModified(i, .Flat):
            note = Note.Default(natural.advancedBy(i.rawValue - 1)).flattened().flattened()
          case let .TwiceModified(i, .Sharp):
            note = Note.Default(natural.advancedBy(i.rawValue - 1)).sharpened().sharpened()
        }
        switch modifier {
          case .Flat?:  result.append(note.flattened())
          case .Sharp?: result.append(note.sharpened())
          case nil:     result.append(note)
        }
      }

      return result
    }

  }
}

extension Chord.ChordPattern {

  /** Specifies the distance from an abstract 'root' note. These correspond to the major diatonic intervals */
  enum Interval: Int {
    case One = 1, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Eleven, Twelve, Thirteen
  }

}

extension Chord.ChordPattern {

  /** Identifies a note relative to an abstract 'root' note */
  enum Degree: RawRepresentable, Equatable {
    case Default (Interval)
    case Modified (Interval, PitchModifier)
    case TwiceModified (Interval, PitchModifier)
    var rawValue: String {
      switch self {
        case let .Default(interval): return String(interval.rawValue)
        case let .Modified(interval, modifier): return modifier.rawValue + String(interval.rawValue)
        case let .TwiceModified(interval, modifier): return (modifier.rawValue * 2) + String(interval.rawValue)
      }
    }
    /**
    initWithRawValue:

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^((?:[♭♯]{1,2})?)(1?[0-9])").firstMatch(rawValue),
        rawIntervalString = match.captures[2]?.string,
        rawInterval = Int(rawIntervalString),
        interval = Interval(rawValue: rawInterval) else { return nil }
      if let rawModifier = match.captures[1]?.string where !rawModifier.isEmpty {
        guard let modifier = PitchModifier(rawValue: rawModifier) else { return nil }
        self = .Modified(interval, modifier)
      } else {
        self = .Default(interval)
      }
    }
  }

}

extension Chord.ChordPattern {
  
  /** Commonly used chord patterns */
  enum StandardChordPattern: String, EnumerableType {
    case Major                                   = "(3,5)"
    case Minor                                   = "(♭3,5)"
    case Augmented                               = "(3,♯5)"
    case Diminished                              = "(♭3,♭5)"
    case SuspendedFourth                         = "(4,5)"
    case FlatFifth                               = "(3,♭5)"
    case SuspendedSecond                         = "(2,5)"
    case MajorSixth                              = "(3,5,6)"
    case AddTwo                                  = "(2,3,5)"
    case MajorSeventh                            = "(3,5,7)"
    case MajorSeventhFlatFifth                   = "(3,♭5,7)"
    case MajorSeventhSharpFifth                  = "(3,♯5,7)"
    case Seventh                                 = "(3,5,♭7)"
    case SeventhFlatFifth                        = "(3,♭5,♭7)"
    case SeventhSharpFifth                       = "(3,♯5,♭7)"
    case SeventhSuspendedFourth                  = "(4,5,♭7)"
    case MinorAddTwo                             = "(2,♭3,5)"
    case MinorSixth                              = "(♭3,5,6)"
    case MinorSeventh                            = "(♭3,5,♭7)"
    case MinorMajorSeventh                       = "(♭3,5,7)"
    case MinorSeventhFlatFifth                   = "(♭4,♭5,♭7)"
    case DiminishedSeventh                       = "(♭3,♭5,♭♭7)"
    case DiminishedMajorSeventh                  = "(♭3,♭5,7)"
    case Fifth                                   = "(5)"
    case SixthNinth                              = "(3,5,6,9)"
    case MajorSixthNinth                         = "(3,5,6,7,9)"
    case MajorSeventhSharpEleventh               = "(3,5,7,♯11)"
    case MajorNinth                              = "(3,5,7,9)"
    case MajorNinthFlatFifth                     = "(3,♭5,7,9)"
    case MajorNinthSharpFifth                    = "(3,♯5,7,9)"
    case MajorNinthSharpEleventh                 = "(3,5,7,9,♯11)"
    case MajorThirteenth                         = "(3,5,7,9,13)"
    case MajorThirteenthFlatFifth                = "(3,♭5,7,9,13)"
    case MajorThirteenthSharpEleventh            = "(3,5,7,9,♯11,13)"
    case SeventhFlatNinth                        = "(3,5,♭7,♭9)"
    case SeventhSharpNinth                       = "(3,5,♭7,♯9)"
    case SeventhSharpEleventh                    = "(3,5,♭7,♯11)"
    case SeventhFlatFifthFlatNinth               = "(3,♭5,♭7,♭9)"
    case SeventhFlatFifthSharpNinth              = "(3,♭5,♭7,♯9)"
    case SeventhSharpFifthFlatNinth              = "(3,♯5,♭7,♭9)"
    case SeventhSharpFifthSharpNinth             = "(3,♯5,♭7,♯9)"
    case SeventhFlatNinthSharpNinth              = "(3,5,♭7,♭9,♯9)"
    case SeventhAddThirteenth                    = "(3,5,♭7,13)"
    case SeventhFlatThirteenth                   = "(3,5,♭7,♭13)"
    case SeventhFlatNinthSharpEleventh           = "(3,5,♭7,♭9,♯11)"
    case SeventhSharpNinthSharpEleventh          = "(3,5,♭7,♯9,♯11)"
    case SeventhFlatNinthFlatThirteenth          = "(3,5,♭7,♭9,♭13)"
    case SeventhSharpNinthFlatThirteenth         = "(3,5,♭7,♯9,♭13)"
    case SeventhSharpEleventhFlatThirteenth      = "(3,5,♭7,♯11,♭13)"
    case SeventhFlatNinthSharpNinthSharpEleventh = "(3,5,♭7,♭9,♯9,♯11)"
    case Ninth                                   = "(3,5,♭7,9)"
    case NinthFlatFifth                          = "(3,♭5,♭7,9)"
    case NinthSharpFifth                         = "(3,♯5,♭7,9)"
    case NinthSharpEleventh                      = "(3,5,♭7,9,♯11)"
    case NinthFlatThirteenth                     = "(3,5,♭7,9,♭13)"
    case NinthSharpEleventhFlatThirteenth        = "(3,5,♭7,9,♯11,♯13)"
    case Eleventh                                = "(5,♭7,9,11)"
    case Thirteenth                              = "(3,5,♭7,9,13)"
    case ThirteenthFlatFifth                     = "(3,♭5,♭7,9,13)"
    case ThirteenthFlatNinth                     = "(3,5,♭7,♭9,13)"
    case ThirteenthSharpNinth                    = "(3,5,♭7,♯9,13)"
    case ThirteenthSharpEleventh                 = "(3,5,♭7,9,♯11,13)"
    case ThirteenthSuspendedFourth               = "(4,5,♭7,9,13)"
    case MinorSharpFifth                         = "(♭3,♯5)"
    case MinorSixthNinth                         = "(♭3,5,6,9)"
    case MinorSeventhAddFourth                   = "(♭3,5,♭7,11)"
    case MinorSeventhFlatFifthFlatNinth          = "(♭3,♭5,♭7,♭9)"
    case MinorNinth                              = "(♭3,5,♭7,9)"
    case MinorNinthMajorSeventh                  = "(♭3,5,7,9)"
    case MinorNinthFlatFifth                     = "(♭3,♭5,♭7,9)"
    case MinorEleventh                           = "(♭3,5,♭7,9,11)"
    case MinorThirteenth                         = "(♭3,5,♭7,9,11,13)"
    case DiminishedSeventhAddNinth               = "(♭3,♭5,♭♭7,9)"
    case MinorEleventhFlatFifth                  = "(♭3,♭5,♭7,9,11)"
    case MinorEleventhMajorSeventh               = "(♭3,5,7,9,11)"
    case SeventhAltered                          = "(3,5,♭7,♭9,♯9,♯11,♭13)"

    static let allCases: [StandardChordPattern] = [
      .Major, .Minor, .Augmented, .Diminished, .SuspendedFourth, .FlatFifth, .SuspendedSecond, .MajorSixth, 
      .AddTwo, .MajorSeventh, .MajorSeventhFlatFifth, .MajorSeventhSharpFifth, .Seventh, .SeventhFlatFifth, 
      .SeventhSharpFifth, .SeventhSuspendedFourth, .MinorAddTwo, .MinorSixth, .MinorSeventh, .MinorMajorSeventh, 
      .MinorSeventhFlatFifth, .DiminishedSeventh, .DiminishedMajorSeventh, .Fifth, .SixthNinth, .MajorSixthNinth, 
      .MajorSeventhSharpEleventh, .MajorNinth, .MajorNinthFlatFifth, .MajorNinthSharpFifth, 
      .MajorNinthSharpEleventh, .MajorThirteenth, .MajorThirteenthFlatFifth, .MajorThirteenthSharpEleventh, 
      .SeventhFlatNinth, .SeventhSharpNinth, .SeventhSharpEleventh, .SeventhFlatFifthFlatNinth, 
      .SeventhFlatFifthSharpNinth, .SeventhSharpFifthFlatNinth, .SeventhSharpFifthSharpNinth, 
      .SeventhFlatNinthSharpNinth, .SeventhAddThirteenth, .SeventhFlatThirteenth, .SeventhFlatNinthSharpEleventh, 
      .SeventhSharpNinthSharpEleventh, .SeventhFlatNinthFlatThirteenth, .SeventhSharpNinthFlatThirteenth, 
      .SeventhSharpEleventhFlatThirteenth, .SeventhFlatNinthSharpNinthSharpEleventh, .Ninth, .NinthFlatFifth, 
      .NinthSharpFifth, .NinthSharpEleventh, .NinthFlatThirteenth, .NinthSharpEleventhFlatThirteenth, .Eleventh, 
      .Thirteenth, .ThirteenthFlatFifth, .ThirteenthFlatNinth, .ThirteenthSharpNinth, .ThirteenthSharpEleventh, 
      .ThirteenthSuspendedFourth, .MinorSharpFifth, .MinorSixthNinth, .MinorSeventhAddFourth, 
      .MinorSeventhFlatFifthFlatNinth, .MinorNinth, .MinorNinthMajorSeventh, .MinorNinthFlatFifth, .MinorEleventh, 
      .MinorThirteenth, .DiminishedSeventhAddNinth, .MinorEleventhFlatFifth, .MinorEleventhMajorSeventh, .SeventhAltered 
    ]    
  }

}
