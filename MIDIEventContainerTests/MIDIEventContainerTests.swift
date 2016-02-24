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

  func testCreation() {
    let events = MIDIEventContainerTests.events
    let container = MIDIEventContainer(events: events)
    print(container)
    XCTAssertEqual(events.count, container.count)
  }

//  func testPerformanceExample() {
//    // This is an example of a performance test case.
//    self.measureBlock {
//      // Put the code you want to measure the time of here.
//    }
//  }

}
