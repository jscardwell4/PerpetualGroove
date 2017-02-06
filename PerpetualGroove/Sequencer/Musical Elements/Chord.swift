//
//  Chord.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/16/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// A structure for representing a harmonic set of notes. Each chord value has a root
/// note, stored in the `root` property, and a pattern which specifies which diatonic
/// major intervals are chord members, stored in the `pattern` property. For more, see
/// the wikipedia entry for [Chord](https://en.wikipedia.org/wiki/Chord_(music)).
struct Chord: RawRepresentable, Hashable, CustomStringConvertible {

  /// The root note of the chord.
  var root = Note.natural(.c)

  /// The pattern specifying which diationic major intervals are members of the chord.
  var pattern = Pattern(.major)

  /// The collection of notes of which the chord is composed.
  var notes: [Note] { return pattern.notes(withRoot: root) }

  /// Initializing with a root note and a pattern.
  /// - Parameters:
  ///   - root: The root note for the chord. The default is a natural 'C' note.
  ///   - pattern: The pattern for the chord. The default specifies a 'major' chord.
  init(root: Note = .natural(.c), pattern: Pattern = Pattern(.major)) {

    // Initialize root with the specified note.
    self.root = root

    // Initialize pattern with the specified chord pattern.
    self.pattern = pattern

  }

  /// The chord represented as a string formed by joining the raw values of `root` and 
  /// `pattern` with ':'.
  var rawValue: String { return "\(root.rawValue):\(pattern.rawValue)" }

  /// Initializing with a string containing the raw chord value.
  /// - Parameter rawValue: To be successful, `rawValue` must hold a valid raw value
  ///                       for initializing `root` followed by a colon and ending with
  ///                       a valid raw value for initializing `pattern`.
  init?(rawValue: String) {

    // Get the elements from `rawValue` as a colon-separated list.
    let components = ":".split(rawValue)

    // Check that there was exactly one colon and create `Note` and `Pattern` values 
    // from the two substrings.
    guard components.count == 2,
        let root = Note(rawValue: components[0]),
        let pattern = Pattern(rawValue: components[1])
      else
    {
      return nil
    }

    // Initialize `root` with the note value created.
    self.root = root

    // Initialize `pattern` with the pattern value created.
    self.pattern = pattern

  }

  var hashValue: Int { return root.hashValue ^ pattern.hashValue }

  /// Returns `true` iff the two chords contain equal `root` and `pattern` values.
  static func ==(lhs: Chord, rhs: Chord) -> Bool {
    return lhs.root == rhs.root && lhs.pattern == rhs.pattern
  }

  /// A space-separated list of the chord's notes.
  var description: String { return " ".join(notes.map({$0.rawValue})) }

  /// A structure for specifying how to derive the notes of a chord.
  struct Pattern: RawRepresentable, Hashable {

    /// The lowest note in the pattern. When this does not correspond to the abstract 'root' 
    /// note, the pattern represents an 'inversion'. The value of this property must also
    /// be present in `components` for it's note to be derived unless the value is equal 
    /// the assumed degree of `one`.
    let bass: Degree

    /// The collection of 'notes' of which the chord consists. These are expressed as 
    /// degrees. Each degree specifies an interval and, optionally, a pitch modifier.
    /// Degree `one` is always assumed and; therefore, is not an element of `components`.
    let components: [Degree]

    /// Initializing with a standard chord pattern.
    init(_ standard: Standard) {

      // The raw value of every case in the `Standard` enumeration is a valid raw value
      // for a pattern. Initialize with the standard pattern's raw value.
      self.init(rawValue: standard.rawValue)!

    }

    /// Initializing with pattern's degrees and, optionally, the bass degree.
    /// - Parameters:
    ///   - bass: The degree to set as the bass degree in the pattern or `nil`. When the
    ///           value of this parameter is `nil`, an unmodified degree of `one` is used.
    ///           The default value for this parameter is `nil`.
    ///   - components: An array of degrees to include in the pattern.
    init(bass: Degree? = nil, components: [Degree]) {

      // Initialize `bass` with the specified degree, falling back to `one` when `nil`.
      self.bass = bass ?? .`default`(.one)

      // Initialize `components` with the specified value.
      self.components = components

    }

    /// The pattern's index in the array of all `Standard` cases or `nil` when the pattern
    /// does not represent one of the `Standard` patterns.
    var standardIndex: Int? { return Standard(rawValue: rawValue)?.index }

