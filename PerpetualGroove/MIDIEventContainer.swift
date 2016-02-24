//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// A hash-based mapping from `BarBeatTime` to `Bag` instances.
//private struct _MIDIEventContainer : CollectionType, DictionaryLiteralConvertible {
//
//  typealias SubSequence = _MIDIEventContainer
//  var buffer: Buffer
//
//  /// Create an empty dictionary.
//  init() { self = _MIDIEventContainer(minimumCapacity: 0) }
//
//  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }
//
//  init(buffer: Buffer) { self.buffer = buffer }
//
//  var startIndex: BagIndex {
//    return buffer.startIndex
//  }
//
//  var endIndex: BagIndex { return buffer.endIndex }
//
//  func indexForTime(time: BarBeatTime) -> BagIndex? { return buffer.indexForTime(time) }
//
//  subscript(position: BagIndex) -> (BarBeatTime, Bag) {
//    return buffer.assertingGet(position)
//  }
//
//  subscript(time: BarBeatTime) -> Bag? {
//    get {
//      return buffer.maybeGet(time)
//    }
//    set {
//      if let x = newValue {
//        // FIXME(performance): this loads and discards the old value.
//        buffer.updateBag(x, forTime: time)
//      }
//      else {
//        // FIXME(performance): this loads and discards the old value.
//        buffer.removeBagForTime(time)
//      }
//    }
//  }
//
//  mutating func updateBag(bag: Bag, forTime time: BarBeatTime) -> Bag? {
//    return buffer.updateBag(bag, forTime: time)
//  }
//
//  mutating func removeAtIndex(index: BagIndex) -> (BarBeatTime, Bag) {
//    return buffer.removeAtIndex(index)
//  }
//
//  mutating func removeBagForTime(time: BarBeatTime) -> Bag? {
//    return buffer.removeBagForTime(time)
//  }
//
//  mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
//    buffer.removeAll(keepCapacity: keepCapacity)
//  }
//
//  /// The number of entries in the dictionary.
//  ///
//  /// - Complexity: O(1).
//  var count: Int { return buffer.count }
//
//  func generate() -> Generator {
//    return Generator()
//  }
//
//  @effects(readonly)
//  init(dictionaryLiteral elements: (BarBeatTime, Bag)...) {
//    self.init(buffer: Buffer.fromArray(elements))
//  }
//
////  var times: LazyMapCollection<_MIDIEventContainer, BarBeatTime> { return buffer.lazy.map { $0.0 } }
////  var bags: LazyMapCollection<_MIDIEventContainer, Bag> { return buffer.lazy.map { $0.1 } }
//
//  var isEmpty: Bool { return count == 0 }
//  
//}
//
//extension _MIDIEventContainer {
//  struct Generator: GeneratorType {
//    private mutating func next() -> MIDIEvent? {
//      return nil
//    }
//  }
//}
//
//extension _MIDIEventContainer {
//  private struct BagIndex: ForwardIndexType, Comparable {
//    let buffer: Buffer
//    let offset: Int
//
//    func successor() -> BagIndex {
//      var i = offset + 1
//      // FIXME: Can't write the simple code pending
//      // <rdar://problem/15484639> Refcounting bug
//      while i < buffer.capacity /*&& !nativeStorage[i]*/ {
//        // FIXME: workaround for <rdar://problem/15484639>
//        if buffer.isInitializedEntry(i) {
//          break
//        }
//        // end workaround
//        i += 1
//      }
//      return BagIndex(buffer: buffer, offset: i)
//    }
//  }
//}
//
//private func ==(lhs: _MIDIEventContainer.BagIndex, rhs: _MIDIEventContainer.BagIndex) -> Bool {
//  assert(lhs.buffer.storage === rhs.buffer.storage)
//  return lhs.offset == rhs.offset
//}
//
//private func <(lhs: _MIDIEventContainer.BagIndex, rhs: _MIDIEventContainer.BagIndex) -> Bool {
//  assert(lhs.buffer.storage === rhs.buffer.storage)
//  return lhs.offset < rhs.offset
//}
//
//extension _MIDIEventContainer {
  private final class Bag: Hashable {
    var time: BarBeatTime { return events.first?.time ?? .start1 }
    var events: OrderedSet<MIDIEvent>
    init(events: OrderedSet<MIDIEvent> = []) { self.events = events }
    var hashValue: Int { return time.hashValue }
  }
