//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/28/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

/// Protocol for sharing implementation details between MIDIEventContainer and MIDIEventContainerSlice.
protocol _MIDIEventContainer: Collection, CustomStringConvertible {
  associatedtype Events: RandomAccessCollection
  var events: Events { get }
}

extension _MIDIEventContainer
  where Events.Element == (key: BarBeatTime, value: MIDIEventContainer.Bag),
        Events:KeyValueBase,
        Events.Value == MIDIEventContainer.Bag,
        Events.LazyValues == LazyMapCollection<Events, Events.Value>,
        Events.Index == Int,
        Index == Any2DIndex<Int, Int>
{

  // MARK: Implementations of Indexable methods.

  /// Returns the distance between two indexes.
  @inline(__always)
  func _distance(from start: Index, to end: Index) -> Int {

    switch (start, end) {

      case let (start, end) where start == end:
        return 0

      case (var start, let end) where start < end:
        var result = 0
        while start.index1 < end.index1 {
          result += events[start.index1].value.count &- start.index2
          start = Any2DIndex(start.index1 + 1, 0)
        }
        result += end.index2 &- start.index2
        return result

      case (let start, var end) /*where start > end*/:
        var result = 0
        while end.index1 < start.index1 {
          result += events[end.index1].value.count &- end.index2
          end = Any2DIndex(end.index1 + 1, 0)
        }
        result += start.index2 &- end.index2
        return -result
    }

  }

  @inline(__always)
  func _index(after i: Index) -> Index {
    var result = i
    _formIndex(after: &result)
    return result
  }

  @inline(__always)
  func _index(before i: Index) -> Index {
    var result = i
    _formIndex(before: &result)
    return result
  }

  @inline(__always)
  func _index(_ i: Index, offsetBy n: Int) -> Index {
    var result = i
    _formIndex(&result, offsetBy: n)
    return result
  }

  @inline(__always)
  func _index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    var result = i
    guard _formIndex(&result, offsetBy: n, limitedBy: limit) else { return nil }
    return result
  }

  @inline(__always)
  func _formIndex(after i: inout Index) {

    // Check whether there are more events in the bag at `i.index1`.
    if events[i.index1].value.endIndex > i.index2 &+ 1 {
      i = Index(i.index1, i.index2 &+ 1)
    }

      // Check whether there are more bags.
    else if events.endIndex > i.index1 + 1 {
      i = Index(i.index1 + 1, 0)
    }

      // Otherwise we've reached the end
    else {
      i = endIndex
    }
    
  }

  @inline(__always)
  func _formIndex(before i: inout Index) {

    // Check whether there are more events in the bag at `i.index1`.
    if i.index2 > 0 {
      i = Index(i.index1, i.index2 &- 1)
    }

    // Check whether there are more bags.
    else if i.index1 > 0 {
      i = Index(i.index1 - 1, events[i.index1 - 1].value.endIndex &- 1)
    }

    // Otherwise we are already at the start.
    else {
      fatalError("i is the startIndex, there is no before")
    }
    
  }

  @inline(__always) func _formIndex(_ index: inout Index, offsetBy n: Int) {

    // Switch by the requested offset.
    switch (index, n) {

      case (_, 0):
        // No offset, return the original index
        return

      case var (i, n) where n < 0:
        // Move backwards by `n`.
        while n < 0 {
          _formIndex(before: &i)
          n = n &+ 1
        }
        index = i

      case var (i, n) /*where n > 0*/:
        // Move forward by `n`.
        while n > 0 {
          _formIndex(after: &i)
          n = n &- 1
        }
        index = i

    }

  }

  @inline(__always)
  func _formIndex(_ index: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {

    // Switch by the requested offset.
    switch (index, n) {

      case (_, 0):
        // No offset, return the original index
        return true

      case var (i, n) where n < 0:
        // Move backwards by `n`.
        while n < 0 {
          _formIndex(before: &i)
          guard i >= limit else { return false }
          n = n &+ 1
        }
        index = i
        return true

      case var (i, n) /*where n > 0*/:
        // Move forward by `n`.
        while n > 0 {
          _formIndex(after: &i)
          guard i <= limit else { return false }
          n = n &- 1
        }
        index = i
        return true

    }

  }

  // MARK: Implementations of filtered event collection derived properties.

  var _metaEvents: AnyBidirectionalCollection<MetaEvent> {
    return AnyBidirectionalCollection(
      events.values.lazy.joined().filter {
        if case .meta = $0 { return true } else { return false } }
        .map {$0.event as! MetaEvent}
    )
  }

  var _channelEvents: AnyBidirectionalCollection<ChannelEvent> {
    return AnyBidirectionalCollection(
      events.values.lazy.joined().filter {
        if case .channel = $0 { return true } else { return false } }
        .map {$0.event as! ChannelEvent}
    )
  }

  var _nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> {
    return AnyBidirectionalCollection(
      events.values.lazy.joined().filter {
        if case .node = $0 { return true } else { return false } }
        .map {$0.event as! MIDINodeEvent}
    )
  }

  var _timeEvents: AnyBidirectionalCollection<MetaEvent> {
    return AnyBidirectionalCollection(events.values.lazy.joined().filter {
      if case .meta(let event) = $0 {
        switch event.data {
        case .timeSignature, .tempo: return true
        default: return false
        }
      } else { return false }
    }.map {$0.event as! MetaEvent})
  }

  var _tempoEvents: AnyBidirectionalCollection<MetaEvent> {
    return AnyBidirectionalCollection(
      _timeEvents.lazy.filter({if case .tempo = $0.data { return true } else { return false }})
    )
  }

  var _description: String {
    var result = "[\n"

    for (time, bag) in events {
      result += "\t\(time):\n"
      for event in bag {
        result += "\t\t\(event)\n"
      }
    }

    result += "\n]"

    return result
  }

}

