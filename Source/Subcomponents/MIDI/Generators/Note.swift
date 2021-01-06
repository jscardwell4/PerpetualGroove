//
//  Note.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// An enumeration for specifying an absolute pitch class value.
public enum Note: RawRepresentable, Comparable, Hashable {

  /// One of the seven natural notes.
  case natural (Natural)

  /// One of the seven natural notes raised or lowered by a pitch modifer.
  case accidental (Natural, PitchModifier)

  /// The natural value associated with the note.
  public var natural: Natural {

    get {

      switch self { case let .natural(n), let .accidental(n, _): return n }

    }

    set {

      switch self {

        case .natural:
          self = .natural(newValue)

        case .accidental(_, let m):
          self = .accidental(newValue, m)

      }

    }

  }

  /// The pitch modifier associated with the note or `nil` if the note is `natural`.
  public var modifier: PitchModifier? {

    get {

      // Get the associated pitch modifer.
      guard case .accidental(_, let modifier) = self else { return nil }

      return modifier

    }

    set {

      // Consider the note and the new pitch modifier value.
      switch (self, newValue) {

        case let (.natural(natural), modifier?),
             let (.accidental(natural, _), modifier?):
          // The note is a natural being given a modifer or the note already has a modifier
          // and it is being replaced with a new value. Either way, create a new note
          // with it's natural and the new pitch modifier.

          self = .accidental(natural, modifier)

        case let (.accidental(natural, _), nil):
          // The note has a pitch modifier that is being removed. Create a new note with
          // it's natural.

          self = .natural(natural)

        case (.natural(_), nil):
          // The note has no pitch modifier and it is not being given a new one. Nothing to
          // do.

          break

      }

    }

  }

  /// The note lowered by a half-step. The value of this property may not be normal.
  public var flattened: Note {

    switch self {

      case .natural(let natural):
        // The note has no pitch modifier. Return the natural modified with `flat`.

        return .accidental(natural, .flat)

      case .accidental(let natural, .sharp):
        // The note has been sharpened. Flatten by removing the modifier.

        return .natural(natural)

      case .accidental(let natural, .flat):
        // The note has been flattened. Flatten further with `doubleFlat`.

        return .accidental(natural, .doubleFlat)

      case .accidental(_, .doubleFlat):
        // The note has been flattened by a whole-step. Flatten the normalized form.

        return normalized.flattened

    }

  }

  /// The note raised by a half-step. The value of this property may not be normal.
  public var sharpened: Note {

    switch self {

      case .natural(let natural):
        // The note has no pitch modifier. Return the natural modified with `sharp`.

        return .accidental(natural, .sharp)

      case .accidental(_, .sharp):
        // The note has been sharpened. Sharpen the normalized form.

        return normalized.sharpened

      case .accidental(let natural, .flat):
        // The note has been flattened. Sharpen by removing the modifier.

        return .natural(natural)

      case .accidental(let natural, .doubleFlat):
        // The note has been flattened by a whole-step. Sharpen by flattening a half-step.

        return .accidental(natural, .flat)

    }

  }

  /// The note converted such that it's pitch modifier is the implicit `natural` or a
  /// `flat` and if the modifier is a `flat` then the next lower natural is a whole-step.
  /// away. The decision to use `flat` instead of `sharp` is entirely arbitrary.
  ///
  /// Applying these restrictions produces the following list for specifying one of
  /// the twelve available absolute pitch classes: A♭, A, B♭, B, C, D♭, D, E♭, E, F, G♭, G.
  public var normalized: Note {

    switch self {

      case .natural:
        // All natural notes are normal, just return `self`.

        return self

      case .accidental(.e, .sharp):
        // There is only a half-step between 'E' and 'F', return a natural 'F'.

        return .natural(.f)

      case .accidental(.b, .sharp):
        // There is only a half-step between 'B' and 'C', return a natural 'C'.

        return .natural(.c)

      case .accidental(.f, .flat):
        // There is only a half-step between 'E' and 'F', return a natural 'E'.

        return .natural(.e)

      case .accidental(.c, .flat):
        // There is only a half-step between 'B' and 'C', return a natural 'B'.

        return .natural(.b)

      case .accidental(.f, .doubleFlat):
        // There is only a half-step between 'E' and 'F', return a flattened 'E'.

        return .accidental(.e, .flat)

      case .accidental(.c, .doubleFlat):
        // There is only a half-step between 'B' and 'C', return a flattened 'B'.

        return .accidental(.b, .flat)

      case .accidental(let natural, .doubleFlat):
        // There is a whole-step between the natural and the next lower natural, return
        // the next lower natural.

        return .natural(natural.advanced(by: -1))

      case .accidental(let natural, .sharp):
        // For the purpose of normalization, adjust the natural so that it is flattened.


        return .accidental(natural.advanced(by: 1), .flat)

      case .accidental(_, .flat):
        // The note is flattened with a natural a whole-step away from the next lower
        // natural. Return `self`.

        return self

    }

  }

