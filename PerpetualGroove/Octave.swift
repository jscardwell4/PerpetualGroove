//
//  Octave.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

enum Octave: Int, EnumerableType {
  case NegativeOne = -1, Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine
  static let allCases: [Octave] = [
    .NegativeOne, .Zero, .One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight, .Nine
  ]
  static var minOctave: Octave { return .NegativeOne }
  static var maxOctave: Octave { return .Nine }
}

extension Octave: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension Octave: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = Int(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

extension Octave: Comparable {}

func <(lhs: Octave, rhs: Octave) -> Bool { return lhs.rawValue < rhs.rawValue }