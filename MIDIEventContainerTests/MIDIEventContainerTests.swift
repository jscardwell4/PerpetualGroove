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

  static func eventsAdvancedBy(_ amount: Double) -> [MIDIEvent] {
    let events = self.events
    var result: [MIDIEvent] = []
    for event in events {
      var event = event
      event.time = event.time + BarBeatTime(seconds: amount)
      result.append(event)
    }
    return result
  }

  static func generateEvents(_ count: Int) -> [MIDIEvent] {
    var result: [MIDIEvent] = events
    for i in 1 ..< max(count, 1) {
      result.append(contentsOf: eventsAdvancedBy(Double(i) * 26))
    }
    return result
  }

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
  static let events: [MIDIEvent] = {
    var events: [MIDIEvent] = []
    events.append(.meta(MIDIEvent.MetaEvent(time: .zero, data: .sequenceTrackName(name: "Track1"))))
    events.append(.meta(MIDIEvent.MetaEvent(time: .zero, data: .timeSignature(signature: .fourFour, clocks: 36, notes: 8))))
    events.append(.meta(MIDIEvent.MetaEvent(time: .zero, data: .tempo(bpm: 120))))
    events.append(.channel(MIDIEvent.ChannelEvent(type: .noteOn, channel: 0, data1: 60, data2: 126, time: .zero)))
    events.append(.channel(MIDIEvent.ChannelEvent(type: .noteOff, channel: 0, data1: 60, data2: 126, time: 2∶3.385)))
    let identifier = MIDIEvent.MIDINodeEvent.Identifier(nodeIdentifier: UUID())
    events.append(
      .node(
        MIDIEvent.MIDINodeEvent(
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
      MIDIEvent.node(
        MIDIEvent.MIDINodeEvent(
          data: .remove(identifier: identifier),
          time: 12∶1.387
        )
      )
    )
    events.append(.meta(MIDIEvent.MetaEvent(data: .endOfTrack, time: 12∶3.289)))
    return events
  }()

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
    let expectedMetaEvents: [MIDIEvent.MetaEvent] = events.filter({if case .meta = $0 { return true } else { return false }}).map({$0.event as! MIDIEvent.MetaEvent})
    guard expect(metaEvents).to(haveCount(IntMax(expectedMetaEvents.count))) else { return }
    expect(metaEvents) == expectedMetaEvents

  }

  func testLazyChannelEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let channelEvents = container.channelEvents
    let expectedChannelEvents: [MIDIEvent.ChannelEvent] = events.filter({if case .channel = $0 { return true } else { return false }}).map({$0.event as! MIDIEvent.ChannelEvent})
    guard expect(channelEvents).to(haveCount(IntMax(expectedChannelEvents.count))) else { return }
    expect(channelEvents) == expectedChannelEvents
  }

  func testLazyNodeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let nodeEvents = container.nodeEvents
    let expectedNodeEvents: [MIDIEvent.MIDINodeEvent] = events.filter({if case .node = $0 { return true } else { return false }}).map({$0.event as! MIDIEvent.MIDINodeEvent})
    guard expect(nodeEvents).to(haveCount(IntMax(expectedNodeEvents.count))) else { return }
    expect(nodeEvents) == expectedNodeEvents
  }

  func testLazyTimeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let timeEvents = container.timeEvents
    let expectedMetaEvents: [MIDIEvent.MetaEvent] = events.filter({if case .meta = $0 { return true } else { return false }}).map({$0.event as! MIDIEvent.MetaEvent})
    let expectedTimeEvents: [MIDIEvent.MetaEvent] = expectedMetaEvents.filter({switch $0.data { case .timeSignature, .tempo: return true; default: return false }})
    guard expect(timeEvents).to(haveCount(IntMax(expectedTimeEvents.count))) else { return }
    expect(timeEvents) == expectedTimeEvents
  }

  func testContainerPerformance() {
    let events = MIDIEventContainerTests.generateEvents(10)
    measure {
      var container = MIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

}
