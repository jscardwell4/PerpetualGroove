//
//  Loop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct Loop: SequenceType {

  var time: CABarBeatTime { return CABarBeatTime(tickValue: events.maxTime.ticks - events.minTime.ticks) }

  var repetitions: Int = 0
  var repeatDelay: UInt64 = 0
  var events: MIDIEventContainer
  var start: CABarBeatTime = .start
  let identifier: Identifier

  typealias Identifier = String

  /**
   initWithIdentifier:events:

   - parameter identifier: String = nonce()
   - parameter events: MIDIEventContainer
  */
  init(identifier: Identifier = nonce(), events: MIDIEventContainer) {
    self.identifier = identifier
    self.events = events
  }

  /**
   generate

    - returns: AnyGenerator<MIDIEvent>
  */
  func generate() -> AnyGenerator<MIDIEvent> {
    var startEventInserted = false
    var endEventInserted = false
    var iteration = 0
    var offset: UInt64 = 0
    var currentGenerator: AnyGenerator<MIDIEvent> = anyGenerator(events.generate())
    return anyGenerator {
      [
        identifier = identifier,
        startTicks = start.ticks,
        repeatCount = repetitions,
        totalTicks = time.ticks,
        delay = repeatDelay
      ]
      () -> MIDIEvent? in

      if !startEventInserted {
        startEventInserted = true
        var event = MetaEvent(.Marker(name: "start\(identifier):\(repeatCount)"))
        event.time = CABarBeatTime(tickValue: startTicks)
        return event
      } else if var event = currentGenerator.next() {
        event.time = CABarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      } else if repeatCount >= iteration++ || repeatCount < 0 {
        offset += delay + totalTicks
        currentGenerator = anyGenerator(self.events.generate())
        if var event = currentGenerator.next() {
          event.time = CABarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        } else if !endEventInserted {
          endEventInserted = true
          var event = MetaEvent(.Marker(name: "end"))
          event.time = CABarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        } else {
          return nil
        }
      } else if !endEventInserted {
        endEventInserted = true
        var event = MetaEvent(.Marker(name: "end"))
        event.time = CABarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      } else {
        return nil
      }
    }
  }

}