//
//  GrooveFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import MIDI
import AudioEngine
import Common
import NodePlayer

/// Struct that holds data for a 'Groove' sequence.
public struct GrooveFile: DataConvertible, LosslessJSONValueConvertible, CustomStringConvertible {

  /// The file's location or `nil` when the file exists in-memory.
  public var source: URL?

  /// The collection of tracks composing the file's sequence.
  public var tracks: [Track] = []

  /// JSON object containing tempo changes for the file's sequence.
  public var tempoChanges = ObjectJSONValue([BarBeatTime.zero.rawValue: 120.0.jsonValue])

  /// The bar beat time that marks the end of the file's sequence.
  public var endOfFile: BarBeatTime = BarBeatTime.zero

  /// Intializing from an existing sequence and, possibly, its origin.
  public init(sequence: Sequence, source: URL?) {

    // Store the source of the sequence.
    self.source = source

    // Initialize `tracks` by converting the instrument tracks of the sequence into `Track` instances.
    tracks = sequence.instrumentTracks.map(Track.init)

    // Iterate the sequence's tempo events.
    for event in sequence.tempoTrack.tempoEvents {

      // Handle by kind of data attached to the event.
      switch event.data {

        case .tempo(let bpm):
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
  public var data: Data { return jsonValue.prettyData }

  /// Initializing with raw data. 
  /// - Parameter data: For initialization to be successful, `data` should be convertible to an 
  ///                   appropriate JSON value.
  public init?(data: Data) { self.init(JSONValue(data: data)) }

  /// A JSON object with values for keys 'source', 'tracks', 'tempoChanges', and 'endOfFile' that 
  /// correspond with property values of the same name.
  public var jsonValue: JSONValue {
    return .object([
      "source": source?.absoluteString.jsonValue ?? .null,
      "tracks": tracks.jsonValue,
      "tempoChanges": tempoChanges.jsonValue,
      "endOfFile": .string(endOfFile.rawValue)
    ])
  }

  /// Initializing with a JSON value.
  /// - Parameter jsonValue: To be successful, `jsonValue` must be an object with keys 'tracks',
  ///                        'tempoChanges', and 'endOfFile' whose values are an array, an object,
  ///                        and a bar beat time respectively. If the object also has an entry for
  ///                        'source' whose value is a string, `source` will be initialized with this value.
  public init?(_ jsonValue: JSONValue?) {

    // Check that `jsonValue` is an object with the required key-value pairs.
    guard let dict = ObjectJSONValue(jsonValue),
          let tracks = ArrayJSONValue(dict["tracks"]),
          let tempoChanges = ObjectJSONValue(dict["tempoChanges"]),
          let endOfFile = BarBeatTime(rawValue: (dict["endOfFile"]?.value as? String ?? ""))
      else
    {
      return nil
    }

    // Initialize `tracks` using the array of track JSON values.
    self.tracks = tracks.flatMap({Track($0)})

    // Initialize `tempoChanges` and `endOfFile`.
    self.tempoChanges = tempoChanges
    self.endOfFile = endOfFile

    // Check for an entry with the source url.
    guard let sourceString = String(dict["source"]) else { return }

    // Initialize `source` using the retrieved text.
    source = URL(string: sourceString)

  }

  public var description: String { return jsonValue.prettyRawValue }

  /// The `GrooveFile` representation of `InstrumentTrack`.
  public struct Track: CustomStringConvertible, LosslessJSONValueConvertible {

    /// A JSON object containing the preset info for an instrument track.
    public var instrument: ObjectJSONValue

    /// The track's name.
    public var name: String

    /// The track's color.
    public var color: TrackColor

    /// An index of nodes belonging to the track.
    public var nodes: [Node.Identifier:Node] = [:]

    /// An index of loops belonging to the track.
    public var loops: [UUID:Loop] = [:]

    /// Initializing with an instance of `InstrumentTrack`.
    public init(track: InstrumentTrack) {

      // Initialize the `name`, `instrument`, and `color` properties.
      name = track.name
      instrument = ObjectJSONValue(track.instrument.preset.jsonValue)!
      color = track.color

      // Iterate through all the events in `track`.
      for event in track.eventContainer {

        // Handle the event according to its type.
        switch event {

          case .meta(let event):
            // Check the meta event for relevant data.

            switch event.data {

              case .marker(let text):
                // Check whether the marker's text begins or ends a loop.

                switch text {

                  case ~/"^start.*":
                    // The marker begins a loop, add a new loop to `loops`.

                    // Generate a loop using `event`.
                    guard let loop = Loop(event: event) else { continue }

                    // Insert into `loops`.
                    loops[loop.identifier] = loop

                  case ~/"^end.*":
                    // The marker ends a loop, update the `Loop` instance in `loops`.

                    // Extract the identifier from `text`.
                    guard let match = (~/"^end\\(([^)]+)\\)$").firstMatch(in: text),
                          let text = match.captures[1]?.substring,
                          let identifer = UUID(uuidString: String(text)) else {
                      continue
                    }

                    // Update the end time of the corresponding loop using `event`.
                    loops[identifer]?.end = event.time

                  default:
                    // The marker does not begin or end a loop, ignore it.

                    continue

                }

              default:
                // The meta event is not one handled by `Track`, ignore it.

                continue

            }

//          case .node(let event):
//            // Check the event's data to determine whether it adds or removes a node.
//
//            switch event.data {
//
//              case .add:
//                // The event adds a node, create a new `Node` instance and append to the track.
//
//                // Generate the new node.
//                guard let node = Node(event: event) else { continue }
//
//                // Check the event for a loop identifier.
//                if let loopIdentifier = event.loopIdentifier {
//
//                  // A loop matching the identifier should have already been created, append the node
//                  // to the loop's nodes.
//                  loops[loopIdentifier]?.nodes[event.identifier] = node
//
//                } else {
//
//                  // Append the node to the track's nodes.
//                  nodes[event.identifier] = node
//
//                }
//
//              case .remove:
//                // The event removes a node, update the node specified by `event`.
//
//                // Check the event for a loop identifier.
//                if let loopIdentifier = event.loopIdentifier {
//
//                  // Update the node contained by the loop matching the identifier.
//                  loops[loopIdentifier]?.nodes[event.identifier]?.removeTime = event.time
//
//                } else {
//
//                  // Update the track's node.
//                  nodes[event.identifier]?.removeTime = event.time
//
//                }
//
//            }

          default:
            // The event is not handled by `Track`, ignore it.

            continue

        }

      }

    }

    public var description: String { return jsonValue.prettyRawValue }

    /// A JSON object containing the track's `name`, `color`, and `instrument` values keyed by property
    /// name. The object also contains value arrays for the `nodes` and loops` properties.
    public var jsonValue: JSONValue {

      return [
        "name": name,
        "color": color,
        "instrument": instrument,
        "nodes": Array(nodes.values),
        "loops": Array(loops.values)
      ]

    }

    /// Initializing with a JSON value. 
    /// - Parameter jsonValue: To be successful `jsonValue` should be a JSON object with keys
    ///                        'name', 'color', 'instrument', 'nodes', and 'loops' with values
    ///                        appropriate for initializing the corresponding property.
    public init?(_ jsonValue: JSONValue?) {

      // Get the JSON object and extract the necessary values.
      guard let dict = ObjectJSONValue(jsonValue),
            let name = String(dict["name"]),
            let color = TrackColor(dict["color"]),
            let instrument = ObjectJSONValue(dict["instrument"]),
            let nodes = ArrayJSONValue(dict["nodes"]),
            let loops = ArrayJSONValue(dict["loops"])
        else
      {
        return nil
      }

      // Initialize the `name`, `instrument` and `color` properties.
      self.name = name
      self.instrument = instrument
      self.color = color

      // Initialize `nodes` by converting the array of JSON values into `Node` instances and mapping.
      self.nodes = Dictionary(nodes.flatMap(Node.init).map({(key: $0.identifier, value: $0)}))


      // Initialize `loops` by converting the array of JSON values into `Loop` instances and mapping.
      self.loops = Dictionary(loops.flatMap(Loop.init).map({(key: $0.identifier, value: $0)}))

    }

  }

  /// A type for specifying a repeating subsequence of node events in a track.
  public struct Loop: CustomStringConvertible, LosslessJSONValueConvertible {

    /// Typealias for the midi event kind utilized by `Loop`.
    public typealias Event = MetaEvent

    /// The unique identifier for the loop within its track.
    public var identifier: UUID

    /// The number of times the subsequence of node events should be run. Setting this property to `0` 
    /// indicates that the loop should repeat forever.
    public var repetitions: Int

    /// The number of ticks after the last event generated by the loop that should elapse before beginning
    /// another repetition of loop events.
    public var repeatDelay: UInt64

    /// The bar beat time at which point the loop begins generating events for its first repetition.
    public var start: BarBeatTime

    /// The bar beat time at which point the loop ends generating events for its first repetition. Setting
    /// the value of this property to a time less than or equal to `start` indicates the loop does not end.
    public var end: BarBeatTime

    /// An index of nodes belonging to the loop.
    public var nodes: [Node.Identifier:Node] = [:]

    /// Initializing from an event. The loop created will have its start and end times set to the event's
    /// time.
    /// - Parameter event: To be successful the event must be a marker with text in the form of
    ///                    `start(`*identifier*`):`*repetitions*`:`*repeatDelay*
    public init?(event: Event) {

      // Extract the identifier, repetitions, and repeat delay from the text contained in the event's data.
      guard case .marker(let text) = event.data,
            let captures = (~/"^start\\(([^)]+)\\):([0-9]+):([0-9]+)$").firstMatch(in: text)?.captures

      else
      {
        return nil
      }

      let capturedID = String(captures[1]?.substring ?? "")
      let capturedReps = String(captures[2]?.substring ?? "")
      let capturedDelay = String(captures[3]?.substring ?? "")

      guard let identifier = UUID(uuidString: capturedID),
            let repetitions = Int(capturedReps),
            let repeatDelay = UInt64(capturedDelay)
        else
      {
        return nil
      }

      // Intialize `identifier`, `repetitions` and `repeatDelay` using the extracted values.
      self.identifier = identifier
      self.repetitions = repetitions
      self.repeatDelay = repeatDelay

      // Use the event's time to initialize `start` and `end`.
      start = event.time
      end = event.time

    }

    /// A JSON object containing the loop's `identifier`, `repetitions`, `repeatDelay`, `start` and `end`
    /// values keyed by property name. The object also contains a value array for the `nodes` property.
    public var jsonValue: JSONValue {

      return .object( [
        "identifier": .string(identifier.uuidString),
        "repetitions": .number(repetitions as NSNumber),
        "repeatDelay": .number(repeatDelay as NSNumber),
        "start": .string(start.rawValue),
        "end": .string(end.rawValue),
        "nodes": .array(Array(nodes.values.map(\Node.jsonValue)))
      ])

    }

    /// Initializing with a JSON value. 
    /// - Parameter jsonValue: To be successful `jsonValue` should be a JSON object with keys
    ///                        'identifier', 'repetitions', 'repeatDelay', 'start', 'end', and
    ///                        'nodes' with values appropriate for initializing the corresponding property.
    public init?(_ jsonValue: JSONValue?) {

      // Get the JSON object and extract the necessary values.
      guard let dict = ObjectJSONValue(jsonValue),
            let identifierString = String(dict["identifier"]),
            let identifier = UUID(uuidString: identifierString),
            let repetitions = Int(dict["repetitions"]),
            let repeatDelay = UInt64(dict["repeatDelay"]),
            let start = BarBeatTime(rawValue: (dict["start"]?.value as? String ?? "")),
            let end = BarBeatTime(rawValue: (dict["end"]?.value as? String ?? "")),
            let nodes = ArrayJSONValue(dict["nodes"])
        else
      {
        return nil
      }

      // Initialize the `identifier`, `repetitions`, `repeatDelay`, `start`, and `end` properties.
      self.identifier = identifier
      self.repetitions = repetitions
      self.repeatDelay = repeatDelay
      self.start = start
      self.end = end

      // Initialize `nodes` by converting the array of JSON values into `Node` instances and mapping.
      self.nodes = Dictionary(nodes.flatMap(Node.init).map({(key: $0.identifier, value: $0)}))

    }

    public var description: String { return jsonValue.prettyRawValue }

  }

  /// A type for encapsulating all the necessary data for adding and removing a `MIDINode`.
  public struct Node: LosslessJSONValueConvertible {

    /// Use the identifier type utilized by midi node events.
    public typealias Identifier = MIDINodeEvent.Identifier

    /// The type for encapsulating initial angle and velocity data.
    public typealias Trajectory = MIDINode.Trajectory

    /// Typealias for the midi event kind utilized by `Node`.
    public typealias Event = MIDINodeEvent

    /// The unique identifier for the node within its track.
    public let identifier: Identifier

    /// The node's initial trajectory.
    public var trajectory: MIDINode.Trajectory

    /// The node's generator
    public var generator: AnyMIDIGenerator

    /// The bar beat time at which point the node is added to the player.
    public var addTime: BarBeatTime

    /// The bar beat time at which point the node is removed from the player. A `nil` value for this
    /// property indicates that the node is never removed from the player.
    public var removeTime: BarBeatTime? {

      didSet {

        // Check that `removeTime` is invalid.
        guard removeTime != nil && removeTime! < addTime else { return }

        // Clear the invalid time.
        removeTime = nil

      }

    }

    /// The event for adding the node to the player.
    public var addEvent: Event {

      // Return an add event with node's identifier, trajectory, generator, and add time.
      return Event(data: .add(identifier: identifier, trajectory: trajectory, generator: generator),
                   time: addTime)

    }

    /// The event for removing the node from the player or `nil` if `removeTime == nil`.
    public var removeEvent: Event? {

      // Get the remove time.
      guard let removeTime = removeTime else { return nil }

      // Return a remove event with the node's identifier and remove time.
      return Event(data: .remove(identifier: identifier), time: removeTime)

    }

    /// Initializing with a node event. 
    /// - Parameter event: To be successful the event must be an add event.
    public init?(event: Event) {

      // Extract the identifier, trajectory and generator from the event's data.
      guard case let .add(identifier, trajectory, generator) = event.data else { return nil }

      // Initialize the node's properties.
      addTime = event.time
      self.identifier = identifier
      self.trajectory = trajectory
      self.generator = generator

    }

    /// A JSON object with values for keys 'identifier', 'generator', 'trajectory', 'addTime', 
    /// and 'removeTime'.
    public var jsonValue: JSONValue {

      return .object ([
        "identifier": identifier.jsonValue,
        "generator": generator.jsonValue,
        "trajectory": trajectory.jsonValue,
        "addTime": .string(addTime.rawValue),
        "removeTime": removeTime != nil ? .string(removeTime!.rawValue) : .null
      ])

    }

    /// Initializing with a JSON value. 
    /// - Parameter jsonValue: To be successful `jsonValue` must be a JSON object with entries
    ///                        for 'identifier', 'trajectory', 'generator', and 'addTime'. The
    ///                        object may optionally include an entry for 'removeTime'.
    public init?(_ jsonValue: JSONValue?) {

      // Extract the identifier, trajectory, generator, and add time values.
      guard let dict = ObjectJSONValue(jsonValue),
            let identifier = Identifier(dict["identifier"]),
            let trajectory = MIDINode.Trajectory(dict["trajectory"]),
            let generator = AnyMIDIGenerator(dict["generator"]),
            let addTime = BarBeatTime(rawValue: (dict["addTime"]?.value as? String ?? ""))
        else
      {
        return nil
      }

      // Intialize the corresponding property for each value extracted from the JSON object.
      self.identifier = identifier
      self.generator = generator
      self.trajectory = trajectory
      self.addTime = addTime

      // Extract the remove time value.
      switch dict["removeTime"] {

        case .string(let s)?:
          // The JSON object contains an entry for node's remove time, use it to initialize `removeTime`.

          removeTime = BarBeatTime(rawValue: s)

        case .null?:
          // The JSON object contains an entry for the node's remove time specifying a null value.

          fallthrough

        default:
          // The JSON object does not contain an entry for the node's remove time.

          removeTime = nil

      }

    }

  }

}

extension Loop {
  /// Iniitializing with a loop from a Groove file and a track. The loop is assigned to the
  /// specified track. The values for `identifier`, `repetitions`, `repeatDelay`, and
  /// `start` are retrieved from `grooveLoop`.
  public convenience init(grooveLoop: GrooveFile.Loop, track: InstrumentTrack) {

    // Create an array for accumulating the loop's MIDI events.
    var events: [MIDIEvent] = []

    // Iterate the nodes in `grooveLoop`.
    for node in grooveLoop.nodes.values {
      // Append a `MIDINodeEvent` that adds the node.
      events.append(.node(node.addEvent))

      // Get the node's remove event.
      if let removeEvent = node.removeEvent {
        // Append a `MIDINodeEvent` that removes the node.
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

extension InstrumentTrack {

  /// Initializing with a sequence and track data from a Groove file. An instrument is
  /// created for the track using the preset data specified by `grooveTrack`, any loop
  /// data provided by `grooveTrack` is used to add loops to the track, and any node data
  /// provided by `grooveTrack` is used to generate MIDI node events for the track.
  ///
  /// - Parameters:
  ///   - sequence: The `Sequence` that owns the created track.
  ///   - grooveTrack: The instrument and event data used to initialize the track.
  /// - Throws: Any error encountered creating the track's instrument, any error
  ///           encountered creating the MIDI client/ports.
  public convenience init(sequence: Sequence, grooveTrack: GrooveFile.Track) throws {

    // Create an array for accumulating MIDI events.
    var events: [MIDIEvent] = []

    // Iterate the node data provided by `grooveTrack`.
    for nodeData in grooveTrack.nodes.values {

      // Append an event adding a MIDI node using `nodeData` to the array of events.
      events.append(.node(MIDINodeEvent(data: .add(identifier: nodeData.identifier,
                                                   trajectory: nodeData.trajectory,
                                                   generator: nodeData.generator))))

      // Check whether a remove time is specified by attempting to create an event that
      // removes the MIDI node created using `nodeData`.
      if let removeTime = nodeData.removeTime {

        let event = MIDINodeEvent(data: .remove(identifier: nodeData.identifier),
                                  time: removeTime)

        // Append the successfully created event to the array of events.
        events.append(.node(event))

      }

    }

    try self.init(sequence: sequence,
                  preset: Instrument.Preset(grooveTrack.instrument.jsonValue),
                  color: grooveTrack.color,
                  name: grooveTrack.name,
                  events: events)


    // Iterate the loop data provided by `grooveTrack`.
    for loopData in grooveTrack.loops.values {

      let loop = Loop(grooveLoop: loopData, track: self)

      // Create a loop using `loopData`.
      add(loop: loop)

    }


  }


}
