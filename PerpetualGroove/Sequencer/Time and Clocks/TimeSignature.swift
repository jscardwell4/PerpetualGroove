//
//  TimeSignature.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

enum TimeSignature {
  case fourFour
  case threeFour
  case twoFour
  case other (UInt8, UInt8)

  var beatUnit: UInt8 { if case .other(_, let u) = self { return u } else { return 4 } }
  var beatsPerBar: Int {
    switch self {
    case .fourFour:        return 4
    case .threeFour:       return 3
    case .twoFour:         return 2
    case .other(let b, _): return Int(b)
    }
  }

  init(upper: UInt8, lower: UInt8) {
    switch (upper, lower) {
      case (4, 4): self = .fourFour
      case (3, 4): self = .threeFour
      case (2, 4): self = .twoFour
      default: self = .other(upper, lower)
    }
  }

}

extension TimeSignature: Hashable {

  var hashValue: Int { return beatsPerBar ^ _mixInt(Int(beatUnit)) }

  static func ==(lhs: TimeSignature, rhs: TimeSignature) -> Bool {
    switch (lhs, rhs) {
      case (.fourFour, .fourFour), (.threeFour, .threeFour), (.twoFour, .twoFour): return true
      case let (.other(x1, y1), .other(x2, y2)) where x1 == x2 && y1 == y2: return true
      default: return false
    }
  }

}

extension TimeSignature: ByteArrayConvertible {

  var bytes: [Byte] { return [beatUnit, Byte(log2(Double(beatsPerBar)))] }

  init(_ bytes: [Byte]) {
    guard bytes.count == 2 else { self.init(upper: 4, lower: 4); return }
    self.init(upper: bytes[0], lower: pow(bytes[1], 2))
  }

}
