//
//  Loop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class Loop: SequenceType, MIDINodeDispatch {

  var time: BarBeatTime { return min(end - start, .start1) }

  var repetitions: Int = 0
  var repeatDelay: UInt64 = 0
  var events: MIDIEventContainer
  var start: BarBeatTime = .start1
  var end: BarBeatTime = .start1

  let identifier: Identifier
  var eventQueue: dispatch_queue_t { return track.eventQueue }

  private(set) var nodeManager: MIDINodeManager!

  var nodes: OrderedSet<HashableTuple<BarBeatTime, MIDINodeRef>> = []

  unowned let track: InstrumentTrack

  var color: TrackColor { return track.color }

  var recording: Bool { return Sequencer.mode == .Loop && MIDIPlayer.currentDispatch === self }

  var nextNodeName: String { return "\(name) \(nodes.count + 1)" }

  var name: String { return "\(track.displayName) (\(identifier.stringValue))" }
  
  /**
   connectNode:

   - parameter node: MIDINode
  */
  func connectNode(node: MIDINode) throws { try track.connectNode(node) }

  /**
   disconnectNode:

   - parameter node: MIDINode
  */
  func disconnectNode(node: MIDINode) throws { try track.disconnectNode(node) }

  typealias Identifier = UUID

  /// 'Marker' meta event in the following format:<br>
  ///      `start(`*identifier*`):`*repetitions*`:`*repeatDelay*
  var beginLoopEvent: MIDIEvent {
    return .Meta(MetaEvent(.Marker(name: "start(\(identifier.stringValue)):\(repetitions):\(repeatDelay)")))
  }

  /// 'Marker' meta event in the following format:<br>
  ///      `end(`*identifier*`)`
  var endLoopEvent: MIDIEvent {
    return .Meta(MetaEvent(.Marker(name: "end(\(identifier.stringValue))")))
  }

  /**
   initWithTrack:

   - parameter track: InstrumentTrack
  */
  init(track: InstrumentTrack) {
    self.track = track
    identifier = UUID()
    events = []
  }

  /**
   initWithGrooveLoop:

   - parameter grooveLoop: GrooveTrack.Loop
  */
  init(grooveLoop: GrooveLoop, track: InstrumentTrack) {
    self.track = track
    identifier = grooveLoop.identifier
    repetitions = grooveLoop.repetitions
    repeatDelay = grooveLoop.repeatDelay
    start = grooveLoop.start
    var events: [MIDIEvent] = []
    for node in grooveLoop.nodes.values {
      events.append(.Node(node.addEvent))
      if let removeEvent = node.removeEvent { events.append(.Node(removeEvent)) }
    }

    self.events = MIDIEventContainer(events: events)
    nodeManager = MIDINodeManager(owner: self)
  }

  /**
   registrationTimesForAddedEvents:

   - parameter events: [MIDIEvent]

    - returns: [BarBeatTime]
  */
  func registrationTimesForAddedEvents<S:SequenceType where S.Generator.Element == MIDIEvent>(events: S) -> [BarBeatTime] {
    return events.filter({ if case .Node(_) = $0 { return true } else { return false } }).map({$0.time})
  }

  /**
   dispatchEvent:

   - parameter event: MIDIEvent
  */
  func dispatchEvent(event: MIDIEvent) {
    guard case .Node(let nodeEvent) = event else { return }
      switch nodeEvent.data {
        case let .Add(identifier, trajectory, generator):
          nodeManager.addNodeWithIdentifier(identifier.nodeIdentifier, trajectory: trajectory, generator: generator)
        case let .Remove(identifier):
          do { try nodeManager.removeNodeWithIdentifier(identifier.nodeIdentifier, delete: false) } catch { logError(error) }
      }
  }

  /**
   generate

    - returns: AnyGenerator<MIDIEventType>
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
        event.time = BarBeatTime(tickValue: startTicks)
        return event
      } else if var event = currentGenerator.next() {
        event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      } else if repeatCount >= iteration++ || repeatCount < 0 {
        offset += delay + totalTicks
        currentGenerator = anyGenerator(self.events.generate())
        if var event = currentGenerator.next() {
          event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        } else if !endEventInserted {
          endEventInserted = true
          var event = endEvent
          event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        } else {
          return nil
        }
      } else if !endEventInserted {
        endEventInserted = true
        var event = endEvent
        event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      } else {
        return nil
      }
    }
  }

}

extension Loop: CustomStringConvertible {
  var description: String {
    return "\n".join(
      "time: \(time)",
      "repetitions: \(repetitions)",
      "repeatDelay: \(repeatDelay)",
      "start: \(start)",
      "end: \(end)",
      "identifier: \(identifier)",
      "color: \(color)",
      "recording: \(recording)",
      "name: \(name)",
      "nodes: \(nodes)",
      "events: \(events)"
    )
  }
}
