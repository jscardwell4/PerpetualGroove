//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonKit

// MARK: - Track

/// A class for representing a MIDI track belonging to a `Sequence`.
public class Track: Named, EventDispatch, CustomStringConvertible {
  // MARK: Stored Properties

  /// The sequence to which the track belongs.
  public unowned let sequence: Sequence

  /// Dispatch queue for generating MIDI events.
  public let eventQueue: DispatchQueue

  /// Container for the track's MIDI events. The events may be intended for dispatch by the
  /// track or they may have been created solely for inclusion in a MIDI file track chunk.
  public var eventContainer = EventContainer()

  /// The name assigned to the track. The default value for this property is the empty
  /// string. When the value of this property is changed. `didUpdate` and `didChangeName`
  /// notifications are posted for the track.
  @Published public var name: String = "" {
    didSet {
      // Check that the value has actually changed.
      guard name != oldValue else { return }

      logi("'\(oldValue)' ➞ '\(name)'")

      // Post notification that the track has been updated.
      postNotification(name: .didUpdate, object: self)

      // Post notification that the track's name has been changed.
      postNotification(name: .didChangeName, object: self)
    }
  }

  // MARK: Initializing

  /// Initializing with a sequence. Initializes the new track with the specified sequence.
  /// Also creates the event queue for the new track with a label formed by appending
  /// the number of tracks in `sequence` to 'Track'.
  ///
  /// - Parameter sequence: The sequence to which the intialized track belongs.
  public init(sequence: Sequence) {
    // Initialize `sequence` using the specified sequence.
    self.sequence = sequence

    // Create the dispatch queue with a label derived from the number of tracks in the
    // sequence.
    eventQueue = DispatchQueue(label: "Track\(sequence.tracks.count)")
  }

  // MARK: Computed Properties

  /// The bar-beat time denoting the end of the track. When `eventContainer` is not empty,
  /// the value of this property is the largest time held by a contained event. When
  /// `eventContainer` is empty, the value of this property is `zero`.
  public var endOfTrack: BarBeatTime { eventContainer.maxTime ?? BarBeatTime.zero }

  /// The position of the track's MIDI file chunk within all track chunks for `sequence`.
  public var chunkIndex: Int {
    unwrapOrDie { sequence.tracks.firstIndex(where: { $0 === self }) }
  }

  /// A comprehensive description of the track.
  public var description: String {
    // Return the track's name followed by all the track's events.
    return [
      "name: \(name)",
      "headEvents:\n\(headEvents)",
      "events:\n\(eventContainer)",
      "tailEvents:\n\(tailEvents)",
    ].joined(separator: "\n")
  }

  // MARK: MIDIFile support

  /// Validates that `container` contains all the track's MIDI events occurring between
  /// the elements of `headEvents` and the elements of `tailEvents`. The default
  /// implementation of this method does nothing. Subclasses may override this method to
  /// modify existing elements of `container` or insert new elements into `container`.
  ///
  /// - Parameter container: The collection of MIDI events to be validated/modified.
  /// - PostCondition: Combining the elements in `headEvents`, `container`, and
  ///                 `tailEvents` results in the collection of MIDI events representing
  ///                 exactly the contents of the track.
  public func validate(events _: inout EventContainer) {}

  /// A track chunk composed of the track's MIDI events. The track's MIDI events are
  /// assembled from `headEvents`, the events from `eventContainer` post validation, and
  /// `tailEvents`.
  public var chunk: TrackChunk {
    // Validate the events held by `eventContainer` to allow subclasses to perform type-
    // specific checks and/or additions.
    validate(events: &eventContainer)

    // Combine all the track's MIDI events into a single array.
    let events: [Event] = headEvents + [Event](eventContainer) + tailEvents

    // Return a track chunk initialized with the array of MIDI events.
    return TrackChunk(events: events)
  }

