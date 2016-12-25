//
//  Chord.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

struct Chord {

  var root = Note.natural(.c)
  var pattern = Pattern(.major)

  var notes: [Note] { return pattern.notes(withRoot: root) }

  init(root: Note = .natural(.c), pattern: Pattern = Pattern(.major)) {
    self.root = root
    self.pattern = pattern
  }

}

extension Chord: RawRepresentable, LosslessJSONValueConvertible {

  var rawValue: String { return "\(root.rawValue):\(pattern.rawValue)" }

  init?(rawValue: String) {
    let components = ":".split(rawValue)
    guard components.count == 2,
      let root = Note(rawValue: components[0]),
      let pattern = Pattern(rawValue: components[1]) else { return nil }

    self.root = root
    self.pattern = pattern
  }

}

extension Chord: CustomStringConvertible {

  var description: String { return " ".join(notes.map({$0.rawValue})) }

}

extension Chord: Hashable {

  var hashValue: Int { return root.hashValue ^ pattern.hashValue }

  static func ==(lhs: Chord, rhs: Chord) -> Bool {
    return lhs.root == rhs.root && lhs.pattern == rhs.pattern
  }

}

extension Chord {

  struct Pattern {

    /// The lowest note in the pattern. When this does not correspond to the abstract 'root' 
    /// note, the pattern represents an 'inversion'.
    let bass: Degree

    /// The collection of 'notes' of which the chord consists
    let components: [Degree]

    /// Initialize using one of the pre-defined standard patterns
    init(_ standard: Standard) { self.init(rawValue: standard.rawValue)! }

    /// Initialize with an optional bass degree and the list of component degrees
    init(bass: Degree? = nil, components: [Degree]) {
      self.bass = bass ?? .`default`(.one)
      self.components = components
    }

    var standardIndex: Int? { return Standard(rawValue: rawValue)?.index }

    func notes(withRoot root: Note) -> [Note] {
      var result: [Note] = []
      let natural = root.natural
      let modifier = root.modifier

      var degrees: [Degree] = [.`default`(.one)] + components
      
      if degrees.contains(bass) {
        while degrees.first != bass { degrees.append(degrees.removeFirst()) }
      }

      for degree in degrees {
        let note: Note
        switch degree {
          case let .`default`(i):
            note = Note.natural(natural.advanced(by: i.rawValue - 1))
          case let .modified(i, .flat):
            note = Note.natural(natural.advanced(by: i.rawValue - 1)).flattened

          case let .modified(i, .sharp):
            note = Note.natural(natural.advanced(by: i.rawValue - 1)).sharpened
          case let .modified(i, .doubleFlat):
            note = Note.natural(natural.advanced(by: i.rawValue - 1)).flattened.flattened
        }

        switch modifier {
          case .flat?:       result.append(note.flattened)
          case .sharp?:      result.append(note.sharpened)
          case .doubleFlat?: result.append(note.flattened.flattened)
          case nil:          result.append(note)
        }
      }

      return result
    }

  }

}

extension Chord.Pattern: Hashable {

  var hashValue: Int {
    return components.reduce(bass.hashValue) { $0 ^ $1.hashValue }
  }

}

extension Chord.Pattern: RawRepresentable {

    var rawValue: String {
      var result = "(\(",".join(components.map({$0.rawValue}))))"
      if bass != .`default`(.one) { result += "/\(bass.rawValue)" }
      return result
    }

    /// Initialize from a string with the following syntax:
    /// '(' <degree> ( ',' <degree> )* ')' ( '/' <degree> )?
    init?(rawValue: String) {
      guard let captures = (rawValue ~=> ~/"^\\(([^)]+)\\)(?:/(.+))?"),
            let componentsList = captures.1 else { return nil }

      components = ",".split(componentsList).flatMap({Degree(rawValue: $0)})
      bass = Degree(rawValue: captures.2 ?? "") ?? .`default`(.one)
    }

}

extension Chord.Pattern {

  /// Specifies the distance from an abstract 'root' note. 
  /// These correspond to the major diatonic intervals.
  enum Interval: Int {
    case one = 1, two, three, four, five, six, seven,
         eight, nine, ten, eleven, twelve, thirteen
  }

}

extension Chord.Pattern {

  /// Identifies a note relative to an abstract 'root' note
  enum Degree {
    case `default` (Interval)
    case modified (Interval, PitchModifier)

  }

}

extension Chord.Pattern.Degree: RawRepresentable {

  var rawValue: String {
    switch self {
      case let .`default`(interval):
        return String(interval.rawValue)
      case let .modified(interval, modifier):
        return modifier.rawValue + String(interval.rawValue)
    }
  }

