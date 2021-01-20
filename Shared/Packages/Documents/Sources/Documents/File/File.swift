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
import Sequencer

// MARK: - File

/// Struct that holds data for a 'Groove' sequence.
@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public struct File: DataConvertible, LosslessJSONValueConvertible
{
  /// The file's location or `nil` when the file exists in-memory.
  public var source: URL?
  
  /// The collection of tracks composing the file's sequence.
  public var tracks: [Track] = []
  
  /// JSON object containing tempo changes for the file's sequence.
  public var tempoChanges = ObjectJSONValue([BarBeatTime.zero.rawValue: 120.0.jsonValue])
  
  /// The bar beat time that marks the end of the file's sequence.
  public var endOfFile = BarBeatTime.zero
  
  /// Intializing from an existing sequence and, possibly, its origin.
  public init(sequence: Sequencer.Sequence, source: URL? = nil)
  {
    // Store the source of the sequence.
    self.source = source
    
    // Initialize `tracks` by converting the instrument tracks of the sequence
    // into `Track` instances.
    tracks = sequence.instrumentTracks.map(Track.init)
    
    // Iterate the sequence's tempo events.
    for event in sequence.tempoTrack.tempoEvents
    {
      // Handle by kind of data attached to the event.
      switch event.data
      {
        case let .tempo(bpm):
          // Store the tempo keyed by the time of `event`.
          
          tempoChanges[event.time.rawValue] = bpm.jsonValue
          
        default:
          // Not relevant, just continue.
          
          continue
      }
    }
    
    // Intialize the end of the file using the end of the sequence.
    endOfFile = sequence.sequenceEnd
  }
  
  /// The file contents as raw data.
  public var data: Data { jsonValue.prettyData }
  
  /// Initializing with raw data.
  /// - Parameter data: For initialization to be successful, `data` should be
  ///                   convertible to an appropriate JSON value.
  public init?(data: Data) { self.init(JSONValue(data: data)) }
  
  /// A JSON object with values for keys 'source', 'tracks', 'tempoChanges', and
  /// 'endOfFile' that correspond with property values of the same name.
  public var jsonValue: JSONValue
  {
    .object([
      "source": source?.absoluteString.jsonValue ?? .null,
      "tracks": tracks.jsonValue,
      "tempoChanges": tempoChanges.jsonValue,
      "endOfFile": .string(endOfFile.rawValue)
    ])
  }
  
  /// Initializing with a JSON value.
  /// - Parameters:
  ///   - jsonValue: To be successful, `jsonValue` must be an object with keys
  ///                'tracks', 'tempoChanges', and 'endOfFile' whose values are
  ///                an array, an object, and a bar beat time respectively. If
  ///                the object also has an entry for 'source' whose value is a
  ///                string, `source` will be initialized with this value.
  public init?(_ jsonValue: JSONValue?)
  {
    // Check that `jsonValue` is an object with the required key-value pairs.
    guard let dict = ObjectJSONValue(jsonValue),
          let tracks = ArrayJSONValue(dict["tracks"]),
          let tempoChanges = ObjectJSONValue(dict["tempoChanges"]),
          let endOfFile = BarBeatTime(rawValue: dict["endOfFile"]?.value as? String ?? "")
    else
    {
      return nil
    }
    
    // Initialize `tracks` using the array of track JSON values.
    self.tracks = tracks.flatMap { Track($0) }
    
    // Initialize `tempoChanges` and `endOfFile`.
    self.tempoChanges = tempoChanges
    self.endOfFile = endOfFile
    
    // Check for an entry with the source url.
    guard let sourceString = String(dict["source"]) else { return }
    
    // Initialize `source` using the retrieved text.
    source = URL(string: sourceString)
  }
}

// MARK: CustomStringConvertible

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension File: CustomStringConvertible
{
  public var description: String { jsonValue.prettyRawValue }
}

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public extension Sequencer.Sequence
{
  /// Initializing with JSON fiie data belonging to a document. After the default
  /// initializer has been invoked passing `document`, the sequence's tempo and
  /// instrument tracks are generated using data obtained from `file`.
  convenience init(file: File)
  {
    // Invoke the default initializer with the specified document.
    self.init()
    
    // Create an array for accumulating tempo events.
    var tempoEvents: [Event] = []
    
    // Iterate through the tempo changes contained by `file`.
    for (key: rawTime, value: bpmValue) in file.tempoChanges.value
    {
      // Convert the key-value pair into `BarBeatTime` and `Double` values.
      guard let time = BarBeatTime(rawValue: rawTime),
            let bpm = Double(bpmValue)
      else
      {
        continue
      }
      
      // Create a meta event using the converted values.
      let tempoEvent = MetaEvent(data: .tempo(bpm: bpm), time: time)
      
      // Append a MIDI event wrapping `tempoEvent` to the array of tempo events.
      tempoEvents.append(.meta(tempoEvent))
    }
    
    // Append the tempo events extracted from `file` to the tempo track created in
    // the default initializer.
    tempoTrack.add(events: tempoEvents)
    
    // Iterate through the file's instrument track data.
    for (index, trackData) in file.tracks.enumerated()
    {
      // Initialize a new track using `trackData`.
      guard let track = try? InstrumentTrack(index: index + 1,
                                             grooveTrack: trackData)
      else { continue }
      
      // Add the track to the sequence.
      add(track: track)
    }
  }
}

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public extension Sequencer.Loop
{
  /// Iniitializing with a loop from a Groove file and a track. The loop is assigned to the
  /// specified track. The values for `identifier`, `repetitions`, `repeatDelay`, and
  /// `start` are retrieved from `grooveLoop`.
  convenience init(grooveLoop: File.Loop, track: InstrumentTrack)
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
public extension InstrumentTrack
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
  convenience init(index: Int, grooveTrack: File.Track) throws
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
                  preset: Instrument.Preset(grooveTrack.instrument.jsonValue),
                  color: grooveTrack.color,
                  name: grooveTrack.name,
                  events: events)
    
    // Iterate the loop data provided by `grooveTrack`.
    for loopData in grooveTrack.loops.values
    {
      let loop = Sequencer.Loop(grooveLoop: loopData, track: self)
      
      // Create a loop using `loopData`.
      add(loop: loop)
    }
  }
}
