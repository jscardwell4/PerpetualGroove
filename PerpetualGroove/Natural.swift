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
  case A, B, C, D, E, F, G

  var scalar: UnicodeScalar { return rawValue.unicodeScalars.first! }

  static let allCases: [Natural] = [.A, .B, .C, .D, .E, .F, .G]

  func successor() -> Natural {
    switch self {
      case .A: return .B
      case .B: return .C
      case .C: return .D
      case .D: return .E
      case .E: return .F
      case .F: return .G
      case .G: return .A
    }
  }

  func predecessor() -> Natural {
    switch self {
      case .A: return .G
      case .B: return .A
      case .C: return .B
      case .D: return .C
      case .E: return .D
      case .F: return .E
      case .G: return .F
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