  init?(rawValue: String) {
     guard let captures = (rawValue ~=> ~/"^([♭♯𝄫])?(1?[0-9])"),
           let rawInterval = Int(captures.2 ?? ""),
           let interval = Chord.Pattern.Interval(rawValue: rawInterval) else { return nil }

    if let rawModifier = captures.1, !rawModifier.isEmpty {
       guard let modifier = PitchModifier(rawValue: rawModifier) else { return nil }
       self = .modified(interval, modifier)
     } else {
       self = .`default`(interval)
     }
  }

}

extension Chord.Pattern.Degree: Hashable {

  var hashValue: Int {
    switch self {
      case let .`default`(interval):
        return interval.hashValue
      case let .modified(interval, modifier):
        return interval.hashValue ^ modifier.hashValue
    }
  }

  static func ==(lhs: Chord.Pattern.Degree, rhs: Chord.Pattern.Degree) -> Bool {
    switch (lhs, rhs) {
      case let (.`default`(interval1), .`default`(interval2))
        where interval1 == interval2:
        return true
      case let (.modified(interval1, modifer1), .modified(interval2, modifier2))
        where interval1 == interval2 && modifer1 == modifier2:
        return true
      default:
        return false
    }
  }

}

extension Chord.Pattern {
  
  /// Commonly used chord patterns
  enum Standard: String {
    case major                                   = "(3,5)"
    case minor                                   = "(♭3,5)"
    case augmented                               = "(3,♯5)"
    case diminished                              = "(♭3,♭5)"
    case suspendedFourth                         = "(4,5)"
    case flatFifth                               = "(3,♭5)"
    case suspendedSecond                         = "(2,5)"
    case sixth                                   = "(3,5,6)"
    case addTwo                                  = "(2,3,5)"
    case majorSeventh                            = "(3,5,7)"
    case majorSeventhFlatFifth                   = "(3,♭5,7)"
    case majorSeventhSharpFifth                  = "(3,♯5,7)"
    case seventh                                 = "(3,5,♭7)"
    case seventhFlatFifth                        = "(3,♭5,♭7)"
    case seventhSharpFifth                       = "(3,♯5,♭7)"
    case seventhSuspendedFourth                  = "(4,5,♭7)"
    case minorAddTwo                             = "(2,♭3,5)"
    case minorSixth                              = "(♭3,5,6)"
    case minorSeventh                            = "(♭3,5,♭7)"
    case minorMajorSeventh                       = "(♭3,5,7)"
    case minorSeventhFlatFifth                   = "(♭3,♭5,♭7)"
    case diminishedSeventh                       = "(♭3,♭5,𝄫7)"
    case diminishedMajorSeventh                  = "(♭3,♭5,7)"
    case fifth                                   = "(5)"
    case sixthNinth                              = "(3,5,6,9)"
    case majorSixthNinth                         = "(3,5,6,7,9)"
    case majorSeventhSharpEleventh               = "(3,5,7,♯11)"
    case majorNinth                              = "(3,5,7,9)"
    case majorNinthFlatFifth                     = "(3,♭5,7,9)"
    case majorNinthSharpFifth                    = "(3,♯5,7,9)"
    case majorNinthSharpEleventh                 = "(3,5,7,9,♯11)"
    case majorThirteenth                         = "(3,5,7,9,13)"
    case majorThirteenthFlatFifth                = "(3,♭5,7,9,13)"
    case majorThirteenthSharpEleventh            = "(3,5,7,9,♯11,13)"
    case seventhFlatNinth                        = "(3,5,♭7,♭9)"
    case seventhSharpNinth                       = "(3,5,♭7,♯9)"
    case seventhSharpEleventh                    = "(3,5,♭7,♯11)"
    case seventhFlatFifthFlatNinth               = "(3,♭5,♭7,♭9)"
    case seventhFlatFifthSharpNinth              = "(3,♭5,♭7,♯9)"
    case seventhSharpFifthFlatNinth              = "(3,♯5,♭7,♭9)"
    case seventhSharpFifthSharpNinth             = "(3,♯5,♭7,♯9)"
    case seventhFlatNinthSharpNinth              = "(3,5,♭7,♭9,♯9)"
    case seventhAddThirteenth                    = "(3,5,♭7,13)"
    case seventhFlatThirteenth                   = "(3,5,♭7,♭13)"
    case seventhFlatNinthSharpEleventh           = "(3,5,♭7,♭9,♯11)"
    case seventhSharpNinthSharpEleventh          = "(3,5,♭7,♯9,♯11)"
    case seventhFlatNinthFlatThirteenth          = "(3,5,♭7,♭9,♭13)"
    case seventhSharpNinthFlatThirteenth         = "(3,5,♭7,♯9,♭13)"
    case seventhSharpEleventhFlatThirteenth      = "(3,5,♭7,♯11,♭13)"
    case seventhFlatNinthSharpNinthSharpEleventh = "(3,5,♭7,♭9,♯9,♯11)"
    case ninth                                   = "(3,5,♭7,9)"
    case ninthFlatFifth                          = "(3,♭5,♭7,9)"
    case ninthSharpFifth                         = "(3,♯5,♭7,9)"
    case ninthSharpEleventh                      = "(3,5,♭7,9,♯11)"
    case ninthFlatThirteenth                     = "(3,5,♭7,9,♭13)"
    case ninthSharpEleventhFlatThirteenth        = "(3,5,♭7,9,♯11,♭13)"
    case eleventh                                = "(5,♭7,9,11)"
    case thirteenth                              = "(3,5,♭7,9,13)"
    case thirteenthFlatFifth                     = "(3,♭5,♭7,9,13)"
    case thirteenthFlatNinth                     = "(3,5,♭7,♭9,13)"
    case thirteenthSharpNinth                    = "(3,5,♭7,♯9,13)"
    case thirteenthSharpEleventh                 = "(3,5,♭7,9,♯11,13)"
    case thirteenthSuspendedFourth               = "(4,5,♭7,9,13)"
    case minorSharpFifth                         = "(♭3,♯5)"
    case minorSixthNinth                         = "(♭3,5,6,9)"
    case minorSeventhAddFourth                   = "(♭3,4,5,♭7)"
    case minorSeventhAddEleventh                 = "(♭3,5,♭7,11)"
    case minorSeventhFlatFifthFlatNinth          = "(♭3,♭5,♭7,♭9)"
    case minorNinth                              = "(♭3,5,♭7,9)"
    case minorNinthMajorSeventh                  = "(♭3,5,7,9)"
    case minorNinthFlatFifth                     = "(♭3,♭5,♭7,9)"
    case minorEleventh                           = "(♭3,5,♭7,9,11)"
    case minorThirteenth                         = "(♭3,5,♭7,9,11,13)"
    case diminishedSeventhAddNinth               = "(♭3,♭5,𝄫7,9)"
    case minorEleventhFlatFifth                  = "(♭3,♭5,♭7,9,11)"
    case minorEleventhMajorSeventh               = "(♭3,5,7,9,11)"
    case seventhAltered                          = "(3,5,♭7,♭9,♯9,♯11,♭13)"
  }

}

