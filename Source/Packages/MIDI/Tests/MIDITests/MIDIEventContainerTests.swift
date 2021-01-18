//
//  EventContainerTests.swift
//  EventContainerTests
//
//  Created by Jason Cardwell on 2/20/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import XCTest
import MoonDev
import Nimble
@testable import MIDI

final class EventContainerTests: XCTestCase {

  static func eventsAdvancedBy(_ amount: Double) -> [Event] {
    let events = self.events
    var result: [Event] = []
    for event in events {
      var event = event
      event.time = event.time + BarBeatTime(seconds: amount)
      result.append(event)
    }
    return result
  }

  static func generateEvents(_ count: Int) -> [Event] {
    var result: [Event] = events
    for i in 1 ..< max(count, 1) {
      result.append(contentsOf: eventsAdvancedBy(Double(i) * 26))
    }
    return result
  }

  static let event0: Event = .meta(MetaEvent(time: .zero, data: .sequenceTrackName(name: "Track1")))
  static let event1: Event = .meta(MetaEvent(time: .zero, data: .timeSignature(signature: .fourFour, clocks: 36, notes: 8)))
  static let event2: Event = .meta(MetaEvent(time: .zero, data: .tempo(bpm: 120)))
  static let event3: Event = .channel(try! ChannelEvent(kind: .noteOn, channel: 0, data1: 60, data2: 126, time: .zero))
  static let event4: Event = .channel(try! ChannelEvent(kind: .noteOff, channel: 0, data1: 60, data2: 126, time: 2∶3.385))

  static let identifier = NodeEvent.Identifier(nodeIdentifier: UUID())

//  static let event5: Event = .node(
//    NodeEvent(
//      data: .add(
//        identifier: identifier,
//        trajectory: Node.Trajectory(velocity: CGVector(dx: 240, dy: 111), position: CGPoint(x: 24, y: 300)),
//        generator: AnyGenerator.note(NoteGenerator())
//      ),
//      time: 3∶3.193
//    )
//  )

//  static let event6: Event = .node(
//    NodeEvent(
//      data: .remove(identifier: identifier),
//      time: 12∶1.387
//    )
//  )

  static let event7: Event = .meta(MetaEvent(data: .endOfTrack, time: 12∶3.289))

  static let events = [event0, event1, event2, event3, event4, /*event5, event6,*/ event7]
  
  func testCreation() {

    let container1 = EventContainer()
    expect(container1).to(haveCount(0))

    let container2 = EventContainer(events: EventContainerTests.events)
    expect(container2).to(haveCount(EventContainerTests.events.count))
    expect(Array(container2)) == EventContainerTests.events

  }

//  func testSubscriptByIndex() {
//
//    let container = EventContainer(events: EventContainerTests.events)
//    expect(container).to(haveCount(EventContainerTests.events.count))
//
//    let startIndex = container.startIndex
//    var result = container[startIndex]
//    expect(result) == EventContainerTests.events[0]
//
//    var index = container.index(after: startIndex)
//    result = container[index]
//    expect(result) == EventContainerTests.events[1]
//
//    index = container.index(startIndex, offsetBy: 2)
//    result = container[index]
//    expect(result) == EventContainerTests.events[2]
//
//    index = startIndex
//    container.formIndex(&index, offsetBy: 3)
//    result = container[index]
//    expect(result) ==  EventContainerTests.events[3]
//
//    container.formIndex(after: &index)
//    result = container[index]
//    expect(result) ==  EventContainerTests.events[4]
//
//    index = container.index(before: container.endIndex)
//    result = container[index]
//    expect(result) ==  EventContainerTests.events[7]
//
//    container.formIndex(&index, offsetBy: -2)
//    result = container[index]
//    expect(result) ==  EventContainerTests.events[5]
//
//    container.formIndex(after: &index)
//    result = container[index]
//    expect(result) ==  EventContainerTests.events[6]
//
//  }

  func testLazyMetaEvents() {
    let events = EventContainerTests.generateEvents(10)
    let container = EventContainer(events: events)
    let metaEvents = container.metaEvents
    let expectedMetaEvents: [MetaEvent] = events.filter({
      if case .meta = $0 { return true } else { return false }
    }).map({$0.event as! MetaEvent})
    expect(metaEvents).to(haveCount(expectedMetaEvents.count))
    expect(Array(metaEvents)) == expectedMetaEvents

  }

  func testLazyChannelEvents() {
    let events = EventContainerTests.generateEvents(10)
    let container = EventContainer(events: events)
    let channelEvents = container.channelEvents
    let expectedChannelEvents: [ChannelEvent] = events.filter({
      if case .channel = $0 { return true } else { return false }
    }).map({$0.event as! ChannelEvent})
    expect(channelEvents).to(haveCount(expectedChannelEvents.count))
    expect(Array(channelEvents)) == expectedChannelEvents
  }

//  func testLazyNodeEvents() {
//    let events = EventContainerTests.generateEvents(10)
//    let container = EventContainer(events: events)
//    let nodeEvents = container.nodeEvents
//    let expectedNodeEvents: [NodeEvent] = events.filter({
//      if case .node = $0 { return true } else { return false }
//    }).map({$0.event as! NodeEvent})
//    expect(nodeEvents).to(haveCount(expectedNodeEvents.count))
//    expect(Array(nodeEvents)) == expectedNodeEvents
//  }

  func testLazyTimeEvents() {
    let events = EventContainerTests.generateEvents(10)
    let container = EventContainer(events: events)
    let timeEvents = container.timeEvents
    let expectedMetaEvents: [MetaEvent] = events.filter({
      if case .meta = $0 { return true } else { return false }
    }).map({$0.event as! MetaEvent})
    let expectedTimeEvents: [MetaEvent] = expectedMetaEvents.filter({
      switch $0.data { case .timeSignature, .tempo: return true; default: return false }
    })
    expect(timeEvents).to(haveCount(expectedTimeEvents.count))
    expect(Array(timeEvents)) == expectedTimeEvents
  }

  func testContainerPerformance() {
    let events = EventContainerTests.generateEvents(10)
    measure {
      var container = EventContainer()
      for event in events { container.append(event) }
    }
  }

}
