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
enum Natural: String, BidirectionalIndexType, Comparable {
  case A, B, C, D, E, F, G

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

func ==(lhs: Natural, rhs: Natural) -> Bool { return lhs.rawValue == rhs.rawValue }
func <(lhs: Natural, rhs: Natural) -> Bool { return lhs.rawValue < rhs.rawValue }