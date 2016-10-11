//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/28/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

fileprivate protocol _MIDIEventContainer: Collection {
  associatedtype Events: RandomAccessCollection
  associatedtype Bag: RandomAccessCollection
  var events: Events { get }
}

extension _MIDIEventContainer
  where Events._Element == (key: BarBeatTime, value: Bag),
        Events.Iterator.Element == (key: BarBeatTime, value: Bag),
        Events:KeyValueBase,
        Events.Value == Bag,
        Events.LazyValues == LazyMapRandomAccessCollection<Events, Events.Value>,
        Events.Index == OrderedDictionaryIndex,
        Bag.Index == Int,
        Bag.IndexDistance == Int,
        Bag._Element == MIDIEvent,
        Bag.Iterator.Element == MIDIEvent,
        Index == MIDIEventContainerIndex
{


  @inline(__always) func _distance(from start: Index, to end: Index) -> Int {
    switch (start, end) {
    case let (start, end) where start == end:
      return 0
    case (var start, let end) where start < end:
      var result = 0
      while start.timeOffset < end.timeOffset {
        result += events[start.timeOffset].value.count &- start.eventOffset
        start.timeOffset += 1
        start.eventOffset = 0
      }
      result += end.eventOffset &- start.eventOffset
      return result
    case (let start, var end) /*where start > end*/:
      var result = 0
      while end.timeOffset < start.timeOffset {
        result += events[end.timeOffset].value.count &- end.eventOffset
        end.timeOffset += 1
        end.eventOffset = 0
      }
      result += start.eventOffset &- end.eventOffset
      return -result
    }
  }

  @inline(__always) func _index(after i: Index) -> Index {
    if events[i.timeOffset].value.endIndex > i.eventOffset &+ 1 {
      return Index(timeOffset: i.timeOffset, eventOffset: i.eventOffset &+ 1)
    } else if events.endIndex > i.timeOffset.advanced(by: 1) {
      return Index(timeOffset: i.timeOffset.advanced(by: 1), eventOffset: 0)
    } else {
      return endIndex
    }
  }

  @inline(__always) func _index(before i: Index) -> Index {
    if i.eventOffset > 0 {
      return Index(timeOffset: i.timeOffset, eventOffset: i.eventOffset &- 1)
    } else if i.timeOffset > 0 {
      return Index(timeOffset: i.timeOffset.advanced(by: -1),
                   eventOffset: events[i.timeOffset.advanced(by: -1)].value.endIndex &- 1)
    } else {
      fatalError("i is the startIndex, there is no before")
    }
  }

  @inline(__always) func _index(_ i: Index, offsetBy n: Int) -> Index {
    switch (i, n) {
    case (_, 0):
      return i
    case var (i, n) where n < 0:
      while n < 0 {
        switch i.eventOffset {
        case 0:
          i.timeOffset -= 1
          i.eventOffset = events[i.timeOffset].value.endIndex &- 1
          n += 1
        case let remainingInBag:
          i.eventOffset += Swift.max(n, -remainingInBag)
          n += remainingInBag
        }
      }
      return i
    case var (i, n) /*where n > 0*/:
      while n > 0 {
        switch i.eventOffset {
        case events[i.timeOffset].value.endIndex &- 1:
          i.timeOffset += 1
          i.eventOffset = 0
          n -= 1
        case let remainingInBag:
          i.eventOffset += Swift.min(n, remainingInBag)
          n -= remainingInBag
        }
      }
      return i
    }
  }

  @inline(__always) func _index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {

    func limitCheck(_ index: Index) -> Bool { return n < 0 ? index >= limit : index <= limit }

    switch (i, n) {
    case (_, 0):
      return i
    case var (i, n) where n < 0:
      while n < 0 {
        switch i.eventOffset {
        case 0:
          i.timeOffset -= 1
          i.eventOffset = events[i.timeOffset].value.endIndex &- 1
          guard limitCheck(i) else { return nil }
          n += 1
        case let remainingInBag:
          i.eventOffset += Swift.max(n, -remainingInBag)
          guard limitCheck(i) else { return nil }
          n += remainingInBag
        }
      }
      return i
    case var (i, n) /*where n > 0*/:
      while n > 0 {
        switch i.eventOffset {
        case events[i.timeOffset].value.endIndex &- 1:
          i.timeOffset += 1
          i.eventOffset = 0
          guard limitCheck(i) else { return nil }
          n -= 1
        case let remainingInBag:
          i.eventOffset += Swift.min(n, remainingInBag)
          guard limitCheck(i) else { return nil }
          n -= remainingInBag
        }
      }
      return i
    }
  }

  @inline(__always) func _formIndex(after i: inout Index) {
    if events[i.timeOffset].value.endIndex > i.eventOffset &+ 1 {
      i.eventOffset += 1
    } else if events.endIndex.value > i.timeOffset.value &+ 1 {
      i.timeOffset += 1; i.eventOffset = 0
    } else {
      i = endIndex
    }
  }

  @inline(__always) func _formIndex(before i: inout Index) {
    if i.eventOffset > 0 {
      i.eventOffset -= 1
    } else if i.timeOffset > 0 {
      i.timeOffset -= 1; i.eventOffset = events[i.timeOffset.advanced(by: -1)].value.endIndex &- 1
    } else {
      fatalError("i is the startIndex, there is no before")
    }
  }

  @inline(__always) func _formIndex(_ i: inout Index, offsetBy n: Int) {
    switch n {
    case 0:
      break
    case var n where n < 0:
      while n < 0 {
        switch i.eventOffset {
        case 0:
          i.timeOffset -= 1
          i.eventOffset = events[i.timeOffset].value.endIndex &- 1
          n += 1
        case let remainingInBag:
          i.eventOffset += Swift.max(n, -remainingInBag)
          n += remainingInBag
        }
      }
    case var n /*where n > 0*/:
      while n > 0 {
        switch i.eventOffset {
        case events[i.timeOffset].value.endIndex &- 1:
          i.timeOffset += 1
          i.eventOffset = 0
          n -= 1
        case let remainingInBag:
          i.eventOffset += Swift.min(n, remainingInBag)
          n -= remainingInBag
        }
      }
    }
  }

  @inline(__always) func _formIndex(_ i: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {
    func limitCheck(_ index: Index) -> Bool { return n < 0 ? index >= limit : index <= limit }

    switch n {
    case 0:
      return true
    case var n where n < 0:
      while n < 0 {
        switch i.eventOffset {
        case 0:
          i.timeOffset -= 1
          i.eventOffset = events[i.timeOffset].value.endIndex &- 1
          guard limitCheck(i) else { return false }
          n += 1
        case let remainingInBag:
          i.eventOffset += Swift.max(n, -remainingInBag)
          guard limitCheck(i) else { return false }
          n += remainingInBag
        }
      }
      return true
    case var n /*where n > 0*/:
      while n > 0 {
        switch i.eventOffset {
        case events[i.timeOffset].value.endIndex &- 1:
          i.timeOffset += 1
          i.eventOffset = 0
          guard limitCheck(i) else { return false }
          n -= 1
        case let remainingInBag:
          i.eventOffset += Swift.min(n, remainingInBag)
          guard limitCheck(i) else { return false }
          n -= remainingInBag
        }
      }
      return true
    }
  }

  var _metaEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({ if case .meta = $0 { return true } else { return false } })
        .map({$0.event as! MIDIEvent.MetaEvent})
    )
  }

  var _channelEvents: AnyBidirectionalCollection<MIDIEvent.ChannelEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({ if case .channel = $0 { return true } else { return false } })
        .map({$0.event as! MIDIEvent.ChannelEvent})
    )
  }

  var _nodeEvents: AnyBidirectionalCollection<MIDIEvent.MIDINodeEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({ if case .node = $0 { return true } else { return false } })
        .map({$0.event as! MIDIEvent.MIDINodeEvent})
    )
  }

  var _timeEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({
          if case .meta(let event) = $0 {
            switch event.data {
            case .timeSignature, .tempo: return true
            default: return false
            }
          } else { return false }
        })
        .map({$0.event as! MIDIEvent.MetaEvent})
    )
  }

}

