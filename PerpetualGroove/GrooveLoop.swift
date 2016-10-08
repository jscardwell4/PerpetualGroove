//
//  GrooveLoop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/2/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct GrooveLoop {

  var identifier: UUID
  var repetitions: Int
  var repeatDelay: UInt64
  var start: BarBeatTime
  var nodes: [GrooveNode.Identifier:GrooveNode] = [:]
  var end: BarBeatTime

  init(identifier: UUID, repetitions: Int, repeatDelay: UInt64, start: BarBeatTime, end: BarBeatTime) {
    self.identifier = identifier
    self.repetitions = repetitions
    self.repeatDelay = repeatDelay
    self.start = start
    self.end = end
  }

  init?(event: MetaEvent) {
    guard case .marker(let text) = event.data,
      let match = (~/"^start\\(([^)]+)\\):([0-9]+):([0-9]+)$").firstMatch(in: text),
          let identifierString = match.captures[1]?.string,
          let identifier = UUID(uuidString: identifierString),
          let repetitionsString = match.captures[2]?.string,
          let repetitions = Int(repetitionsString),
          let repeatDelayString = match.captures[3]?.string,
          let repeatDelay = UInt64(repeatDelayString) else { return nil }
    self.identifier = identifier
    self.repetitions = repetitions
    self.repeatDelay = repeatDelay
    start = event.time
    end = event.time
  }
  
}
