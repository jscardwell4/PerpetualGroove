//
//  Natural.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** The seven 'natural' note names in western tonal music */
enum Natural: String, Hashable, EnumerableType {
  case a = "A", b = "B", c = "C", d = "D", e = "E", f = "F", g = "G"

  var scalar: UnicodeScalar { return rawValue.unicodeScalars.first! }

  static let allCases: [Natural] = [.a, .b, .c, .d, .e, .f, .g]

  func successor() -> Natural {
    switch self {
      case .a: return .b
      case .b: return .c
      case .c: return .d
      case .d: return .e
      case .e: return .f
      case .f: return .g
      case .g: return .a
    }
  }

  func predecessor() -> Natural {
    switch self {
      case .a: return .g
      case .b: return .a
      case .c: return .b
      case .d: return .c
      case .e: return .d
      case .f: return .e
      case .g: return .f
    }
  }

}

extension Natural: Equatable {
  static func ==(lhs: Natural, rhs: Natural) -> Bool { return lhs.rawValue == rhs.rawValue }
}

extension Natural: Comparable {
  static func <(lhs: Natural, rhs: Natural) -> Bool { return lhs.rawValue < rhs.rawValue }
}

extension Natural: Strideable {
  func advanced(by: Int) -> Natural {
    let value = scalar.value
    let offset = by < 0 ? 7 + by % 7 : by % 7
    let advancedValue = (value.advanced(by: offset) - 65) % 7 + 65
    let advancedScalar = UnicodeScalar(advancedValue)!
    return Natural(rawValue: String(advancedScalar))!
  }

  func distance(to: Natural) -> Int {
    return Int(to.scalar.value) - Int(scalar.value)
  }
}
