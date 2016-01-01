//
//  Duration.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

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

extension Duration: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension Duration: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

