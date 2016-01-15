//
//  GrooveTrack.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct GrooveTrack {

  var instrument: ObjectJSONValue
  var name: String
  var color: TrackColor

  var nodes: [MIDINodeEvent.Identifier:GrooveNode] = [:]

  var loops: [GrooveLoop.Identifier:GrooveLoop] = [:]

  init(track: InstrumentTrack) {
    name = track.name
    instrument = ObjectJSONValue(track.instrument.jsonValue)!
    color = track.color

    var loops: [GrooveLoop.Identifier:GrooveLoop] = [:]

    for event in track.events {
      switch event {

        case .Meta(let event):
          switch event.data {
            case .Marker(let text):
              switch text {
                case ~/"^start.*":
                  guard let loop = GrooveLoop(event: event) else { continue }
                  loops[loop.identifier] = loop

                case ~/"^end.*":
                  guard let match = (~/"^end\\(([^)]+)\\)$").firstMatch(text),
                  identifierString = match.captures[1]?.string,
                  identifier = GrooveLoop.Identifier(identifierString) else { continue }
                  loops[identifier]?.end = event.time

                default: break
              }
            default: break
          }

        case .Node(let event):
          switch event.data {
            case .Add:
              guard let node = GrooveNode(event: event) else { continue }
              if let loopIdentifier = event.loopIdentifier {
                loops[loopIdentifier]?.nodes[event.identifier] = node
              } else {
                nodes[event.identifier] = node
              }
            case .Remove:
              if let loopIdentifier = event.loopIdentifier {
                loops[loopIdentifier]?.nodes[event.identifier]?.removeTime = event.time
              } else {
                nodes[event.identifier]?.removeTime = event.time
              }

          }

        default: break

      }
    }
  }

}

extension GrooveTrack: CustomStringConvertible {
  var description: String { return jsonValue.prettyRawValue }
}

extension GrooveTrack: JSONValueConvertible {
  var jsonValue: JSONValue { return [ "name": name, "color": color, "instrument": instrument, "nodes": Array(nodes.values) ] }
}

extension GrooveTrack: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              name = String(dict["name"]),
              color = TrackColor(dict["color"]),
              instrument = ObjectJSONValue(dict["instrument"]),
              nodes = ArrayJSONValue(dict["nodes"]) else { return nil }
    self.name = name
    self.instrument = instrument
    self.color = color
    for node in nodes.flatMap({GrooveNode($0)}) { self.nodes[node.identifier] = node }
  }
}