//}
//
//extension _MIDIEventContainer {
//  struct EventIndex {
//    let container: _MIDIEventContainer
//    let bagIndex: BagIndex
//    let index: Int
//
//    func successor() -> EventIndex {
//      let bag = buffer[bagIndex].1
//      var i = offset + 1
//      // FIXME: Can't write the simple code pending
//      // <rdar://problem/15484639> Refcounting bug
//      while i < buffer.capacity /*&& !nativeStorage[i]*/ {
//        // FIXME: workaround for <rdar://problem/15484639>
//        if buffer.isInitializedEntry(i) {
//          break
//        }
//        // end workaround
//        i += 1
//      }
//      return BagIndex(buffer: buffer, offset: i)
//    }
//  }
//}
private func ==(lhs: Bag, rhs: Bag) -> Bool { return lhs === rhs }

//extension _MIDIEventContainer {
  private typealias StorageHead = (count: Int, capacity: Int, maxLoadFactorInverse: Double)
  private final class Storage: ManagedBuffer<StorageHead, UInt8> {

    static func bytesForBitMap(capacity: Int) -> Int {
      let numWords = BitMap.wordsFor(capacity)
      return numWords * sizeof(UInt) + alignof(UInt)
    }

    static func bytesForTimes(capacity: Int) -> Int {
      let padding = max(0, alignof(BarBeatTime) - alignof(UInt))
      return strideof(BarBeatTime) * capacity + padding
    }

    static func bytesForTimeMap(capacity: Int) -> Int {
      let maxPrevAlignment = max(alignof(BarBeatTime), alignof(UInt))
      let padding = max(0, alignof(Int) - maxPrevAlignment)
      return strideof(Int) * capacity + padding
    }

    static func bytesForBags(capacity: Int) -> Int {
      let maxPrevAlignment = max(alignof(BarBeatTime), alignof(UInt), alignof(Int))
      let padding = max(0, alignof(Bag) - maxPrevAlignment)
      return strideof(Bag) * capacity + padding
    }

    var capacity: Int { return withUnsafeMutablePointerToValue {$0.memory.capacity } }

    var count: Int {
      get { return withUnsafeMutablePointerToValue { $0.memory.count } }
      set { withUnsafeMutablePointerToValue { $0.memory.count = newValue } }
    }

    var maxLoadFactorInverse: Double {
      return withUnsafeMutablePointerToValue { $0.memory.maxLoadFactorInverse }
    }

    var bitMap: UnsafeMutablePointer<UInt> {
        let start = UInt(withUnsafeMutablePointerToElements({$0._rawValue}))
        let alignment = UInt(alignof(UInt))
        let alignMask = alignment &- UInt(1)
        return UnsafeMutablePointer<UInt>( bitPattern:(start &+ alignMask) & ~alignMask)
    }

    var times: UnsafeMutablePointer<BarBeatTime> {
      let start = UInt(withUnsafeMutablePointerToElements({$0._rawValue}))
               &+ UInt(BitMap.wordsFor(capacity)) &* UInt(strideof(UInt))
      let alignment = UInt(alignof(BarBeatTime))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<BarBeatTime>(bitPattern:(start &+ alignMask) & ~alignMask)
    }

    var timeMap: UnsafeMutablePointer<Int> {
      let start = UInt(withUnsafeMutablePointerToElements({$0._rawValue}))
               &+ UInt(BitMap.wordsFor(capacity)) &* UInt(strideof(UInt))
               &+ UInt(capacity) &* UInt(strideof(BarBeatTime))
      let alignment = UInt(alignof(Int))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<Int>(bitPattern:(start &+ alignMask) & ~alignMask)
    }

    var bags: UnsafeMutablePointer<Bag> {
      let start = UInt(withUnsafeMutablePointerToElements({$0._rawValue}))
               &+ UInt(BitMap.wordsFor(capacity)) &* UInt(strideof(UInt))
               &+ UInt(capacity) &* UInt(strideof(BarBeatTime))
      let alignment = UInt(alignof(Bag))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<Bag>(bitPattern:(start &+ alignMask) & ~alignMask)
    }

    class func create(capacity: Int) -> Storage {
      let requiredCapacity = bytesForBitMap(capacity) + bytesForTimes(capacity) + bytesForBags(capacity)

      let storage = super.create(requiredCapacity) { _ in
        (count: 0, capacity: capacity, maxLoadFactorInverse: defaultMaxLoadFactorInverse)
      } as! Storage

      BitMap(storage: storage.bitMap, bitCount: capacity).initializeToZero()
      return storage
    }

    deinit {
      let capacity = self.capacity
      let initializedEntries = BitMap(storage: bitMap, bitCount: capacity)
      let times = self.times
      let bags = self.bags

      if !_isPOD(BarBeatTime) {
        for i in 0 ..< capacity where initializedEntries[i] { (times+i).destroy() }
      }

      if !_isPOD(Bag) {
        for i in 0 ..< capacity where initializedEntries[i] { (bags + i).destroy() }
      }

      withUnsafeMutablePointerToValue {$0.destroy()}
      _fixLifetime(self)
    }

  }
