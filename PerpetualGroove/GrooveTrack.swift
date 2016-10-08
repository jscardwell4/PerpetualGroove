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

  var loops: [UUID:GrooveLoop] = [:]

  init(track: InstrumentTrack) {
    name = track.name
    instrument = ObjectJSONValue(track.instrument.preset.jsonValue)!
    color = track.color

//    var loops: [UUID:GrooveLoop] = [:]

/*    for event in track.eventContainer {
      switch event {

        case .meta(let event):
          switch event.data {
            case .marker(let text):
              switch text {
                case ~/"^start.*":
                  guard let loop = GrooveLoop(event: event) else { continue }
                  loops[loop.identifier] = loop

                case ~/"^end.*":
                  guard let match = (~/"^end\\(([^)]+)\\)$").firstMatch(in: text),
                  let identifierString = match.captures[1]?.string,
                  let identifier = UUID(uuidString: identifierString) else { continue }
                  loops[identifier]?.end = event.time

                default: break
              }
            default: break
          }

        case .node(let event):
          switch event.data {
            case .add:
              guard let node = GrooveNode(event: event) else { continue }
              if let loopIdentifier = event.loopIdentifier {
                loops[loopIdentifier]?.nodes[event.identifier] = node
              } else {
                nodes[event.identifier] = node
              }
            case .remove:
              if let loopIdentifier = event.loopIdentifier {
                loops[loopIdentifier]?.nodes[event.identifier]?.removeTime = event.time
              } else {
                nodes[event.identifier]?.removeTime = event.time
              }

          }

        default: break

      }
    }*/
  }

}

extension GrooveTrack: CustomStringConvertible {
  var description: String { return jsonValue.prettyRawValue }
}

extension GrooveTrack: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return [ "name": name, "color": color, "instrument": instrument, "nodes": Array(nodes.values) ]
  }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              let name = String(dict["name"]),
              let color = TrackColor(dict["color"]),
              let instrument = ObjectJSONValue(dict["instrument"]),
              let nodes = ArrayJSONValue(dict["nodes"]) else { return nil }
    self.name = name
    self.instrument = instrument
    self.color = color
    for node in nodes.flatMap({GrooveNode($0)}) { self.nodes[node.identifier] = node }
  }

}