    /// Returns an array of all the notes in the pattern derived with `root`.
    func notes(withRoot root: Note) -> [Note] {

      // Create an array for accumulating the dervied notes.
      var result: [Note] = []

      // Get the root's natural.
      let natural = root.natural

      // Get the root's modifier.
      let modifier = root.modifier

      // Create the list of degrees for which notes shall be derived by appending 
      // `components` to the assumed first degree.
      var degrees: [Degree] = [.`default`(.one)] + components

      // Check whether `bass` is present in the list of degrees.
      if degrees.contains(bass) {

        // Iterate through `degrees` while `bass` is not it's first element.
        while degrees.first != bass {

          // Move the first element to the end of the list.
          degrees.append(degrees.removeFirst())

        }

      }

      // Iterate the list of degrees.
      for degree in degrees {

        // Create a variable to hold the derived note.
        let note: Note

        // Get the natural value corresponding to root's natural advanced by the degree's 
        // interval, subtracting one from the raw interval value to convert for zero-based
        // arithmetic.
        let naturalʹ = natural.advanced(by: degree.interval.rawValue &- 1)

        // Consider the modifier specified by the degree.
        switch degree.modifier {

          case let modifierʹ?:
            // Initialize the derived note using `naturalʹ` and `modifierʹ`.

            note = .accidental(naturalʹ, modifierʹ)

          case nil:
            // Initialize the derived note using `naturalʹ`.

            note = .natural(naturalʹ)

        }

        // Consider the root's modifier when appending the derived note to result.
        switch modifier {

          case .flat?:
            // Account for the flattened root by appending the derived note flattened.

            result.append(note.flattened)

          case .sharp?:
            // Account for the sharpened root by appending the derived note sharpened.

            result.append(note.sharpened)

          case .doubleFlat?:
            // Account for the twice flattened root by appending the derived note flattened
            // and flattened again.

            result.append(note.flattened.flattened)

          case nil:
            // The derived note is already correct, just append it to the result.

            result.append(note)

        }

      }

      // Return the array of derived notes.
      return result

    }

    var hashValue: Int {
      return components.reduce(bass.hashValue) { $0 ^ $1.hashValue }
    }

    /// The raw string value of the pattern. The content of the string consists of a
    /// '(' followed by the raw values for the elements in `components` joined with ',', 
    /// followed by ')'. If `bass` is not equal to the assumed degree of `one`; then,
    /// '/' followed by `bass.rawValue` is appended.
    var rawValue: String {

      // Initialize the return value with raw values of each of the components joined 
      // with a comma and wrapped in parentheses.
      var result = "(\(",".join(components.map({$0.rawValue}))))"

      // Check whether `bass` need be added.
      if bass != .`default`(.one) {

        // Add a forward slash followed by the raw value for bass.
        result += "/\(bass.rawValue)"

      }

      return result

    }

    /// Initializing with a string containing the pattern's raw value.
    /// - Parameter rawValue: To be successful, `rawValue` must begin with a comma-
    ///                       separated list of raw degree values that has been wrapped
    ///                       within left and right parentheses. Optionally, the bass
    ///                       degree may be specified by following the right parenthesis
    ///                       with a forward slash which is then followed by raw bass 
    ///                       degree value.
    init?(rawValue: String) {

      // Use regular expression matching to extract the list of components.
      guard let captures = (rawValue ~=> ~/"^\\(([^)]+)\\)(?:/(.+))?"),
            let componentsList = captures.1 else { return nil }

      // Initialize `components` by mapping the list separated by a comma.
      components = ",".split(componentsList).flatMap({Degree(rawValue: $0)})

      // Initialize `bass` with captured raw degree, falling back to assumed degree of 
      // `one`.
      bass = Degree(rawValue: captures.2 ?? "") ?? .`default`(.one)

    }


    /// An enumeration for specifying a note's distance from the root in a 
    /// [diationic scale](https://en.wikipedia.org/wiki/Diatonic_scale).
    /// For more, see the wikipedia entry for 
    /// [Interval](https://en.wikipedia.org/wiki/Interval_(music)).
    enum Interval: Int {

      case one = 1, two, three, four, five, six, seven,
           eight, nine, ten, eleven, twelve, thirteen

    }

    /// An enumeration for specifying an interval and an optional pitch modifier for 
    /// altering the pitch class specified by that interval.
    enum Degree: RawRepresentable, Hashable {

      /// Represents the note located by the associated interval.
      case `default` (Interval)

      /// Represents the note located by the associated interval and modified by the
      /// associated pitch modifier.
      case modified (Interval, PitchModifier)

      /// The interval value specified by the degree.
      var interval: Interval {

        switch self {

          case .`default`(let interval),
               .modified(let interval, _):
            // Return the associated interval value.

            return interval

        }

      }

      /// The pitch modifier value specified by the degree or `nil`.
      var modifier: PitchModifier? {

        switch self {

          case .`default`:
            // The degree has no modifier, return `nil`.

            return nil

          case .modified(_, let modifier):
            // Return the associated modifier value.

            return modifier

        }

      }

      /// The degree represented as a string composed of the associated interval's raw
      /// value and, if the degree is of case `modified`, the associated pitch modifier's
      /// raw value. When the string contains a pitch modifier it appears before the 
      /// interval.
      var rawValue: String {

        switch self {

          case let .`default`(interval):
            // Return the string representation of the interval's raw value.

            return String(interval.rawValue)

          case let .modified(interval, modifier):
            // Return the pitch modifier's raw value followed by the string representation
            // of the interval's raw value.

            return modifier.rawValue + String(interval.rawValue)

        }

      }

