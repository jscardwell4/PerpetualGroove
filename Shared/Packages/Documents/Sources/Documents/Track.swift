//
//  Track.swift
//  Documents
//
//  Created by Jason Cardwell on 01/06/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MoonDev
import Sequencer

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension File
{
  /// The `Documents.File` representation of `InstrumentTrack`.
  public struct Track: CustomStringConvertible, Codable
  {
    public typealias Color = Sequencer.Track.Color
    public typealias Preset = Instrument.Preset
    public typealias Identifier = Node.Identifier

    /// The preset used by the track.
    public var preset: Preset

    /// The track's name.
    public var name: String

    /// The track's color.
    public var color: Color

    /// An index of nodes belonging to the track.
    public var nodes: [Identifier: Node] = [:]

    /// An index of loops belonging to the track.
    public var loops: [UUID: Loop] = [:]

    /// Initializing with an instance of `InstrumentTrack`.
    public init(track: InstrumentTrack)
    {
      // Initialize the `name`, `instrument`, and `color` properties.
      name = track.name

      preset = track.instrument.preset
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
                // The event adds a node, create a new `Node` instance and append to
                // the track.

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

    public var description: String { "" } // jsonValue.prettyRawValue }

    private enum CodingKeys: String, CodingKey
    {
      case name, color, preset, nodes, loops
    }

    public func encode(to encoder: Encoder) throws
    {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
      try container.encode(color, forKey: .color)
      try container.encode(preset, forKey: .preset)
      try container.encode(nodes, forKey: .nodes)
      try container.encode(loops, forKey: .loops)
    }

    public init(from decoder: Decoder) throws
    {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      name = try container.decode(String.self, forKey: .name)
      color = try container.decode(Color.self, forKey: .color)
      preset = try container.decode(Preset.self, forKey: .preset)
      nodes = try container.decode([Identifier: Node].self, forKey: .nodes)
      loops = try container.decode([UUID: Loop].self, forKey: .loops)
    }
  }
}
