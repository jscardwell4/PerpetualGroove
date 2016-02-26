//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

/* Should generator be switched to `IndexingGenerator`? */

public struct OrderedDictionary<Key : Hashable, Value> : KeyValueCollectionType {

  public typealias Index = Int
  public typealias SelfType = OrderedDictionary<Key, Value>

  private(set) public var dictionary: [Key:Value]
  private(set) var _keys: [Key]
  public var keys: LazyCollection<Array<Key>> { return LazyCollection(_keys) }
  public var printableKeys: Bool { return typeCast(_keys, Array<CustomStringConvertible>.self) != nil }

  public var userInfo: [String:AnyObject]?
  public var count: Int { return _keys.count }
  public var isEmpty: Bool { return _keys.isEmpty }
  public var values: LazyMapCollection<[Key], Value> {
    return keys.map({self.dictionary[$0]!})
  }

  public var keyValuePairs: [(Key, Value)] { return Array(zip(_keys, _keys.map({self.dictionary[$0]!}))) }

  /**
  Initialize with a minimum capacity

  - parameter minimumCapacity: Int = 4
  */
  public init(minimumCapacity: Int = 4) {
    dictionary = Dictionary(minimumCapacity: minimumCapacity)
    _keys = []
    _keys.reserveCapacity(minimumCapacity)
  }


  /**
  Initialize with an `NSDictionary`

  - parameter dict: NSDictionary
  */
  public init(_ dict: NSDictionary) {
    if let kArray = typeCast(dict.allKeys, Array<Key>.self), vArray = typeCast(dict.allValues, Array<Value>.self) {
      self = SelfType(keys: kArray, values: vArray)
    } else {
      _keys = []
      dictionary = [:]
    }
  }

  /**
  Initialize with an `MSDictionary`, preserving order

  - parameter dict: MSDictionary
  */
//  public init(_ dict: MSDictionary) {
//    self.init(dict as NSDictionary)
//    if let kArray = typeCast(dict.allKeys, Array<Key>.self) { _keys = kArray }
//  }

  /**
  Initialize with a dictionary

  - parameter dict: [Key
  */
  public init(_ dict: [Key:Value]) {
    dictionary = dict
    _keys = Array(dict.keys)
  }

  /**
  Initialize with a sequence of keys and a sequence of values

  - parameter keys: S1
  - parameter values: S2
  */
  public init<S1:SequenceType, S2:SequenceType where S1.Generator.Element == Key, S2.Generator.Element == Value>(keys: S1, values: S2) {
    self.init(zip(keys, values))
  }

  /**
  Initialize with sequence of (Key, Value) tuples

  - parameter elements: S
  */
  public init<S:SequenceType where S.Generator.Element == (Key,Value)>(_ elements: S) {
    _keys = []
    dictionary = [:]
    for (k, v) in elements { _keys.append(k); dictionary[k] = v }
  }

  // MARK: - Indexes

  public var startIndex: Index { return 0 }
  public var endIndex: Index { return _keys.count }


  public func indexForKey(key: Key) -> Index? { return _keys.indexOf(key) }

  public func keyForIndex(idx: Index) -> Key { return _keys[idx] }

  public func valueAtIndex(idx: Index) -> Value? { return dictionary[_keys[idx]] }

  /**
  subscript:

  - parameter key: Key

  - returns: Value?
  */
  public subscript (key: Key) -> Value? {
    get { return dictionary[key] }
    mutating set { setValue(newValue, forKey: key) }
  }

  /**
  subscript:

  - parameter i: Index

  - returns: (Key, Value)
  */
  public subscript(i: Index) -> (Index, Key, Value) {
    get {
      precondition(i < _keys.count)
      return (i, _keys[i], values[i])
    }
    mutating set {
      precondition(i < _keys.count)
      insertValue(newValue.2, atIndex: i, forKey: newValue.1)
    }
  }

  /**
  subscript:

  - parameter keys: [Key]

  - returns: [Value?]
  */
  public subscript(keys: [Key]) -> [Value?] {
    get {
      var values: [Value?] = []
      for key in keys { values.append(self[key]) }
      return values
    }
    mutating set {
      if newValue.count == keys.count {
        for (i, key) in keys.enumerate() { self[key] = newValue[i] }
      }
    }
  }


  // MARK: - Updating and removing values


  /**
  insertValue:atIndex:forKey:

  - parameter value: Value?
  - parameter index: Int
  - parameter key: Key
  */
  public mutating func insertValue(value: Value?, atIndex index: Int, forKey key: Key) {
    precondition(index < _keys.count)
    if let v = value {
      if let currentIndex = indexForKey(key) {
        if currentIndex != index {
          _keys.removeAtIndex(currentIndex)
          _keys.insert(key, atIndex: index)
        }
      } else {
        _keys.insert(key, atIndex: index)
      }
      dictionary[key] = v
    } else {
      if let currentIndex = indexForKey(key) { _keys.removeAtIndex(currentIndex) }
      dictionary[key] = nil
    }
  }


  /**
  setValue:forKey:

  - parameter value: Value?
  - parameter key: Key
  */
  public mutating func setValue(value: Value?, forKey key: Key) {
    if let v = value {
      if !_keys.contains(key) { _keys.append(key) }
      dictionary[key] = v
    } else {
      if let idx = indexForKey(key) { _keys.removeAtIndex(idx) }
      dictionary[key] = nil
    }
  }