extension Chord.Pattern.Standard: EnumerableType {

  static let allCases: [Chord.Pattern.Standard] = [
    .major, .minor, .augmented, .diminished, .suspendedFourth, .flatFifth, .suspendedSecond, .sixth, 
    .addTwo, .majorSeventh, .majorSeventhFlatFifth, .majorSeventhSharpFifth, .seventh,
    .seventhFlatFifth, .seventhSharpFifth, .seventhSuspendedFourth, .minorAddTwo, .minorSixth,
    .minorSeventh, .minorMajorSeventh, .minorSeventhFlatFifth, .diminishedSeventh,
    .diminishedMajorSeventh, .fifth, .sixthNinth, .majorSixthNinth, .majorSeventhSharpEleventh,
    .majorNinth, .majorNinthFlatFifth, .majorNinthSharpFifth, .majorNinthSharpEleventh,
    .majorThirteenth, .majorThirteenthFlatFifth, .majorThirteenthSharpEleventh, .seventhFlatNinth,
    .seventhSharpNinth, .seventhSharpEleventh, .seventhFlatFifthFlatNinth, .seventhFlatFifthSharpNinth,
    .seventhSharpFifthFlatNinth, .seventhSharpFifthSharpNinth, .seventhFlatNinthSharpNinth,
    .seventhAddThirteenth, .seventhFlatThirteenth, .seventhFlatNinthSharpEleventh,
    .seventhSharpNinthSharpEleventh, .seventhFlatNinthFlatThirteenth, .seventhSharpNinthFlatThirteenth,
    .seventhSharpEleventhFlatThirteenth, .seventhFlatNinthSharpNinthSharpEleventh, .ninth,
    .ninthFlatFifth, .ninthSharpFifth, .ninthSharpEleventh, .ninthFlatThirteenth,
    .ninthSharpEleventhFlatThirteenth, .eleventh, .thirteenth, .thirteenthFlatFifth,
    .thirteenthFlatNinth, .thirteenthSharpNinth, .thirteenthSharpEleventh, .thirteenthSuspendedFourth,
    .minorSharpFifth, .minorSixthNinth, .minorSeventhAddFourth, .minorSeventhAddEleventh,
    .minorSeventhFlatFifthFlatNinth, .minorNinth, .minorNinthMajorSeventh, .minorNinthFlatFifth,
    .minorEleventh, .minorThirteenth, .diminishedSeventhAddNinth, .minorEleventhFlatFifth,
    .minorEleventhMajorSeventh, .seventhAltered
  ]

}

extension Chord.Pattern.Standard: Named {