//}
private let defaultMaxLoadFactorInverse = 1.0 / 0.75

//extension _MIDIEventContainer {
//  private struct Buffer {
//
//    typealias Index = BagIndex
//    typealias Element = (BarBeatTime, Bag)
//    typealias SubSequence = AnySequence<Element>
//
//    let storage: Storage
//
//    let initializedEntries: BitMap
//    let times: UnsafeMutablePointer<BarBeatTime>
//    let bags: UnsafeMutablePointer<Bag>
//
//    init(capacity: Int) {
//      storage = Storage.create(capacity)
//      initializedEntries = BitMap(storage: storage.bitMap, bitCount: capacity)
//      times = storage.times
//      bags = storage.bags
//      _fixLifetime(storage)
//    }
//
//    init(minimumCapacity: Int = 2) {
//      // Make sure there's a representable power of 2 >= minimumCapacity
//      assert(minimumCapacity <= (Int.max >> 1) + 1)
//
//      var capacity = 2
//      while capacity < minimumCapacity { capacity <<= 1 }
//
//      self = Buffer(capacity: capacity)
//    }
//
//    var capacity: Int {
//      defer { _fixLifetime(storage) }
//      return storage.capacity
//    }
//
//    var count: Int {
//      get {
//        defer { _fixLifetime(storage) }
//        return storage.count
//      }
//      nonmutating set(newValue) {
//        defer { _fixLifetime(storage) }
//        storage.count = newValue
//      }
//    }
//
//
//    var maxLoadFactorInverse: Double {
//      defer { _fixLifetime(storage) }
//      return storage.maxLoadFactorInverse
//    }
//
//    func timeAt(i: Int) -> BarBeatTime {
//      precondition(i >= 0 && i < capacity)
//      assert(isInitializedEntry(i))
//
//      defer { _fixLifetime(self) }
//      return (times + i).memory
//    }
//
//    func isInitializedEntry(i: Int) -> Bool {
//      precondition(i >= 0 && i < capacity)
//      return initializedEntries[i]
//    }
//
//    func destroyEntryAt(i: Int) {
//      assert(isInitializedEntry(i))
//      defer { _fixLifetime(self) }
//      (times + i).destroy()
//      (bags + i).destroy()
//      initializedEntries[i] = false
//    }
//
//    func initializeTime(t: BarBeatTime, bag b: Bag, at i: Int) {
//      assert(!isInitializedEntry(i))
//      defer { _fixLifetime(self) }
//      (times + i).initialize(t)
//      (bags + i).initialize(b)
//      initializedEntries[i] = true
//    }
//
//    func moveInitializeFrom(from: Buffer, at: Int, toEntryAt: Int) {
//      assert(!isInitializedEntry(toEntryAt))
//      (times + toEntryAt).initialize((from.times + at).move())
//      (bags + toEntryAt).initialize((from.bags + at).move())
//      from.initializedEntries[at] = false
//      initializedEntries[toEntryAt] = true
//    }
//
//    func bagAt(i: Int) -> Bag {
//      assert(isInitializedEntry(i))
//      defer { _fixLifetime(self) }
//      return (bags + i).memory
//    }
//
//    func setTime(time: BarBeatTime, bag: Bag, at i: Int) {
//      assert(isInitializedEntry(i))
//      defer { _fixLifetime(self) }
//      (times + i).memory = time
//      (bags + i).memory = bag
//    }
//
//    var bucketMask: Int {
//      // The capacity is not negative, therefore subtracting 1 will not overflow.
//      return capacity &- 1
//    }
//
//    func bucket(t: BarBeatTime) -> Int { return _squeezeHashValue(t.hashValue, 0..<capacity) }
//
//    func next(bucket: Int) -> Int { return (bucket &+ 1) & bucketMask }
//
//    func prev(bucket: Int) -> Int { return (bucket &- 1) & bucketMask }
//
//    func find(time: BarBeatTime, _ startBucket: Int) -> (pos: BagIndex, found: Bool) {
//      var bucket = startBucket
//
//      // The invariant guarantees there's always a hole, so we just loop
//      // until we find one
//      while true {
//        guard isInitializedEntry(bucket) else { return (BagIndex(buffer: self, offset: bucket), false) }
//        guard timeAt(bucket) != time else { return (BagIndex(buffer: self, offset: bucket), true) }
//        bucket = next(bucket)
//      }
//    }
//
//    static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
//      // `requestedCount + 1` below ensures that we don't fill in the last hole
//      return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
//    }
//
//    mutating func unsafeAddNew(time newTime: BarBeatTime, bag: Bag) {
//      let (i, found) = find(newTime, bucket(newTime))
//      assert(!found, "unsafeAddNew was called, but the time is already present")
//      initializeTime(newTime, bag: bag, at: i.offset)
//    }
//
//    var startIndex: BagIndex { return BagIndex(buffer: self, offset: -1).successor() }
//
//    var endIndex: BagIndex { return BagIndex(buffer: self, offset: capacity) }
//
//    func indexForTime(time: BarBeatTime) -> BagIndex? {
//      guard count > 0  else { return nil }
//      let (i, found) = find(time, bucket(time))
//      return found ? i : nil
//    }
//
//    func assertingGet(i: BagIndex) -> (BarBeatTime, Bag) {
//      precondition(isInitializedEntry(i.offset), "Index invalid")
//      return (timeAt(i.offset), bagAt(i.offset))
//    }
//
//    func assertingGet(time: BarBeatTime) -> Bag {
//      let (i, found) = find(time, bucket(time))
//      precondition(found, "key not found")
//      return bagAt(i.offset)
//    }
//
//    func maybeGet(time: BarBeatTime) -> Bag? {
//      guard count > 0 else { return nil }
//
//      let (i, found) = find(time, bucket(time))
//      return found ? bagAt(i.offset) : nil
//    }
//
//    mutating func updateBag(bag: Bag, forTime: BarBeatTime) -> Bag? {
//      fatalError()
//    }
//
//    mutating func removeAtIndex(index: BagIndex) -> (BarBeatTime, Bag) {
//      fatalError()
//    }
//
//    mutating func removeBagForTime(time: BarBeatTime) -> Bag? {
//      fatalError()
//    }
//
//    mutating func removeAll(keepCapacity keepCapacity: Bool) {
//      fatalError()
//    }
//    
//
//    static func fromArray(elements: [(BarBeatTime, Bag)]) -> Buffer {
//      let requiredCapacity = minimumCapacityForCount(elements.count, defaultMaxLoadFactorInverse)
//      let buffer = Buffer(minimumCapacity: requiredCapacity)
//
//      for (time, bag) in elements {
//        let (i, found) = buffer.find(time, buffer.bucket(time))
//        precondition(!found, "Dictionary literal contains duplicate keys")
//        buffer.initializeTime(time, bag: bag, at: i.offset)
//      }
//      buffer.count = elements.count
//
//      return buffer
//    }
//
//    func generate() -> Generator { return Generator() }
//
//  }
//}

