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
  var root = Note.`default`(.c)
  var pattern = ChordPattern(.major)

  var rawValue: String { return "\(root.rawValue):\(pattern.rawValue)" }

  init?(rawValue: String) {
    let components = ":".split(rawValue)
    guard components.count == 2,
      let root = Note(rawValue: components[0]),
      let pattern = ChordPattern(rawValue: components[1]) else { return nil }

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
      if bass != .`default`(.one) { result += "/\(bass.rawValue)" }
      return result
    }

    /**
     Initialize from a string with the following syntax:
     '(' <degree> ( ',' <degree> )* ')' ( '/' <degree> )?

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^\\(([^)]+)\\)(?:/(.+))?").firstMatch(in: rawValue),
        let componentsList = match.captures[1]?.string else { return nil }

      components = ",".split(componentsList).flatMap({Degree(rawValue: $0)})
      bass = Degree(rawValue: match.captures[2]?.string ?? "") ?? .`default`(.one)
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
      self.bass = bass ?? .`default`(.one)
      self.components = components
    }

    /**
    notesWithRoot:

    - parameter root: Note

    - returns: [Note]
    */
    func notesWithRoot(_ root: Note) -> [Note] {
      var result: [Note] = []
      let natural = root.natural
      let modifier = root.modifier

      var degrees: [Degree] = [Degree.`default`(.one)] + components
      if degrees.contains(bass) {
        while degrees.first != bass { let degree = degrees.remove(at: 0); degrees.append(degree) }
      }

      for degree in degrees {
        let note: Note
        switch degree {
          case let .`default`(i):
            note = Note.`default`(natural.advanced(by: i.rawValue - 1))
          case let .modified(i, .flat):
            note = Note.`default`(natural.advanced(by: i.rawValue - 1)).flattened()
          case let .modified(i, .sharp):
            note = Note.`default`(natural.advanced(by: i.rawValue - 1)).sharpened()
          case let .modified(i, .doubleFlat):
            note = Note.`default`(natural.advanced(by: i.rawValue - 1)).flattened().flattened()
        }
        switch modifier {
          case .flat?:       result.append(note.flattened())
          case .sharp?:      result.append(note.sharpened())
          case .doubleFlat?: result.append(note.flattened().flattened())
          case nil:          result.append(note)
        }
      }

      return result
    }

  }
}

extension Chord.ChordPattern {

  /** Specifies the distance from an abstract 'root' note. These correspond to the major diatonic intervals */
  enum Interval: Int {
    case one = 1, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, thirteen
  }

}

extension Chord.ChordPattern {

  /** Identifies a note relative to an abstract 'root' note */
  enum Degree: RawRepresentable, Equatable {
    case `default` (Interval)
    case modified (Interval, PitchModifier)
    var rawValue: String {
      switch self {
        case let .`default`(interval): return String(interval.rawValue)
        case let .modified(interval, modifier): return modifier.rawValue + String(interval.rawValue)
      }
    }
    /**
    initWithRawValue:

    - parameter rawValue: String
    */
    init?(rawValue: String) {
       guard let match = (~/"^([♭♯𝄫])?(1?[0-9])").firstMatch(in: rawValue),
         let rawIntervalString = match.captures[2]?.string,
         let rawInterval = Int(rawIntervalString),
         let interval = Interval(rawValue: rawInterval) else { return nil }
       if let rawModifier = match.captures[1]?.string , !rawModifier.isEmpty {
         guard let modifier = PitchModifier(rawValue: rawModifier) else { return nil }
         self = .modified(interval, modifier)
       } else {
         self = .`default`(interval)
       }
    }
  }

}

extension Chord: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension Chord: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}
