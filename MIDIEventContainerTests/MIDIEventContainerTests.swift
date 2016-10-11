//
//  MIDIEventContainerTests.swift
//  MIDIEventContainerTests
//
//  Created by Jason Cardwell on 2/20/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
import MoonKit
import MoonKitTest
@testable import Groove

final class MIDIEventContainerTests: XCTestCase {

  static func eventsAdvancedBy(_ amount: Double) -> [AnyMIDIEvent] {
    let events = self.events
    var result: [AnyMIDIEvent] = []
    for event in events {
      var event = event
      event.time = event.time + BarBeatTime(seconds: amount)
      result.append(event)
    }
    return result
  }

  static func generateEvents(_ count: Int) -> [AnyMIDIEvent] {
    var result: [AnyMIDIEvent] = events
    for i in 0 ..< max(count, 1) {
      result.append(contentsOf: eventsAdvancedBy(Double(i) * 26))
    }
    return result
  }

  static let metaEvents: [MetaEvent] = events.filter({if case .meta = $0 { return true } else { return false }}).map({$0.event as! MetaEvent})
  static let channelEvents: [ChannelEvent] = events.filter({if case .channel = $0 { return true } else { return false }}).map({$0.event as! ChannelEvent})
  static let nodeEvents: [MIDINodeEvent] = events.filter({if case .node = $0 { return true } else { return false }}).map({$0.event as! MIDINodeEvent})
  static let timeEvents: [MetaEvent] = metaEvents.filter({switch $0.data { case .timeSignature, .tempo: return true; default: return false }})

  /*
   event types:
   Meta
   Meta (Time)
   Meta (Time)
   Channel
   Channel
   Node
   Node
   Meta
   */
  static let events: [AnyMIDIEvent] = {
    var events: [AnyMIDIEvent] = []
    events.append(.meta(MetaEvent(time: .zero, data: .sequenceTrackName(name: "Track1"))))
    events.append(.meta(MetaEvent(time: .zero, data: .timeSignature(signature: .fourFour, clocks: 36, notes: 8))))
    events.append(.meta(MetaEvent(time: .zero, data: .tempo(bpm: 120))))
    events.append(.channel(ChannelEvent(type: .noteOn, channel: 0, data1: 60, data2: 126, time: .zero)))
    events.append(.channel(ChannelEvent(type: .noteOff, channel: 0, data1: 60, data2: 126, time: 2∶3.385)))
    let identifier = MIDINodeEvent.Identifier(nodeIdentifier: UUID())
    events.append(
      .node(
        MIDINodeEvent(
          data: .add(
            identifier: identifier,
            trajectory: Trajectory(vector: CGVector(dx: 240, dy: 111), point: CGPoint(x: 24, y: 300)),
            generator: AnyMIDIGenerator.note(NoteGenerator())
          ),
          time: 3∶3.193

        )
      )
    )
    events.append(
      AnyMIDIEvent.node(
        MIDINodeEvent(
          data: .remove(identifier: identifier),
          time: 12∶1.387
        )
      )
    )
    events.append(.meta(MetaEvent(data: .endOfTrack, time: 12∶3.289)))
    return events
  }()

  static let metaEventCount: Int = metaEvents.count
  static let channelEventCount: Int = channelEvents.count
  static let nodeEventCount: Int = nodeEvents.count
  static let timeEventCount: Int = timeEvents.count

  func testCreation() {
    let events = MIDIEventContainerTests.events
    let container = MIDIEventContainer(events: events)
    guard expect(container).to(haveCount(events.count)) else { return }
    expect(container) == events
  }

  func testLazyMetaEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let metaEvents = container.metaEvents
    guard expect(metaEvents).to(haveCount(IntMax(MIDIEventContainerTests.metaEventCount) * 10)) else { return }
    expect(metaEvents) == repeatElement(MIDIEventContainerTests.metaEvents, count: 10).joined()
  }

  func testLazyChannelEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let channelEvents = container.channelEvents
    guard expect(channelEvents).to(haveCount(IntMax(MIDIEventContainerTests.channelEventCount) * 10)) else { return }
    expect(channelEvents) == repeatElement(MIDIEventContainerTests.channelEvents, count: 10).joined()
  }

  func testLazyNodeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let nodeEvents = container.nodeEvents
    guard expect(nodeEvents).to(haveCount(IntMax(MIDIEventContainerTests.nodeEventCount) * 10)) else { return }
    expect(nodeEvents) == repeatElement(MIDIEventContainerTests.nodeEvents, count: 10).joined()
  }

  func testLazyTimeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let timeEvents = container.timeEvents
    guard expect(timeEvents).to(haveCount(IntMax(MIDIEventContainerTests.timeEventCount) * 10)) else { return }
    expect(timeEvents) == repeatElement(MIDIEventContainerTests.timeEvents, count: 10).joined()
  }

  func testContainerPerformance() {
    let events = MIDIEventContainerTests.generateEvents(10)
    measure {
      var container = MIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

}