struct MIDIEventContainer: _MIDIEventContainer {

  typealias Index = MIDIEventContainerIndex
  typealias Iterator = MIDIEventContainerIterator
  typealias SubSequence = MIDIEventContainerSlice

  fileprivate var events: SortedDictionary<BarBeatTime, Bag> = [:]

  init() {}

  private mutating func bag(forTime time: BarBeatTime) -> Bag {
    guard let bag = existingBag(forTime: time) else {
      let bag = Bag(); events[time] = bag; return bag
    }
    return bag
  }

  private func existingBag(forTime time: BarBeatTime) -> Bag? { return events[time] }

  func makeIterator() -> Iterator {
    return Iterator(slice: self[startIndex ..< endIndex])
  }

  var startIndex: Index { return Index(timeOffset: 0, eventOffset: 0) }
  var endIndex: Index {
    switch events.count - 1 {
      case -1: return startIndex
      case let n: return Index(timeOffset: OrderedDictionaryIndex(n), eventOffset: events[n].value.endIndex)
    }

  }

  subscript(index: Index) -> MIDIEvent {
    get { return events[index.timeOffset].value[index.eventOffset] }
    set { events[index.timeOffset].value[index.eventOffset] = newValue }
  }

  subscript(time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>? {
    guard let bag = existingBag(forTime: time) else { return nil }
    return AnyRandomAccessCollection<MIDIEvent>(bag.events)
  }

  subscript(subRange: Range<Index>) -> MIDIEventContainerSlice {
    return MIDIEventContainerSlice(events: events[subRange.lowerBound.timeOffset ... subRange.upperBound.timeOffset],
                                   subRange: subRange)
  }

  init<Source:Swift.Sequence>(events: Source) where Source.Iterator.Element == MIDIEvent {
    append(contentsOf: events)
  }

  mutating func append(_ event: MIDIEvent) {
    bag(forTime: event.time).append(event)
  }

  mutating func append<Source:Swift.Sequence>(contentsOf source: Source)
    where Source.Iterator.Element == MIDIEvent
  {
    for event in source { append(event) }
  }

  var minTime: BarBeatTime? { return events.keys.first }

  var maxTime: BarBeatTime? { return events.keys.last }

  mutating func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
    for (time, bag) in events {
      bag.removeEvents(matching: predicate)
      if bag.isEmpty { events[time] = nil }
    }
  }