  /**
  updateValue:forKey:

  - parameter value: Value
  - parameter key: Key

  - returns: Value?
  */
  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    if !_keys.contains(key) { _keys.append(key) }
    return dictionary.updateValue(value, forKey: key)
  }

  /**
  updateValue:atIndex:

  - parameter value: Value
  - parameter atIndex: idx Index

  - returns: Value?
  */
  public mutating func updateValue(value: Value, atIndex index: Index) -> Value? {
    precondition(index < _keys.count)
    return dictionary.updateValue(value, forKey: _keys[index])
  }

  public mutating func appendContentsOf<S: SequenceType where S.Generator.Element == (Int, Key, Value)>(s: S) {
    for (_, k, v) in s { self[k] = v }
  }

  /**
  removeAtIndex:

  - parameter index: Index

  - returns: Value?
  */
  public mutating func removeAtIndex(index: Index) -> Value? {
    precondition(index < _keys.count)
    return removeValueForKey(_keys[index])
  }


  /**
  removeValueForKey:

  - parameter key: Key

  - returns: Value?
  */
  public mutating func removeValueForKey(key: Key) -> Value? {
    if let idx = indexForKey(key) { _keys.removeAtIndex(idx) }
    return dictionary.removeValueForKey(key)
  }

  public mutating func removeValuesForKeys<S:SequenceType where S.Generator.Element == Key>(keys: S) {
    keys ➤ {self.removeValueForKey($0)}
  }

  /**
  removeAll:

  - parameter keepCapacity: Bool = false
  */
  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    _keys.removeAll(keepCapacity: keepCapacity)
    dictionary.removeAll(keepCapacity: keepCapacity)
  }


  /**
  sort:

  - parameter isOrderedBefore: (Key, Key) -> Bool
  */
  public mutating func sort(isOrderedBefore: (Key, Key) -> Bool) { _keys = _keys.sort(isOrderedBefore) }

  private static var defaultExpand: (Stack<String>, SelfType) -> Value {
    return {
      (var kp: Stack<String>, var leaf: SelfType) -> Value  in

      // If there are stops along the way from first to last, recursively embed in dictionaries
      while let k = kp.pop() { leaf = [k as! Key: leaf as! Value] }

      return leaf as! Value
    }
  }

  public func inflated(expand: (Stack<String>, SelfType) -> Value = defaultExpand)  -> SelfType {
    var result = self
    result.inflate(expand)
    return result
  }

  /** inflate */
  public mutating func inflate(expand: (Stack<String>, SelfType) -> Value = defaultExpand) {
    if let stringKeys = typeCast(_keys, Array<String>.self) {

      // First gather a list of keys to inflate
      let inflatableKeys = Array(stringKeys.filter({$0 ~= "(?:\\w\\.)+\\w"}))

      // Enumerate the list inflating each key
      for key in inflatableKeys {

        let keyComponents = ".".split(key)
        let firstKey = keyComponents.first!
        let lastKey = keyComponents.last!
        let keypath = Stack(keyComponents.dropFirst().dropLast())
        let value: Value

        // If our value is an array, we embed each value in the array and keep our value as an array
        if let valueArray = typeCast(self[key as! Key], Array<Value>.self) {
          value = valueArray.map({expand(keypath, [lastKey as! Key:$0])}) as! Value
        }

          // Otherwise we embed the value
        else { value = expand(keypath, [lastKey as! Key: self[key as! Key]!]) }

        insertValue(value, atIndex: _keys.indexOf(key as! Key)!, forKey: firstKey as! Key)
        self[key as! Key] = nil // Remove the compressed key-value entry
      }
    }
  }



  /**
  reverse

  - returns: OrderedDictionary<Key, Value>
  */
  public mutating func reverse() -> SelfType {
    var result = self
    result._keys = Array(result._keys.reverse())
    return result
  }


  /**
  filter

  - parameter includeElement: (Key,Value) -> Bool

  - returns: OrderedDictionary<Key, Value>
  */
  public func filter(includeElement: (Index, Key, Value) -> Bool) -> SelfType {
    var result: SelfType = [:]
    for (i, k, v) in self { if includeElement((i, k, v)) { result.setValue(v, forKey: k) } }
    return result
  }


  /**
  map

  - parameter transform: (Key, Value) -> U

  - returns: OrderedDictionary<Key, U>
  */
  public func map<U>(transform: (Index, Key, Value) -> U) -> OrderedDictionary<Key, U> {
    var result: OrderedDictionary<Key, U> = [:]
    for (i, k, v) in self { result[k] = transform(i, k, v) }
    return result
  }

  /**
  coompressedMap

  - parameter transform: (Key, Value) -> U?

  - returns: OrderedDictionary<Key, U>
  */
  public func compressedMap<U>(transform: (Index, Key, Value) -> U?) -> OrderedDictionary<Key, U> {
    return map(transform).filter({$2 != nil}).map({$2!})
  }

  public func valuesForKeys<S:SequenceType where S.Generator.Element == Key>(keys: S) -> OrderedDictionary<Key, Value?> {
    var result: OrderedDictionary<Key, Value?> = [:]
    keys ➤ {result[$0] = self[$0]}
    return result
  }

//  public static func dictionaryWithXMLData(data: NSData) -> OrderedDictionary<String, AnyObject> {
//    return OrderedDictionary<String,AnyObject>(MSDictionary(byParsingXML: data))
//  }

}

extension OrderedDictionary: NestingContainer {
  public var topLevelObjects: [Any] {
    var result: [Any] = []
    for value in values {
      result.append(value as Any)
    }
    return result
  }
  public func topLevelObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in values {
      if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
  public var allObjects: [Any] {
    var result: [Any] = []
    for value in values {
      if let container = value as? NestingContainer {
        result.appendContentsOf(container.allObjects)
      } else {
        result.append(value as Any)
      }
    }
    return result
  }
  public func allObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in values {
      if let container = value as? NestingContainer {
        result.appendContentsOf(container.allObjects(type))
      } else if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
}

extension OrderedDictionary: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}

extension OrderedDictionary: KeyedContainer {
  public func hasKey(key: Key) -> Bool { return _keys.contains(key) }
  public func valueForKey(key: Key) -> Any? { return self[key] }
}

// MARK: - Printing
extension  OrderedDictionary: CustomStringConvertible, CustomDebugStringConvertible {

