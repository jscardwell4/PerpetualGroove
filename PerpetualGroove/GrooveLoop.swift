//
//  GrooveLoop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/2/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct GrooveLoop {

  typealias Identifier = Loop.Identifier

  var identifier: Identifier
  var repetitions: Int
  var repeatDelay: UInt64
  var start: CABarBeatTime
  var nodes: [GrooveNode.Identifier:GrooveNode] = [:]
  var end: CABarBeatTime?

  /**
   initWithIdentifier:repetitions:repeatDelay:start:

   - parameter identifier: Identifier
   - parameter repetitions: Int
   - parameter repeatDelay: UInt64
   - parameter start: CABarBeatTime
  */
  init(identifier: Identifier, repetitions: Int, repeatDelay: UInt64, start: CABarBeatTime) {
    self.identifier = identifier
    self.repetitions = repetitions
    self.repeatDelay = repeatDelay
    self.start = start
  }

  /**
   initWithEvent:

   - parameter event: MetaEvent
  */
  init?(event: MetaEvent) {
    guard case .Marker(let text) = event.data,
      let match = (~/"^start\\(([^)]+)\\):([0-9]+):([0-9]+)$").firstMatch(text),
          identifierString = match.captures[1]?.string,
          identifier = Identifier(identifierString),
          repetitionsString = match.captures[2]?.string,
          repetitions = Int(repetitionsString),
          repeatDelayString = match.captures[3]?.string,
          repeatDelay = UInt64(repeatDelayString) else { return nil }
    self.identifier = identifier
    self.repetitions = repetitions
    self.repeatDelay = repeatDelay
    start = event.time
  }
}
