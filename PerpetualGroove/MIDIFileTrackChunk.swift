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
struct MIDIFileTrackChunk {
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
  init(eventContainer: MIDIEventContainer) { events = Array(eventContainer) }

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:Collection>(bytes: C) throws where C.Iterator.Element == Byte,
    C.Index == Int, C.IndexDistance == Int, C.SubSequence.Iterator.Element == Byte,
    C.SubSequence:Collection, C.SubSequence.Index == Int, C.SubSequence.IndexDistance == Int,
    C.SubSequence.SubSequence == C.SubSequence
  {
    guard bytes.count > 8 else { throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes in chunk") }
    guard bytes[bytes.startIndex ..< bytes.startIndex + 4].elementsEqual("MTrk".utf8) else {
      throw MIDIFileError(type: .invalidHeader, reason: "Track chunk header must be of type 'MTrk'")
    }

    let chunkLength = Byte4(bytes[bytes.startIndex + 4 ..< bytes.startIndex + 8])
    guard bytes.count == Int(chunkLength) + 8 else {
      throw MIDIFileError(type: .invalidLength,
                          reason: "Length specified in bytes and the length of the bytes do not match")
    }

    var currentIndex = bytes.startIndex + 8
    var events: [MIDIEvent] = []

    while currentIndex < bytes.endIndex {
      var i = currentIndex
      while bytes[i] & 0x80 != 0 { i += 1 }
      let deltaBytes = bytes[currentIndex ... i]
      let delta = VariableLengthQuantity(bytes: deltaBytes)
      i += 1
      currentIndex = i
      let eventStart = currentIndex
      switch bytes[currentIndex] {
        case 0xFF:
          i = currentIndex + 1
          let type = bytes[i]
          i += 1
          currentIndex = i
          while bytes[i] & 0x80 != 0 { i += 1 }
          let dataLengthBytes = bytes[currentIndex ... i]
          let dataLength = VariableLengthQuantity(bytes: dataLengthBytes)
          i += dataLength.intValue + 1

          let eventBytes = bytes[eventStart ..< i]
          if type == 0x07 {
            events.append(.node(try MIDINodeEvent(delta: delta, bytes: eventBytes)))
          } else {
            events.append(.meta(try MetaEvent(delta: delta, bytes: eventBytes)))
          }
          currentIndex = i

        default:
          guard let type = ChannelEvent.EventType(rawValue: bytes[currentIndex] >> 4) else {
            throw MIDIFileError(type: .unsupportedEvent, reason: "\(bytes[currentIndex] >> 4) is not a supported ChannelEvent")
          }
          i = currentIndex + type.byteCount
          events.append(.channel(try ChannelEvent(delta: delta, bytes: bytes[currentIndex ..< i])))
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
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}
