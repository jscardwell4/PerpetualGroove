//
//  Note.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

enum PitchModifier: String { case flat = "♭", sharp = "♯", doubleFlat = "𝄫" }


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
    guard let match = (~/"^([A-G])([♭♯])?$").firstMatch(in: rawValue),
      let rawNatural = match.captures[1]?.string,
      let natural = Natural(rawValue: rawNatural) else { return nil }
    if let rawModifier = match.captures[2]?.string, let modifier = PitchModifier(rawValue: rawModifier) {
      self = .modified(natural, modifier)
    } else {
      self = .`default`(natural)
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
          case .c: return .`default`(.b)
          case .f: return .`default`(.e)
          default: return .modified(n, .flat)
        }
      case let .modified(n, .sharp): return .`default`(n)
      case let .modified(n, .flat): return .`default`(n.predecessor())
      case let .modified(n, .doubleFlat): return .modified(n.predecessor(), .flat)
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
          case .b: return .`default`(.c)
          case .e: return .`default`(.f)
          default: return .modified(n, .sharp)
        }
      case let .modified(n, .sharp): return .`default`(n.successor())
      case let .modified(n, .flat): return .`default`(n)
      case let .modified(n, .doubleFlat): return .modified(n, .flat)
    }
  }

}

extension Note: Equatable {}

func ==(lhs: Note, rhs: Note) -> Bool {
  switch (lhs, rhs) {
    case let (.`default`(n1), .`default`(n2)) where n1 == n2: return true
    case let (.modified(n1, m1), .modified(n2, m2)) where n1 == n2 && m1 == m2: return true
    case let (.`default`(n1), .modified(n2, .flat)):
      switch (n1, n2) {
        case (.e, .f), (.b, .c): return true
        default:                 return false
      }
    case let (.`default`(n1), .modified(n2, .sharp)):
      switch (n1, n2) {
        case (.f, .e), (.c, .b): return true
        default:                 return false
      }
    case let (.modified(n1, .flat), .`default`(n2)):
      switch (n1, n2) {
        case (.f, .e), (.c, .b): return true
        default:                 return false
      }
    case let (.modified(n1, .sharp), .`default`(n2)):
      switch (n1, n2) {
        case (.e, .f), (.b, .c): return true
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
    case let (.modified(n1, .flat),  .modified(n2, .flat))  where n1 < n2:  return true
    case let (.modified(n1, .sharp), .modified(n2, .sharp)) where n1 < n2:  return true
    case let (.modified(n1, .flat),  .modified(n2, .sharp)) where n1 <= n2: return true
    case let (.modified(n1, .sharp), .modified(n2, .flat))  where n1 < n2:  return true
    case let (.`default`(n1), .modified(n2, .flat)) where n1 < n2:
      switch (n1, n2) {
        case (.b, .c), (.e, .f): return false
        default:                 return true
      }
    case let (.`default`(n1), .modified(n2, .sharp)) where n1 <= n2: return true
    case let (.modified(n1, .flat), .`default`(n2))  where n1 <= n2: return true
    case let (.modified(n1, .sharp), .`default`(n2)) where n1 < n2:
      switch (n1, n2) {
        case (.b, .c), (.e, .f): return false
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
