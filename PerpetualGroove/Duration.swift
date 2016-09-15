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

extension Duration: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension Duration: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

