//
//  Velocity.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Enumeration for musical dynamics 𝑚𝑝𝑚𝑓 */
enum Velocity: String, EnumerableType, ImageAssetLiteralType {
  case 𝑝𝑝𝑝, 𝑝𝑝, 𝑝, 𝑚𝑝, 𝑚𝑓, 𝑓, 𝑓𝑓, 𝑓𝑓𝑓

  static let allCases: [Velocity] = [.𝑝𝑝𝑝, .𝑝𝑝, .𝑝, .𝑚𝑝, .𝑚𝑓, .𝑓, .𝑓𝑓, .𝑓𝑓𝑓]

}

extension Velocity: MIDIConvertible {

  var midi: Byte {
    switch self {
      case .𝑝𝑝𝑝:	return 16
      case .𝑝𝑝:		return 33
      case .𝑝:		return 49
      case .𝑚𝑝:		return 64
      case .𝑚𝑓:		return 80
      case .𝑓:			return 96
      case .𝑓𝑓:		return 112
      case .𝑓𝑓𝑓:		return 126
    }
  }

  init(midi value: Byte) {
    switch value {
      case 0 ... 22:    self = .𝑝𝑝𝑝
      case 23 ... 40:   self = .𝑝𝑝
      case 41 ... 51:   self = .𝑝
      case 52 ... 70:   self = .𝑚𝑝
      case 71 ... 88:   self = .𝑚𝑓
      case 81 ... 102:  self = .𝑓
      case 103 ... 119: self = .𝑓𝑓
      default:          self = .𝑓𝑓𝑓
    }
  }

}

extension Velocity: CustomStringConvertible {
  var description: String { return rawValue }
}

extension Velocity: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension Velocity: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

