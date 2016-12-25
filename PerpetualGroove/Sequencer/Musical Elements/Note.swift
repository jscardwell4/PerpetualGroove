//
//  Note.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

/// Specifies an absolute pitch class value
enum Note {
  case natural (Natural)
  case accidental (Natural, PitchModifier)


  var natural: Natural {
    get { switch self { case let .natural(n), let .accidental(n, _): return n } }
    set {
      switch self {
        case .natural:
          self = .natural(newValue)
        case .accidental(_, let m):
          self = .accidental(newValue, m)
      }
    }
  }

  var modifier: PitchModifier? {
    get {
      guard case .accidental(_, let m) = self else { return nil }
      return m
    }
    set {
      switch (self, newValue) {
        case let (.natural(n), m?),
             let (.accidental(n, _), m?):
          self = .accidental(n, m)
        case let (.accidental(n, _), nil):
          self = .natural(n)
        case (.natural(_), nil):
          break
      }
    }
  }

  var flattened: Note {
    switch self {
      case let .natural(natural):
        switch natural {
          case .c: return .natural(.b)
          case .f: return .natural(.e)
          default: return .accidental(natural, .flat)
        }
      case let .accidental(natural, .sharp):      return .natural(natural)
      case let .accidental(natural, .flat):       return .natural(natural.advanced(by: -1))
      case let .accidental(natural, .doubleFlat): return .accidental(natural.advanced(by: -1), .flat)
    }
  }

  var sharpened: Note {
    switch self {
      case let .natural(natural):
        switch natural {
          case .b: return .natural(.c)
          case .e: return .natural(.f)
          default: return .accidental(natural, .sharp)
        }
      case let .accidental(natural, .sharp):      return .natural(natural.advanced(by: 1))
      case let .accidental(natural, .flat):       return .natural(natural)
      case let .accidental(natural, .doubleFlat): return .accidental(natural, .flat)
    }
  }

}

extension Note: RawRepresentable, LosslessJSONValueConvertible {

  var rawValue: String {
    var result = natural.rawValue
    if let modifier = modifier { result += modifier.rawValue }
    return result
  }

  init?(rawValue: String) {
    guard let captures = (rawValue ~=> ~/"^([A-G])([♭♯𝄫])?$"),
          let rawNatural = captures.1,
          let natural = Natural(rawValue: rawNatural) else { return nil }

    if let rawModifier = captures.2,
       let modifier = PitchModifier(rawValue: rawModifier)
    {
      self = .accidental(natural, modifier)
    } else {
      self = .natural(natural)
    }
  }

}

extension Note: Comparable {

  static func <(lhs: Note, rhs: Note) -> Bool {
    guard lhs != rhs else { return false }

    switch (lhs, rhs) {

      case let (.natural(n1),            .natural(n2))            where n1 < n2,
           let (.accidental(n1, .flat),  .accidental(n2, .flat))  where n1 < n2,
           let (.accidental(n1, .sharp), .accidental(n2, .sharp)) where n1 < n2,
           let (.accidental(n1, .flat),  .accidental(n2, .sharp)) where n1 <= n2,
           let (.accidental(n1, .sharp), .accidental(n2, .flat))  where n1 < n2,
           let (.natural(n1),            .accidental(n2, .sharp)) where n1 <= n2,
           let (.accidental(n1, .flat),  .natural(n2))            where n1 <= n2:
        return true
        
      case let (.natural(n1), .accidental(n2, .flat)) where n1 < n2:
        switch (n1, n2) {

          case (.b, .c),
               (.e, .f):
            return false

          default:
            return true
        }

      case let (.accidental(n1, .sharp), .natural(n2)) where n1 < n2:
        switch (n1, n2) {

          case (.b, .c), (.e, .f):
            return false

          default:
            return true

        }

      default:
        return false

    }

  }
  
}

extension Note: Hashable {

  static func ==(lhs: Note, rhs: Note) -> Bool {

    switch (lhs, rhs) {

    case let (.natural(n1), .natural(n2)) where n1 == n2:
      return true

    case let (.accidental(n1, m1), .accidental(n2, m2)) where n1 == n2 && m1 == m2:
      return true

    case let (.natural(n1), .accidental(n2, .flat)):

      switch (n1, n2) {

        case (.e, .f),
             (.b, .c):
          return true

        default:
          return false

      }

    case let (.natural(n1), .accidental(n2, .sharp)):

      switch (n1, n2) {

        case (.f, .e),
             (.c, .b):
          return true

        default:
          return false

      }

    case let (.accidental(n1, .flat), .natural(n2)):

      switch (n1, n2) {

        case (.f, .e),
             (.c, .b):
          return true

        default:
          return false

      }

    case let (.accidental(n1, .sharp), .natural(n2)):

      switch (n1, n2) {

        case (.e, .f),
             (.b, .c):
          return true

        default:
          return false

      }

    case let (.natural(n1), .accidental(n2, .doubleFlat)) where n1.advanced(by: 1) == n2:
      return true

    case let (.accidental(n1, .doubleFlat), .natural(n2)) where n2.advanced(by: 1) == n1:
      return true

    default:
      return false

    }

  }

  var hashValue: Int {

    switch self {

      case .accidental(.b, .sharp):
        return Note.natural(.c).hashValue

      case .accidental(.c, .flat):
        return Note.natural(.b).hashValue

      case .accidental(.e, .sharp):
        return Note.natural(.f).hashValue

      case .accidental(.f, .flat):
        return Note.natural(.e).hashValue

      default:
        return rawValue.hashValue

    }

  }

}
