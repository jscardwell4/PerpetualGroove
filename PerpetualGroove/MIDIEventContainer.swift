//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/28/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct MIDIEventContainer: CollectionType {

  private final class Bag: _CollectionWrapperType, CollectionType, CustomStringConvertible {
    var _base: OrderedSet<MIDIEvent> = []
    func append(event: MIDIEvent) { _base.append(event) }
    init() {}
    subscript(position: Int) -> MIDIEvent {
      get { return _base[position] }
      set { _base[position] = newValue }
    }
    var description: String { return _base.description }
  }

  private typealias Buffer = OrderedDictionary<BarBeatTime, Bag>

  typealias _Element = MIDIEvent

  private final class Owner: NonObjectiveCBase {
    var buffer: Buffer
    override init() { buffer = Buffer(minimumCapacity: 1000) }
    init(buffer: Buffer) { self.buffer = buffer }
  }

  struct Index: BidirectionalIndexType, Comparable {
    let bag: Int
    let position: Int
    private let buffer: Buffer

    func predecessor() -> Index {
      if position > 0 { return Index(bag: bag, position: position - 1, buffer: buffer) }
      else if bag > 0 {
        var previousBag = bag - 1
        var previousPosition = buffer[previousBag].1.count - 1
        while previousPosition < 0 {
          guard previousBag > 0 else { fatalError("Unable to provide predecessor for index \(self)") }
          previousBag -= 1
          previousPosition = buffer[previousBag].1.count - 1
        }
        return Index(bag: previousBag, position: previousPosition, buffer: buffer)
      } else {
        fatalError("Unable to provide predecessor for index \(self)")
      }
    }

    func successor() -> Index {
      if position.successor() < buffer[bag].1.endIndex || bag.successor() == buffer.endIndex {
        return Index(bag: bag, position: position.successor(), buffer: buffer)
      } else {
        return Index(bag: bag.successor(), position: buffer[bag.successor()].1.startIndex, buffer: buffer)
      }
    }
  }

  private var buffer: Buffer

  init() { buffer = Buffer() }

  init<S:SequenceType where S.Generator.Element == MIDIEvent>(events sequence: S) {
    var buffer: Buffer = [:]
    for event in sequence {
      var bag = buffer[event.time]
      if bag == nil { bag = Bag(); buffer[event.time] = bag }
      bag!.append(event)
    }
    self.buffer = buffer
  }

//  private mutating func ensureUnique() {
//    guard !isUniquelyReferenced(&owner) else { return }
//    owner = Owner(events: owner.events)
//  }

  var minTime: BarBeatTime? { return buffer.keys.first }
  var maxTime: BarBeatTime? { return buffer.keys.last }

  var count: Int { return buffer.reduce(0) {$0 + $1.1.count} }
  var startIndex: Index { return Index(bag: 0, position: 0, buffer: buffer) }
  var endIndex: Index {
    guard buffer.count > 0 else { return startIndex }
    assert(buffer[buffer.count - 1].1.count > 0, "buffer contains empty bag")
    let bag = buffer.count - 1
    let position = buffer[bag].1.endIndex
    return Index(bag: bag, position: position, buffer: buffer)
  }

  mutating func append(event: MIDIEvent) {
//    ensureUnique()
    var bag = buffer[event.time]
    if bag == nil { bag = Bag(); buffer[event.time] = bag }
    bag!.append(event)
  }

  mutating func appendEvents<S: SequenceType where S.Generator.Element == MIDIEvent>(events: S) {
    events.forEach { append($0) }
  }

  mutating func removeEventsMatching(predicate: (MIDIEvent) -> Bool) {
    var result: Buffer = [:]
    var countDidChange = false
    for (time, bag) in buffer {
      let resultBag = Bag()
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
      if !countDidChange && resultBag.count < bag.count { countDidChange = true }
    }

    guard countDidChange else { return }
//    ensureUnique()
    buffer = result
  }

  subscript(time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return buffer[time]?._base }

  subscript(index: Index) -> MIDIEvent {
    get {
      assert(buffer.count > index.bag && buffer[index.bag].1.count > index.position, "Invalid index")
      return buffer[index.bag].1[index.position]
    }
    set {
      assert(buffer.count > index.bag && buffer[index.bag].1.count > index.position, "Invalid index")
//      ensureUnique()
      let (_, bag) = buffer[index.bag]
      bag[index.position] = newValue
    }
  }

  var metaEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> {
    return lazy.filter({if case .Meta = $0 { return true } else { return false }})
               .map({$0.event as! MetaEvent})
  }

  var channelEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, ChannelEvent> {
    return lazy.filter({if case .Channel = $0 { return true } else { return false }})
               .map({$0.event as! ChannelEvent})
  }

  var nodeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MIDINodeEvent> {
    return lazy.filter({if case .Node = $0 { return true } else { return false }})
               .map({$0.event as! MIDINodeEvent})
  }

  var timeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> {
    return lazy.filter({
                        if case .Meta(let event) = $0 {
                          switch event.data {
                            case .TimeSignature, .Tempo: return true
                            default: return false
                          }
                        } else { return false }})
               .map({$0.event as! MetaEvent})
  }

}

func ==(lhs: MIDIEventContainer.Index, rhs: MIDIEventContainer.Index) -> Bool {
  return lhs.bag == rhs.bag && lhs.position == rhs.position
}

func <(lhs: MIDIEventContainer.Index, rhs: MIDIEventContainer.Index) -> Bool {
  guard lhs.bag == rhs.bag else { return lhs.bag < rhs.bag }
  return lhs.position < rhs.position
}

extension MIDIEventContainer: ArrayLiteralConvertible {
  init(arrayLiteral elements: MIDIEvent...) { self.init(events: elements) }
}
extension MIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(map({$0.description})) }
}