// MARK: - Implementation for the event container
public struct MIDIEventContainer: _MIDIEventContainer {

  public typealias Index = Any2DIndex<Int, Int>
  public typealias Iterator = MIDIEventContainerIterator
  public typealias SubSequence = MIDIEventContainerSlice

  public var events: SortedDictionary<BarBeatTime, Bag> = [:]

  public init() {}

  /// Returns the existing bag for `time` if it exists; otherwise, creates and returns a new bag for `time`.
  private mutating func bag(forTime time: BarBeatTime) -> Bag {
    guard let bag = existingBag(forTime: time) else {
      let bag = Bag(); events[time] = bag; return bag
    }
    return bag
  }

  /// Returns the existing bag for `time` or `nil` if such a bag does not exist.
  private func existingBag(forTime time: BarBeatTime) -> Bag? { return events[time] }

  /// Returns an iterator over `startIndex ..< endIndex`.
  public func makeIterator() -> Iterator { return Iterator(slice: self[startIndex ..< endIndex]) }

  public var startIndex: Index { return Index(0, 0) }

  public var endIndex: Index {
    switch events.count - 1 {
      case -1: return startIndex
      case let n: return Index(Int(n), events[n].value.endIndex)
    }

  }

  /// Accessors for the event stored at `index`.
  public subscript(index: Index) -> MIDIEvent {
    get { return events[index.index1].value[index.index2] }
    set { events[index.index1].value[index.index2] = newValue }
  }

  /// Returns the collection of events contained by the bag for `time` or `nil` if the bag does not exist.
  public subscript(time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>? {
    guard let bag = existingBag(forTime: time) else { return nil }
    return AnyRandomAccessCollection<MIDIEvent>(bag.events)
  }

  /// Returns a slice over `subRange`.
  public subscript(subRange: Range<Index>) -> SubSequence {
    return SubSequence(events: events[subRange.lowerBound.index1 ... subRange.upperBound.index1],
                       subRange: subRange)
  }

  /// Initializes the container from a sequence of events.
  public init<Source>(events: Source)
    where Source:Swift.Sequence, Source.Iterator.Element == MIDIEvent
  {
    append(contentsOf: events)
  }

  /// Appends `event` to the container.
  public mutating func append(_ event: MIDIEvent) {
    bag(forTime: event.time).append(event)
  }

  /// Appends a sequence of events to the container.
  public mutating func append<Source>(contentsOf source: Source)
    where Source:Swift.Sequence, Source.Iterator.Element == MIDIEvent
  {
    for event in source { append(event) }
  }

  /// The minimum time for which a bag exists in the collection.
  public var minTime: BarBeatTime? { events.keys.first }

  /// The maximum time for which a bag exists in the collection.
  public var maxTime: BarBeatTime? { events.keys.last }

  /// Removes all events in the container that satisfy `predicate`. Any empty bags are also removed.
  public  mutating func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
    for (time, bag) in events {
      bag.removeEvents(matching: predicate)
      if bag.isEmpty { events[time] = nil }
    }
  }

