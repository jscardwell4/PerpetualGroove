//
//  Track.swift
//  Documents
//
//  Created by Jason Cardwell on 01/06/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import MoonKit
import Sequencer

public extension File
{
  /// The `Documents.File` representation of `InstrumentTrack`.
  struct Track: CustomStringConvertible, LosslessJSONValueConvertible
  {
    /// A JSON object containing the preset info for an instrument track.
    public var instrument: ObjectJSONValue

    /// The track's name.
    public var name: String

    /// The track's color.
    public var color: TrackColor

    /// An index of nodes belonging to the track.
    public var nodes: [Node.Identifier: Node] = [:]

    /// An index of loops belonging to the track.
    public var loops: [UUID: Loop] = [:]

    /// Initializing with an instance of `InstrumentTrack`.
    public init(track: InstrumentTrack)
    {
      // Initialize the `name`, `instrument`, and `color` properties.
      name = track.name
      instrument = ObjectJSONValue(track.instrument.preset.jsonValue)!
      color = track.color

      // Iterate through all the events in `track`.
      for event in track.eventContainer
      {
        // Handle the event according to its type.
        switch event
        {
          case let .meta(event):
            // Check the meta event for relevant data.

            switch event.data
            {
              case let .marker(text):
                // Check whether the marker's text begins or ends a loop.

                switch text
                {
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
                          let identifer = UUID(uuidString: String(text))
                    else
                    {
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

          case let .node(event):
            // Check the event's data to determine whether it adds or removes a node.

            switch event.data
            {
              case .add:
                // The event adds a node, create a new `Node` instance and append to the track.

                // Generate the new node.
                guard let node = Node(event: event) else { continue }

                // Check the event for a loop identifier.
                if let loopIdentifier = event.loopIdentifier
                {
                  // A loop matching the identifier should have already been created,
                  // append the node to the loop's nodes.
                  loops[loopIdentifier]?.nodes[event.identifier] = node
                }
                else
                {
                  // Append the node to the track's nodes.
                  nodes[event.identifier] = node
                }

              case .remove:
                // The event removes a node, update the node specified by `event`.

                // Check the event for a loop identifier.
                if let loopIdentifier = event.loopIdentifier
                {
                  // Update the node contained by the loop matching the identifier.
                  loops[loopIdentifier]?.nodes[event.identifier]?.removeTime = event.time
                }
                else
                {
                  // Update the track's node.
                  nodes[event.identifier]?.removeTime = event.time
                }
            }

          default:
            // The event is not handled by `Track`, ignore it.

            continue
        }
      }
    }

    public var description: String { return jsonValue.prettyRawValue }

    /// A JSON object containing the track's `name`, `color`, and `instrument` values keyed by property
    /// name. The object also contains value arrays for the `nodes` and loops` properties.
    public var jsonValue: JSONValue
    {
      return [
        "name": name,
        "color": color,
        "instrument": instrument,
        "nodes": Array(nodes.values),
        "loops": Array(loops.values),
      ]
    }

    /// Initializing with a JSON value.
    /// - Parameter jsonValue: To be successful `jsonValue` should be a JSON object with keys
    ///                        'name', 'color', 'instrument', 'nodes', and 'loops' with values
    ///                        appropriate for initializing the corresponding property.
    public init?(_ jsonValue: JSONValue?)
    {
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
      self.nodes = Dictionary(nodes.flatMap(Node.init).map { (key: $0.identifier, value: $0) })

      // Initialize `loops` by converting the array of JSON values into `Loop` instances and mapping.
      self.loops = Dictionary(loops.flatMap(Loop.init).map { (key: $0.identifier, value: $0) })
    }
  }
}
