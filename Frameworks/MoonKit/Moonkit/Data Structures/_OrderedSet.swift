//
//  _OrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

// MARK: - Storage
// MARK: -

internal struct _OrderedSetStorageHeader {
  var count: Int
  let capacity: Int
  let bytesAllocated: Int
  var maxLoadFactorInverse: Double

  init(count: Int = 0, capacity: Int, bytesAllocated: Int, maxLoadFactorInverse: Double = 1 / 0.75) {
    self.count = count
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.maxLoadFactorInverse = maxLoadFactorInverse
  }
}

internal final class _OrderedSetStorage<Member:Hashable>: ManagedBuffer<_OrderedSetStorageHeader, UInt8> {

  typealias Storage = _OrderedSetStorage<Member>

  static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  var bitMapBytes: Int { return Storage.bytesForBitMap(capacity) }

  static func bytesForBucketMap(capacity: Int) -> Int {

    let padding = max(0, alignof(Int) - alignof(UInt))
    return strideof(Int) * capacity + padding
  }

  var bucketMapBytes: Int { return Storage.bytesForBucketMap(capacity) }

  static func bytesForMembers(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Member) - maxPrevAlignment)
    return strideof(Member) * capacity + padding
  }

  var membersBytes: Int { return Storage.bytesForMembers(capacity) }

  var capacity: Int { return value.capacity }

  var count: Int { get { return value.count } set { value.count = newValue } }

  var maxLoadFactorInverse: Double {
    get { return value.maxLoadFactorInverse }
    set { value.maxLoadFactorInverse = newValue }
  }

  var bytesAllocated: Int { return value.bytesAllocated }

  var bitMap: UnsafeMutablePointer<UInt> {
    return UnsafeMutablePointer<UInt>(withUnsafeMutablePointerToElements({$0}))
  }

  var bucketMap: UnsafeMutablePointer<Int> {
    return UnsafeMutablePointer<Int>(UnsafePointer<UInt8>(bitMap) + bitMapBytes)
  }

  var members: UnsafeMutablePointer<Member> {
    return UnsafeMutablePointer<Member>(UnsafePointer<UInt8>(bucketMap) + bucketMapBytes)
  }

  static func capacityForMinimumCapacity(minimumCapacity: Int) -> Int {
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }
    return capacity
  }

  static func create(minimumCapacity: Int) -> _OrderedSetStorage {
    let capacity = capacityForMinimumCapacity(minimumCapacity)
    let bitMapBytes = bytesForBitMap(capacity)
    let requiredCapacity = bitMapBytes + bytesForBucketMap(capacity) + bytesForMembers(capacity)

    let storage = super.create(requiredCapacity) {
      $0.withUnsafeMutablePointerToElements {
        BitMap(storage: UnsafeMutablePointer<UInt>($0), bitCount: capacity).initializeToZero()
        let bucketMap = UnsafeMutablePointer<Int>($0 + bitMapBytes)
        for i in 0 ..< capacity { (bucketMap + i).initialize(-1) }
      }
      return _OrderedSetStorageHeader(capacity: capacity, bytesAllocated: $0.allocatedElementCount)
    }

    return storage as! Storage
  }

  func clone() -> Storage {

    let storage = Storage.create(capacity)

    func initialize<Memory>(target: UnsafeMutablePointer<Memory>,
                    from: UnsafeMutablePointer<Memory>,
                    count: Int)
    {
      UnsafeMutablePointer<UInt8>(target).initializeFrom(UnsafeMutablePointer<UInt8>(from), count: count)
    }

    initialize(storage.bitMap, from: bitMap, count: bitMapBytes)
    initialize(storage.bucketMap, from: bucketMap, count: bucketMapBytes)
    initialize(storage.members, from: members, count: membersBytes)
    storage.count = count

    return storage
  }

  deinit {
    defer { _fixLifetime(self) }
    let count = self.count
    let bucketMap = self.bucketMap
    let members = self.members
    if !_isPOD(Member) {
      for i in 0 ..< count {
        let h = bucketMap[i]
        (members + h).destroy()
      }
    }
  }
}