struct MIDIEventContainer: CollectionType, Indexable, MutableIndexable {

  private(set) var startIndex: Index = .EndIndex

  var endIndex: Index { return .EndIndex }

  var isEmpty: Bool {
    return events.isEmpty || events.values.flatMap({$0.events.isEmpty ? $0 : nil}).count > 0
  }

  subscript(index: Index) -> MIDIEvent {
    get {
      guard let event = events[index.time]?[index.position] else { fatalError("invalid index \(index)") }
      return event
    }
    set {
      events[index.time]?[index.position] = newValue
    }
  }

  subscript(bounds: Range<Index>) -> MIDIEventContainer {
    return MIDIEventContainer(events: bounds.map({self[$0]}))
  }

  subscript(bounds: Range<BarBeatTime>) -> MIDIEventContainer {
    var result: [MIDIEvent] = []
    for (time, bag) in events where bounds ∋ time {
      result.appendContentsOf(bag.events)
    }

    return MIDIEventContainer(events: result)
  }

  var count: Int { return _indices.count }

  private(set) var eventTimes: [BarBeatTime] = []

  private var _indices: Range<Index> = .EndIndex ..< .EndIndex

  private mutating func rebuildIndices() {
    var currentIndex: Index = .EndIndex
    var indices: [Index] = [currentIndex]
    for time in eventTimes.reverse() {
      let bagIndices = Array(events[time]!.indices).reverse()
      for bagIndex in bagIndices {
        let index: Index = .ValueIndex(time, bagIndex, currentIndex)
        indices.append(index)
        currentIndex = index
      }
    }
    startIndex = currentIndex
  }

