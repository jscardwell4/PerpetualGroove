//
//  StandardChordPattern.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

extension Chord.ChordPattern {
  
  /** Commonly used chord patterns */
  enum StandardChordPattern: String, EnumerableType, Named {
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

    static let allCases: [StandardChordPattern] = [
      .major, .minor, .augmented, .diminished, .suspendedFourth, .flatFifth, .suspendedSecond, .sixth, 
      .addTwo, .majorSeventh, .majorSeventhFlatFifth, .majorSeventhSharpFifth, .seventh, .seventhFlatFifth, 
      .seventhSharpFifth, .seventhSuspendedFourth, .minorAddTwo, .minorSixth, .minorSeventh, .minorMajorSeventh, 
      .minorSeventhFlatFifth, .diminishedSeventh, .diminishedMajorSeventh, .fifth, .sixthNinth, .majorSixthNinth, 
      .majorSeventhSharpEleventh, .majorNinth, .majorNinthFlatFifth, .majorNinthSharpFifth, 
      .majorNinthSharpEleventh, .majorThirteenth, .majorThirteenthFlatFifth, .majorThirteenthSharpEleventh, 
      .seventhFlatNinth, .seventhSharpNinth, .seventhSharpEleventh, .seventhFlatFifthFlatNinth, 
      .seventhFlatFifthSharpNinth, .seventhSharpFifthFlatNinth, .seventhSharpFifthSharpNinth, 
      .seventhFlatNinthSharpNinth, .seventhAddThirteenth, .seventhFlatThirteenth, .seventhFlatNinthSharpEleventh, 
      .seventhSharpNinthSharpEleventh, .seventhFlatNinthFlatThirteenth, .seventhSharpNinthFlatThirteenth, 
      .seventhSharpEleventhFlatThirteenth, .seventhFlatNinthSharpNinthSharpEleventh, .ninth, .ninthFlatFifth, 
      .ninthSharpFifth, .ninthSharpEleventh, .ninthFlatThirteenth, .ninthSharpEleventhFlatThirteenth, .eleventh, 
      .thirteenth, .thirteenthFlatFifth, .thirteenthFlatNinth, .thirteenthSharpNinth, .thirteenthSharpEleventh, 
      .thirteenthSuspendedFourth, .minorSharpFifth, .minorSixthNinth, .minorSeventhAddFourth, .minorSeventhAddEleventh,
      .minorSeventhFlatFifthFlatNinth, .minorNinth, .minorNinthMajorSeventh, .minorNinthFlatFifth, .minorEleventh, 
      .minorThirteenth, .diminishedSeventhAddNinth, .minorEleventhFlatFifth, .minorEleventhMajorSeventh, .seventhAltered 
    ]    

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

    var pattern: Chord.ChordPattern { return Chord.ChordPattern(self) }

  }

}