  var metaEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { return _metaEvents }
  var channelEvents: AnyBidirectionalCollection<MIDIEvent.ChannelEvent> { return _channelEvents }
  var nodeEvents: AnyBidirectionalCollection<MIDIEvent.MIDINodeEvent> { return _nodeEvents }
  var timeEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { return _timeEvents }

  @inline(__always) func distance(from start: Index, to end: Index) -> Int {
    return _distance(from: start, to: end)
  }
  @inline(__always) func index(after i: Index) -> Index { return _index(after: i) }
  @inline(__always) func index(before i: Index) -> Index { return _index(before: i) }
  @inline(__always) func index(_ i: Index, offsetBy n: Int) -> Index { return _index(i, offsetBy: n) }
  @inline(__always) func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    return _index(i, offsetBy: n, limitedBy: limit)
  }
  @inline(__always) func formIndex(after i: inout Index) { _formIndex(after: &i) }
  @inline(__always) func formIndex(before i: inout Index) { _formIndex(before: &i) }
  @inline(__always) func formIndex(_ i: inout Index, offsetBy n: Int) { _formIndex(&i, offsetBy: n) }
  @inline(__always) func formIndex(_ i: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {
    return _formIndex(&i, offsetBy: n, limitedBy: limit)
  }

}


struct MIDIEventContainerIndex: Comparable {

  fileprivate(set) var timeOffset: OrderedDictionaryIndex
  fileprivate(set) var eventOffset: Int

  fileprivate init(timeOffset: OrderedDictionaryIndex, eventOffset: Int) {
    self.timeOffset = timeOffset
    self.eventOffset = eventOffset
  }

  static func ==(lhs: MIDIEventContainerIndex, rhs: MIDIEventContainerIndex) -> Bool {
    return lhs.timeOffset == rhs.timeOffset && lhs.eventOffset == rhs.eventOffset
  }

  static func <(lhs: MIDIEventContainerIndex, rhs: MIDIEventContainerIndex) -> Bool {
    return lhs.timeOffset < rhs.timeOffset || lhs.timeOffset == rhs.timeOffset && lhs.eventOffset < rhs.eventOffset
  }

}

struct MIDIEventContainerIterator: IteratorProtocol {

  private let slice: MIDIEventContainerSlice

  private var currentIndex: MIDIEventContainerSlice.Index

  fileprivate init(slice: MIDIEventContainerSlice) {
    self.slice = slice
    currentIndex = slice.startIndex
  }

  mutating func next() -> MIDIEvent? {
    guard currentIndex < slice.endIndex else { return nil }
    defer { slice.formIndex(after: &currentIndex) }
    return slice[currentIndex]
  }

}


struct MIDIEventContainerSlice: _MIDIEventContainer {

  typealias Index = MIDIEventContainerIndex
  typealias Iterator = MIDIEventContainerIterator
  typealias SubSequence = MIDIEventContainerSlice

  fileprivate typealias Bag = MIDIEventContainer.Bag

  let startIndex: Index
  let endIndex: Index