  /** init */
  init() {}

  /**
  initWithEvents:

  - parameter events: MIDIEvent
  */
  init(events: [MIDIEvent]) { self.init(); for event in events { append(event) } }

  /**
  generate

  - returns: Generator
  */
  func generate() -> AnyGenerator<MIDIEvent> {
    var index = startIndex
    let container = self
    return AnyGenerator {
      switch index {
      case .EndIndex: return nil
      case .ValueIndex(_, _, let successor):
        let event = container[index]
        index = successor
        return event
      }
    }
  }

  var minTime: BarBeatTime { return events.keys.minElement() ?? .start1              }
  var maxTime: BarBeatTime { return events.keys.maxElement() ?? Sequencer.time.barBeatTime }

  private var events: [BarBeatTime:EventBag] = [:] {
    didSet { eventTimes = events.keys.sort(); rebuildIndices() }
  }

  /**
  append:

  - parameter event: MIDIEvent
  */
  mutating func append(event: MIDIEvent) {
    switch event {
      case .Meta(let metaEvent):
        if case .SequenceTrackName = metaEvent.data { return }
        else if case .EndOfTrack = metaEvent.data { return }
      default: break
    }

    var bag = events[event.time] ?? EventBag(event.time)
    bag.append(event)
    events[event.time] = bag
  }

  /**
   Implemented because default map wasn't working correctly.

   - parameter transform: (MIDIEvent) throws -> T
  */
  func map<T>(@noescape transform: (MIDIEvent) throws -> T) rethrows -> [T] {
    var result: [T] = []
    for event in self {
      result.append(try transform(event))
    }
    return result
  }

