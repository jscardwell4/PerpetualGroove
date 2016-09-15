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
  case negativeOne = -1, zero, one, two, three, four, five, six, seven, eight, nine
  static let allCases: [Octave] = [
    .negativeOne, .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine
  ]
  static var minOctave: Octave { return .negativeOne }
  static var maxOctave: Octave { return .nine }
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
