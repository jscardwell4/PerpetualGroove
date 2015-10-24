//
//  MIDIEventMap.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct MIDIEventMap: CollectionType {

  private var _map: [CABarBeatTime:[MIDIEvent]] = [:]

  var startIndex: DictionaryIndex<CABarBeatTime, [MIDIEvent]> { return _map.startIndex }
  var endIndex: DictionaryIndex<CABarBeatTime, [MIDIEvent]> { return _map.endIndex }
  var times: LazyMapCollection<Dictionary<CABarBeatTime, [MIDIEvent]>, CABarBeatTime> { return _map.keys }

  func eventsForTime(time: CABarBeatTime) -> [MIDIEvent]? { return _map[time] }

  /**
   subscript:

   - parameter position: DictionaryIndex<CABarBeatTime, [MIDIEvent]>

   - returns: (CABarBeatTime, [MIDIEvent])
   */
  subscript(position: DictionaryIndex<CABarBeatTime, [MIDIEvent]>) -> (CABarBeatTime, [MIDIEvent]) {
    return _map[position]
  }

  /**
  subscript:

  - parameter time: CABarBeatTime

  - returns: [MIDIEvent]?
  */
//  subscript(time: CABarBeatTime) -> [MIDIEvent]? {
//    get { return nil }// _map[time] }
//    set {  }//_map[time] = newValue }
//  }

  /**
  generate

  - returns: DictionaryGenerator<CABarBeatTime, [MIDIEvent]>
  */
  func generate() -> DictionaryGenerator<CABarBeatTime, [MIDIEvent]> { return _map.generate() }

  /**
  insert:

  - parameter events: S
  */
  mutating func insert(events: [MIDIEvent]) {
    for event in events {
      var eventBag: [MIDIEvent] = _map[event.time] ?? []
      eventBag.append(event)
      _map[event.time] = eventBag
    }
  }

}

extension MIDIEventMap: CustomStringConvertible {
  var description: String {
    return "\n".join(_map.map({ time, events in "\(time): [\(", ".join(events.map({$0.description})))]"}))
  }
}
