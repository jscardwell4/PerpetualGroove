//
//  MIDIFileProtocols.swift
//  PerpetualGroove
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
}

/** Wrapper for MIDI events so they can be compared */
struct AnyMIDIEvent: Comparable {
  private(set) var event: MIDIEvent

  init(_ event: MIDIEvent) { self.event = event }
  
  var time: CABarBeatTime {
    get { return event.time }
    set { event.time = newValue }
  }
  var delta: VariableLengthQuantity? {
    get { return event.delta }
    set { event.delta = newValue }
  }
  var bytes: [Byte] { return event.bytes }

}

func ==(lhs: AnyMIDIEvent, rhs: AnyMIDIEvent) -> Bool { return lhs.bytes == rhs.bytes }
func <(lhs: AnyMIDIEvent, rhs: AnyMIDIEvent) -> Bool { return lhs.time < rhs.time }