extension _OrderedSetStorage {
  var description: String {
    defer { _fixLifetime(self) }
    let bitMap = BitMap(storage: self.bitMap, bitCount: capacity)
    var bitMapDescription = ""
    for i in 0 ..< capacity {
      let isInitialized = bitMap[i]
      bitMapDescription += isInitialized ? "1" : "0"
    }
    defer { _fixLifetime(bitMap) }
    var result = "_OrderedSetStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tbitMapBytes: \(bitMapBytes)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\tmembersBytes: \(membersBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tbitMap: \(bitMapDescription)\n"
    result += "\tbucketMap: \(Array(UnsafeBufferPointer(start: bucketMap, count: count)))\n"
    result += "\tmembers: \(Array(UnsafeBufferPointer(start: members, count: count)))\n"
    result += "\n}"
    return result
  }
}

// MARK: - Generator
// MARK: -

public struct _OrderedSetGenerator<Member:Hashable>: GeneratorType {
  internal typealias Buffer = _OrderedSetBuffer<Member>
  internal let buffer: Buffer
  internal var index: Int = 0
  internal init(buffer: Buffer) { self.buffer = buffer }

  public mutating func next() -> (Member)? {
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.memberAtPosition(index)
  }
}

internal struct _OrderedSetBuffer<Member:Hashable> {

  internal typealias Index = Int
  internal typealias Element = Member
  internal typealias Generator = _OrderedSetGenerator<Member>

  internal typealias Buffer = _OrderedSetBuffer<Member>
  internal typealias Storage = _OrderedSetStorage<Member>
  internal typealias Bucket = Int

  // MARK: Pointers to the underlying memory

  internal var storage: Storage
  internal var bitMap: BitMap
  internal var bucketMap: UnsafeMutablePointer<Int>
  internal var members: UnsafeMutablePointer<Member>

  // MARK: Accessors for the storage header properties

  internal var capacity: Int { return storage.capacity }

  internal var count: Int {
    get { return storage.count }
    nonmutating set { storage.count = newValue }
  }

  internal var maxLoadFactorInverse: Double {
    get { return storage.maxLoadFactorInverse }
    set { storage.maxLoadFactorInverse = newValue }
  }

  // MARK: Initializing by capacity

  internal init(minimumCapacity: Int = 2) {
    storage = Storage.create(Buffer.minimumCapacityForCount(minimumCapacity, 1 / 0.75))
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    members = storage.members
    bucketMap = storage.bucketMap
    _fixLifetime(storage)
  }

  internal static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  // MARK: Initializing with data

  internal init(storage: Storage) {
    self.storage = storage
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    bucketMap = storage.bucketMap
    members = storage.members
  }

