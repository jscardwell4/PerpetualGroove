//
//  ElementalComponents.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

/// Modifiers that lower or raise a note or chord by a number of half steps.
enum PitchModifier: String { case flat = "♭", sharp = "♯", doubleFlat = "𝄫" }

/// The seven 'natural' note names in western tonal music
enum Natural: String, EnumerableType {


  case a = "A", b = "B", c = "C", d = "D", e = "E", f = "F", g = "G"

  var scalar: UnicodeScalar { return rawValue.unicodeScalars.first! }

  static let allCases: [Natural] = [.a, .b, .c, .d, .e, .f, .g]

}

extension Natural: Strideable {

  func advanced(by: Int) -> Natural {
    let value = scalar.value
    let offset = by < 0 ? 7 + by % 7 : by % 7
    let advancedValue = (value.advanced(by: offset) - 65) % 7 + 65
    let advancedScalar = UnicodeScalar(advancedValue)!
    return Natural(rawValue: String(advancedScalar))!
  }

  func distance(to: Natural) -> Int {
    return Int(to.scalar.value) - Int(scalar.value)
  }
  
}

/// The range of available octaves expressed as an integer.
enum Octave: Int, LosslessJSONValueConvertible, EnumerableType {

  case negativeOne = -1, zero, one, two, three, four, five, six, seven, eight, nine

  static let allCases: [Octave] = [
    .negativeOne, .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine
  ]

  static var minOctave: Octave { return .negativeOne }
  static var maxOctave: Octave { return .nine }

}

/// Enumeration for musical dynamics.
enum Velocity: String, EnumerableType, LosslessJSONValueConvertible, ImageAssetLiteralType {
  case 𝑝𝑝𝑝, 𝑝𝑝, 𝑝, 𝑚𝑝, 𝑚𝑓, 𝑓, 𝑓𝑓, 𝑓𝑓𝑓

  static let allCases: [Velocity] = [.𝑝𝑝𝑝, .𝑝𝑝, .𝑝, .𝑚𝑝, .𝑚𝑓, .𝑓, .𝑓𝑓, .𝑓𝑓𝑓]

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

}

extension Velocity: CustomStringConvertible {
  var description: String { return rawValue }
}

/// Enumeration for a musical note duration
enum Duration: String, EnumerableType, ImageAssetLiteralType, LosslessJSONValueConvertible {
  case doubleWhole, dottedWhole, whole, dottedHalf, half, dottedQuarter, quarter, dottedEighth,
       eighth, dottedSixteenth, sixteenth, dottedThirtySecond, thirtySecond, dottedSixtyFourth,
       sixtyFourth, dottedHundredTwentyEighth, hundredTwentyEighth, dottedTwoHundredFiftySixth,
       twoHundredFiftySixth

  var seconds: Double {
    let secondsPerBeat = 60 / Sequencer.tempo
    switch self {
      case .doubleWhole:                return secondsPerBeat * 8
      case .dottedWhole:                return secondsPerBeat * 6
      case .whole:                      return secondsPerBeat * 4
      case .dottedHalf:                 return secondsPerBeat * 3
      case .half:                       return secondsPerBeat * 2
      case .dottedQuarter:              return secondsPerBeat * 3/2
      case .quarter:                    return secondsPerBeat
      case .dottedEighth:               return secondsPerBeat * 3/4
      case .eighth:                     return secondsPerBeat * 1/2
      case .dottedSixteenth:            return secondsPerBeat * 3/8
      case .sixteenth:                  return secondsPerBeat * 1/4
      case .dottedThirtySecond:         return secondsPerBeat * 3/16
      case .thirtySecond:               return secondsPerBeat * 1/8
      case .dottedSixtyFourth:          return secondsPerBeat * 3/32
      case .sixtyFourth:                return secondsPerBeat * 1/16
      case .dottedHundredTwentyEighth:  return secondsPerBeat * 3/64
      case .hundredTwentyEighth:        return secondsPerBeat * 1/32
      case .dottedTwoHundredFiftySixth: return secondsPerBeat * 3/128
      case .twoHundredFiftySixth:       return secondsPerBeat * 1/64
    }
  }

  static let allCases: [Duration] = [
    .doubleWhole, .dottedWhole, .whole, .dottedHalf, .half, .dottedQuarter, .quarter,
    .dottedEighth, .eighth, .dottedSixteenth, .sixteenth, .dottedThirtySecond,
    .thirtySecond, .dottedSixtyFourth, .sixtyFourth, .dottedHundredTwentyEighth,
    .hundredTwentyEighth, .dottedTwoHundredFiftySixth, .twoHundredFiftySixth
  ]

}

extension Duration: CustomStringConvertible {

  var description: String {
    switch self {
      case .doubleWhole:                return "double-whole note"
      case .dottedWhole:                return "dotted whole note"
      case .whole:                      return "whole note"
      case .dottedHalf:                 return "dotted half note"
      case .half:                       return "half note"
      case .dottedQuarter:              return "dotted quarter note"
      case .quarter:                    return "quarter note"
      case .dottedEighth:               return "dotted eighth note"
      case .eighth:                     return "eighth note"
      case .dottedSixteenth:            return "dotted sixteenth note"
      case .sixteenth:                  return "sixteenth note"
      case .dottedThirtySecond:         return "dotted thirty-second note"
      case .thirtySecond:               return "thirty-second note"
      case .dottedSixtyFourth:          return "dotted sixty-fourth note"
      case .sixtyFourth:                return "sixty-fourth note"
      case .dottedHundredTwentyEighth:  return "dotted hundred twenty-eighth note"
      case .hundredTwentyEighth:        return "hundred twenty-eighth note"
      case .dottedTwoHundredFiftySixth: return "dotted two hundred-fifty-sixth note"
      case .twoHundredFiftySixth:       return "two hundred fifty-sixth note"
    }
  }  

}
