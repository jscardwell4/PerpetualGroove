//
//  Chord.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit


struct ChordPattern: RawRepresentable {

  var rawValue: String {
    var strings: [String] = []
    for degree in notes.keys.sort({$0.rawValue < $1.rawValue}) {
      strings.append("\(notes[degree]!)\(degree)")
    }
    return "-".join(strings)
  }
  enum IntervalType: String { case None, Flat = "♭", Natural = "", Sharp = "♯" }
  enum Degree: Int {
    case Tonic, Supertonic, Mediant, Subdominant, Dominant, Submediant, LeadingNote, Octave
  }

  var notes: [Degree:IntervalType] = [:]

  init?(rawValue: String) {
    for string in "-".split(rawValue) {
      guard let match = (~/"^([♭♯]?)([1-8])").firstMatch(string),
      rawIntervalType = match.captures[1]?.string,
      intervalType = IntervalType(rawValue: rawIntervalType),
      rawDegreeString = match.captures[2]?.string,
      rawDegree = Int(rawDegreeString),
      degree = Degree(rawValue: rawDegree) else { continue }

      notes[degree] = intervalType
    }
  }

  static let Major           = ChordPattern(rawValue: "1-3-5")!
  static let Minor           = ChordPattern(rawValue: "1-♭3-5")!
  static let Diminished      = ChordPattern(rawValue: "1-♭3-♭5")!
  static let Augmented       = ChordPattern(rawValue: "1-3-♭5")!
  static let Dominate7       = ChordPattern(rawValue: "1-3-5-♭7")!
  static let Major7          = ChordPattern(rawValue: "1-3-5-7")!
  static let Minor7          = ChordPattern(rawValue: "1-♭3-5-♭7")!
  static let MinorMajor7     = ChordPattern(rawValue: "1-♭3-5-7")!
  static let Diminished7     = ChordPattern(rawValue: "1-♭3-♭5-♭7")!
  static let Augmented7      = ChordPattern(rawValue: "1-3-♭5-♭7")!
  static let Major7Sharp5    = ChordPattern(rawValue: "1-3-♯5-7")!
  static let Major6          = ChordPattern(rawValue: "1-3-5-6")!
  static let Minor6          = ChordPattern(rawValue: "1-♭3-5-6")!
  static let MajorFlat6      = ChordPattern(rawValue: "1-3-5-♭6")!
  static let MinorFlat6      = ChordPattern(rawValue: "1-♭3-5-♭6")!
  static let Diminished6     = ChordPattern(rawValue: "1-♭3-♭5-6")!
  static let DiminishedFlat6 = ChordPattern(rawValue: "1-♭3-♭5-♭6")!
  static let Augmented6      = ChordPattern(rawValue: "1-3-♭5-6")!
  static let AugmentedFlat6  = ChordPattern(rawValue: "1-3-♭5-♭6")!
  static let Sustained4      = ChordPattern(rawValue: "1-4-5")!
  static let Power           = ChordPattern(rawValue: "1-5")!
}