      /// Initializing with a string representation of a degree.
      /// - Parameter rawValue: To be successful, `rawValue` must match the regular
      ///                       expression `^([♭♯𝄫])?(1?[0-9])`. The first group optionally
      ///                       matches a pitch modifier's raw value. The second group
      ///                       matches an interval's raw value; therefore, the number
      ///                       captured by the group must fall within the range 1-13.
      init?(rawValue: String) {

        // Evaluate `rawValue` against a regular expression capturing the raw modifier
        // and interval values. Convert the captured raw interval into an `Interval`.
        guard let captures = (rawValue ~=> ~/"^([♭♯𝄫])?(1?[0-9])"),
              let rawInterval = Int(captures.2 ?? ""),
              let interval = Interval(rawValue: rawInterval) else { return nil }

        // Check whether `rawValue` specifies a pitch modifier.
        if let rawModifier = captures.1, !rawModifier.isEmpty {

          // Create the pitch modifier using the raw value captured.
          guard let modifier = PitchModifier(rawValue: rawModifier) else { return nil }

          // Intialize using the interval and modifier.
          self = .modified(interval, modifier)

         }

        // Continue without a pitch modifier.
        else {

          // Initialize with the interval.
           self = .`default`(interval)

         }

      }

      var hashValue: Int {

        switch self {

          case let .`default`(interval):
            // Return the hash value of the associated interval.

            return interval.hashValue

          case let .modified(interval, modifier):
            // Return the bitwise XOR of the hash values for the associated interval and
            // pitch modifier.

            return interval.hashValue ^ modifier.hashValue

        }

      }

      /// Returns `true` iff the two values are of the same case with equal associated 
      /// values.
      static func ==(lhs: Degree, rhs: Degree) -> Bool {

        switch (lhs, rhs) {

          case let (.`default`(interval1), .`default`(interval2))
            where interval1 == interval2:
            // The two values are composed of the same interval. Return `true`.

            return true

          case let (.modified(interval1, modifer1), .modified(interval2, modifier2))
            where interval1 == interval2 && modifer1 == modifier2:
            // The two values are composed of the same interval and modifer. Return `true`.

            return true

          default:
            // The two values are not of the same case or their associated values are not
            // equal.

            return false

        }

      }

    } // Chord.Pattern.Degree

    /// An enumeration of commonly used chord patterns. The raw string values are suitable
    /// for use in `Pattern.init?(rawValue:)`.
    enum Standard: String, EnumerableType, Named {

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

      /// All standard chord patterns in unspecified order.
      static let allCases: [Standard] = [
        .major, .minor, .augmented, .diminished, .suspendedFourth, .flatFifth,
        .suspendedSecond, .sixth, .addTwo, .majorSeventh, .majorSeventhFlatFifth,
        .majorSeventhSharpFifth, .seventh, .seventhFlatFifth, .seventhSharpFifth,
        .seventhSuspendedFourth, .minorAddTwo, .minorSixth, .minorSeventh,
        .minorMajorSeventh, .minorSeventhFlatFifth, .diminishedSeventh,
        .diminishedMajorSeventh, .fifth, .sixthNinth, .majorSixthNinth,
        .majorSeventhSharpEleventh, .majorNinth, .majorNinthFlatFifth,
        .majorNinthSharpFifth, .majorNinthSharpEleventh, .majorThirteenth,
        .majorThirteenthFlatFifth, .majorThirteenthSharpEleventh, .seventhFlatNinth,
        .seventhSharpNinth, .seventhSharpEleventh, .seventhFlatFifthFlatNinth,
        .seventhFlatFifthSharpNinth, .seventhSharpFifthFlatNinth,
        .seventhSharpFifthSharpNinth, .seventhFlatNinthSharpNinth,
        .seventhAddThirteenth, .seventhFlatThirteenth, .seventhFlatNinthSharpEleventh,
        .seventhSharpNinthSharpEleventh, .seventhFlatNinthFlatThirteenth,
        .seventhSharpNinthFlatThirteenth, .seventhSharpEleventhFlatThirteenth,
        .seventhFlatNinthSharpNinthSharpEleventh, .ninth, .ninthFlatFifth,
        .ninthSharpFifth, .ninthSharpEleventh, .ninthFlatThirteenth,
        .ninthSharpEleventhFlatThirteenth, .eleventh, .thirteenth, .thirteenthFlatFifth,
        .thirteenthFlatNinth, .thirteenthSharpNinth, .thirteenthSharpEleventh,
        .thirteenthSuspendedFourth, .minorSharpFifth, .minorSixthNinth,
        .minorSeventhAddFourth, .minorSeventhAddEleventh, .minorSeventhFlatFifthFlatNinth,
        .minorNinth, .minorNinthMajorSeventh, .minorNinthFlatFifth, .minorEleventh,
        .minorThirteenth, .diminishedSeventhAddNinth, .minorEleventhFlatFifth,
        .minorEleventhMajorSeventh, .seventhAltered
      ]

      /// A string describing the standard chord pattern using western musical notation.
      /// i.e. 'maj7♭5'
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

    } // Chord.Pattern.Standard

  } // Chord.Pattern

} // Chord

extension Chord: LosslessJSONValueConvertible { }
