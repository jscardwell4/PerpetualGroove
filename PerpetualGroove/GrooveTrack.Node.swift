//
//  GrooveTrackNode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/2/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

extension GrooveTrack {
  struct Node: JSONValueConvertible, JSONValueInitializable {
    let identifier: MIDINodeEvent.Identifier
    var trajectory: Trajectory
    var generator: ObjectJSONValue
    var addTime: CABarBeatTime
    var removeTime: CABarBeatTime? {
      didSet { if let time = removeTime where time < addTime { removeTime = nil } }
    }

    var jsonValue: JSONValue {
      return [
        "identifier": identifier,
        "generator": generator,
        "trajectory": trajectory,
        "addTime": addTime,
        "removeTime": removeTime
        ]
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
        identifier = MIDINodeEvent.Identifier(dict["identifier"]),
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
}