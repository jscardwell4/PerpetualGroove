//
//  MIDIEventContainerTests.swift
//  MIDIEventContainerTests
//
//  Created by Jason Cardwell on 2/20/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import XCTest
import struct MoonKit.UUID
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
      result.appendContentsOf(eventsAdvancedBy(Double(i) * 26))
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
    events.append(.Meta(MetaEvent(.start1, .SequenceTrackName(name: "Track1"))))
    events.append(.Meta(MetaEvent(.start1, .TimeSignature(signature: .FourFour, clocks: 36, notes: 8))))
    events.append(.Meta(MetaEvent(.start1, .Tempo(bpm: 120))))
    events.append(.Channel(ChannelEvent(.NoteOn, 0, 60, 126, .start1)))
    events.append(.Channel(ChannelEvent(.NoteOff, 0, 60, 126, BarBeatTime.start1.advancedBy(3.4))))
    let identifier = MIDINodeEvent.Identifier(nodeIdentifier: MIDINode.Identifier())
    events.append(
      MIDIEvent.Node(
        MIDINodeEvent(
          .Add(
            identifier: identifier,
            trajectory: Trajectory(vector: CGVector(dx: 240, dy: 111), point: CGPoint(x: 24, y: 300)),
            generator: MIDIGenerator.Note(NoteGenerator())
          ),
          BarBeatTime.start1.advancedBy(6.2)
        )
      )
    )
    events.append(
      MIDIEvent.Node(
        MIDINodeEvent(
          .Remove(identifier: identifier),
          BarBeatTime.start1.advancedBy(24.35)
        )
      )
    )
    events.append(.Meta(MetaEvent(.EndOfTrack, BarBeatTime.start1.advancedBy(25.3))))
    return events
  }()

  static let metaEventCount: Int = {
    events.reduce(0) { if case .Meta = $1 { return $0 + 1 } else { return $0 } }
  }()

  static let channelEventCount: Int = {
    events.reduce(0) { if case .Channel = $1 { return $0 + 1 } else { return $0 } }
  }()

  static let nodeEventCount: Int = {
    events.reduce(0) { if case .Node = $1 { return $0 + 1 } else { return $0 } }
  }()

  static let timeEventCount: Int = {
    events.reduce(0) {
      if case .Meta(let event) = $1 {
        switch event.data {
          case .TimeSignature, .Tempo: return $0 + 1
          default: return $0
        }
      } else { return $0 }
    }
  }()

  func testCreation() {
    let events = MIDIEventContainerTests.events
    let container = MIDIEventContainer(events: events)
    XCTAssertEqual(events.count, container.count)
  }

  func testLazyMetaEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let metaEvents = container.metaEvents
    XCTAssertEqual(metaEvents.count, MIDIEventContainerTests.metaEventCount * 10)
  }

  func testLazyChannelEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let channelEvents = container.channelEvents
    XCTAssertEqual(channelEvents.count, MIDIEventContainerTests.channelEventCount * 10)
  }

  func testLazyNodeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let nodeEvents = container.nodeEvents
    XCTAssertEqual(nodeEvents.count, MIDIEventContainerTests.nodeEventCount * 10)
  }

  func testLazyTimeEvents() {
    let events = MIDIEventContainerTests.generateEvents(10)
    let container = MIDIEventContainer(events: events)
    let timeEvents = container.timeEvents
    XCTAssertEqual(timeEvents.count, MIDIEventContainerTests.timeEventCount * 10)
  }

  func testOldContainerPerformance() {
    let events = MIDIEventContainerTests.generateEvents(10)
    measure { 
      var container = OldMIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

  func testContainerPerformance() {
    let events = MIDIEventContainerTests.generateEvents(10)
    measure {
      var container = MIDIEventContainer()
      for event in events { container.append(event) }
    }
  }

}