  internal init<S:SequenceType where S.Generator.Element == Element>(elements: S, capacity: Int? = nil) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount(), 1 / 0.75)
    let requiredCapacity = max(minimumCapacity, capacity ?? 0)
    let buffer = Buffer(minimumCapacity: requiredCapacity)

    var count = 0
    var duplicates = 0

    for (position, member) in elements.enumerate() {
      let (bucket, found) = buffer.find(member)
      if found {
        duplicates += 1
        continue
      } else {
        buffer.initializeMember(member, position: position - duplicates, bucket: bucket)
        count += 1
      }
    }
    buffer.count = count

    self = buffer
  }


  // MARK: Queries

  internal var bucketMask: Int { return capacity &- 1 }

  internal func bucketForMember(member: Member) -> Bucket {
    return _squeezeHashValue(member.hashValue, 0 ..< capacity)
  }

  internal func positionForBucket(bucket: Bucket) -> Index {
    for position in 0 ..< count { guard bucketMap[position] != bucket else { return position } }
    return count
  }

  internal func bucketForPosition(position: Index) -> Bucket { return bucketMap[position] }

  internal func nextBucket(bucket: Bucket) -> Bucket { return (bucket &+ 1) & bucketMask }

  internal func previousBucket(bucket: Bucket) -> Bucket { return (bucket &- 1) & bucketMask }

  internal func find(member: Member) -> (position: Bucket, found: Bool) {

    let startBucket = bucketForMember(member)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard memberInBucket(bucket) != member  else { return (bucket, true) }
      bucket = nextBucket(bucket)
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  internal func memberInBucket(bucket: Bucket) -> Member { return members[bucket] }

  internal func memberAtPosition(position: Index) -> Element {
    return memberInBucket(bucketForPosition(position))
  }

  internal func isInitializedBucket(bucket: Bucket) -> Bool { return bitMap[bucket] }

  internal func indexForMember(member: Member) -> Index? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(member)
    guard found else { return nil }
    return positionForBucket(bucket)
  }

  // MARK: Removing data

  internal func destroyMemberAt(position: Index) {
    defer { _fixLifetime(self) }
    var bucket = bucketForPosition(position)
    //    print("\(debugDescription)")
    assert(bitMap[bucket], "bucket empty")
    var idealBucket = bucketForMember((members + bucket).move())
    //    print("(members + bucket).memory = \((members + bucket).memory)")
    bucketMap[position] = -1
    bitMap[bucket] = false

    if position + 1 < count {
      let from = bucketMap + position + 1
      let moveCount = count - position - 1
      (bucketMap + position).moveInitializeFrom(from, count: moveCount)
    }

    //TODO: rework to use position-based bucket checks

    // If we've put a hole in a chain of contiguous elements, some
    // element after the hole may belong where the new hole is.
    var hole = bucket

    // Find the first bucket in the contiguous chain
    var start = idealBucket
    while isInitializedBucket(previousBucket(start)) { start = previousBucket(start) }

    // Find the last bucket in the contiguous chain
    var lastInChain = hole
    bucket = nextBucket(lastInChain)
    while isInitializedBucket(bucket) { lastInChain = bucket; bucket = nextBucket(bucket) }

    // Relocate out-of-place elements in the chain, repeating until
    // none are found.
    while hole != lastInChain {
      // Walk backwards from the end of the chain looking for
      // something out-of-place.
      bucket = lastInChain
      while bucket != hole {
        idealBucket = bucketForMember(memberInBucket(bucket))

        // Does this element belong between start and hole?  We need
        // two separate tests depending on whether [start,hole] wraps
        // around the end of the buffer
        let c0 = idealBucket >= start
        let c1 = idealBucket <= hole
        if start <= hole ? (c0 && c1) : (c0 || c1) {
          break // Found it
        }
        bucket = previousBucket(bucket)
      }

      if bucket == hole { // No out-of-place elements found; we're done adjusting
        break
      }

      // Move the found element into the hole
      (members + hole).initialize((members + bucket).move())
      bitMap[hole] = true
      bitMap[bucket] = false
      bucketMap[positionForBucket(bucket)] = hole
      hole = bucket
    }

    count -= 1
  }

  internal func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self) }
    let oldCount = storage.count
    let removeCount: Int = subRange.count
    let insertCount: Int = numericCast(newElements.count)
    let newCount = oldCount - removeCount + insertCount
    assert(capacity >= newCount, "not enough capacity for new count: \(newCount)")

    let members = storage.members
    for (index, positionOffset) in subRange.enumerate() {
      let memberPointer = members + positionOffset
      if index < insertCount {
        let element = newElements[newElements.startIndex.advancedBy(numericCast(index))]
        memberPointer.initialize(element)
      } else {
        memberPointer.destroy()
      }
    }

    // Return early if we don't need to shift old elements or insert remaining new elements
    guard removeCount != insertCount else { return }

    // Check if we need to shift old elements
    if subRange.endIndex < storage.count {

      // Shift forward when removing more elements than are being inserted
      if removeCount > insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = members + subRange.endIndex
        let destination = members + subRange.startIndex.advancedBy(insertCount)
        destination.moveInitializeFrom(moveSource, count: moveCount)
      }

        // Shift backward when inserting more elements than are being removed
      else if removeCount < insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = members + subRange.endIndex

        let oldElementsDestinationOffset = subRange.startIndex.advancedBy(insertCount)
        let oldElementsDestination = members + oldElementsDestinationOffset

        oldElementsDestination.moveInitializeBackwardFrom(moveSource, count: moveCount)

        let uninsertedElementDestinationOffset = subRange.endIndex
        var uninsertedElementDestination = members + uninsertedElementDestinationOffset

        for index in newElements.startIndex.advancedBy(numericCast(removeCount)) ..< newElements.endIndex {
          uninsertedElementDestination.initialize(newElements[index])
          uninsertedElementDestination += 1
        }

      }
    }
    storage.count = newCount

  }


  // MARK: Initializing with data

  internal func initializeMember(member: Member, position: Int, bucket: Int) {
    defer { _fixLifetime(self) }
    (members + bucket).initialize(member)
    bitMap[bucket] = true
    (bucketMap + position).initialize(bucket)
  }


  internal func initializeMember(member: Member, bucket: Bucket) {
    initializeMember(member, position: count, bucket: bucket)
  }

  // MARK: Assigning into already initialized data
  internal func setMember(member: Member, at position: Index) {
    setMember(member, inBucket: bucketForPosition(position))
  }

  internal func setMember(member: Member, inBucket bucket: Bucket) {
    (members + bucket).initialize(member)
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension _OrderedSetBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for bucket in UnsafeBufferPointer(start: bucketMap, count: count) {
      if first { first = false } else { result += ", " }
      debugPrint(members[bucket], terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  internal var description: String { return elementsDescription }

  internal var debugDescription: String {
    var result = elementsDescription + "\n"
    result += "count = \(count)\n"
    result += "capacity = \(capacity)\n"
    for position in 0 ..< capacity {
      let bucket = bucketMap[position]
      if bucket > -1 {
        result += "position \(position) ➞ bucket \(bucket)\n"
      } else {
        result += "position \(position), empty\n"
      }
    }
    for bucket in 0 ..< capacity {
      if isInitializedBucket(bucket) {
        let member = memberInBucket(bucket)
        result += "bucket \(bucket), ideal bucket = \(bucketForMember(member))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

// MARK: - Owner
// MARK: -

internal final class _OrderedSetStorageOwner<Member:Hashable>: NonObjectiveCBase {

  typealias Buffer = _OrderedSetBuffer<Member>
  var buffer: Buffer
  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }
  init(buffer: Buffer) { self.buffer = buffer }
}

// MARK: - SubSequence
// MARK: -

public struct _OrderedSetSlice<Member:Hashable>: CollectionType {
  public typealias Index = Int
  internal typealias Buffer = _OrderedSetBuffer<Member>
  public var startIndex: Int { return bounds.startIndex }
  public var endIndex: Int  { return bounds.endIndex }
  internal let buffer: Buffer
  internal let bounds: Range<Int>
  public subscript(position: Index) -> Member { return buffer.memberAtPosition(position) }
  internal init(buffer: Buffer, bounds: Range<Int>) {
    precondition(bounds.startIndex >= 0, "Invalid start for bounds: \(bounds.startIndex)")
    precondition(bounds.endIndex <= buffer.count, "Invalid end for bounds: \(bounds.endIndex)")
    self.buffer = buffer
    self.bounds = bounds
  }
}

extension _OrderedSetSlice: CustomStringConvertible {
  public var description: String {
    var result = "["
    var first = true
    for item in self {
      if first { first = false } else { result += ", " }
      debugPrint(item, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
}


// MARK: - _OrderedSet
// MARK: -

/// A hash-based mapping from `Key` to `Member` instances that preserves elment order.
public struct _OrderedSet<Member:Hashable>: CollectionType {

  public typealias Index = Int//_OrderedSetIndex<Member>
  public typealias Generator = _OrderedSetGenerator<Member>
  public typealias SubSequence = _OrderedSetSlice<Member>
  public typealias Element = (Member)
  public typealias _Element = Element
  internal typealias Storage = _OrderedSetStorage<Member>
  internal typealias Buffer = _OrderedSetBuffer<Member>
  internal typealias Owner = _OrderedSetStorageOwner<Member>

  internal var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  internal var owner: Owner

  internal mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {

    if capacity >= minimumCapacity {
      guard !isUniquelyReferenced(&owner) else { return(reallocated: false, capacityChanged: false) }
      owner = Owner(buffer: Buffer(storage: buffer.storage.clone()))
      return (reallocated: true, capacityChanged: false)
    }

    let newBuffer = Buffer(minimumCapacity: minimumCapacity * 2)
    for position in 0 ..< count {
      let oldBucket = buffer.bucketMap[position]
      let member = buffer.members[oldBucket]
      let (bucket, _) = newBuffer.find(member)
      newBuffer.initializeMember(member, position: position, bucket: bucket)
    }
    newBuffer.count = buffer.count
    owner = Owner(buffer: newBuffer)
    return (reallocated: true, capacityChanged: true)

  }

  public init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  internal init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

  public var hashValue: Int {
    // FIXME: <rdar://problem/18915294> Cache Set<T> hashValue
    var result: Int = _mixInt(0)
    for member in self {
      result ^= _mixInt(member.hashValue)
    }
    return result
  }

  @warn_unused_result
  public func _customContainsEquatableElement(member: Element) -> Bool? {
    return contains(member)
  }

  @warn_unused_result
  public func _customIndexOfEquatableElement(member: Element) -> Index?? {
    return Optional(indexOf(member))
  }
  

  public func indexOf(member: Member) -> Index? { return buffer.indexForMember(member) }

  public subscript(position: Int) -> Member {
    get { return buffer.memberAtPosition(position) }
    set { _updateMember(newValue, atPosition: position, oldMember: nil) }
  }

  internal mutating func _updateMember(member: Member,
                                      atPosition position: Int,
                                                 oldMember: UnsafeMutablePointer<Member?>)
  {
    var (bucket, found) = buffer.find(member)

    if oldMember != nil {
      if found {
        oldMember.initialize(buffer.memberInBucket(bucket))
      } else {
        oldMember.initialize(nil)
      }
    }

    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1, buffer.maxLoadFactorInverse)

    let (_, capacityChanged) = ensureUniqueWithCapacity(minCapacity)
    if capacityChanged { (bucket, found) = buffer.find(member) }

    if found {
      buffer.setMember(member, inBucket: bucket)
    } else {
      buffer.initializeMember(member, bucket: bucket)
      buffer.count += 1
    }
  }

  @warn_unused_result
  public func contains(member: Member) -> Bool { let (_, found) = buffer.find(member); return found }

//  public mutating func updateMember(member: Member, atPosition position: Int) -> Member? {
//    let oldMember = UnsafeMutablePointer<Member?>.alloc(1)
//    _updateMember(member, atPosition: position, oldMember: oldMember)
//    return oldMember.memory
//  }

  internal mutating func _removeAtIndex(index: Index, oldElement: UnsafeMutablePointer<Element>) {
    if oldElement != nil { oldElement.initialize(buffer.memberInBucket(buffer.bucketForPosition(index))) }
    ensureUniqueWithCapacity(capacity)
    buffer.destroyMemberAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> Member {
    let oldElement = UnsafeMutablePointer<Element>.alloc(1)
    _removeAtIndex(index, oldElement: oldElement)
    return oldElement.memory
  }

  internal mutating func _removeMember(member: Member, oldMember: UnsafeMutablePointer<Member?>) {
    guard let index = buffer.indexForMember(member) else {
      if oldMember != nil { oldMember.initialize(nil) }
      return
    }
    if oldMember != nil {
      let oldElement = UnsafeMutablePointer<Element>.alloc(1)
      _removeAtIndex(index, oldElement: oldElement)
      oldMember.initialize(oldElement.memory)
    } else {
      _removeAtIndex(index, oldElement: nil)
    }
  }

  public mutating func remove(member: Member) -> Member? {
    let oldMember = UnsafeMutablePointer<Member?>.alloc(1)
    _removeMember(member, oldMember: oldMember)
    return oldMember.memory
  }

  public mutating func removeFirst() -> Member {
//    assert(count > 0, "removeFirst() requires the set not be empty")
    return removeAtIndex(0)
  }

  public mutating func insert(member: Member) {
    ensureUniqueWithCapacity(count + 1)
    let (bucket, found) = buffer.find(member)
    guard !found else { return }
    buffer.initializeMember(member, bucket: bucket)
    buffer.count += 1
  }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public func generate() -> Generator { return Generator(buffer: buffer) }

  public var isEmpty: Bool { return count == 0 }

  public var first: Element? { guard count > 0 else { return nil }; return buffer.memberAtPosition(0) }

  public mutating func popFirst() -> Element? { guard count > 0 else { return nil }; return removeAtIndex(0) }

}

extension _OrderedSet: SetType {

  public init<S : SequenceType where S.Generator.Element == Element>(_ elements: S) {
    self.init(buffer: Buffer(elements: elements)) // Uniqueness checked by `Buffer`
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set`.
  @warn_unused_result
  public func isSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0
    for element in sequence where self.contains(element) {
      hitCount += 1
      guard hitCount < count else { return true }
    }
    return hitCount == count
  }
  /// Returns true if the set is a subset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  public func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0, totalCount = 0
    for element in sequence {
      if contains(element) { hitCount += 1 }
      totalCount += 1
      guard hitCount < count || totalCount <= count else { return true }
    }
    return hitCount == count && totalCount > count
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set`.
  @warn_unused_result
  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard contains(element) else { return false } }
    return true
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  public func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var totalCount = 0
    for element in sequence {
      totalCount += 1
      guard contains(element) else { return false }
    }
    return totalCount < count
  }

  /// Returns true if no members in the set are in a finite sequence as a `Set`.
  @warn_unused_result
  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard !contains(element) else { return false } }
    return true
  }

  /// Return a new `Set` with items in both this set and a finite sequence.
  @warn_unused_result
  public func union<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> _OrderedSet<Element> {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  /// Insert elements of a finite sequence into this `Set`.
  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence { insert(element) }
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  public func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> _OrderedSet<Element> {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  /// Remove all members in the set that occur in a finite sequence.
  public mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence {
      guard let index = indexOf(element) else { continue }
      _removeAtIndex(index, oldElement: nil)
    }
  }

  /// Return a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  public func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> _OrderedSet<Element> {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  /// Remove any members of this set that aren't also in a finite sequence.
  public mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = _OrderedSet<Element>(minimumCapacity: capacity)
    for element in self where set.contains(element) { result.insert(element) }
    self = result
  }

  /// Return a new set with elements that are either in the set or a finite sequence but do not occur in both.
  @warn_unused_result
  public func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> _OrderedSet<Element> {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  /// For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it
  /// to the set. Repeated elements of the sequence will be ignored.
  public mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = _OrderedSet<Member>(minimumCapacity: capacity + set.count)
    for element in self where !set.contains(element) { result.insert(element) }
    for element in set where !contains(element) { result.insert(element) }
    self = result
  }
}

extension _OrderedSet: MutableCollectionType {
  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(buffer: buffer, bounds: bounds) }
    set { for position in newValue.bounds { self[position] = newValue[position] } }
  }
}

extension _OrderedSet: RangeReplaceableCollectionType {

  public init() { owner = Owner(minimumCapacity: 0) }

  public mutating func reserveCapacity(minimumCapacity: Int) { ensureUniqueWithCapacity(minimumCapacity) }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    ensureUniqueWithCapacity(capacity - subRange.count + numericCast(newElements.count))
    // Ensure uniqueness
    let elementsToRemove = self[subRange]
    let filteredElements = newElements.filter { !contains($0) || elementsToRemove.contains($0) }

    // Replace with uniqued collection
    buffer.replaceRange(subRange, with: filteredElements)
  }

  public mutating func append(element: Element) { insert(element) }

  public mutating func appendContentsOf<S:SequenceType where S.Generator.Element == Element>(newElements: S) {
    for element in newElements { insert(element) } // Membership check by `insert()`
  }

  public mutating func insert(newElement: Element, atIndex i: Int) {
    precondition(i < count, "Index out of bounds: \(i)")
    replaceRange(i ..< i, with: CollectionOfOne(newElement))
  }

  public mutating func insertContentsOf<C:CollectionType
    where C.Generator.Element == Element>(newElements: C, at i: Int)
  {
    precondition(i < count, "Index out of bounds: \(i)")
    replaceRange(i ..< i, with: newElements)
  }

  public mutating func removeFirst(n: Int) {
    assert(count >= n, "Cannot remove more elements than the set contains")
    replaceRange(0 ..< n, with: EmptyCollection())
  }

  public mutating func removeRange(subRange: Range<Int>) {
    replaceRange(subRange, with: EmptyCollection())
  }

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    owner = Owner(buffer: Buffer(storage: Storage.create(keepCapacity ? capacity : 0)))
  }
  
}

extension _OrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(buffer: Buffer(elements: elements))
  }
}

extension _OrderedSet: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for member in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(member, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  public var description: String { return elementsDescription }

  public var debugDescription: String { return elementsDescription }
}

public func == <Member:Hashable>
  (lhs: _OrderedSet<Member>, rhs: _OrderedSet<Member>) -> Bool
{
  
  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }
  
  for (v1, v2) in zip(lhs, rhs) { guard v1 == v2 else { return false } }
  
  return true
}
