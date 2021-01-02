//
//  MIDIEventContainerTests.swift
//  MIDIEventContainerTests
//
//  Created by Jason Cardwell on 2/20/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import XCTest
import MoonKit
import Nimble
@testable import Groove

typealias MetaEvent = MIDIEvent.MetaEvent
typealias ChannelEvent = MIDIEvent.ChannelEvent
typealias MIDINodeEvent = MIDIEvent.MIDINodeEvent

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

  static let event0: MIDIEvent = .meta(MetaEvent(time: .zero, data: .sequenceTrackName(name: "Track1")))
  static let event1: MIDIEvent = .meta(MetaEvent(time: .zero, data: .timeSignature(signature: .fourFour, clocks: 36, notes: 8)))
  static let event2: MIDIEvent = .meta(MetaEvent(time: .zero, data: .tempo(bpm: 120)))
  static let event3: MIDIEvent = .channel(try! ChannelEvent(type: .noteOn, channel: 0, data1: 60, data2: 126, time: .zero))
  static let event4: MIDIEvent = .channel(try! ChannelEvent(type: .noteOff, channel: 0, data1: 60, data2: 126, time: 2∶3.385))

  static let identifier = MIDINodeEvent.Identifier(nodeIdentifier: UUID())

  static let event5: MIDIEvent = .node(
    MIDINodeEvent(
      data: .add(
        identifier: identifier,
        trajectory: MIDINode.Trajectory(velocity: CGVector(dx: 240, dy: 111), position: CGPoint(x: 24, y: 300)),
        generator: AnyMIDIGenerator.note(NoteGenerator())
      ),
      time: 3∶3.193
    )
  )

  static let event6: MIDIEvent = .node(
    MIDINodeEvent(
      data: .remove(identifier: identifier),
      time: 12∶1.387
    )
  )

  static let event7: MIDIEvent = .meta(MetaEvent(data: .endOfTrack, time: 12∶3.289))

  static let events = [event0, event1, event2, event3, event4, event5, event6, event7]
  
  func testCreation() {

    let container1 = MIDIEventContainer()
    expect(container1).to(haveCount(0))

    let container2 = MIDIEventContainer(events: MIDIEventContainerTests.events)
    expect(container2).to(haveCount(MIDIEventContainerTests.events.count))
    expect(Array(container2)) == MIDIEventContainerTests.events

  }

  func testSubscriptByIndex() {

    let container = MIDIEventContainer(events: MIDIEventContainerTests.events)
    expect(container).to(haveCount(MIDIEventContainerTests.events.count))

    let startIndex = container.startIndex
    var result = container[startIndex]
    expect(result) == MIDIEventContainerTests.events[0]

    var index = container.index(after: startIndex)
    result = container[index]
    expect(result) == MIDIEventContainerTests.events[1]

    index = container.index(startIndex, offsetBy: 2)
    result = container[index]
    expect(result) == MIDIEventContainerTests.events[2]

    index = startIndex
    container.formIndex(&index, offsetBy: 3)
    result = container[index]
    expect(result) ==  MIDIEventContainerTests.events[3]

    container.formIndex(after: &index)
    result = container[index]
    expect(result) ==  MIDIEventContainerTests.events[4]

    index = container.index(before: container.endIndex)
    result = container[index]
    expect(result) ==  MIDIEventContainerTests.events[7]

    container.formIndex(&index, offsetBy: -2)
    result = container[index]
    expect(result) ==  MIDIEventContainerTests.events[5]

    container.formIndex(after: &index)
    result = container[index]
    expect(result) ==  MIDIEventContainerTests.events[6]

  }

  func testLazyMetaEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let metaEvents = container.metaEvents
    let expectedMetaEvents: [MetaEvent] = events.filter({
      if case .meta = $0 { return true } else { return false }
    }).map({$0.event as! MetaEvent})
    expect(metaEvents).to(haveCount(expectedMetaEvents.count))
    expect(Array(metaEvents)) == expectedMetaEvents

  }

  func testLazyChannelEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let channelEvents = container.channelEvents
    let expectedChannelEvents: [ChannelEvent] = events.filter({
      if case .channel = $0 { return true } else { return false }
    }).map({$0.event as! ChannelEvent})
    expect(channelEvents).to(haveCount(expectedChannelEvents.count))
    expect(Array(channelEvents)) == expectedChannelEvents
  }

  func testLazyNodeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let nodeEvents = container.nodeEvents
    let expectedNodeEvents: [MIDINodeEvent] = events.filter({
      if case .node = $0 { return true } else { return false }
    }).map({$0.event as! MIDINodeEvent})
    expect(nodeEvents).to(haveCount(expectedNodeEvents.count))
    expect(Array(nodeEvents)) == expectedNodeEvents
  }

  func testLazyTimeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
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
    let events = MIDIEventContainerTests.generateEvents(10)
    measure {
      var container = MIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

}
