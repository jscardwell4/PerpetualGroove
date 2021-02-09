//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MIDI
import MoonDev

// MARK: - Track

public protocol Track: Named, EventManaging
{
  var index: Int { get }

  /// A track chunk composed of the track's MIDI events. The track's MIDI events are
  /// assembled from `headEvents`, the events from `eventContainer` post validation, and
  /// `tailEvents`.
  var chunk: TrackChunk { get }

  /// An array containing the MIDI events that should proceed all others when representing
  /// the track in a MIDI file. The abstract `Track` implementation of this property
  /// provides an array containing a single event specifying the track's name. If `name`
  /// is equal to the empty string, the generic 'Track' is combined with the position of
  /// the track within the sequence to generate a name for the MIDI event.
  var headEvents: [Event] { get }

  /// An array containing the MIDI events that should succeed all others when representing
  /// the track in a MIDI file. The abstract `Track` implementation of this property
  /// provides an array containing a single event specifying the end of the track.
  var tailEvents: [Event] { get }

  /// Validates that `container` contains all the track's MIDI events occurring between
  /// the elements of `headEvents` and the elements of `tailEvents`. This method is
  /// invoked while generating the track chunk within the default implementation of
  /// `chunk`. The default implementation of this method does nothing.
  ///
  /// Implement this method to modify existing elements of `container` or insert new
  /// elements into `container` while generating `chunk`.
  ///
  /// - Parameter container: The collection of MIDI events to be validated/modified.
  /// - PostCondition: Combining the elements in `headEvents`, `container`, and
  ///                 `tailEvents` results in the collection of MIDI events fully
  ///                 representing the track.
  func validate(events _: inout EventContainer)
}

extension Track
{
  public var chunk: TrackChunk
  {
    // Validate the events held by `eventContainer` to allow subclasses to perform type-
    // specific checks and/or additions.
    validate(events: &eventManager.container)

    // Combine all the track's MIDI events into a single array.
    let events: [Event] = headEvents + [Event](eventManager.container) + tailEvents

    // Return a track chunk initialized with the array of MIDI events.
    return TrackChunk(events: events)
  }

  public var headEvents: [Event] { commonHeadEvents }

  public var commonHeadEvents: [Event]
  {
    // Determine the name to specify in the track name event.
    let trackName = name.isEmpty ? "Track\(index)" : name

    // Create the data for the track name MIDI event.
    let trackNameEventData: MetaEvent.Data = .sequenceTrackName(name: trackName)

    // Create the track name MIDI event.
    let trackNameEvent: Event = .meta(MetaEvent(data: trackNameEventData))

    // Return an array containing the track name event.
    return [trackNameEvent]
  }

  public var tailEvents: [Event] { commonTailEvents }

  public var commonTailEvents: [Event]
  {
    // Create the end of track meta event using `endOfTrack`.
    let endOfTrackMetaEvent = MetaEvent(data: .endOfTrack, time: eventManager.endOfTrack)

    // Create the MIDI event specifying the end of the track.
    let endOfTrackEvent: Event = .meta(endOfTrackMetaEvent)

    // Return an array containing the end of track event.
    return [endOfTrackEvent]
  }

  public func validate(events: inout EventContainer) {}

  public var description: String
  {
    """
    name: \(name)
    headEvents:
    \(headEvents)
    events:
    \(eventManager.container)
    tailEvents:
    \(tailEvents)
    """
  }
}
