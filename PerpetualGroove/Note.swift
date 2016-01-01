//
//  Note.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

enum PitchModifier: String { case Flat = "♭", Sharp = "♯", DoubleFlat = "𝄫" }


/** Specifies an absolute pitch class value */
enum Note: RawRepresentable {
  case Default (Natural)
  case Modified (Natural, PitchModifier)


  var natural: Natural {
    get {
      switch self {
        case let .Default(n):     return n
        case let .Modified(n, _): return n
      }
    }
    set {
      switch self {
        case .Default:            self = .Default(newValue)
        case .Modified(_, let m): self = .Modified(newValue, m)
      }
    }
  }
  var modifier: PitchModifier? {
    get {
      switch self {
        case .Default:            return nil
        case let .Modified(_, m): return m
      }
    }
    set {
      switch (self, newValue) {
        case let (.Default(n), m?):      self = .Modified(n, m)
        case     (.Default(_), nil):     break
        case let (.Modified(n, _), m?):  self = .Modified(n, m)
        case let (.Modified(n, _), nil): self = .Default(n)
      }
    }
  }

  var rawValue: String {
    var result = natural.rawValue
    if let modifier = modifier { result += modifier.rawValue }
    return result
  }

  /**
  initWithRawValue:

  - parameter rawValue: String
  */
  init?(rawValue: String) {
    guard let match = (~/"^([A-G])([♭♯])?$").firstMatch(rawValue),
      rawNatural = match.captures[1]?.string,
      natural = Natural(rawValue: rawNatural) else { return nil }
    if let rawModifier = match.captures[2]?.string, modifier = PitchModifier(rawValue: rawModifier) {
      self = .Modified(natural, modifier)
    } else {
      self = .Default(natural)
    }
  }

  /**
  flattened

  - returns: Note
  */
  func flattened() -> Note {
    switch self {
      case let .Default(n):
        switch n {
          case .C: return .Default(.B)
          case .F: return .Default(.E)
          default: return .Modified(n, .Flat)
        }
      case let .Modified(n, .Sharp): return .Default(n)
      case let .Modified(n, .Flat): return .Default(n.predecessor())
      case let .Modified(n, .DoubleFlat): return .Modified(n.predecessor(), .Flat)
    }
  }

  /**
  sharpened

  - returns: Note
  */
  func sharpened() -> Note {
    switch self {
      case let .Default(n):
        switch n {
          case .B: return .Default(.C)
          case .E: return .Default(.F)
          default: return .Modified(n, .Sharp)
        }
      case let .Modified(n, .Sharp): return .Default(n.successor())
      case let .Modified(n, .Flat): return .Default(n)
      case let .Modified(n, .DoubleFlat): return .Modified(n, .Flat)
    }
  }

}

extension Note: Equatable {}

func ==(lhs: Note, rhs: Note) -> Bool {
  switch (lhs, rhs) {
    case let (.Default(n1), .Default(n2)) where n1 == n2: return true
    case let (.Modified(n1, m1), .Modified(n2, m2)) where n1 == n2 && m1 == m2: return true
    case let (.Default(n1), .Modified(n2, .Flat)):
      switch (n1, n2) {
        case (.E, .F), (.B, .C): return true
        default:                 return false
      }
    case let (.Default(n1), .Modified(n2, .Sharp)):
      switch (n1, n2) {
        case (.F, .E), (.C, .B): return true
        default:                 return false
      }
    case let (.Modified(n1, .Flat), .Default(n2)):
      switch (n1, n2) {
        case (.F, .E), (.C, .B): return true
        default:                 return false
      }
    case let (.Modified(n1, .Sharp), .Default(n2)):
      switch (n1, n2) {
        case (.E, .F), (.B, .C): return true
        default:                 return false
      }
    default: return false
  }
}

extension Note: Comparable {}

func <(lhs: Note, rhs: Note) -> Bool {
  guard lhs != rhs else { return false }
  switch (lhs, rhs) {
    case let (.Default(n1),          .Default(n2))          where n1 < n2:  return true
    case let (.Modified(n1, .Flat),  .Modified(n2, .Flat))  where n1 < n2:  return true
    case let (.Modified(n1, .Sharp), .Modified(n2, .Sharp)) where n1 < n2:  return true
    case let (.Modified(n1, .Flat),  .Modified(n2, .Sharp)) where n1 <= n2: return true
    case let (.Modified(n1, .Sharp), .Modified(n2, .Flat))  where n1 < n2:  return true
    case let (.Default(n1), .Modified(n2, .Flat)) where n1 < n2:
      switch (n1, n2) {
        case (.B, .C), (.E, .F): return false
        default:                 return true
      }
    case let (.Default(n1), .Modified(n2, .Sharp)) where n1 <= n2: return true
    case let (.Modified(n1, .Flat), .Default(n2))  where n1 <= n2: return true
    case let (.Modified(n1, .Sharp), .Default(n2)) where n1 < n2:
      switch (n1, n2) {
        case (.B, .C), (.E, .F): return false
        default:                 return true
      }
    default: return false
  }
}
extension Note: Hashable { var hashValue: Int { return rawValue.hashValue } }

extension Note: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension Note: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}
