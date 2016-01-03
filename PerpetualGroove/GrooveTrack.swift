//
//  GrooveTrack.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct GrooveTrack {

  var instrument: ObjectJSONValue
  var name: String
  var color: TrackColor

  var nodes: [MIDINodeEvent.Identifier:Node] = [:]


  init(track: InstrumentTrack) {
    name = track.name
    instrument = ObjectJSONValue(track.instrument.jsonValue)!
    color = track.color

    for event in track.eventContainer {
      switch event {
      case let event as MetaEvent:
        switch event.data {
        case .Marker(let text):
          switch text {
            case ~/"^start.*":
              guard let match = (~/"^start\\(([^)]+)\\):([0-9]+)$").firstMatch(text),
                        identifier = match.captures[1]?.string,
                        repetitionsString = match.captures[2]?.string,
                        repetitions = Int(repetitionsString) else { continue }

            case ~/"^end.*": break
            default: break
          }
        default: break
        }
      case let event as MIDINodeEvent:
        switch event.data {
          case .Add: guard let node = Node(event: event) else { continue }; nodes[event.identifier] = node
          case .Remove: nodes[event.identifier]?.removeTime = event.time
        }
      default: break
      }
    }

    let (addEvents, removeEvents) = track.nodeEvents.bisect({
      switch $0.data {
        case .Add: return true
        case .Remove: return false
      }
    })
    for node in addEvents.flatMap({Node(event: $0)}) { nodes[node.identifier] = node }
    for event in removeEvents { nodes[event.identifier]?.removeTime = event.time }
  }

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
    for node in nodes.flatMap({Node($0)}) { self.nodes[node.identifier] = node }
  }
}