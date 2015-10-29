//
//  Placement.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct Placement {
  let position: CGPoint
  let vector: CGVector
  static let zero = Placement(position: .zero, vector: .zero)
  static let null = Placement(position: .null, vector: .zero)
}

extension Placement: ByteArrayConvertible {
  var bytes: [Byte] {
    let positionString = NSStringFromCGPoint(position)
    let vectorString = NSStringFromCGVector(vector)
    let string = "{\(positionString), \(vectorString)}"
    return Array(string.utf8)
  }

  /**
  init:

  - parameter bytes: [Byte]
  */
  init(_ bytes: [Byte]) {
    let string = String(bytes)
    let float = "-?[0-9]+(?:\\.[0-9]+)?"
    let value = "\\{\(float), \(float)\\}"
    guard let match = (~/"\\{(\(value)), (\(value))\\}").firstMatch(string, anchored: true),
      positionCapture = match.captures[1],
      vectorCapture = match.captures[2] else { self = .null; return }
    guard let p = CGPoint(positionCapture.string), v = CGVector(vectorCapture.string) else { self = .null; return }
    position = p
    vector = v
  }
}

extension Placement: CustomStringConvertible {
  var description: String { return "{\(position.description(3)), \(vector.description(3))}" }
}

extension Placement: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}