  public var description: String {
    var description = "{\n\t"
    description += "\n\t".join(keyValuePairs.map({String(prettyNil: $0) + ": " + String(prettyNil: $1)}))
    description += "\n}"
    return description
  }
  public var debugDescription: String { return "\(self.dynamicType.self): " + description }

}

// MARK: DictionaryLiteralConvertible
extension  OrderedDictionary: DictionaryLiteralConvertible {
  public init(dictionaryLiteral elements: (Key, Value)...) { self = OrderedDictionary(elements) }
}

// MARK: _ObjectiveBridgeable
extension OrderedDictionary: _ObjectiveCBridgeable {
  static public func _isBridgedToObjectiveC() -> Bool {
    return true
  }
  public typealias _ObjectiveCType = MSDictionary
  static public func _getObjectiveCType() -> Any.Type { return _ObjectiveCType.self }
  public func _bridgeToObjectiveC() -> _ObjectiveCType {
    var keys: [AnyObject] = []
    var values: [AnyObject] = []
    for key in self.keys {
      if key is AnyObject {
        keys.append(key as! AnyObject)
      }
    }
    for value in self.values {
      if value is AnyObject {
        values.append(value as! AnyObject)
      }
    }
    if keys.count == values.count && keys.count == self.count {
      return MSDictionary(values: values, forKeys: keys)
    } else {
      return MSDictionary()
    }
  }

  static public func _forceBridgeFromObjectiveC(source: MSDictionary, inout result: OrderedDictionary?) {
    var d = OrderedDictionary(minimumCapacity: source.count)
    for (k, v) in zip(source.allKeys, source.allValues) {
      if let key = typeCast(k, Key.self), value = typeCast(v, Value.self) {
        d[key] = value
      }
    }
    if d.count == source.count {
      result = d
    }
  }
  static public func _conditionallyBridgeFromObjectiveC(source: MSDictionary, inout result: OrderedDictionary?) -> Bool {
    var d = OrderedDictionary(minimumCapacity: source.count)
    for (k, v) in zip(source.allKeys, source.allValues) {
      if let key = typeCast(k, Key.self), value = typeCast(v, Value.self) {
        d[key] = value
      }
    }
    if d.count == source.count {
      result = d
      return true
    }
    return false
  }
}

// MARK: - Generator

extension  OrderedDictionary: SequenceType  {
  public func generate() -> OrderedDictionaryGenerator<Key, Value> {
    return OrderedDictionaryGenerator(self)
  }
}

public struct OrderedDictionaryGenerator<Key:Hashable, Value> : GeneratorType {

  public typealias Index = OrderedDictionary<Key, Value>.Index
  let dictionary: OrderedDictionary<Key, Value>
  var index: Index


  init(_ value: OrderedDictionary<Key,Value>) {
    dictionary = value; index = dictionary.startIndex
  }

  public mutating func next() -> (Index, Key, Value)? {
    if index < dictionary.endIndex {
      let key: Key = dictionary._keys[index]
      let value: Value = dictionary.dictionary[key]!
      let element = (index, key, value)
      index += 1
      return element
    } else { return nil }
  }

}

// MARK: - Operations

//public func +<K, V>(lhs: OrderedDictionary<K, V>, rhs: OrderedDictionary<K,V>) -> OrderedDictionary<K, V> {
//  let keys: [K] = lhs._keys + rhs._keys
//  let values: [V] = Array(lhs.values) + Array(rhs.values)
//  return OrderedDictionary<K,V>(keys: keys, values: values)
//}

public func +<K, V, S:SequenceType where S.Generator.Element == (Int, K, V)>(var lhs: OrderedDictionary<K, V>, rhs: S) -> OrderedDictionary<K,V> {
  for (_, k, v) in rhs { lhs[k] = v }
  return lhs
}

public func +=<K, V, S:SequenceType where S.Generator.Element == (Int, K, V)>(inout lhs: OrderedDictionary<K, V>, rhs: S) {
  lhs = lhs + rhs
}

public func -<K, V>(var lhs: OrderedDictionary<K, V>, rhs: K) -> OrderedDictionary<K, V> {
  lhs.removeValueForKey(rhs)
  return lhs
}

public func -<K, V>(var lhs: OrderedDictionary<K, V>, rhs: [K]) -> OrderedDictionary<K, V> {
  lhs.removeValuesForKeys(rhs)
  return lhs
}

public func -=<K, V>(inout lhs: OrderedDictionary<K, V>, rhs: K) {
  lhs.removeValueForKey(rhs)
}

public func -=<K, V>(inout lhs: OrderedDictionary<K, V>, rhs: [K]) {
  lhs.removeValuesForKeys(rhs)
}

private struct OrderedDictionaryStorageHeader {
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

private final class OrderedDictionaryStorage<Key:Hashable, Value>: ManagedBuffer<OrderedDictionaryStorageHeader, UInt8> {

  typealias BytePointer = UnsafeMutablePointer<UInt8>

  static func bytesForBitMap(capacity: Int) -> Int {
    
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  var bitMapBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForBitMap(capacity) }

  static func bytesForKeyMap(capacity: Int) -> Int {
    
    let padding = max(0, alignof(Int) - alignof(UInt))
    return strideof(Int) * capacity + padding
  }

  var keyMapBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForKeyMap(capacity) }

  static func bytesForKeys(capacity: Int) -> Int {
    
    let maxPrevAlignment = max(alignof(Int), alignof(UInt))
    let padding = max(0, alignof(Key) - maxPrevAlignment)
    return strideof(Key) * capacity + padding
  }

  var keysBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForKeys(capacity) }

