//
//  MIDIEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review the use of `time` and `delta` properties within the file.


/// A protocol with properties common to all types representing a MIDI event.
internal protocol _MIDIEvent: CustomStringConvertible {

  /// The event's tick offset expressed in bar-beat time.
  var time: BarBeatTime { get set }

  /// The event's tick offset.
  var delta: UInt64? { get set }

  /// The MIDI event expressed in raw bytes.
  var bytes: [UInt8] { get }

}

/// An enumeration of MIDI event types.
public enum MIDIEvent: Hashable, CustomStringConvertible {

  /// The `MIDIEvent` wraps a `MetaEvent` instance.
  case meta (MetaEvent)

  /// The `MIDIEvent` wraps a `ChannelEvent` instance.
  case channel (ChannelEvent)

  /// The `MIDIEvent` wraps a `MIDINodeEvent` instance.
  case node (MIDINodeEvent)

  /// The wrapped MIDI event upcast to `_MIDIEvent`.
  private var baseEvent: _MIDIEvent {

    // Consider the MIDI event.
    switch self {
      case .meta(let event):
        // Return the wrapped `MetaEvent`.

        return event

      case .channel(let event):
        // Return the wrapped `ChannelEvent`.

        return event

      case .node(let event):
        // Return the wrapped `MIDINodeEvent`.

        return event

    }

  }

  /// Initialize with an event.
  /// 
  /// - Parameter baseEvent: The MIDI event to wrap.
  private init(_ baseEvent: _MIDIEvent) {

    // Consider the event to wrap.
    switch baseEvent {

      case let event as MetaEvent:
        // Wrap the `MetaEvent`.

        self = .meta(event)

      case let event as ChannelEvent:
        // Wrap the `ChannelEvent`.

        self = .channel(event)

      case let event as MIDINodeEvent:
        // Wrap the `MIDINodeEvent`.

        self = .node(event)

      default:
        // This case is unreachable because one of the previous cases must match. This
        // can be known because `_MIDIEvent` is a private protocol, meaning declarations
        // of conformance appear within this file.

        fatalError("\(#fileID) \(#function) Failed to downcast event.")

    }

  }

  /// The base midi event exposed as `Any`.
  public var event: Any { return baseEvent }

  /// The wrapped MIDI event's tick offset expressed in bar-beat time.
  public var time: BarBeatTime {

    get {

      // Return the bar-beat time of the wrapped MIDI event.
      baseEvent.time

    }

    set {

      // Create a mutable copy of the wrapped MIDI event.
      var event = baseEvent

      // Update the MIDI event's bar-beat time.
      event.time = newValue

      // Replace `self` with a `MIDIEvent` wrapping the updated MIDI event.
      self = MIDIEvent(event)

    }

  }

  /// The wrapped MIDI event's tick offset.
  public var delta: UInt64? {

    get {

      // Return the wrapped MIDI event's delta value.
      baseEvent.delta

    }

    set {

      // Create a mutable copy of the wrapped MIDI event.
      var event = baseEvent

      // Update the MIDI event's delta value.
      event.delta = newValue

      // Replace `self` with a `MIDIEvent` wrapping the updated MIDI event.
      self = MIDIEvent(event)

    }

  }

  /// The base event encoded as an array of `UInt8` values.
  public var bytes: [UInt8] { return baseEvent.bytes }

  /// Returns `true` iff the two values are of the same enumeration case and the two MIDI
  /// event values they wrap are equal.
  ///
  /// - Parameters:
  ///   - lhs: One of the two `MIDIEvent` values to compare for equality.
  ///   - rhs: The other of the two `MIDIEvent` values to compare for equality.
  /// - Returns: `true` if the two values are equal and `false` otherwise.
  public static func ==(lhs: MIDIEvent, rhs: MIDIEvent) -> Bool {

    // Consider the two values.
    switch (lhs, rhs) {

      case let (.meta(event1), .meta(event2))
        where event1 == event2:
        // `lhs` and `rhs` wrap equal `MetaEvent` values. Return `true`.

        return true

      case let (.channel(event1), .channel(event2))
        where event1 == event2:
        // `lhs` and `rhs` wrap equal `ChannelEvent` values. Return `true`.

        return true

      case let (.node(event1), .node(event2))
        where event1 == event2:
        // `lhs` and `rhs` wrap equal `MIDINodeEvent` values. Return `true`.

        return true

      default:
        // `lhs` and `rhs` wrap unequal MIDI event values. Return `false`.

        return false

    }

  }

  public func hash(into hasher: inout Hasher) {
    bytes.hash(into: &hasher)
    delta?.hash(into: &hasher)
    time.hash(into: &hasher)
  }

  public var description: String { baseEvent.description }

}

