//
//  TempoTrack.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonDev
import SwiftUI

/// A subclass of `Track` for containing only tempo-related MIDI events.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class TempoTrack: Track
{
  @Environment(\.currentTransport) var transport: Transport

  // MARK: Stored Properties

  /// The position of the track's MIDI file chunk within all track chunks for `sequence`.
  public let index = 0

  /// Container for the track's MIDI events. The events may be intended for dispatch by the
  /// track or they may have been created solely for inclusion in a MIDI file track chunk.
  public let eventManager = EventManager()

  /// The name assigned to the track. The default value for this property is the empty
  /// string. When the value of this property is changed. `didUpdate` and `didChangeName`
  /// notifications are posted for the track.
  public let name = "Tempo"

  /// Flag indicating whether changes to `tempo` or `timeSignature` should be persisted
  /// by adding a new MIDI event to the track.
  public var isRecording: Bool = false

  /// The number of beats per minute currently set for the track. The value of this property
  /// corresponds to the most recently dispatched tempo meta event. The default value of
  /// this property is retrieved from the Controller.shared. When the track's `isRecording` flag
  /// equals `true`, changing the value of this property causes the track to add a tempo
  /// event for the new value and post a `didUpdate` notification.
  public var tempo: Double
  {
    didSet
    {
      // Check that the value has actually changed and the track is recording.
      guard tempo != oldValue, isRecording else { return }

      logi("inserting event for tempo \(tempo)")

      // Add `tempoEvent` to the track's events, which always generates a new MIDI event
      // using the track's `tempo` value.
      eventManager.add(event: .meta(tempoEvent))
    }
  }

  /// The time signature currently set for the track. The value of this property corresponds
  /// to the most recently dispatched time signature meta event. The default value of
  /// this property is retrieved from the Controller.shared. When the track's `isRecording` flag
  /// equals `true`, changing the value of this property causes the track to add a time
  /// signature event for the new value and post a `didUpdate` notification.
  public var timeSignature: TimeSignature
  {
    didSet
    {
      // Check that the value has actually changed and that the track is recording.
      guard timeSignature != oldValue, isRecording else { return }

      logi("inserting event for signature \(timeSignature)")

      // Add `timeSignatureEvent` to the track's events, which always generates a new MIDI
      // event using the track's `timeSignature` value.
      eventManager.add(event: .meta(timeSignatureEvent))
    }
  }

  // MARK: Computed Properties

  /// A new MIDI meta event initialized with the current bar-beat time and tempo data
  /// initialized with the track's current `tempo` value.
  private var tempoEvent: MetaEvent
  {
    // Get the current bar-beat time.
    let time = transport.time.barBeatTime

    // Create tempo data with the current `tempo` value.
    let data: MetaEvent.Data = .tempo(bpm: tempo)

    // Return a Meta MIDI event initialized with `time` and `data`.
    return MetaEvent(time: time, data: data)
  }

  /// A new MIDI meta event initialized with the current bar-beat time and time signature
  /// data initialized with the track's current `timeSignature` value, `36` clocks, and `8`
  /// notes.
  ///
  /// - TODO: Add what the 'clocks' and 'notes' values are to the property's description.
  private var timeSignatureEvent: MetaEvent
  {
    // Get the current bar-beat time.
    let time = transport.time.barBeatTime

    // Create time signature data with the current `timeSignature` value.
    let data: MetaEvent.Data = .timeSignature(signature: timeSignature,
                                              clocks: 36,
                                              notes: 8)

    // Return a Meta MIDI event initialized with `time` and `data`.
    return MetaEvent(time: time, data: data)
  }

  // MARK: Identifying Tempo Events

  /// Tests whether a MIDI event is suitable for inclusion among the events of an instance
  /// of `TempoTrack`. Returns `true` iff the specified MIDI event contains tempo, time
  /// signature, end-of-track, or track name data where the track name specified is a
  /// case-insenstive match for "Tempo".
  ///
  /// - Parameter trackEvent: The MIDI event to test.
  /// - Returns: `true` if `trackEvent` is containable by an instance of `TempoTrack` and
  ///            `false` otherwise.
  public static func isTempoTrackEvent(_ trackEvent: Event) -> Bool
  {
    // Get the meta event wrapped by the MIDI event.
    guard case let .meta(metaEvent) = trackEvent else { return false }

    // Consider the meta event's data.
    switch metaEvent.data
    {
      case .tempo,
           .timeSignature,
           .endOfTrack:
        // The event contains tempo, time signature, or end of track data. Return `true`.

        return true

      case let .sequenceTrackName(name)
      where name.lowercased() == "tempo":
        // The event contains track name data that is a match for 'Tempo' ignoring case.
        // Return `true`.

        return true

      default:
        // The event does not contain data relating to a tempo track. Return `false`.

        return false
    }
  }

  // MARK: Event Dispatch

  /// Handles the specified event. If `event` does not wrap a tempo or time signature event
  /// then this method does nothing. If `event` wraps a tempo event then the track's `tempo`
  /// value is updated using the data contained by `event` and an automated update of the
  /// sequencer's tempo value is performed. If `event` wraps a time signature event then
  /// the track's `timeSignature` value is updated using the data contained by `event`.
  ///
  /// - Parameter event: The MIDI event to be dispatched by the tempo track.
  public func dispatch(event: Event)
  {
    // Get the meta event wrapped by `event`.
    guard case let .meta(metaEvent) = event else { return }

    // Consider the meta event's data.
    switch metaEvent.data
    {
      case let .tempo(bpm):
        // The meta event specifies a tempo.

        // Update `tempo` with the value specified by the meta event.
        tempo = bpm

        // Set the sequencer's tempo with the `automated` flag equal to `true`.
        transport.tempo = UInt16(bpm)

      case let .timeSignature(signature, _, _):
        // The meta event specifies a time signature.

        // Update `timeSignature` with the value specified by the meta event.
        timeSignature = signature

      default:
        // The meta event is not of a dispatchable nature. Nothing to do.

        break
    }
  }

  // MARK: Initializing

  /// Initializing with an index. Overridden to add time signature and tempo events to the
  /// new track.
  ///
  /// - Parameter index: The track's index.
  public init(tempo: Double = 120, timeSignature: TimeSignature = .fourFour)
  {
    self.tempo = tempo
    self.timeSignature = timeSignature
    
    // Add a time signature event with the sequencer's current value.
    eventManager.add(event:
                      .meta(MetaEvent(time: .zero,
                                      data: .timeSignature(signature: timeSignature,
                                                                              clocks: 36,
                                                                              notes: 8))))

    // Add a tempo event with the sequencer's current value.
    eventManager.add(event: .meta(MetaEvent(time: .zero, data: .tempo(bpm: tempo))))
  }

  /// Initializing with an index and a MIDI file chunk. The MIDI events contained by
  /// `trackChunk` are filtered using `TempoTrack.isTempoTrackEvent`. The filtered events
  /// are then added to the tempo track. If the filtered events did not contain a time
  /// signature event, `timeSignatureEvent` is added to the tempo track. If the filtered
  /// events did not contain a tempo event, `tempoEvent` is added to the tempo track.
  ///
  /// - Parameters:
  ///   - index: The track's index.
  ///   - trackChunk: The `TrackChunk` containing the tempo track's MIDI events.
  public init(trackChunk: TrackChunk,
              tempo: Double = 120,
              timeSignature: TimeSignature = .fourFour)
  {
    self.tempo = tempo
    self.timeSignature = timeSignature

    // Add all suitable MIDI events from `trackChunk` to the tempo track.
    eventManager.add(events: trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    // Get tempo track's collection time-related meta events.
    let timeEvents = eventManager.timeEvents

    // Check whether the tempo track is missing a time signature event.
    if timeEvents.first(where: {
      if case .timeSignature = $0.data { return true }
      else { return false }
    }) == nil
    {
      // Add a time signature event generated from the tempo track's default value.
      eventManager.add(event: .meta(timeSignatureEvent))
    }

    // Check whether the tempo track is missing a tempo event.
    if timeEvents.first(where: {
      if case .tempo = $0.data { return true }
      else { return false }
    }) == nil
    {
      // Add a tempo event generated from the tempo track's default value.
      eventManager.add(event: .meta(tempoEvent))
    }
  }
}