  static func bytesForValues(capacity: Int) -> Int {
    
    let maxPrevAlignment = max(alignof(Key), alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Key) - maxPrevAlignment)
    return strideof(Key) * capacity + padding
  }

  var valuesBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForValues(capacity) }

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

  var keyMap: UnsafeMutablePointer<Int> {
    return UnsafeMutablePointer<Int>(UnsafePointer<UInt8>(bitMap) + bitMapBytes)
  }

  var keys: UnsafeMutablePointer<Key> {
    return UnsafeMutablePointer<Key>(UnsafePointer<UInt8>(keyMap) + keyMapBytes)
  }

  var values: UnsafeMutablePointer<Value> {
    return UnsafeMutablePointer<Value>(UnsafePointer<UInt8>(keys) + keysBytes)
  }

  class func create(capacity: Int) -> OrderedDictionaryStorage {
    
    let bitMapBytes = bytesForBitMap(capacity)
    let requiredCapacity = bitMapBytes
      + bytesForKeys(capacity)
      + bytesForKeyMap(capacity)
      + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      $0.withUnsafeMutablePointerToElements {
        BitMap(storage: UnsafeMutablePointer<UInt>($0), bitCount: capacity).initializeToZero()
        let keyMap = UnsafeMutablePointer<Int>($0 + bitMapBytes)
        for i in 0 ..< capacity { (keyMap + i).initialize(-1) }
      }
      return OrderedDictionaryStorageHeader(capacity: capacity, bytesAllocated: $0.allocatedElementCount)
    }

    return storage as! OrderedDictionaryStorage<Key, Value>
  }

  func resize(capacity: Int) -> OrderedDictionaryStorage<Key, Value> {

    assert(count <= capacity, "Cannot resize to a capacity less than count")
    let storage = OrderedDictionaryStorage<Key, Value>.create(capacity)

    BytePointer(storage.bitMap).initializeFrom(BytePointer(self.bitMap), count: self.bitMapBytes)
    BytePointer(storage.keyMap).initializeFrom(BytePointer(self.keyMap), count: self.keyMapBytes)
    BytePointer(storage.keys).initializeFrom(BytePointer(self.keys), count: self.keysBytes)
    BytePointer(storage.values).initializeFrom(BytePointer(self.values), count: self.valuesBytes)
    storage.count = count
    return storage
  }

  func clone() -> OrderedDictionaryStorage<Key, Value> {
    
    return withUnsafeMutablePointers {
      (head: UnsafeMutablePointer<OrderedDictionaryStorageHeader>,
      elements: UnsafeMutablePointer<UInt8>) -> OrderedDictionaryStorage<Key, Value> in

      OrderedDictionaryStorage<Key, Value>.create(head.memory.capacity) {
        proto in
        proto.withUnsafeMutablePointerToElements {
          $0.initializeFrom(elements, count: head.memory.bytesAllocated)
        }
        return head.memory
        } as! OrderedDictionaryStorage<Key, Value>
    }
  }

  deinit {
    defer { _fixLifetime(self) }
    for i in 0 ..< count {
      let h = keyMap[i]
      (keyMap + i).destroy()
      (keys + h).destroy()
      (values + h).destroy()
    }
    //    let capacity = self.capacity
    //    let initializedEntries = BitMap(storage: bitMap, bitCount: capacity)
    //    let keys = self.keys
    //    let values = self.values
    //
    //    for i in 0 ..< capacity where initializedEntries[i] {
    //      if !_isPOD(Key) {(keys+i).destroy() }
    //      if !_isPOD(Value) { (values + i).destroy() }
    //    }

    withUnsafeMutablePointerToValue {$0.destroy()}
  }
}

extension OrderedDictionaryStorage {
  var description: String {
    defer { _fixLifetime(self) }
    let bitMap = BitMap(storage: self.bitMap, bitCount: capacity)
    var bitMapDescription = ""
    for i in 0 ..< capacity {
      let isInitialized = bitMap[i]
      bitMapDescription += isInitialized ? "1" : "0"
    }
    defer { _fixLifetime(bitMap) }
    var result = "OrderedDictionaryStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tbitMapBytes: \(bitMapBytes)\n"
    result += "\tkeyMapBytes: \(keyMapBytes)\n"
    result += "\tkeysBytes: \(keysBytes)\n"
    result += "\tvaluesBytes: \(valuesBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tbitMap: \(bitMapDescription)\n"
    result += "\tkeyMap: \(Array(UnsafeBufferPointer(start: keyMap, count: count)))\n"
    result += "\tkeys: \(Array(UnsafeBufferPointer(start: keys, count: count)))\n"
    result += "\tvalues: \(Array(UnsafeBufferPointer(start: values, count: count)))\n"
    result += "\n}"
    return result
  }
}
private let defaultMaxLoadFactorInverse = 1.0 / 0.75

public struct __OrderedDictionaryGenerator__<Key: Hashable, Value>: GeneratorType {
  private typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  private let buffer: Buffer
  private var index: OrderedDictionaryIndex<Key, Value>
  private init(buffer: Buffer) {
    self.buffer = buffer
    index = buffer.startIndex
  }
  public mutating func next() -> (Key, Value)? {
    
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.elementAt(index)
  }
}

extension UnsafeMutablePointer {
  subscript(position: IntValued) -> Memory {
    get { return self[position.value] }
    set { self[position.value] = newValue }
  }
}

extension BitMap {
  subscript(position: IntValued) -> Bool {
    get { return self[position.value] }
    set { self[position.value] = newValue }
  }
}

public struct OrderedDictionaryBuffer<Key:Hashable, Value>: SequenceType {

  public typealias Index = OrderedDictionaryIndex<Key, Value>
  public typealias Element = (Key, Value)
  public typealias Generator = __OrderedDictionaryGenerator__<Key, Value>

  private typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  private typealias Storage = OrderedDictionaryStorage<Key, Value>

  private var storage: Storage

  // MARK: - Pointers to the underlying memory

  private var bitMap: BitMap
  private var keys: UnsafeMutablePointer<Key>
  private var keyMap: UnsafeMutablePointer<Int>
  private var values: UnsafeMutablePointer<Value>

  // MARK: - Accessors for the storage header properties

  public var capacity: Int { return storage.capacity }

  public private(set) var count: Int { get { return storage.count } nonmutating set { storage.count = newValue } }

  var maxLoadFactorInverse: Double { return storage.maxLoadFactorInverse }

  // MARK: - Initializing by capacity

