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

  /**
  initWithUpper:lower:

  - parameter upper: UInt8
  - parameter lower: UInt8
  */
  init(_ upper: UInt8, _ lower: UInt8) {
    switch (upper, lower) {
    case (4, 4): self = .fourFour
    case (3, 4): self = .threeFour
    case (2, 4): self = .twoFour
    default: self = .other(upper, lower)
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