  /// A string composed of the raw values of the note's associated values. For `natural`
  /// cases this results in a string identical to the note's natural's raw value. For
  /// `accidental` cases this results in the note's natural's raw value followed by the
  /// note's pitch modifier's raw value.
  public var rawValue: String {

    return "\(natural.rawValue)\(modifier?.rawValue ?? "")"

  }

  /// Initializing with a string representation of a note.
  /// - Parameter rawValue: To be successful, `rawValue` must match the regular expression
  ///                       `^[A-G][[♭♯𝄫]?`.
  public init?(rawValue: String) {

    // Extract raw values for the note's natural and, possibly, the note's modifier.
    // Create the note's natural using the captured raw value.
    guard let captures = (~/"^([A-G])([♭♯𝄫])?$").firstMatch(in: rawValue),
          let rawNatural = captures[1]?.substring,
          let natural = Natural(rawValue: String(rawNatural)) else { return nil }

    // Create the note's modifier if a raw modifier has been captured.
    if let rawModifier = captures[2]?.substring,
       let modifier = PitchModifier(rawValue: String(rawModifier))
    {

      // Intialize as an accidental with the natural and modifier values.
      self = .accidental(natural, modifier)

    }

    // Otherwise, the note will have no modifier.
    else {

      // Initialize with the natural.
      self = .natural(natural)

    }

  }

  /// Returns `true` iff the absolute pitch class of `lhs` is lower than that of `rhs`.
  public static func <(lhs: Note, rhs: Note) -> Bool {

    // Consider the two normalized forms. Note that normalizing dictates that where
    // note is an accidental case it's modifier must be `flat`.
    switch (lhs.normalized, rhs.normalized) {

    case (.natural(let natural1), .natural(let natural2)),
         (.accidental(let natural1, _), .accidental(let natural2, _)),
         (.natural(let natural1), .accidental(let natural2, _)):
      // Either `lhs` and `rhs` are both naturals, both flattened, or a natural and 
      // flattened natural. In all three cases, for `lhs` to be less than `rhs` the
      // natural of `lhs` must be less than the natural of `rhs`.

      return natural1 < natural2

    case (.accidental(let natural1, _), .natural(let natural2)):
      // `lhs` is a flattened natural and `rhs` is a natural. Because `lhs` is flattened,
      // `lhs` is less than `rhs` when it's natural is less than the natural of `rhs` or
      // when it's natural is equal to the natural of `rhs`.

      return natural1 <= natural2



    }

  }

  /// Returns `true` iff the two notes describe the same absolute pitch class. This is 
  /// the case when the normalized forms of the two notes are identical.
  public static func ==(lhs: Note, rhs: Note) -> Bool {

    // Consider the normalized forms of `lhs` and `rhs`.
    switch (lhs.normalized, rhs.normalized) {

      case let (.natural(n1), .natural(n2)) where n1 == n2:
        // These values are identical natural notes.

        return true

      case let (.accidental(n1, m1), .accidental(n2, m2)) where n1 == n2 && m1 == m2:
        // These values are identical accidental notes.

        return true

      default:
        // These values represent two different absolute pitch classes.

        return false

    }

  }

}

extension Note: LosslessJSONValueConvertible {}