  /**
   initWithCapacity:

   - parameter capacity: Int
   */
  init(capacity: Int) {
    storage = Storage.create(capacity)
    bitMap = BitMap(storage: storage.bitMap, bitCount: capacity)
    keys = storage.keys
    values = storage.values
    keyMap = storage.keyMap
    _fixLifetime(storage)
  }

  /**
   initWithMinimumCapacity:

   - parameter minimumCapacity: Int = 2
   */
  init(minimumCapacity: Int = 2) {
    // Make sure there's a representable power of 2 >= minimumCapacity
    assert(minimumCapacity <= (Int.max >> 1) + 1)

    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }

    self.init(capacity: capacity)
  }

  /**
   minimumCapacityForCount:maxLoadFactorInverse:

   - parameter count: Int
   - parameter maxLoadFactorInverse: Double

    - returns: Int
  */
  static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

    // MARK: - Initializing with data

  /**
   initWithStorage:

   - parameter storage: Storage
  */
  private init(storage: Storage) {
    self.storage = storage
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    keyMap = storage.keyMap
    keys = storage.keys
    values = storage.values
  }

  /**
   initWithElements:capacity:

   - parameter elements: [Element]
   - parameter capacity: Int? = nil
  */
  init(elements: [Element], capacity: Int? = nil) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.count, defaultMaxLoadFactorInverse)
    let requiredCapacity = max(minimumCapacity, capacity ?? 0)
    let buffer = Buffer(minimumCapacity: requiredCapacity)

    for (p, (k, v)) in elements.enumerate() {
      let (idx, found) = buffer.find(k)
      precondition(!found, "Dictionary literal contains duplicate keys")
      buffer.initializeKey(k, value: v, position: p, bucket: idx.value)
    }
    buffer.count = elements.count

    self = buffer
  }


  // MARK: - Queries

  /**
   find:

   - parameter key: Key

    - returns: (position: Index, found: Bool)
  */
  private func find(k: Key) -> (position: Index, found: Bool) {
    
    let startBucket = Index(k, self)
    var b = startBucket

    repeat {
      guard isInitializedEntry(b) else { return (b, false) }
      guard keyAt(b) != k else { return (b, true) }
      b._successorInPlace()
    } while b != startBucket

    fatalError("failed to locate hole")
  }

  /**
   keyAt:

   - parameter idx: Index

    - returns: Key
  */
  func keyAt(idx: Index) -> Key {
    guard let h = idx.hashedInitialized else {
      fatalError("failed to get hashed index from index: \(idx)")
    }
    return (keys + h).memory
  }

  /**
   valueAt:

   - parameter idx: Index

    - returns: Value
  */
  func valueAt(idx: Index) -> Value {
    guard let h = idx.hashedInitialized else {
      fatalError("failed to get hashed index from index: \(idx)")
    }
    return values[h]
  }

  /**
   valueForKey:

   - parameter k: Key

    - returns: Value?
  */
  func valueForKey(k: Key) -> Value? {
    guard count > 0 else { return nil }
    guard let idx = indexForKey(k) else { return nil }
    return valueAt(idx)
  }

  /**
   elementAt:

   - parameter idx: Index

    - returns: Element
  */
  func elementAt(idx: Index) -> Element { return (keyAt(idx), valueAt(idx)) }

  /**
   isInitializedEntry:

   - parameter index: Index

    - returns: Bool
  */
  private func isInitializedEntry(index: Index) -> Bool {
    guard let h = index.hashed else { return false }
    return bitMap[h]
  }

  /**
   indexForKey:

   - parameter k: Key

    - returns: Index?
  */
  func indexForKey(k: Key) -> Index? {
    guard count > 0 else { return nil }
    let (idx, found) = find(k)
    guard found else { return nil }
    return idx
  }

  // MARK: - Removing data

  /**
   destroyEntryAt:

   - parameter index: Index
  */
  mutating func destroyEntryAt(index: Index) {
    guard let o = index.orderedInitialized, h = index.hashedInitialized else {
      fatalError("failed to retrieve ordered and hashed indices from index: (index)")
    }
    defer { _fixLifetime(self) }
    let k = keyAt(h)
    let from = keyMap + o + 1
    let moveCount = count - o - 1
    (keyMap + o).moveInitializeFrom(from, count: moveCount)
    (keys + h).destroy()
    (values + h).destroy()
    bitMap[h] = false

    //TODO: rework to use position-based bucket checks

    // If we've put a hole in a chain of contiguous elements, some
    // element after the hole may belong where the new hole is.
    var hole = h

    // Find the first bucket in the contiguous chain
    var start = Index(k, self)
    while isInitializedEntry(start.predecessor()) { start._predecessorInPlace() }

    // Find the last bucket in the contiguous chain
    var lastInChain = hole
    var b = lastInChain.successor()
    while isInitializedEntry(b) { lastInChain = b; b._successorInPlace() }

    // Relocate out-of-place elements in the chain, repeating until
    // none are found.
    while hole != lastInChain {
      // Walk backwards from the end of the chain looking for
      // something out-of-place.
      var b = lastInChain
      while b != hole {
        let idealBucket = Index(keyAt(b), self)

        // Does this element belong between start and hole?  We need
        // two separate tests depending on whether [start,hole] wraps
        // around the end of the buffer
        let c0 = idealBucket >= start
        let c1 = idealBucket <= hole
        if start <= hole ? (c0 && c1) : (c0 || c1) {
          break // Found it
        }
        b._predecessorInPlace()
      }

      if b == hole { // No out-of-place elements found; we're done adjusting
        break
      }

      // Move the found element into the hole
      moveInitializeFrom(b, to: hole)
      hole = b
    }

    count -= 1
  }

  // MARK: - Initializing with data

  /**
   initializeKey:value:position:bucket:

   - parameter k: Key
   - parameter v: Value
   - parameter p: Int
   - parameter b: Int
  */
  func initializeKey(k: Key, value v: Value, position p: Int, bucket b: Int) {
    defer { _fixLifetime(self) }
    let r = 0 ..< capacity
    guard r ∋ b else { fatalError("Invalid bucket: \(b)") }
    guard !bitMap[b] else { fatalError("Expected uninitialized bucket") }
    guard r ∋ p else { fatalError("Invalid postion: \(p)") }
    (keys + b).initialize(k)
    (values + b).initialize(v)
    bitMap[b] = true
    (keyMap + p).initialize(b)
  }


  /**
   initializeKey:value:at:

   - parameter k: Key
   - parameter v: Value
   - parameter i: Index
  */
  func initializeKey(k: Key, value v: Value, at i: Index) {
    guard let b = i.hashedUninitialized?.value else {
      fatalError("failed to get hashed uninitialized index from index: \(i)")
    }
    initializeKey(k, value: v, position: count, bucket: b)
  }

  /**
   uncheckedMoveInitializeFrom:to:forPosition:

   - parameter b1: Int
   - parameter b2: Int
   - parameter p: Int
  */
  private func uncheckedMoveInitializeFrom(b1: Int, to b2: Int, forPosition p: Int) {
    (keys + b2).initialize((keys + b1).move())
    (values + b2).initialize((values + b1).move())
    keyMap[p] = b2
    bitMap[b1] = false
    bitMap[b2] = true
  }

  /**
   moveInitializeFrom:to:forPosition:

   - parameter b1: Int
   - parameter b2: Int
   - parameter p: Int
  */
  private func moveInitializeFrom(b1: Int, to b2: Int, forPosition p: Int) {
    let r = 0 ..< capacity
    guard r ∋ b1 && bitMap[b1] else { fatalError("from bucket invalid or uninitialized: \(b1)") }
    guard r ∋ b2 && !bitMap[b2] else { fatalError("to bucket invalid or already initialized: \(b1)") }
    guard r ∋ p && keyMap[p] == b1 else { fatalError("position invalid: \(p)") }
    uncheckedMoveInitializeFrom(b1, to: b2, forPosition: p)
  }

  /**
   moveInitializeFrom:to:

   - parameter from: Index
   - parameter to: Index
  */
  private func moveInitializeFrom(from: Index, to: Index) {

    guard let b1 = from.hashedInitialized?.value else {
      fatalError("failed to get hashed initialized index from index: \(from)")
    }

    guard let p = from.ordered?.value else {
      fatalError("failed to get ordered index from index: \(from)")
    }

    guard let b2 = to.hashedUninitialized?.value else {
      fatalError("failed to get hashed unitialized index from index: \(to)")
    }

    uncheckedMoveInitializeFrom(b1, to: b2, forPosition: p)
  }

  // MARK: - Assigning into already initialized data

  /**
   setKey:value:at:

   - parameter key: Key
   - parameter value: Value
   - parameter index: Index
  */
  mutating func setKey(key: Key, value: Value, at index: Index) {
    guard let h = index.hashedInitialized else {
      fatalError("failed to get hashed index from index: \(index)")
    }
    keys[h] = key
    values[h] = value
  }

}

