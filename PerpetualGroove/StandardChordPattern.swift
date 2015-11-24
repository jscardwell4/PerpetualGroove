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
    case Major                                   = "(3,5)"
    case Minor                                   = "(♭3,5)"
    case Augmented                               = "(3,♯5)"
    case Diminished                              = "(♭3,♭5)"
    case SuspendedFourth                         = "(4,5)"
    case FlatFifth                               = "(3,♭5)"
    case SuspendedSecond                         = "(2,5)"
    case Sixth                                   = "(3,5,6)"
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
    case MinorSeventhFlatFifth                   = "(♭3,♭5,♭7)"
    case DiminishedSeventh                       = "(♭3,♭5,𝄫7)"
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
    case NinthSharpEleventhFlatThirteenth        = "(3,5,♭7,9,♯11,♭13)"
    case Eleventh                                = "(5,♭7,9,11)"
    case Thirteenth                              = "(3,5,♭7,9,13)"
    case ThirteenthFlatFifth                     = "(3,♭5,♭7,9,13)"
    case ThirteenthFlatNinth                     = "(3,5,♭7,♭9,13)"
    case ThirteenthSharpNinth                    = "(3,5,♭7,♯9,13)"
    case ThirteenthSharpEleventh                 = "(3,5,♭7,9,♯11,13)"
    case ThirteenthSuspendedFourth               = "(4,5,♭7,9,13)"
    case MinorSharpFifth                         = "(♭3,♯5)"
    case MinorSixthNinth                         = "(♭3,5,6,9)"
    case MinorSeventhAddFourth                   = "(♭3,4,5,♭7)"
    case MinorSeventhAddEleventh                 = "(♭3,5,♭7,11)"
    case MinorSeventhFlatFifthFlatNinth          = "(♭3,♭5,♭7,♭9)"
    case MinorNinth                              = "(♭3,5,♭7,9)"
    case MinorNinthMajorSeventh                  = "(♭3,5,7,9)"
    case MinorNinthFlatFifth                     = "(♭3,♭5,♭7,9)"
    case MinorEleventh                           = "(♭3,5,♭7,9,11)"
    case MinorThirteenth                         = "(♭3,5,♭7,9,11,13)"
    case DiminishedSeventhAddNinth               = "(♭3,♭5,𝄫7,9)"
    case MinorEleventhFlatFifth                  = "(♭3,♭5,♭7,9,11)"
    case MinorEleventhMajorSeventh               = "(♭3,5,7,9,11)"
    case SeventhAltered                          = "(3,5,♭7,♭9,♯9,♯11,♭13)"

    static let allCases: [StandardChordPattern] = [
      .Major, .Minor, .Augmented, .Diminished, .SuspendedFourth, .FlatFifth, .SuspendedSecond, .Sixth, 
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
      .ThirteenthSuspendedFourth, .MinorSharpFifth, .MinorSixthNinth, .MinorSeventhAddFourth, .MinorSeventhAddEleventh,
      .MinorSeventhFlatFifthFlatNinth, .MinorNinth, .MinorNinthMajorSeventh, .MinorNinthFlatFifth, .MinorEleventh, 
      .MinorThirteenth, .DiminishedSeventhAddNinth, .MinorEleventhFlatFifth, .MinorEleventhMajorSeventh, .SeventhAltered 
    ]    

    var name: String {
      switch self {
        case .Major:                                   return "maj"
        case .Minor:                                   return "min"
        case .Augmented:                               return "aug"
        case .Diminished:                              return "dim"
        case .SuspendedFourth:                         return "sus4"
        case .FlatFifth:                               return "(♭5)"
        case .SuspendedSecond:                         return "sus2"
        case .Sixth:                                   return "6"
        case .AddTwo:                                  return "(add2)"
        case .MajorSeventh:                            return "maj7"
        case .MajorSeventhFlatFifth:                   return "maj7♭5"
        case .MajorSeventhSharpFifth:                  return "maj7♯5"
        case .Seventh:                                 return "7"
        case .SeventhFlatFifth:                        return "7♭5"
        case .SeventhSharpFifth:                       return "7♯5"
        case .SeventhSuspendedFourth:                  return "7sus4"
        case .MinorAddTwo:                             return "m(add2)"
        case .MinorSixth:                              return "m6"
        case .MinorSeventh:                            return "m7"
        case .MinorMajorSeventh:                       return "m(maj7)"
        case .MinorSeventhFlatFifth:                   return "m7♭5"
        case .DiminishedSeventh:                       return "dim7"
        case .DiminishedMajorSeventh:                  return "dim7(maj7)"
        case .Fifth:                                   return "5"
        case .SixthNinth:                              return "6╱9"
        case .MajorSixthNinth:                         return "maj6╱9"
        case .MajorSeventhSharpEleventh:               return "maj7♯11"
        case .MajorNinth:                              return "maj9"
        case .MajorNinthFlatFifth:                     return "maj9♭5"
        case .MajorNinthSharpFifth:                    return "maj9♯5"
        case .MajorNinthSharpEleventh:                 return "maj9♯11"
        case .MajorThirteenth:                         return "maj13"
        case .MajorThirteenthFlatFifth:                return "maj13♭5"
        case .MajorThirteenthSharpEleventh:            return "maj13♯11"
        case .SeventhFlatNinth:                        return "7♭9"
        case .SeventhSharpNinth:                       return "7♯9"
        case .SeventhSharpEleventh:                    return "7♯11"
        case .SeventhFlatFifthFlatNinth:               return "7♭5(♭9)"
        case .SeventhFlatFifthSharpNinth:              return "7♭5(♯9)"
        case .SeventhSharpFifthFlatNinth:              return "7♯5(♭9)"
        case .SeventhSharpFifthSharpNinth:             return "7♯5(♯9)"
        case .SeventhFlatNinthSharpNinth:              return "7♭9(♯9)"
        case .SeventhAddThirteenth:                    return "7(add13)"
        case .SeventhFlatThirteenth:                   return "7♭13"
        case .SeventhFlatNinthSharpEleventh:           return "7♭9(♯11)"
        case .SeventhSharpNinthSharpEleventh:          return "7♯9(♯11)"
        case .SeventhFlatNinthFlatThirteenth:          return "7♭9(♭13)"
        case .SeventhSharpNinthFlatThirteenth:         return "7♯9(♭13)"
        case .SeventhSharpEleventhFlatThirteenth:      return "7♯11(♭13)"
        case .SeventhFlatNinthSharpNinthSharpEleventh: return "7♭9(♯9,♯11)"
        case .Ninth:                                   return "9"
        case .NinthFlatFifth:                          return "9(♭5)"
        case .NinthSharpFifth:                         return "9♯5"
        case .NinthSharpEleventh:                      return "9♯11"
        case .NinthFlatThirteenth:                     return "9♭13"
        case .NinthSharpEleventhFlatThirteenth:        return "9♯11(♭13)"
        case .Eleventh:                                return "11"
        case .Thirteenth:                              return "13"
        case .ThirteenthFlatFifth:                     return "13♭5"
        case .ThirteenthFlatNinth:                     return "13♭9"
        case .ThirteenthSharpNinth:                    return "13♯9"
        case .ThirteenthSharpEleventh:                 return "13♯11"
        case .ThirteenthSuspendedFourth:               return "13(sus4)"
        case .MinorSharpFifth:                         return "m(♯5)"
        case .MinorSixthNinth:                         return "m6╱9"
        case .MinorSeventhAddFourth:                   return "m7(add4)"
        case .MinorSeventhAddEleventh:                 return "m7(add11)"
        case .MinorSeventhFlatFifthFlatNinth:          return "m7♭5(♭9)"
        case .MinorNinth:                              return "m9"
        case .MinorNinthMajorSeventh:                  return "m9(maj7)"
        case .MinorNinthFlatFifth:                     return "m9(♭5)"
        case .MinorEleventh:                           return "m11"
        case .MinorThirteenth:                         return "m13"
        case .DiminishedSeventhAddNinth:               return "dim7(add9)"
        case .MinorEleventhFlatFifth:                  return "m11♭5"
        case .MinorEleventhMajorSeventh:               return "m11(maj7)"
        case .SeventhAltered:                          return "7alt"
      }
    }

    var pattern: Chord.ChordPattern { return Chord.ChordPattern(self) }

  }

}
