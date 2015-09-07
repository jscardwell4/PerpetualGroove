//
//  MIDINodeEvent.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct MIDINodeEvent: TrackEvent {
  var time: CABarBeatTime = .start
  let data: Data
  var bytes: [Byte] { return Byte(0xFF).bytes + [0x07] + data.length.bytes + data.bytes }

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "data: \(data)",
      "time: \(time)(\(time.doubleValue); \(time.tickValue))"
    )
    result += "\n}"
    return result
  }

  /**
  Initializer that taks the event's data

  - parameter d: MetaEventData
  */
  init(_ d: Data) { data = d }


  /**
  Initializer that takes a `VariableLengthQuantity` as well as the event's data

  - parameter t: CABarBeatTime
  - parameter d: Data
  */
  init(barBeatTime t: CABarBeatTime, data d: Data) { time = t; data = d }

  enum Data: Equatable {
    case Add(identifier: UInt, placement: MIDINode.Placement)
    case Remove(identifier: UInt)

    var bytes: [Byte] {
      switch self {
        case let .Add(identifier, placement): return identifier.bytes + placement.bytes
        case let .Remove(identifier): return identifier.bytes
      }
    }
    
    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
  }
}

func ==(lhs: MIDINodeEvent.Data, rhs: MIDINodeEvent.Data) -> Bool {
  switch (lhs, rhs) {
    case (.Add, .Remove), (.Remove, .Add):                            return false
    case let (.Add(i1, p1), .Add(i2, p2)) where i1 != i2 || p1 != p2: return false
    case let (.Remove(i1), .Remove(i2)) where i1 != i2:               return false
    default:                                                          return true
  }
}