//
//  MIDIFileTrackChunk.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct to hold a track chunk for a MIDI file where chunk = \<chunk type\> \<length\> \<track event\>+ */
struct MIDIFileTrackChunk: MIDIChunk {
  let type = Byte4("MTrk".utf8)
  var events: [MIDIEvent] = []

  /** init */
  init() {}

  /**
  init:

  - parameter e: [MIDIEvent]
  */
  init(events e: [MIDIEvent]) { events = e }

  /**
  initWithEventContainer:

  - parameter eventContainer: MIDIEventContainer
  */
  init(eventContainer: MIDIEventContainer) { events = eventContainer.events }

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:CollectionType where C.Generator.Element == Byte,
    C.Index == Int, C.SubSequence.Generator.Element == Byte,
    C.SubSequence:CollectionType, C.SubSequence.Index == Int,
    C.SubSequence.SubSequence == C.SubSequence>(bytes: C) throws
  {
    guard bytes.count > 8 else { throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes in chunk") }
    guard bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(4)].elementsEqual("MTrk".utf8) else {
      throw MIDIFileError(type: .InvalidHeader, reason: "Track chunk header must be of type 'MTrk'")
    }

    let chunkLength = Byte4(bytes[bytes.startIndex.advancedBy(4) ..< bytes.startIndex.advancedBy(8)])
    guard bytes.count == Int(chunkLength) + 8 else {
      throw MIDIFileError(type: .InvalidLength,
                          reason: "Length specified in bytes and the length of the bytes do not match")
    }

    var currentIndex = bytes.startIndex.advancedBy(8)
    var events: [MIDIEvent] = []

    while currentIndex < bytes.endIndex {
      var i = currentIndex
      while bytes[i] & 0x80 != 0 { i.increment() }
      let deltaBytes = bytes[currentIndex ... i]
      let delta = VariableLengthQuantity(bytes: deltaBytes)
      i.increment()
      currentIndex = i
      let eventStart = currentIndex
      switch bytes[currentIndex] {
        case 0xFF:
          i = currentIndex.advancedBy(1)
          let type = bytes[i]
          i.increment()
          currentIndex = i
          while bytes[i] & 0x80 != 0 { i.increment() }
          let dataLengthBytes = bytes[currentIndex ... i]
          let dataLength = VariableLengthQuantity(bytes: dataLengthBytes)
          i.advanceBy(dataLength.intValue + 1)

          let eventBytes = bytes[eventStart ..< i]
          if type == 0x07 {
            events.append(try MIDINodeEvent(delta: delta, bytes: eventBytes))
          } else {
            events.append(try MetaEvent(delta: delta, bytes: eventBytes))
          }
          currentIndex = i

        default:
          guard let type = ChannelEvent.EventType(rawValue: bytes[currentIndex] >> 4) else {
            throw MIDIFileError(type: .UnsupportedEvent, reason: "\(bytes[currentIndex] >> 4) is not a supported ChannelEvent")
          }
          i = currentIndex.advancedBy(type.byteCount)
          events.append(try ChannelEvent(delta: delta, bytes: bytes[currentIndex ..< i]))
          currentIndex = i
      }
    }

    self.events = events
  }
}

extension MIDIFileTrackChunk: CustomStringConvertible {
  var description: String { return "MTrk\n\("\n".join(events.map({$0.description.indentedBy(1, useTabs: true)})))" }
}

extension MIDIFileTrackChunk: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}