  fileprivate let events: SortedDictionary<BarBeatTime, Bag>.SubSequence

  fileprivate init(events: SortedDictionary<BarBeatTime, Bag>.SubSequence, subRange: Range<Index>) {
    startIndex = subRange.lowerBound
    endIndex = subRange.upperBound
    self.events = events
  }

  subscript(index: Index) -> MIDIEvent {
    precondition((startIndex..<endIndex).contains(index), "Index out of bounds: '\(index)'")
    return events[index.timeOffset].value[index.eventOffset]
  }


  subscript(subRange: Range<Index>) -> MIDIEventContainerSlice {
    return MIDIEventContainerSlice(events: events[startIndex.timeOffset...endIndex.timeOffset],
                                   subRange: subRange)
  }

  func makeIterator() -> MIDIEventContainerIterator {
    return MIDIEventContainerIterator(slice: self)
  }

  var metaEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { return _metaEvents }
  var channelEvents: AnyBidirectionalCollection<MIDIEvent.ChannelEvent> { return _channelEvents }
  var nodeEvents: AnyBidirectionalCollection<MIDIEvent.MIDINodeEvent> { return _nodeEvents }
  var timeEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { return _timeEvents }

  @inline(__always) func distance(from start: Index, to end: Index) -> Int {
    return _distance(from: start, to: end)
  }
  @inline(__always) func index(after i: Index) -> Index { return _index(after: i) }
  @inline(__always) func index(before i: Index) -> Index { return _index(before: i) }
  @inline(__always) func index(_ i: Index, offsetBy n: Int) -> Index { return _index(i, offsetBy: n) }
  @inline(__always) func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    return _index(i, offsetBy: n, limitedBy: limit)
  }
  @inline(__always) func formIndex(after i: inout Index) { _formIndex(after: &i) }
  @inline(__always) func formIndex(before i: inout Index) { _formIndex(before: &i) }
  @inline(__always) func formIndex(_ i: inout Index, offsetBy n: Int) { _formIndex(&i, offsetBy: n) }
  @inline(__always) func formIndex(_ i: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {
    return _formIndex(&i, offsetBy: n, limitedBy: limit)
  }
  
}

extension MIDIEventContainer {

  fileprivate class Bag: RandomAccessCollection {

    typealias Index = Int
    typealias Iterator = AnyIterator<MIDIEvent>
    typealias SubSequence = OrderedSet<MIDIEvent>.SubSequence

    typealias Indices = OrderedSet<MIDIEvent>.Indices

    private(set) var events: OrderedSet<MIDIEvent> = []

    subscript(index: Index) -> MIDIEvent {
      get { return events[index] }
      set { events[index] = newValue }
    }

    subscript(subRange: Range<Index>) -> SubSequence { return events[subRange] }

    var startIndex: Int { return events.startIndex }
    var endIndex: Int { return events.endIndex }

    var indices: Indices { return events.indices }

    func makeIterator() -> AnyIterator<MIDIEvent> {
      return AnyIterator(events.makeIterator())
    }

    func append(_ event: MIDIEvent) {
      events.append(event)
    }

    func append<Source:Swift.Sequence>(contentsOf source: Source)
      where Source.Iterator.Element == MIDIEvent
    {
      events.append(contentsOf: source)
    }

    func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
      for event in events where predicate(event) { events.remove(event) }
    }

    @inline(__always) func distance(from start: Int, to end: Int) -> Int { return end &- start }

    @inline(__always) func index(after i: Int) -> Int { return i &+ 1 }
    @inline(__always) func index(before i: Int) -> Int { return i &- 1 }
    @inline(__always) func index(_ i: Int, offsetBy n: Int) -> Int { return i &+ n }
    @inline(__always) func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
      switch (i &+ n, n < 0) {
        case (let iʹ, true) where iʹ >= limit, (let iʹ, false) where iʹ <= limit: return iʹ
        default: return nil
      }
    }
    @inline(__always) func formIndex(after i: inout Int) { i = i &+ 1 }
    @inline(__always) func formIndex(before i: inout Int) { i = i &- 1 }
    @inline(__always) func formIndex(_ i: inout Int, offsetBy n: Int) { i = i &+ n }
    @inline(__always) func formIndex(_ i: inout Int, offsetBy n: Int, limitedBy limit: Int) -> Bool {
      switch (i &+ n, n < 0) {
        case (let iʹ, true) where iʹ >= limit, (let iʹ, false) where iʹ <= limit: i = iʹ; return true
        default: return false
      }
    }

  }
  
}