  /**
  appendEvents:

  - parameter events: S
  */
  mutating func appendEvents<S: SequenceType where S.Generator.Element == MIDIEvent>(events: S) {
    for event in events { append(event) }
  }

  var metaEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in self { if case .Meta(let event) = event { result.append(event) } }
    return result
  }

  var channelEvents: [ChannelEvent] {
    var result: [ChannelEvent] = []
    for event in self { if case .Channel(let event) = event { result.append(event) } }
    return result
  }
  
  var nodeEvents: [MIDINodeEvent] {
    var result: [MIDINodeEvent] = []
    for event in self { if case .Node(let event) = event { result .append(event) } }
    return result
  }

  var timeEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in metaEvents {
      switch event.data {
        case .TimeSignature, .Tempo: result.append(event)
        default:                      break
      }
    }
    return result
  }

  /**
   eventsForTime:

   - parameter time: BarBeatTime

    - returns: [MIDIEvent]?
  */
  func eventsForTime(time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return events[time]?.events }

  /**
   removeEventsMatching:

   - parameter predicate: (MIDIEvent) -> Bool
  */
  mutating func removeEventsMatching(predicate: (MIDIEvent) -> Bool) {
    var result: [BarBeatTime:EventBag] = [:]
    for (time, bag) in events {
      var resultBag = EventBag(time)
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
    }
    events = result
  }
}

private extension MIDIEventContainer {

  struct EventBag: Comparable, CollectionType, MutableCollectionType {
    let time: BarBeatTime
    var events: OrderedSet<MIDIEvent> = []

    var startIndex: Int { return events.startIndex }
    var endIndex: Int { return events.endIndex }

    /**
    Create a new bag for the specified time.

    - parameter time: BarBeatTime
    */
    init(_ time: BarBeatTime) { self.time = time }

    /**
    Create a generator over the bag's events

    - returns: IndexingGenerator<[MIDIEvent]>
    */
    func generate() -> AnyGenerator<MIDIEvent> { return events.generate() }

    /**
    Append a new event to the bag

    - parameter event: MIDIEvent
    */
    mutating func append(event: MIDIEvent) { events.append(event) }

    /**
    Get or set the event at the specified position

    - parameter position: Int

    - returns: MIDIEvent
    */
    subscript(position: Int) -> MIDIEvent {
      get { return events[position] }
      set { events[position] = newValue }
    }

    /**
    Get or set the events in the specified range

    - parameter bounds: Range<Int>

    - returns: ArraySlice<MIDIEvent>
    */
    subscript(bounds: Range<Int>) -> OrderedSetSlice<MIDIEvent> {
      get { return events[bounds] }
      set { events[bounds] = newValue }
    }
  }

}

extension MIDIEventContainer: ArrayLiteralConvertible {
  init(arrayLiteral elements: MIDIEvent...) {
    self.init(events: elements)
  }
}

extension MIDIEventContainer {
  enum Index: ForwardIndexType {
    indirect case ValueIndex (BarBeatTime, Int, Index)
    case EndIndex

    func successor() -> Index {
      switch self {
        case .ValueIndex(_, _, let index): return index
        case .EndIndex: return .EndIndex
      }
    }

    var time: BarBeatTime {
      switch self {
        case .ValueIndex(let time, _, _): return time
        case .EndIndex: return .null
      }
    }

    var position: Int {
      switch self {
        case .ValueIndex(_, let position, _): return position
        case .EndIndex: return -1
      }
    }

  }

}

func ==(lhs: MIDIEventContainer.Index, rhs: MIDIEventContainer.Index) -> Bool {
  return lhs.time == rhs.time && lhs.position == rhs.position
}

private func ==(lhs: MIDIEventContainer.EventBag, rhs: MIDIEventContainer.EventBag) -> Bool {
  return lhs.time == rhs.time
}

private func <(lhs: MIDIEventContainer.EventBag, rhs: MIDIEventContainer.EventBag) -> Bool {
  return lhs.time < rhs.time
}

extension MIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(map({$0.description})) }
}

extension MIDIEventContainer: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

