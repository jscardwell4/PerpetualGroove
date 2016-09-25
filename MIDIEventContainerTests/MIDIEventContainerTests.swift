//
//  MIDIEventContainerTests.swift
//  MIDIEventContainerTests
//
//  Created by Jason Cardwell on 2/20/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import Groove

final class MIDIEventContainerTests: XCTestCase {

  static func eventsAdvancedBy(_ amount: Double) -> [MIDIEvent] {
    let events = self.events
    var result: [MIDIEvent] = []
    for event in events {
      var event = event
      event.time = event.time + amount
      result.append(event)
    }
    return result
  }

  static func generateEvents(_ count: Int) -> [MIDIEvent] {
    var result: [MIDIEvent] = events
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
  static let events: [MIDIEvent] = {
    var events: [MIDIEvent] = []
    events.append(.meta(MetaEvent("1:1.1₁", .sequenceTrackName(name: "Track1"))))
    events.append(.meta(MetaEvent("1:1.1₁", .timeSignature(signature: .fourFour, clocks: 36, notes: 8))))
    events.append(.meta(MetaEvent("1:1.1₁", .tempo(bpm: 120))))
    events.append(.channel(ChannelEvent(.noteOn, 0, 60, 126, "1:1.1₁")))
    events.append(.channel(ChannelEvent(.noteOff, 0, 60, 126, /*BarBeatTime.start1 + 3.4*/"2:3.385₁")))
    let identifier = MIDINodeEvent.Identifier(nodeIdentifier: MIDINode.Identifier())
    events.append(
      MIDIEvent.node(
        MIDINodeEvent(
          .add(
            identifier: identifier,
            trajectory: Trajectory(vector: CGVector(dx: 240, dy: 111), point: CGPoint(x: 24, y: 300)),
            generator: MIDIGenerator.note(NoteGenerator())
          ),
          /*BarBeatTime.start1 + 6.2*/"3:3.193₁"

        )
      )
    )
    events.append(
      MIDIEvent.node(
        MIDINodeEvent(
          .remove(identifier: identifier),
          /*BarBeatTime.start1 + 24.35*/"12:1.387₁"

        )
      )
    )
    events.append(.meta(MetaEvent(.endOfTrack, /*BarBeatTime.start1 + 25.3*/"12:3.289₁")))
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
    guard expect(metaEvents).to(haveCount(MIDIEventContainerTests.metaEventCount * 10)) else { return }
    expect(metaEvents) == repeatElement(MIDIEventContainerTests.metaEvents, count: 10).joined()
  }

  func testLazyChannelEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let channelEvents = container.channelEvents
    guard expect(channelEvents).to(haveCount(MIDIEventContainerTests.channelEventCount * 10)) else { return }
    expect(channelEvents) == repeatElement(MIDIEventContainerTests.channelEvents, count: 10).joined()
  }

  func testLazyNodeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let nodeEvents = container.nodeEvents
    guard expect(nodeEvents).to(haveCount(MIDIEventContainerTests.nodeEventCount * 10)) else { return }
    expect(nodeEvents) == repeatElement(MIDIEventContainerTests.nodeEvents, count: 10).joined()
  }

  func testLazyTimeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let timeEvents = container.timeEvents
    guard expect(timeEvents).to(haveCount(MIDIEventContainerTests.timeEventCount * 10)) else { return }
    expect(timeEvents) == repeatElement(MIDIEventContainerTests.timeEvents, count: 10).joined()
  }

  func testContainerPerformance() {
    let events = MIDIEventContainerTests.generateEvents(10)
    measure {
      var container = MIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

  func testCreationAlt() {
    let events = MIDIEventContainerTests.events
    let container = AltMIDIEventContainer(events: events)
    expect(container.startIndex) == AltMIDIEventContainer.Index(timeOffset: 0, eventOffset: 0)
    guard expect(events).to(haveCount(container.count)) else { return }
    expect(container) == events
  }

  func testLazyMetaEventsAlt() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = AltMIDIEventContainer(events: events)
    let metaEvents = container.metaEvents
    guard expect(metaEvents).to(haveCount(numericCast(MIDIEventContainerTests.metaEventCount * 10))) else { return }
    expect(metaEvents) == repeatElement(MIDIEventContainerTests.metaEvents, count: 10).joined()
  }

  func testLazyChannelEventsAlt() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = AltMIDIEventContainer(events: events)
    let channelEvents = container.channelEvents
    guard expect(channelEvents).to(haveCount(numericCast(MIDIEventContainerTests.channelEventCount * 10))) else { return }
    expect(channelEvents) == repeatElement(MIDIEventContainerTests.channelEvents, count: 10).joined()
  }

  func testLazyNodeEventsAlt() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = AltMIDIEventContainer(events: events)
    let nodeEvents = container.nodeEvents
    guard expect(nodeEvents).to(haveCount(numericCast(MIDIEventContainerTests.nodeEventCount * 10))) else { return }
    expect(nodeEvents) == repeatElement(MIDIEventContainerTests.nodeEvents, count: 10).joined()
  }

  func testLazyTimeEventsAlt() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = AltMIDIEventContainer(events: events)
    let timeEvents = container.timeEvents
    guard expect(timeEvents).to(haveCount(numericCast(MIDIEventContainerTests.timeEventCount * 10))) else { return }
    expect(timeEvents) == repeatElement(MIDIEventContainerTests.timeEvents, count: 10).joined()
  }

  func testContainerPerformanceAlt() {
    let events = MIDIEventContainerTests.generateEvents(10)
    measure {
      var container = AltMIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

}