  /// An array containing the MIDI events that should proceed all others when representing
  /// the track in a MIDI file. The abstract `Track` implementation of this property
  /// provides an array containing a single event specifying the track's name. If `name`
  /// is equal to the empty string, the generic 'Track' is combined with the position of
  /// the track within the sequence to generate a name for the MIDI event.
  public var headEvents: [Event] {
    // Determine the name to specify in the track name event.
    let trackName = name.isEmpty ? "Track\(chunkIndex)" : name

    // Create the data for the track name MIDI event.
    let trackNameEventData: MetaEvent.Data = .sequenceTrackName(name: trackName)

    // Create the track name MIDI event.
    let trackNameEvent: Event = .meta(MetaEvent(data: trackNameEventData))

    // Return an array containing the track name event.
    return [trackNameEvent]
  }

  /// An array containing the MIDI events that should succeed all others when representing
  /// the track in a MIDI file. The abstract `Track` implementation of this property
  /// provides an array containing a single event specifying the end of the track.
  public var tailEvents: [Event] {
    // Create the end of track meta event using `endOfTrack`.
    let endOfTrackMetaEvent = MetaEvent(data: .endOfTrack, time: endOfTrack)

    // Create the MIDI event specifying the end of the track.
    let endOfTrackEvent: Event = .meta(endOfTrackMetaEvent)

    // Return an array containing the end of track event.
    return [endOfTrackEvent]
  }

  // MARK: Event Dispatch

  /// Adds events to `eventContainer` and register's the event times with the clock.
  /// - Parameter events: The MIDI events to add to the sequence.
  public func add<S: Swift.Sequence>(events: S) where S.Element == Event {
    eventContainer.append(contentsOf: events)
    Controller.shared.time.register(
      callback: weakCapture(of: self, block: type(of: self).dispatchEvents),
      forTimes: registrationTimes(forAdding: events),
      identifier: UUID()
    )
  }

  /// Generates times with which to register clock callbacks according to the
  /// specified MIDI events. The default implementation returns the time that
  /// corresponds with the end of the track or an empty array if no such event
  /// may be found within `events`.
  /// - Parameter events: The MIDI events for which to generate registration times.
  /// - Returns: The registration times appropriate for `events`.
  public func registrationTimes<Source>(forAdding events: Source) -> [BarBeatTime]
    where Source: Swift.Sequence, Source.Element == Event
  {
    // Get the end of track event contained by `events` or return an empty array.
    guard let eot = events.first(where: {
      if case let .meta(event) = $0,
         event.data == .endOfTrack { return true }
      else { return false }
    })
    else {
      return []
    }

    // Return an array containing the time specified by the end of track event.
    return [eot.time]
  }

  public func dispatch(event _: Event) {}
}

// MARK: NotificationDispatching

extension Track: NotificationDispatching {
  /// An enumeration of the notification names posted by `Track`.
  public enum NotificationName: String, LosslessStringConvertible {
    /// Posted when a track's content has been modified.
    case didUpdate

    /// Posted by a track when it's name has changed.
    case didChangeName

    /// Posted by a track when the value of it's `forceMute` flag has changed.
    case forceMuteStatusDidChange

    /// Posted by a track when the value of it's `mute` flag has changed.
    case muteStatusDidChange

    /// Posted by a track when the value of it's `solo` flag has changed.
    case soloStatusDidChange

    public var description: String { rawValue }

    public init?(_ description: String) { self.init(rawValue: description) }
  }
}

public extension Notification.Name {
  static var trackDidUpdate: Notification.Name {
    Notification.Name(rawValue: Track.NotificationName.didUpdate.rawValue)
  }
  static var trackDidChangeName: Notification.Name {
    Notification.Name(rawValue: Track.NotificationName.didChangeName.rawValue)
  }
  static var trackForceMuteStatusDidChange: Notification.Name {
    Notification.Name(rawValue: Track.NotificationName.forceMuteStatusDidChange.rawValue)
  }
  static var trackMuteStatusDidChange: Notification.Name {
    Notification.Name(rawValue: Track.NotificationName.muteStatusDidChange.rawValue)
  }
  static var trackSoloStatusDidChange: Notification.Name {
    Notification.Name(rawValue: Track.NotificationName.soloStatusDidChange.rawValue)
  }
}