extension OrderedDictionaryBuffer : CustomStringConvertible, CustomDebugStringConvertible {
    
  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for (k, v) in self {
      if first { first = false } else { result += ", " }
      debugPrint(k, terminator: ": ", toStream: &result)
      debugPrint(v, terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String { return elementsDescription }

  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String {
    var result = elementsDescription + "\n"
    for i in startIndex ..< endIndex {
      if isInitializedEntry(i) {
        let k = keyAt(i)
        result += "bucket \(i), ideal bucket = \(Index(k, self)), actual bucket = \(i.hashed), key = \(k)\n"
      } else {
        result += "bucket \(i), empty\n"
      }
    }
    return result
  }
}

extension OrderedDictionaryBuffer: CollectionType {

  public typealias _Element = Element

  public var startIndex: Index { return .Ordered(0, self) }

  public var endIndex: Index { return .Ordered(count, self) }


  public subscript(position: Index) -> Element {
    return elementAt(position)
  }

  public func generate() -> Generator { return Generator(buffer: self) }
}

public enum OrderedDictionaryIndex<Key: Hashable, Value>: BidirectionalIndexType, Comparable, CustomStringConvertible, IntValued {
  public typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  case Ordered(Int, Buffer)
  case Hashed(Int, Buffer)

  public var value: Int { switch self { case .Ordered(let i, _): return i; case .Hashed(let i, _): return i } }
  var buffer: Buffer { switch self { case .Ordered(_, let b): return b; case .Hashed(_, let b): return b } }

  public func successor() -> OrderedDictionaryIndex {
    switch self {
      case .Ordered(let i, let buffer): return .Ordered(i.successor(), buffer)
      case .Hashed(let i, let buffer): return .Hashed(i.successor() & (buffer.capacity &- 1), buffer)
    }
  }

  private init(_ k: Key, _ buffer: Buffer) {
    self = .Hashed(_squeezeHashValue(k.hashValue, 0 ..< buffer.capacity), buffer)
  }

  public func predecessor() -> OrderedDictionaryIndex {
    switch self {
      case .Ordered(let i, let buffer): return .Ordered(i.predecessor(), buffer)
      case .Hashed(let i, let buffer): return .Hashed(i.predecessor() & (buffer.capacity &- 1), buffer)
    }
  }

  var ordered: OrderedDictionaryIndex<Key, Value>? {
    if case .Hashed(let h, let buffer) = self {
      for i in 0 ..< buffer.count {
        guard buffer.keyMap[i] != h else { return .Ordered(i, buffer) }
      }
      return .Ordered(buffer.count, buffer)
    } else {
      return self
    }
  }

  var orderedInitialized: OrderedDictionaryIndex<Key, Value>? {
    if case .Hashed(let h, let buffer) = self {
      guard buffer.isInitializedEntry(self) else { return nil }
      for i in 0 ..< buffer.count {
        guard buffer.keyMap[i] != h else { return .Ordered(i, buffer) }
      }
      return nil
    } else if case .Ordered(let v, let b) = self where b.count > v {
      return self
    } else { return nil }
  }

  var orderedUninitialized: OrderedDictionaryIndex<Key, Value>? {
    if case .Hashed(_, let buffer) = self {
      guard !buffer.isInitializedEntry(self) else { return nil }
      return .Ordered(buffer.count, buffer)
    } else if case .Ordered(let v, let b) = self where v == b.count {
      return self
    } else {
      return nil
    }
  }

  var hashed: OrderedDictionaryIndex<Key, Value>? {
    if case .Ordered(let o, let buffer) = self {
      guard o < buffer.count else { fatalError("ordered index greater than buffer count") }
      let h = buffer.keyMap[o]
      guard (0 ..< buffer.capacity) ∋ h else { return nil }
      return .Hashed(h, buffer)
    } else {
      return self
    }
  }

  var hashedInitialized: OrderedDictionaryIndex<Key, Value>? {
    guard let h = hashed where buffer.isInitializedEntry(h) else {
      return nil
    }
    return h
  }

  var hashedUninitialized: OrderedDictionaryIndex<Key, Value>? {
    guard let h = hashed where !buffer.isInitializedEntry(h) else {
      return nil
    }
    return h
  }

  public var description: String {
    switch self {
      case .Ordered(let v, _): return "Ordered(\(v))"
      case .Hashed(let v, _): return "Hashed(\(v))"
    }
  }
}

public func <<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
  
  return lhs.value < numericCast(rhs)
}

public func ><K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
  
