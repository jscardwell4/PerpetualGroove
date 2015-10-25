//
//  MIDIFileProtocols.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

// MARK: - The chunk protocol

/** Protocol for types that can produce a valid chunk for a MIDI file */
protocol MIDIChunk : CustomStringConvertible, CustomDebugStringConvertible {
  var type: Byte4 { get }
}

// MARK: - The track event protocol

/**  Protocol for types that produce data for a track event in a track chunk */
protocol MIDIEvent: CustomStringConvertible, CustomDebugStringConvertible {
  var time: CABarBeatTime { get set }
  var delta: VariableLengthQuantity? { get set }
  var bytes: [Byte] { get }
}

extension MIDIEvent {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
  var descriptionWithDelta: String { return "\(delta?.paddedDescription ?? (" " * 6)) \(description)" }
}

// MARK: - The track type protocol

/** Protocol for types that provide a collection of `MIDIEvent` values for a chunk and can produce that chunk */
//protocol MIDITrackType: class, CustomStringConvertible, CustomDebugStringConvertible {
//  var chunk: MIDIFileTrackChunk { get }
//  var name: String { get }
//  var eventContainer: MIDIEventContainer { get set }
//  var eventMap: MIDIEventMap { get }
//  var trackEnd: CABarBeatTime { get }
////  unowned var sequence: MIDISequence { get }
//  init(trackChunk: MIDIFileTrackChunk/*, sequence s: MIDISequence*/) throws
//}

//extension MIDITrackType {
//
//  var trackNameEvent: MetaEvent? { return eventContainer.trackNameEvent }
//
//  var endOfTrackEvent: MetaEvent? { return eventContainer.endOfTrackEvent }
//
//  /** validateFirstAndLastEvents */
//  func validateFirstAndLastEvents() {
//    if var event = trackNameEvent, case let .SequenceTrackName(n) = event.data where n != name {
//      event.data = .SequenceTrackName(name: name)
//      eventContainer.trackNameEvent = event
//    } else if trackNameEvent == nil {
//      eventContainer.trackNameEvent = MetaEvent(.SequenceTrackName(name: name))
//    }
//
//    if eventContainer.count < 2 { eventContainer.endOfTrackEvent = MetaEvent(.EndOfTrack) }
//    else if eventContainer.endOfTrackEvent == nil {
//      eventContainer.endOfTrackEvent = MetaEvent(.EndOfTrack, eventContainer.last?.time)
//    } else {
//      let previousEvent = eventContainer[eventContainer.count - 2]
//      if var event = endOfTrackEvent where event.time != previousEvent.time {
//        event.time = previousEvent.time
//        eventContainer.endOfTrackEvent = event
//      }
//    }
//  }
//
//  var chunk: MIDIFileTrackChunk {
//    validateFirstAndLastEvents()
//    return MIDIFileTrackChunk(eventContainer: eventContainer)
//  }
//
//  var debugDescription: String { var result = ""; dump(self, &result); return result }
//
//}

//enum MIDITrackNotification: String, NotificationType, NotificationNameType {
//  case DidUpdateEvents
//  typealias Key = String
//}

