//
//  File.swift
//  Documents
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MIDI
import MoonDev
import Sequencing

// MARK: - File

/// Struct that holds data for a 'Groove' sequence.
@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public struct File: DataConvertible, Codable
{
  /// The file's name.
  public var name: String

  /// The collection of tracks composing the file's sequence.
  public var tracks: [Track] = []

  /// JSON containing tempo changes for the file's sequence.
  public var tempoChanges: [BarBeatTime: Double] = [BarBeatTime.zero: 120.0]

  /// The bar beat time that marks the end of the file's sequence.
  public var endOfFile = BarBeatTime.zero

  /// Intializing from an existing sequence and, possibly, its origin.
  public init(sequence: Sequence)
  {
    name = sequence.name

    // Initialize `tracks` by converting the instrument tracks of the sequence
    // into `Track` instances.
    tracks = sequence.instrumentTracks.map(Track.init)

    // Iterate the sequence's tempo events.
    for event in sequence.tempoTrack.eventManager.tempoEvents
    {
      // Handle by kind of data attached to the event.
      switch event.data
      {
        case let .tempo(bpm):
          // Store the tempo keyed by the time of `event`.

          tempoChanges[event.time] = bpm

        default:
          // Not relevant, just continue.

          continue
      }
    }

    // Intialize the end of the file using the end of the sequence.
    endOfFile = sequence.sequenceEnd
  }

  /// The file contents as raw data.
  public var data: Data
  {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(self)
    return data
  }

  /// Initializing with raw data.
  /// - Parameter data: For initialization to be successful, `data` should be
  ///                   convertible to an appropriate JSON value.
  public init?(data: Data)
  {
    let decoder = JSONDecoder()
    guard let file = try? decoder.decode(File.self, from: data) else { return nil }

    self = file
  }

  private enum CodingKeys: String, CodingKey
  {
    case name, tracks, tempoChanges, endOfFile
  }

  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(tracks, forKey: .tracks)
    try container.encode(tempoChanges, forKey: .tempoChanges)
    try container.encode(endOfFile, forKey: .endOfFile)
  }

  public init(from decoder: Decoder) throws
  {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    tracks = try container.decode([Track].self, forKey: .tracks)
    tempoChanges = try container.decode([BarBeatTime: Double].self, forKey: .tempoChanges)
    endOfFile = try container.decode(BarBeatTime.self, forKey: .endOfFile)
  }
}

// MARK: CustomStringConvertible

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension File: CustomStringConvertible
{
  public var description: String
  {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(self)
    let string = String(data: data, encoding: .utf8)!
    return string
  }
}

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension Sequence
{
  /// Initializing with JSON fiie data belonging to a document. After the default
  /// initializer has been invoked passing `document`, the sequence's tempo and
  /// instrument tracks are generated using data obtained from `file`.
  public convenience init(file: File)
  {
    // Invoke the default initializer with the specified document.
    self.init()

    name = file.name

    // Create an array for accumulating tempo events.
    var tempoEvents: [Event] = []

    // Iterate through the tempo changes contained by `file`.
    for (key: time, value: bpm) in file.tempoChanges
    {
      // Create a meta event using the converted values.
      let tempoEvent = MetaEvent(data: .tempo(bpm: bpm), time: time)

      // Append a MIDI event wrapping `tempoEvent` to the array of tempo events.
      tempoEvents.append(.meta(tempoEvent))
    }

    // Append the tempo events extracted from `file` to the tempo track created in
    // the default initializer.
    tempoTrack.eventManager.add(events: tempoEvents)

    // Iterate through the file's instrument track data.
    for (index, trackData) in file.tracks.enumerated()
    {
      // Initialize a new track using `trackData`.
      guard let track = try? InstrumentTrack(index: index + 1, grooveTrack: trackData)
      else { continue }

      // Add the track to the sequence.
      add(track: track)
    }
  }
}

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension Loop
{
  /// Iniitializing with a loop from a Groove file and a track. The loop is assigned to the
  /// specified track. The values for `identifier`, `repetitions`, `repeatDelay`, and
  /// `start` are retrieved from `grooveLoop`.
  public convenience init(grooveLoop: File.Loop, track: InstrumentTrack)
  {
    // Create an array for accumulating the loop's MIDI events.
    var events: [Event] = []

    // Iterate the nodes in `grooveLoop`.
    for node in grooveLoop.nodes.values
    {
      // Append a `NodeEvent` that adds the node.
      events.append(.node(node.addEvent))

      // Get the node's remove event.
      if let removeEvent = node.removeEvent
      {
        // Append a `NodeEvent` that removes the node.
        events.append(.node(removeEvent))
      }
    }

    self.init(identifier: grooveLoop.identifier,
              track: track,
              repetitions: grooveLoop.repetitions,
              repeatDelay: grooveLoop.repeatDelay,
              start: grooveLoop.start,
              events: events)
  }
}

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension InstrumentTrack
{
  /// Initializing with an index and track data from a Groove file. An instrument is
  /// created for the track using the preset data specified by `grooveTrack`, any loop
  /// data provided by `grooveTrack` is used to add loops to the track, and any node data
  /// provided by `grooveTrack` is used to generate MIDI node events for the track.
  ///
  /// - Parameters:
  ///   - index: The track's index.
  ///   - grooveTrack: The instrument and event data used to initialize the track.
  /// - Throws: Any error encountered creating the track's instrument, any error
  ///           encountered creating the MIDI client/ports.
  public convenience init(index: Int, grooveTrack: File.Track) throws
  {
    // Create an array for accumulating MIDI events.
    var events: [Event] = []

    // Iterate the node data provided by `grooveTrack`.
    for nodeData in grooveTrack.nodes.values
    {
      // Append an event adding a MIDI node using `nodeData` to the array of events.
      events.append(.node(NodeEvent(data: .add(identifier: nodeData.identifier,
                                               trajectory: nodeData.trajectory,
                                               generator: nodeData.generator))))

      // Check whether a remove time is specified by attempting to create an event that
      // removes the MIDI node created using `nodeData`.
      if let removeTime = nodeData.removeTime
      {
        let event = NodeEvent(data: .remove(identifier: nodeData.identifier),
                              time: removeTime)

        // Append the successfully created event to the array of events.
        events.append(.node(event))
      }
    }

    try self.init(index: index,
                  preset: grooveTrack.preset,
                  color: grooveTrack.color,
                  name: grooveTrack.name,
                  events: events)

    // Iterate the loop data provided by `grooveTrack`.
    for loopData in grooveTrack.loops.values
    {
      let loop = Loop(grooveLoop: loopData, track: self)

      // Create a loop using `loopData`.
      add(loop: loop)
    }
  }
}
