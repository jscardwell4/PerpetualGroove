//
//  TimeSignature.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

enum TimeSignature: ByteArrayConvertible {
  case FourFour
  case ThreeFour
  case TwoFour
  case Other (UInt8, UInt8)

  var beatUnit: UInt8 { if case .Other(_, let u) = self { return u } else { return 4 } }
  var beatsPerBar: UInt8 {
    switch self {
    case .FourFour:        return 4
    case .ThreeFour:       return 3
    case .TwoFour:         return 2
    case .Other(let b, _): return b
    }
  }

  /**
  initWithUpper:lower:

  - parameter upper: UInt8
  - parameter lower: UInt8
  */
  init(_ upper: UInt8, _ lower: UInt8) {
    switch (upper, lower) {
    case (4, 4): self = .FourFour
    case (3, 4): self = .ThreeFour
    case (2, 4): self = .TwoFour
    default: self = .Other(upper, lower)
    }
  }

  var bytes: [Byte] { return [beatUnit, Byte(log2(Double(beatsPerBar)))] }

  /**
  init:

  - parameter bytes: [Byte]
  */
  init(_ bytes: [Byte]) {
    guard bytes.count == 2 else { self.init(4, 4); return }
    self.init(bytes[0], Byte(pow(Double(bytes[1]), 2)))
  }
}