  return lhs.value > numericCast(rhs)
}

public func <=<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
  
  return lhs.value <= numericCast(rhs)
}

public func >=<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
  
  return lhs.value >= numericCast(rhs)
}

public func <<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  
  return numericCast(lhs) < rhs.value
}

public func ><K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  
  return numericCast(lhs) > rhs.value
}

public func <=<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  
  return numericCast(lhs) <= rhs.value
}

public func >=<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  
  return numericCast(lhs) >= rhs.value
}
private func compareIndices<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>, operation: (Int, Int) -> Bool) -> Bool {
  if case .Hashed = lhs {
    guard let rhsHashed = rhs.hashed else { return false }
    return operation(lhs.value, rhsHashed.value)
  } else {
    guard let rhsOrdered = rhs.ordered else { return false }
    return operation(lhs.value, rhsOrdered.value)
  }
}
public func <<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  return compareIndices(lhs, rhs: rhs, operation: <)
}

public func ><K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  return compareIndices(lhs, rhs: rhs, operation: >)
}

public func <=<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  return compareIndices(lhs, rhs: rhs, operation: <=)
}

public func >=<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  return compareIndices(lhs, rhs: rhs, operation: >=)
}

public func +<K, V, Memory>(lhs: UnsafeMutablePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafeMutablePointer<Memory> {
  
  return lhs + rhs.value
}

public func +<K, V, Memory>(lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Memory> {
  
  return rhs + lhs
}

public func -<K, V, Memory>(lhs: UnsafeMutablePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafeMutablePointer<Memory> {
  
  return lhs - rhs.value
}
public func -<K, V, Memory>(lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Memory> {
  
  return rhs - lhs
}

public func +<K, V, Memory>(lhs: UnsafePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafePointer<Memory> {

  return lhs + rhs.value
}

public func +<K, V, Memory>(lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafePointer<Memory>) -> UnsafePointer<Memory> {

  return rhs + lhs
}

public func -<K, V, Memory>(lhs: UnsafePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafePointer<Memory> {

  return lhs - rhs.value
}
public func -<K, V, Memory>(lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafePointer<Memory>) -> UnsafePointer<Memory> {

  return rhs - lhs
}

public func +<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
  
  return lhs + numericCast(rhs.value)
}

public func +<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V> {
  
  switch lhs {
  case let .Ordered(v, b): return .Ordered(v + numericCast(rhs), b)
  case let .Hashed(v, b):  return .Hashed(v + numericCast(rhs), b)
  }
}

public func -<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
  
  return lhs - numericCast(rhs.value)
}
public func -<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V> {
  
  switch lhs {
  case let .Ordered(v, b): return .Ordered(v - numericCast(rhs), b)
  case let .Hashed(v, b):  return .Hashed(v - numericCast(rhs), b)
  }
}

public func &<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
  
  return lhs & numericCast(rhs.value)
}

public func &<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V> {
  
  switch lhs {
  case let .Ordered(v, b): return .Ordered(v & numericCast(rhs), b)
  case let .Hashed(v, b):  return .Hashed(v & numericCast(rhs), b)
  }
}

public func |<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
  
  return lhs | numericCast(rhs.value)
}
public func |<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V> {
  
  switch lhs {
  case let .Ordered(v, b): return .Ordered(v | numericCast(rhs), b)
  case let .Hashed(v, b):  return .Hashed(v | numericCast(rhs), b)
  }
}

public func &+<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
  
  return lhs &+ numericCast(rhs.value)
}

public func &+<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V> {
  
  switch lhs {
  case let .Ordered(v, b): return .Ordered(v &+ numericCast(rhs), b)
  case let .Hashed(v, b):  return .Hashed(v &+ numericCast(rhs), b)
  }
}

public func &-<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
  
  return lhs &- numericCast(rhs.value)
}
public func &-<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V> {
  
  switch lhs {
  case let .Ordered(v, b): return .Ordered(v &- numericCast(rhs), b)
  case let .Hashed(v, b):  return .Hashed(v &- numericCast(rhs), b)
  }
}

public func ==<K:Hashable, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  
  switch (lhs, rhs) {
  case (.Ordered(let v1, let buffer1), .Ordered(let v2, let buffer2))
    where v1 == v2 && buffer1.storage === buffer2.storage:
    return true
  case (.Hashed(let v1, let buffer1), .Hashed(let v2, let buffer2))
    where v1 == v2 && buffer1.storage === buffer2.storage:
    return true
  default: return false
  }
}

