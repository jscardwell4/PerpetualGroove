//
//  GrooveNode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/2/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct GrooveNode: JSONValueConvertible, JSONValueInitializable {
  typealias Identifier = MIDINodeEvent.Identifier
  let identifier: Identifier
  var trajectory: Trajectory
  var generator: AnyMIDIGenerator
  var addTime: BarBeatTime
  var removeTime: BarBeatTime? {
    didSet { if let time = removeTime , time < addTime { removeTime = nil } }
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

  var addEvent: MIDINodeEvent {
    return MIDINodeEvent(.add(identifier: identifier, trajectory: trajectory, generator: generator), addTime)
  }

  var removeEvent: MIDINodeEvent? {
    guard let removeTime = removeTime else { return nil }
    return MIDINodeEvent(.remove(identifier: identifier), removeTime)
  }

  init?(event: MIDINodeEvent) {
    guard case let .add(identifier, trajectory, generator) = event.data else { return nil }
    addTime = event.time
    self.identifier = identifier
    self.trajectory = trajectory
    self.generator = generator
  }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
      let identifier = MIDINodeEvent.Identifier(dict["identifier"]),
      let trajectory = Trajectory(dict["trajectory"]),
      let generator = AnyMIDIGenerator(dict["generator"]),
      let addTime = BarBeatTime(dict["addTime"])
      else { return nil }
    self.identifier = identifier
    self.generator = generator
    self.trajectory = trajectory
    self.addTime = addTime
    switch dict["removeTime"] {
    case .string(let s)?: removeTime = BarBeatTime(rawValue: s)
    case .null?: fallthrough
    default: removeTime = nil
    }
  }
}
