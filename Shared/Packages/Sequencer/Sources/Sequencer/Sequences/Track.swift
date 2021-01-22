//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonDev

#if canImport(UIKit)
import class UIKit.UIColor
#endif

import struct SwiftUI.Color

// MARK: - Track

/// A class for representing a MIDI track belonging to a `Sequence`.
@available(iOS 14.0, *)
public class Track: Named, EventDispatch, CustomStringConvertible
{
  // MARK: Stored Properties

  /// Dispatch queue for generating MIDI events.
  public let eventQueue: DispatchQueue

  /// Container for the track's MIDI events. The events may be intended for dispatch by the
  /// track or they may have been created solely for inclusion in a MIDI file track chunk.
  public var eventContainer = EventContainer()

  /// The name assigned to the track. The default value for this property is the empty
  /// string. When the value of this property is changed. `didUpdate` and `didChangeName`
  /// notifications are posted for the track.
  @Published public var name: String = ""
  {
    didSet
    {
      // Check that the value has actually changed.
      guard name != oldValue else { return }

      logi("'\(oldValue)' ➞ '\(name)'")

      // Post notification that the track has been updated.
      postNotification(name: .trackDidUpdate, object: self)

      // Post notification that the track's name has been changed.
      postNotification(name: .trackDidChangeName, object: self)
    }
  }

  // MARK: Initializing

  /// Initializing with an index. Creates the event queue for the new track
  /// with a label formed by appending the `index` to 'Track'.
  ///
  /// - Parameter index: The index to assign the track.
  public init(index: Int)
  {
    self.index = index

    // Create the dispatch queue with a label derived from the number of tracks in the
    // sequence.
    eventQueue = DispatchQueue(label: "Track\(index)")
  }

  // MARK: Computed Properties

  /// The bar-beat time denoting the end of the track. When `eventContainer` is not empty,
  /// the value of this property is the largest time held by a contained event. When
  /// `eventContainer` is empty, the value of this property is `zero`.
  public var endOfTrack: BarBeatTime { eventContainer.maxTime ?? BarBeatTime.zero }

  /// The position of the track's MIDI file chunk within all track chunks for `sequence`.
  public var index: Int

  /// A comprehensive description of the track.
  public var description: String
  {
    // Return the track's name followed by all the track's events.
    return [
      "name: \(name)",
      "headEvents:\n\(headEvents)",
      "events:\n\(eventContainer)",
      "tailEvents:\n\(tailEvents)"
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
  public var chunk: TrackChunk
  {
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
  public var headEvents: [Event]
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

  /// An array containing the MIDI events that should succeed all others when representing
  /// the track in a MIDI file. The abstract `Track` implementation of this property
  /// provides an array containing a single event specifying the end of the track.
  public var tailEvents: [Event]
  {
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
  public func add<S: Swift.Sequence>(events: S) where S.Element == Event
  {
    eventContainer.append(contentsOf: events)
    sequencer.time.register(
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
    else
    {
      return []
    }

    // Return an array containing the time specified by the end of track event.
    return [eot.time]
  }

  public func dispatch(event _: Event) {}
}

// MARK: NotificationDispatching

@available(iOS 14.0, *)
extension Track: NotificationDispatching
{
  public static var didUpdateNotification =
    Notification.Name("didUpdate")

  public static var didChangeNameNotification =
    Notification.Name("didChangeName")

  public static var forceMuteStatusDidChangeNotification =
    Notification.Name("forceMuteStatusDidChange")

  public static var muteStatusDidChangeNotification =
    Notification.Name("muteStatusDidChange")

  public static var soloStatusDidChangeNotification =
    Notification.Name("soloStatusDidChange")
}

@available(iOS 14.0, *)
extension Notification.Name
{
  public static let trackDidUpdate = Track.didUpdateNotification
  public static let trackDidChangeName = Track.didChangeNameNotification
  public static let trackForceMuteStatusDidChange = Track
    .forceMuteStatusDidChangeNotification
  public static let trackMuteStatusDidChange = Track.muteStatusDidChangeNotification
  public static let trackSoloStatusDidChange = Track.soloStatusDidChangeNotification
}

@available(iOS 14.0, *)
extension Track
{
  /// Enumeration for specifying the color of a MIDI node dispatching instance whose raw
  /// value is an unsigned 32-bit integer representing a hexadecimal RGB value.
  public enum Color: String, CaseIterable, Codable
  {
    case muddyWaters
    case steelBlue
    case celery
    case chestnut
    case crayonPurple
    case verdigris
    case twine
    case tapestry
    case vegasGold
    case richBlue
    case fruitSalad
    case husk
    case mahogany
    case mediumElectricBlue
    case appleGreen
    case venetianRed
    case indigo
    case easternBlue
    case indochine
    case flirt
    case ultramarine
    case laRioja
    case forestGreen
    case pizza

    #if canImport(UIKIt)

    /// The `UIColor` derived from `rawValue`.
    public var uiColor: UIColor
    {
      UIColor(named: rawValue, in: .module, compatibleWith: nil)!
    }

    #endif

    public var color: SwiftUI.Color { .init(rawValue, bundle: .module) }

    public static subscript(index: Int) -> Color { allCases[index % allCases.count] }

    /// All possible `TrackColor` values.
    public static let allCases: [Color] = [
      .muddyWaters, .steelBlue, .celery, .chestnut, .crayonPurple, .verdigris, .twine,
      .tapestry, .vegasGold, .richBlue, .fruitSalad, .husk, .mahogany, .mediumElectricBlue,
      .appleGreen, .venetianRed, .indigo, .easternBlue, .indochine, .flirt, .ultramarine,
      .laRioja, .forestGreen, .pizza
    ]
  }
}

// MARK: - Track.Color + CustomStringConvertible

@available(iOS 14.0, *)
extension Track.Color: CustomStringConvertible
{
  /// The color's name.
  public var description: String { rawValue }
}

//// MARK: - Track.Color + LosslessJSONValueConvertible
//
// @available(iOS 14.0, *)
// extension Track.Color: LosslessJSONValueConvertible
// {
//  /// A string with the pound-prefixed hexadecimal representation of `rawValue`.
//  public var jsonValue: JSONValue { "#\(String(rawValue, radix: 16))".jsonValue }
//
//  /// Initializing with a JSON value.
//  /// - Parameter jsonValue: To be successful, `jsonValue` must be a string that
//  ///                        begins with '#' and whose remaining characters form
//  ///                        a string convertible to `UInt32`.
//  public init?(_ jsonValue: JSONValue?)
//  {
//    // Check that the JSON value is a string and get convert it to a hexadecimal value.
//    guard let string = String(jsonValue),
//          string.hasPrefix("#"),
//          let hex = UInt32(String(string.dropFirst()), radix: 16)
//    else
//    {
//      return nil
//    }
//
//    // Initialize with the hexadecimal value.
//    self.init(rawValue: hex)
//  }
// }