  // MARK: Derived properties corresponding to _MIDIEventContainer implementations.
  public var metaEvents: AnyBidirectionalCollection<MetaEvent> { _metaEvents }
  public var channelEvents: AnyBidirectionalCollection<ChannelEvent> { _channelEvents }
  public var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> { _nodeEvents }
  public var timeEvents: AnyBidirectionalCollection<MetaEvent> { _timeEvents }
  public var tempoEvents: AnyBidirectionalCollection<MetaEvent> { _tempoEvents }

  // MARK: Index-related functions corresponding to _MIDIEventContainer implementations.
  @inline(__always) public func distance(from start: Index, to end: Index) -> Int {
    _distance(from: start, to: end)
  }
  @inline(__always) public func index(after i: Index) -> Index { _index(after: i) }
  @inline(__always) public func index(before i: Index) -> Index { _index(before: i) }
  @inline(__always) public func index(_ i: Index, offsetBy n: Int) -> Index { _index(i, offsetBy: n) }
  @inline(__always) public func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    _index(i, offsetBy: n, limitedBy: limit)
  }
  @inline(__always) public func formIndex(after i: inout Index) { _formIndex(after: &i) }
  @inline(__always) public func formIndex(before i: inout Index) { _formIndex(before: &i) }
  @inline(__always) public func formIndex(_ i: inout Index, offsetBy n: Int) { _formIndex(&i, offsetBy: n) }
  @inline(__always) public func formIndex(_ i: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {
    return _formIndex(&i, offsetBy: n, limitedBy: limit)
  }

  public var description: String { _description }

}

public struct MIDIEventContainerIterator: IteratorProtocol {

  private let slice: MIDIEventContainerSlice

  private var currentIndex: MIDIEventContainerSlice.Index

  fileprivate init(slice: MIDIEventContainerSlice) {
    self.slice = slice
    currentIndex = slice.startIndex
  }

  public mutating func next() -> MIDIEvent? {
    guard currentIndex < slice.endIndex else { return nil }
    defer { slice.formIndex(after: &currentIndex) }
    return slice[currentIndex]
  }

}

public struct MIDIEventContainerSlice: _MIDIEventContainer {

  public typealias Index = Any2DIndex<Int, Int>
  public typealias Iterator = MIDIEventContainerIterator
  public typealias SubSequence = MIDIEventContainerSlice

  public typealias Bag = MIDIEventContainer.Bag

  public let startIndex: Index
  public let endIndex: Index

  public let events: SortedDictionary<BarBeatTime, Bag>.SubSequence

  fileprivate init(events: SortedDictionary<BarBeatTime, Bag>.SubSequence, subRange: Range<Index>) {
    startIndex = subRange.lowerBound
    endIndex = subRange.upperBound
    self.events = events
  }

  public subscript(index: Index) -> MIDIEvent {
    precondition((startIndex..<endIndex).contains(index), "Index out of bounds: '\(index)'")
    return events[index.index1].value[index.index2]
  }


  public subscript(subRange: Range<Index>) -> SubSequence {
    return SubSequence(events: events[startIndex.index1...endIndex.index1], subRange: subRange)
  }

  public func makeIterator() -> Iterator { return Iterator(slice: self) }

  public var metaEvents: AnyBidirectionalCollection<MetaEvent> { _metaEvents }
  public var channelEvents: AnyBidirectionalCollection<ChannelEvent> { _channelEvents }
  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> { _nodeEvents }
  public var timeEvents: AnyBidirectionalCollection<MetaEvent> { _timeEvents }
  public var tempoEvents: AnyBidirectionalCollection<MetaEvent> { _tempoEvents }

