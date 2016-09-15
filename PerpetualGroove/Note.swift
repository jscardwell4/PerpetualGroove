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
  case `default` (Natural)
  case modified (Natural, PitchModifier)


  var natural: Natural {
    get { switch self { case let .`default`(n), let .modified(n, _): return n } }
    set {
      switch self {
        case .`default`:            self = .`default`(newValue)
        case .modified(_, let m): self = .modified(newValue, m)
      }
    }
  }
  var modifier: PitchModifier? {
    get {
      guard case .modified(_, let m) = self else { return nil }
      return m
    }
    set {
      switch (self, newValue) {
        case let (.`default`(n), m?),
             let (.modified(n, _), m?):
          self = .modified(n, m)
        case let (.modified(n, _), nil):
          self = .`default`(n)
        case (.`default`(_), nil):
          break
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
      let rawNatural = match.captures[1]?.string,
      let natural = Natural(rawValue: rawNatural) else { return nil }
    if let rawModifier = match.captures[2]?.string, let modifier = PitchModifier(rawValue: rawModifier) {
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
      case let .`default`(n):
        switch n {
          case .C: return .`default`(.B)
          case .F: return .`default`(.E)
          default: return .modified(n, .Flat)
        }
      case let .modified(n, .Sharp): return .`default`(n)
      case let .modified(n, .Flat): return .`default`(n.predecessor())
      case let .modified(n, .DoubleFlat): return .modified(n.predecessor(), .Flat)
    }
  }

  /**
  sharpened

  - returns: Note
  */
  func sharpened() -> Note {
    switch self {
      case let .`default`(n):
        switch n {
          case .B: return .`default`(.C)
          case .E: return .`default`(.F)
          default: return .modified(n, .Sharp)
        }
      case let .modified(n, .Sharp): return .`default`(n.successor())
      case let .modified(n, .Flat): return .`default`(n)
      case let .modified(n, .DoubleFlat): return .modified(n, .Flat)
    }
  }

}

extension Note: Equatable {}

func ==(lhs: Note, rhs: Note) -> Bool {
  switch (lhs, rhs) {
    case let (.`default`(n1), .`default`(n2)) where n1 == n2: return true
    case let (.modified(n1, m1), .modified(n2, m2)) where n1 == n2 && m1 == m2: return true
    case let (.`default`(n1), .modified(n2, .Flat)):
      switch (n1, n2) {
        case (.E, .F), (.B, .C): return true
        default:                 return false
      }
    case let (.`default`(n1), .modified(n2, .Sharp)):
      switch (n1, n2) {
        case (.F, .E), (.C, .B): return true
        default:                 return false
      }
    case let (.modified(n1, .Flat), .`default`(n2)):
      switch (n1, n2) {
        case (.F, .E), (.C, .B): return true
        default:                 return false
      }
    case let (.modified(n1, .Sharp), .`default`(n2)):
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
    case let (.`default`(n1),          .`default`(n2))          where n1 < n2:  return true
    case let (.modified(n1, .Flat),  .modified(n2, .Flat))  where n1 < n2:  return true
    case let (.modified(n1, .Sharp), .modified(n2, .Sharp)) where n1 < n2:  return true
    case let (.modified(n1, .Flat),  .modified(n2, .Sharp)) where n1 <= n2: return true
    case let (.modified(n1, .Sharp), .modified(n2, .Flat))  where n1 < n2:  return true
    case let (.`default`(n1), .modified(n2, .Flat)) where n1 < n2:
      switch (n1, n2) {
        case (.B, .C), (.E, .F): return false
        default:                 return true
      }
    case let (.`default`(n1), .modified(n2, .Sharp)) where n1 <= n2: return true
    case let (.modified(n1, .Flat), .`default`(n2))  where n1 <= n2: return true
    case let (.modified(n1, .Sharp), .`default`(n2)) where n1 < n2:
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
