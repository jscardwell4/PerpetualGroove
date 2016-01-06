//
//  MIDILoop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct MIDILoop: SequenceType {

  var time: CABarBeatTime { return CABarBeatTime(tickValue: events.maxTime.ticks - events.minTime.ticks) }

  var repetitions: Int = 0
  var repeatDelay: UInt64 = 0
  var events: MIDIEventContainer
  var start: CABarBeatTime = .start
  let identifier: Identifier

  typealias Identifier = UUID

  /// 'Marker' meta event in the following format:<br>
  ///      `start(`*identifier*`):`*repetitions*`:`*repeatDelay*
  var beginLoopEvent: MetaEvent {
    return MetaEvent(.Marker(name: "start(\(identifier.stringValue)):\(repetitions):\(repeatDelay)"))
  }

  /// 'Marker' meta event in the following format:<br>
  ///      `end(`*identifier*`)`
  var endLoopEvent: MetaEvent {
    return MetaEvent(.Marker(name: "end(\(identifier.stringValue))"))
  }

  /**
   initWithIdentifier:events:

   - parameter identifier: String = nonce()
   - parameter events: MIDIEventContainer
  */
  init(identifier: Identifier = UUID(), events: MIDIEventContainer) {
    self.identifier = identifier
    self.events = events
  }

  /**
   initWithGrooveLoop:

   - parameter grooveLoop: GrooveTrack.Loop
  */
  init(grooveLoop: GrooveLoop) {
    identifier = grooveLoop.identifier
    repetitions = grooveLoop.repetitions
    repeatDelay = grooveLoop.repeatDelay
    start = grooveLoop.start
    var events: [MIDIEvent] = []
    for node in grooveLoop.nodes.values {
      events.append(node.addEvent)
      if let removeEvent = node.removeEvent { events.append(removeEvent) }
    }

    self.events = MIDIEventContainer(events: events)
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
        startTicks = start.ticks,
        repeatCount = repetitions,
        totalTicks = time.ticks,
        delay = repeatDelay,
        beginEvent = beginLoopEvent,
        endEvent = endLoopEvent
      ]
      () -> MIDIEvent? in

      if !startEventInserted {
        startEventInserted = true
        var event = beginEvent
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
          var event = endEvent
          event.time = CABarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        } else {
          return nil
        }
      } else if !endEventInserted {
        endEventInserted = true
        var event = endEvent
        event.time = CABarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      } else {
        return nil
      }
    }
  }

}