  @inline(__always) public func distance(from start: Index, to end: Index) -> Int {
    return _distance(from: start, to: end)
  }
  @inline(__always) public func index(after i: Index) -> Index { return _index(after: i) }
  @inline(__always) public func index(before i: Index) -> Index { return _index(before: i) }
  @inline(__always) public func index(_ i: Index, offsetBy n: Int) -> Index { return _index(i, offsetBy: n) }
  @inline(__always) public func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    return _index(i, offsetBy: n, limitedBy: limit)
  }
  @inline(__always) public func formIndex(after i: inout Index) { _formIndex(after: &i) }
  @inline(__always) public func formIndex(before i: inout Index) { _formIndex(before: &i) }
  @inline(__always) public func formIndex(_ i: inout Index, offsetBy n: Int) { _formIndex(&i, offsetBy: n) }
  @inline(__always) public func formIndex(_ i: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {
    return _formIndex(&i, offsetBy: n, limitedBy: limit)
  }
  
  public var description: String { return _description }

}

// MARK: - MIDIEventContainer.Bag
extension MIDIEventContainer {

  /// A class that wraps an `OrderedSet<MIDIEvent>` structure for maintaining 
  /// a uniqued and ordered collection of events.
  public class Bag: RandomAccessCollection {

    public typealias Index = Int
    public typealias Iterator = AnyIterator<MIDIEvent>
    public typealias SubSequence = OrderedSet<MIDIEvent>.SubSequence

    public typealias Indices = OrderedSet<MIDIEvent>.Indices

    /// The events contained by the bag.
    public private(set) var events: OrderedSet<MIDIEvent> = []

    /// Accessors for the event at `index`.
    public subscript(index: Index) -> MIDIEvent {
      get { return events[index] }
      set { events[index] = newValue }
    }

    /// Returns a collection of the events within `subRange`.
    public subscript(subRange: Range<Index>) -> SubSequence { return events[subRange] }

    public var startIndex: Int { return events.startIndex }
    public var endIndex: Int { return events.endIndex }

    public var indices: Indices { return events.indices }

    /// Returns an iterator over `events`.
    public func makeIterator() -> AnyIterator<MIDIEvent> {
      return AnyIterator(events.makeIterator())
    }

    /// Appends `event` to the bag.
    public func append(_ event: MIDIEvent) { events.append(event) }

    /// Appends a sequence of events to the bag.
    public func append<Source>(contentsOf source: Source)
      where Source:Swift.Sequence, Source.Iterator.Element == MIDIEvent
    {
      events.append(contentsOf: source)
    }

    /// Removes any events from the bag that satisfy `predicate`.
    public func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
      for event in events where predicate(event) { events.remove(event) }
    }

    // MARK: Index-related method implementations.

    @inline(__always) public func distance(from start: Int, to end: Int) -> Int { return end &- start }

    @inline(__always) public func index(after i: Int) -> Int { return i &+ 1 }
    @inline(__always) public func index(before i: Int) -> Int { return i &- 1 }
    @inline(__always) public func index(_ i: Int, offsetBy n: Int) -> Int { return i &+ n }
    @inline(__always) public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
      switch (i &+ n, n < 0) {
        case (let iʹ, true) where iʹ >= limit, (let iʹ, false) where iʹ <= limit: return iʹ
        default: return nil
      }
    }
    @inline(__always) public func formIndex(after i: inout Int) { i = i &+ 1 }
    @inline(__always) public func formIndex(before i: inout Int) { i = i &- 1 }
    @inline(__always) public func formIndex(_ i: inout Int, offsetBy n: Int) { i = i &+ n }
    @inline(__always) public func formIndex(_ i: inout Int, offsetBy n: Int, limitedBy limit: Int) -> Bool {
      switch (i &+ n, n < 0) {
        case (let iʹ, true) where iʹ >= limit, (let iʹ, false) where iʹ <= limit: i = iʹ; return true
        default: return false
      }
    }

  }
  
}