  var name: String {
    switch self {
      case .major:                                   return "maj"
      case .minor:                                   return "min"
      case .augmented:                               return "aug"
      case .diminished:                              return "dim"
      case .suspendedFourth:                         return "sus4"
      case .flatFifth:                               return "(♭5)"
      case .suspendedSecond:                         return "sus2"
      case .sixth:                                   return "6"
      case .addTwo:                                  return "(add2)"
      case .majorSeventh:                            return "maj7"
      case .majorSeventhFlatFifth:                   return "maj7♭5"
      case .majorSeventhSharpFifth:                  return "maj7♯5"
      case .seventh:                                 return "7"
      case .seventhFlatFifth:                        return "7♭5"
      case .seventhSharpFifth:                       return "7♯5"
      case .seventhSuspendedFourth:                  return "7sus4"
      case .minorAddTwo:                             return "m(add2)"
      case .minorSixth:                              return "m6"
      case .minorSeventh:                            return "m7"
      case .minorMajorSeventh:                       return "m(maj7)"
      case .minorSeventhFlatFifth:                   return "m7♭5"
      case .diminishedSeventh:                       return "dim7"
      case .diminishedMajorSeventh:                  return "dim7(maj7)"
      case .fifth:                                   return "5"
      case .sixthNinth:                              return "6╱9"
      case .majorSixthNinth:                         return "maj6╱9"
      case .majorSeventhSharpEleventh:               return "maj7♯11"
      case .majorNinth:                              return "maj9"
      case .majorNinthFlatFifth:                     return "maj9♭5"
      case .majorNinthSharpFifth:                    return "maj9♯5"
      case .majorNinthSharpEleventh:                 return "maj9♯11"
      case .majorThirteenth:                         return "maj13"
      case .majorThirteenthFlatFifth:                return "maj13♭5"
      case .majorThirteenthSharpEleventh:            return "maj13♯11"
      case .seventhFlatNinth:                        return "7♭9"
      case .seventhSharpNinth:                       return "7♯9"
      case .seventhSharpEleventh:                    return "7♯11"
      case .seventhFlatFifthFlatNinth:               return "7♭5(♭9)"
      case .seventhFlatFifthSharpNinth:              return "7♭5(♯9)"
      case .seventhSharpFifthFlatNinth:              return "7♯5(♭9)"
      case .seventhSharpFifthSharpNinth:             return "7♯5(♯9)"
      case .seventhFlatNinthSharpNinth:              return "7♭9(♯9)"
      case .seventhAddThirteenth:                    return "7(add13)"
      case .seventhFlatThirteenth:                   return "7♭13"
      case .seventhFlatNinthSharpEleventh:           return "7♭9(♯11)"
      case .seventhSharpNinthSharpEleventh:          return "7♯9(♯11)"
      case .seventhFlatNinthFlatThirteenth:          return "7♭9(♭13)"
      case .seventhSharpNinthFlatThirteenth:         return "7♯9(♭13)"
      case .seventhSharpEleventhFlatThirteenth:      return "7♯11(♭13)"
      case .seventhFlatNinthSharpNinthSharpEleventh: return "7♭9(♯9,♯11)"
      case .ninth:                                   return "9"
      case .ninthFlatFifth:                          return "9(♭5)"
      case .ninthSharpFifth:                         return "9♯5"
      case .ninthSharpEleventh:                      return "9♯11"
      case .ninthFlatThirteenth:                     return "9♭13"
      case .ninthSharpEleventhFlatThirteenth:        return "9♯11(♭13)"
      case .eleventh:                                return "11"
      case .thirteenth:                              return "13"
      case .thirteenthFlatFifth:                     return "13♭5"
      case .thirteenthFlatNinth:                     return "13♭9"
      case .thirteenthSharpNinth:                    return "13♯9"
      case .thirteenthSharpEleventh:                 return "13♯11"
      case .thirteenthSuspendedFourth:               return "13(sus4)"
      case .minorSharpFifth:                         return "m(♯5)"
      case .minorSixthNinth:                         return "m6╱9"
      case .minorSeventhAddFourth:                   return "m7(add4)"
      case .minorSeventhAddEleventh:                 return "m7(add11)"
      case .minorSeventhFlatFifthFlatNinth:          return "m7♭5(♭9)"
      case .minorNinth:                              return "m9"
      case .minorNinthMajorSeventh:                  return "m9(maj7)"
      case .minorNinthFlatFifth:                     return "m9(♭5)"
      case .minorEleventh:                           return "m11"
      case .minorThirteenth:                         return "m13"
      case .diminishedSeventhAddNinth:               return "dim7(add9)"
      case .minorEleventhFlatFifth:                  return "m11♭5"
      case .minorEleventhMajorSeventh:               return "m11(maj7)"
      case .seventhAltered:                          return "7alt"
    }
  }

}
