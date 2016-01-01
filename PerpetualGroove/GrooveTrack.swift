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

  var nodes: [UInt64:Node] = [:]

  struct Node: JSONValueConvertible, JSONValueInitializable {
    let identifier: UInt64
    var trajectory: Trajectory
    var generator: ObjectJSONValue
    var addTime: CABarBeatTime
    var removeTime: CABarBeatTime? { didSet { if let time = removeTime where time < addTime { removeTime = nil } } }

    var jsonValue: JSONValue {
      return ObjectJSONValue([
        "identifier": identifier.jsonValue,
        "generator": generator.jsonValue,
        "trajectory": trajectory.jsonValue,
        "addTime": addTime.jsonValue,
        "removeTime": removeTime?.jsonValue ?? JSONValue.Null
        ]).jsonValue
    }

    init?(event: MIDINodeEvent) {
      guard case let .Add(identifier, trajectory, generator) = event.data else { return nil }
      addTime = event.time
      self.identifier = identifier
      self.trajectory = trajectory
      self.generator = ObjectJSONValue(generator.jsonValue)!
    }

    init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              identifier = UInt64(dict["identifier"]),
              trajectory = Trajectory(dict["trajectory"]),
              generator = ObjectJSONValue(dict["generator"]),
              addTime = CABarBeatTime(dict["addTime"])
      else { return nil }
      self.identifier = identifier
      self.generator = generator
      self.trajectory = trajectory
      self.addTime = addTime
      switch dict["removeTime"] {
        case .String(let s)?: removeTime = CABarBeatTime(rawValue: s)
        case .Null?: fallthrough
        default: removeTime = nil
      }
    }
  }

  init(track: InstrumentTrack) {
    name = track.name
    instrument = ObjectJSONValue(track.instrument.jsonValue)!
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
  var jsonValue: JSONValue { return [ "name": name, "instrument": instrument, "nodes": Array(nodes.values) ] }
}

extension GrooveTrack: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              name = String(dict["name"]),
              instrument = ObjectJSONValue(dict["instrument"]),
              nodes = ArrayJSONValue(dict["nodes"]) else { return nil }
    self.name = name
    self.instrument = instrument
    for node in nodes.flatMap({Node($0)}) { self.nodes[node.identifier] = node }
  }
}