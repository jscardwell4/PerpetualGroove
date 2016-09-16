//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/28/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct MIDIEventContainer: Collection {

  typealias Bag = OrderedSet<MIDIEvent>
//  fileprivate final class Bag: _CollectionWrapperType, Collection, CustomStringConvertible {
//    var _base: OrderedSet<MIDIEvent> = []
//    func append(_ event: MIDIEvent) { _base.append(event) }
//    init() {}
//    subscript(position: Int) -> MIDIEvent {
//      get { return _base[position] }
//      set { _base[position] = newValue }
//    }
//    var description: String { return _base.description }
//  }

  fileprivate typealias Buffer = OrderedDictionary<BarBeatTime, Bag>

  typealias _Element = MIDIEvent

//  fileprivate final class Owner: NonObjectiveCBase {
//    var buffer: Buffer
//    override init() { buffer = Buffer(minimumCapacity: 1000) }
//    init(buffer: Buffer) { self.buffer = buffer }
//  }

  struct Index: Comparable {
    let bag: Int
    let position: Int
    fileprivate let buffer: Buffer

    func predecessor() -> Index {
      if position > 0 { return Index(bag: bag, position: position - 1, buffer: buffer) }
      else if bag > 0 {
        var previousBag = bag - 1
        var previousPosition = buffer[buffer.index(buffer.startIndex, offsetBy: previousBag)].value.count - 1
        while previousPosition < 0 {
          guard previousBag > 0 else { fatalError("Unable to provide predecessor for index \(self)") }
          previousBag -= 1
          previousPosition = buffer[buffer.index(buffer.startIndex, offsetBy: previousBag)].value.count - 1
        }
        return Index(bag: previousBag, position: previousPosition, buffer: buffer)
      } else {
        fatalError("Unable to provide predecessor for index \(self)")
      }
    }

    func successor() -> Index {
      if (position + 1) < buffer[buffer.index(buffer.startIndex, offsetBy: bag)].value.endIndex
        || buffer.index(buffer.startIndex, offsetBy: bag + 1) == buffer.endIndex
      {
        return Index(bag: bag, position: (position + 1), buffer: buffer)
      } else {
        return Index(bag: (bag + 1), position: buffer[bag + 1].1.startIndex, buffer: buffer)
      }
    }

    static func ==(lhs: Index, rhs: Index) -> Bool {
      return lhs.bag == rhs.bag && lhs.position == rhs.position
    }

    static func <(lhs: Index, rhs: Index) -> Bool {
      guard lhs.bag == rhs.bag else { return lhs.bag < rhs.bag }
      return lhs.position < rhs.position
    }
    

  }

  fileprivate var buffer: Buffer

  init() { buffer = Buffer() }

  init<S:Swift.Sequence>(events sequence: S) where S.Iterator.Element == MIDIEvent {
    var buffer: Buffer = [:]
    for event in sequence {
      var bag = buffer[event.time]
      if bag == nil { bag = Bag(); buffer[event.time] = bag }
      bag!.append(event)
    }
    self.buffer = buffer
  }

  typealias Iterator = AnyIterator<MIDIEvent>
  func makeIterator() -> AnyIterator<MIDIEvent> {
    return AnyIterator(FlattenCollection(buffer.values).makeIterator())
  }

//  private mutating func ensureUnique() {
//    guard !isUniquelyReferenced(&owner) else { return }
//    owner = Owner(events: owner.events)
//  }

  var minTime: BarBeatTime? { return buffer.keys.first }
  var maxTime: BarBeatTime? { return Array(buffer.keys).last }

  var count: Int { return buffer.reduce(0) {$0 + $1.1.count} }
  var startIndex: Index { return Index(bag: 0, position: 0, buffer: buffer) }
  var endIndex: Index {
    guard buffer.count > 0 else { return startIndex }
    assert(buffer[buffer.index(before: buffer.endIndex)].value.count > 0, "buffer contains empty bag")
    let bag = buffer.index(before: buffer.endIndex)
    let position = buffer[bag].value.endIndex
    return Index(bag: buffer.count - 1, position: position, buffer: buffer)
  }

  mutating func append(_ event: MIDIEvent) {
//    ensureUnique()
    var bag = buffer[event.time]
    if bag == nil { bag = Bag(); buffer[event.time] = bag }
    bag!.append(event)
  }

  mutating func appendEvents<S: Swift.Sequence>(_ events: S) where S.Iterator.Element == MIDIEvent {
    events.forEach { append($0) }
  }

  mutating func removeEventsMatching(_ predicate: (MIDIEvent) -> Bool) {
    var result: Buffer = [:]
    var countDidChange = false
    for (time, bag) in buffer {
      var resultBag = Bag()
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
      if !countDidChange && resultBag.count < bag.count { countDidChange = true }
    }

    guard countDidChange else { return }
//    ensureUnique()
    buffer = result
  }

  subscript(time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return buffer[time] }

  subscript(index: Index) -> MIDIEvent {
    get {
      assert(buffer.count > index.bag && buffer[buffer.index(buffer.startIndex, offsetBy: index.bag)].value.count > index.position, "Invalid index")
      return buffer[buffer.index(buffer.startIndex, offsetBy: index.bag)].value[index.position]
    }
    set {
      assert(buffer.count > index.bag && buffer[buffer.index(buffer.startIndex, offsetBy: index.bag)].value.count > index.position, "Invalid index")
//      ensureUnique()
      let i = buffer.index(buffer.startIndex, offsetBy: index.bag)
      var (time, bag) = buffer[i]
      bag[index.position] = newValue
      buffer[i] = (key: time, value: bag)
    }
  }

  var metaEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> {
    return lazy.filter({if case .meta = $0 { return true } else { return false }})
               .map({$0.event as! MetaEvent})
  }

  var channelEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, ChannelEvent> {
    return lazy.filter({if case .channel = $0 { return true } else { return false }})
               .map({$0.event as! ChannelEvent})
  }

  var nodeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MIDINodeEvent> {
    return lazy.filter({if case .node = $0 { return true } else { return false }})
               .map({$0.event as! MIDINodeEvent})
  }

  var timeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> {
    return lazy.filter({
                        if case .meta(let event) = $0 {
                          switch event.data {
                            case .timeSignature, .tempo: return true
                            default: return false
                          }
                        } else { return false }})
               .map({$0.event as! MetaEvent})
  }

  func index(after i: MIDIEventContainer.Index) -> MIDIEventContainer.Index {
    return i.successor()
  }
}

extension MIDIEventContainer: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: MIDIEvent...) { self.init(events: elements) }
}
extension MIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(map({$0.description})) }
}