private final class Owner<Key: Hashable, Value>: NonObjectiveCBase {

  typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  var buffer: Buffer
  init(minimumCapacity: Int) {
    buffer = Buffer(minimumCapacity: minimumCapacity)
  }
  init(buffer: Buffer) { self.buffer = buffer }
}

/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct __OrderedDictionary__<Key: Hashable, Value>: CollectionType, DictionaryLiteralConvertible {

  public typealias Index = OrderedDictionaryIndex<Key, Value>
  public typealias Generator = __OrderedDictionaryGenerator__<Key, Value>
  public typealias _Element = (Key, Value)
  private typealias Storage = OrderedDictionaryStorage<Key, Value>
  private typealias Buffer = OrderedDictionaryBuffer<Key, Value>

  //  private var buffer: OrderedDictionaryBuffer<Key, Value> { return owner.buffer }
  private var buffer: Buffer {
    unsafeAddress { return withUnsafePointer(&owner.buffer, {$0}) }
    unsafeMutableAddress { return withUnsafeMutablePointer(&owner.buffer, {$0}) }
  }

  private var owner: Owner<Key, Value>

  private mutating func cloneStorage() { owner.buffer.storage = buffer.storage.clone() }

  private mutating func rehashKeys() {
    

  }


  private mutating func resizeStorage(capacity: Int) {
    buffer = Buffer(storage: buffer.storage.resize(capacity))
  }

  mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    
    if capacity >= minimumCapacity {
      guard !isUniquelyReferenced(&owner) else { return(reallocated: false, capacityChanged: false) }
      cloneStorage()
      return (reallocated: true, capacityChanged: false)
    }
    resizeStorage(minimumCapacity)
    return (reallocated: true, capacityChanged: true)

  }

  /// Create an empty dictionary.
  public init() { self.init(minimumCapacity: 0) }

  public init(minimumCapacity: Int) { owner = Owner<Key, Value>(minimumCapacity: minimumCapacity) }

  private init(buffer: Buffer) { owner = Owner<Key, Value>(buffer: buffer) }

  public var startIndex: Index { return buffer.startIndex }

  public var endIndex: Index { return buffer.endIndex }

  public func indexForKey(key: Key) -> Index? {
        return buffer.indexForKey(key) }

  public subscript(position: Index) -> (Key, Value) { return buffer.elementAt(position) }

  public subscript(position: Int) -> Value {
    get {
      guard let h = Index.Ordered(position, buffer).hashedInitialized else {
        fatalError("Index out of bounds: \(position)")
      }
      return buffer.values[h.value]
    }
    set {
      guard let h = Index.Ordered(position, buffer).hashedInitialized else {
        fatalError("Index out of bounds: \(position)")
      }
      buffer.values[h.value] = newValue
    }
  }

  public subscript(key: Key) -> Value? {
    get { return buffer.valueForKey(key) }
    set {
      if let value = newValue { _updateValue(value, forKey: key) }
      else { _removeValueForKey(key) }
    }
  }

  private mutating func _updateValue(value: Value, forKey key: Key) {
    
    let (i, found) = buffer.find(key)
    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1, buffer.maxLoadFactorInverse)

    ensureUniqueWithCapacity(minCapacity)

    if found {
      buffer.setKey(key, value: value, at: i)
    } else {
      buffer.initializeKey(key, value: value, at: i)
      buffer.count += 1
    }
  }

  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    
    let oldValue = buffer.valueForKey(key)

    _updateValue(value, forKey: key)
    return oldValue
  }

  private mutating func _removeAtIndex(index: Index) {    
    ensureUniqueWithCapacity(capacity)
    buffer.destroyEntryAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> (Key, Value) {
    
    let (key, value) = buffer.elementAt(index)
    _removeAtIndex(index)
    return (key, value)
  }

  private mutating func _removeValueForKey(key: Key) {
    
    guard let index = buffer.indexForKey(key) else { return }
    _removeAtIndex(index)
  }

  public mutating func removeValueForKey(key: Key) -> Value? {
    
    let oldValue = buffer.valueForKey(key)
    _removeValueForKey(key)
    return oldValue
  }

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    
    guard isUniquelyReferenced(&owner) else {
      owner = Owner<Key, Value>(minimumCapacity: keepCapacity ? capacity : 2)
      return
    }

    guard keepCapacity else { owner.buffer = Buffer(minimumCapacity: 0); return }

    for i in startIndex ..< endIndex { buffer.destroyEntryAt(i) }
    buffer.count = 0
  }

  /// The number of entries in the dictionary.
  ///
  /// - Complexity: O(1).
  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public func generate() -> __OrderedDictionaryGenerator__<Key, Value> {
    
    return __OrderedDictionaryGenerator__<Key, Value>(buffer: buffer)
  }

  //  @effects(readonly)
  public init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(buffer: OrderedDictionaryBuffer(elements: elements))
  }

  public var keys: LazyMapCollection<__OrderedDictionary__<Key, Value>, Key> {
    return lazy.map { $0.0 }
  }

  public var values: LazyMapCollection<__OrderedDictionary__<Key, Value>, Value> {
    return lazy.map { $0.1 }
  }

  public var isEmpty: Bool { return count == 0 }

}
extension __OrderedDictionary__: CustomStringConvertible, CustomDebugStringConvertible {
  func _makeDescription() -> String {
    
    if count == 0 {
      return "[:]"
    }

    var result = "["
    var first = true
    for (k, v) in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(k, terminator: "", toStream: &result)
      result += ": "
      debugPrint(v, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String {
    return _makeDescription()
  }
  
  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String {
    return _makeDescription()
  }
}

public func == <Key: Hashable, Value: Equatable>
  (lhs: __OrderedDictionary__<Key, Value>, rhs: __OrderedDictionary__<Key, Value>) -> Bool
{
    
  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }
  
  for i in 0 ..< lhs.count {
    guard lhs[i] == rhs[i] else { return false }
  }
  
  return true
}
