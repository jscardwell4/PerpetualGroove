//
//  Note.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// Specifies an absolute pitch class value
enum Note {
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

  func flattened() -> Note {
    switch self {
      case let .`default`(natural):
        switch natural {
          case .c: return .`default`(.b)
          case .f: return .`default`(.e)
          default: return .modified(natural, .flat)
        }
      case let .modified(natural, .sharp):      return .`default`(natural)
      case let .modified(natural, .flat):       return .`default`(natural.advanced(by: -1))
      case let .modified(natural, .doubleFlat): return .modified(natural.advanced(by: -1), .flat)
    }
  }

  func sharpened() -> Note {
    switch self {
      case let .`default`(natural):
        switch natural {
          case .b: return .`default`(.c)
          case .e: return .`default`(.f)
          default: return .modified(natural, .sharp)
        }
      case let .modified(natural, .sharp):      return .`default`(natural.advanced(by: 1))
      case let .modified(natural, .flat):       return .`default`(natural)
      case let .modified(natural, .doubleFlat): return .modified(natural, .flat)
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
    guard let captures = (rawValue ~=> ~/"^([A-G])([♭♯])?$"),
          let rawNatural = captures.1,
          let natural = Natural(rawValue: rawNatural) else { return nil }

    if let rawModifier = captures.2,
       let modifier = PitchModifier(rawValue: rawModifier)
    {
      self = .modified(natural, modifier)
    } else {
      self = .`default`(natural)
    }
  }

}

extension Note: Comparable {
  static func <(lhs: Note, rhs: Note) -> Bool { return lhs.rawValue < rhs.rawValue }
}

extension Note: Hashable { var hashValue: Int { return rawValue.hashValue } }
