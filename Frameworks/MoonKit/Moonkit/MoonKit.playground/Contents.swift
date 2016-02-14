import Foundation
import MoonKit
import XCPlayground

struct _SwiftArrayBodyStorage {
  var count: Int
  var capacityAndFlags: UInt
}

struct _ArrayBody {
  var storage: _SwiftArrayBodyStorage
}

var someArray = [1, 5, 7, 22, 645, 12, 656, 2, 12]
  someArray.dynamicType._Buffer.self
  debugPrint(someArray._buffer.withUnsafeBufferPointer({$0}))
  if let owner = someArray._owner {
    debugPrint(owner.dynamicType)
    let value = ManagedBufferPointer<_ArrayBody, Int>(unsafeBufferObject: owner).value
    let count = value.storage.count
    ManagedBufferPointer<_ArrayBody, Int>(unsafeBufferObject: owner).withUnsafeMutablePointerToElements {
      for i in 0 ..< count {
        print(($0 + i).memory)
      }
    }
//    _fixLifetime(managedBufferPointer)
  }
var filteredArray = someArray.filter {(element:Int) -> Bool in return element % 2 == 0}
filteredArray.count
filteredArray[filteredArray.startIndex]
someArray.removeAtIndex(3)
filteredArray.count

public struct FilteredArray<Element> { //: _CollectionWrapperType, CollectionType {

  private weak var owner: AnyObject?

  init<Value>(bufferPointer: ManagedBufferPointer<Value,Element>) {
    owner = bufferPointer.buffer
//    if let owner = array._owner { self.owner = owner }
//    owner = array._owner
  }

//  public typealias Base = ContiguousArray<Element>
//  public var _base: Base
//
//  /** init */
//  public init() { _base = [] }
//
//  /**
//   initWithMinimumCapacity:
//
//   - parameter minimumCapacity: Int
//  */
//  public init(minimumCapacity: Int) { self.init(); _base.reserveCapacity(minimumCapacity) }
//
//  /**
//   init:
//
//   - parameter collection: C
//  */
//  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
//    _base = Base(collection)
//    sortElements()
//  }
//
//  /**
//   _customContainsEquatableElement:
//
//   - parameter element: Element
//
//    - returns: Bool?
//  */
//  public func _customContainsEquatableElement(element: Element) -> Bool? {
//    return _base._buffer.withUnsafeBufferPointer { binarySearch($0, element: element) != nil }
//  }
//
//  /**
//   _customIndexOfEquatableElement:
//
//   - parameter element: Element
//
//   - returns: Int??
//  */
//  public func _customIndexOfEquatableElement(element: Element) -> Int?? {
//    return Optional(_base._buffer.withUnsafeBufferPointer { binarySearch($0, element: element) })
//  }
//
//  /**
//   _initializeTo:
//
//   - parameter ptr: UnsafeMutablePointer<Element>
//
//   - returns: UnsafeMutablePointer<Element>
//  */
//  public func _initializeTo(ptr: UnsafeMutablePointer<Element>) -> UnsafeMutablePointer<Element> {
//
//    return _base._initializeTo(ptr)
//  }
//
//  /** sortElements */
//  private mutating func sortElements() {
//    guard count > 1 else { return }
//
//    _base._buffer.withUnsafeMutableBufferPointer {
//      var buffer = $0
//      func sort(range: Range<Int>) {
//        guard range.count > 1 else { return }
//        guard range.count > 2 else {
//          if buffer[range.startIndex] > buffer[range.startIndex.successor()] {
//            swap(&buffer[range.startIndex], &buffer[range.startIndex.successor()])
//          }
//          return
//        }
//        let p = buffer.partition(range)
//        sort(range.startIndex ..< p)
//        sort(p.successor() ..< range.endIndex)
//      }
//
//      sort(0 ..< count)
//    }
//
//  }
//
//  /**
//   indexOf:predicate:
//
//   - parameter isOrderedBefore: (Element) throws -> Bool
//   - parameter predicate: (Element) throws -> Bool
//
//   - returns: Int?
//  */
//  public func indexOf(isOrderedBefore isOrderedBefore: (Element) throws -> Bool,
//            predicate: (Element) throws -> Bool) rethrows -> Int?
//  {
//    let buffer = _base._buffer.withUnsafeBufferPointer {$0}
//    defer { _fixLifetime(buffer) }
//    return try binarySearch(buffer, isOrderedBefore: isOrderedBefore, predicate: predicate)
//  }
//
//  /**
//   Don't inline copyBuffer - this would inline the copy loop into the current
//   path preventing retains/releases to be matched across that region.
//
//   - parameter buffer: _ContiguousArrayBuffer<Element>
//  */
//  @inline(never)
//  static internal func _copyBuffer(inout buffer: _Buffer) {
//    let newBuffer = _Buffer(count: buffer.count, minimumCapacity: buffer.count)
//    buffer._uninitializedCopy(buffer.indices, target: newBuffer.firstElementAddress)
//    buffer = _Buffer(newBuffer, shiftedToStartIndex: buffer.startIndex)
//  }
//}
//
//extension FilteredArray: _ArrayType {
//
//  public typealias _Buffer = Base._Buffer
//
//  /// An object that guarantees the lifetime of this array's elements.
//  public var _owner: AnyObject? { return _base._owner }
//
//  /// If the elements are stored contiguously, a pointer to the first
//  /// element. Otherwise, `nil`.
//  public var _baseAddressIfContiguous: UnsafeMutablePointer<Element> { return _base._baseAddressIfContiguous }
//
//  public var _buffer: _Buffer { return _base._buffer }
//
//  /**
//   replaceRange:with:
//
//   - parameter subRange: Range<Int>
//   - parameter newElements: C
//  */
//  public mutating func replaceRange<C:CollectionType
//    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
//  {
//    _base.replaceRange(subRange, with: newElements)
//    sortElements()
//  }
//
//  public mutating func append(element: Element) {
//    if !_base._buffer.isMutableAndUniquelyReferenced() {
//      FilteredArray<Element>._copyBuffer(&_base._buffer)
//    }
//    let minimumCapacity = _base.count + 1
//    if _base._buffer.requestUniqueMutableBackingBuffer(minimumCapacity) == nil {
//
//      let newBuffer = _ContiguousArrayBuffer<Element>(count: count, minimumCapacity: minimumCapacity)
//
//      _base._buffer._uninitializedCopy(_base._buffer.indices, target: newBuffer.firstElementAddress)
//      _base._buffer = _ContiguousArrayBuffer<Element>(newBuffer, shiftedToStartIndex: _base._buffer.startIndex)
//    }
//
//    let firstElement = _base._buffer.firstElementAddress
//    let insertionPoint = binaryInsertion(UnsafeBufferPointer(start: firstElement, count: count), element: element)
//
//    if insertionPoint != count {
//      let countToMove = count - insertionPoint
//      guard countToMove > 0 else {
//        fatalError("bad insertion point '\(insertionPoint)' for count '\(count)'")
//      }
//
//      (firstElement + insertionPoint + 1).moveInitializeBackwardFrom(firstElement + insertionPoint, count: countToMove)
//    }
//
//    (firstElement + insertionPoint).initialize(element)
//    _base._buffer.count++
//
//  }
//
//  /// Append the elements of `newElements` to `self`.
//  ///
//  /// - Complexity: O(*length of result*).
//  public mutating func appendContentsOf<S : SequenceType
//    where S.Generator.Element == Element>(newElements: S)
//  {
//    _base.appendContentsOf(newElements)
//    sortElements()
//  }
//
//  /// Remove the element at index `i`.
//  ///
//  /// Invalidates all indices with respect to `self`.
//  ///
//  /// - Complexity: O(`self.count`).
//  public mutating func removeAtIndex(i: Int) -> Element { return _base.removeAtIndex(i) }
//
//  /// Remove the element at `startIndex` and return it.
//  ///
//  /// - Complexity: O(`self.count`)
//  /// - Requires: `!self.isEmpty`.
//  public mutating func removeFirst() -> Element { return _base.removeFirst() }
//
//  /// Remove the first `n` elements.
//  ///
//  /// - Complexity: O(`self.count`)
//  /// - Requires: `self.count >= n`.
//  public mutating func removeFirst(n: Int) { return _base.removeFirst(n) }
//
//
//  /// Remove the indicated `subRange` of elements.
//  ///
//  /// Invalidates all indices with respect to `self`.
//  ///
//  /// - Complexity: O(`self.count`).
//  public mutating func removeRange(subRange: Range<Int>) { _base.removeRange(subRange) }
//
//  /// Remove all elements.
//  ///
//  /// Invalidates all indices with respect to `self`.
//  ///
//  /// - parameter keepCapacity: If `true`, is a non-binding request to
//  ///    avoid releasing storage, which can be a useful optimization
//  ///    when `self` is going to be grown again.
//  ///
//  /// - Complexity: O(`self.count`).
//  public mutating func removeAll(keepCapacity keepCapacity: Bool) {
//    _base.removeAll(keepCapacity: keepCapacity)
//  }
//
//
//  /// Construct an array of `count` elements, each initialized to `repeatedValue`.
//  public init(count: Int, repeatedValue: Element) {
//    _base = Base(count: count, repeatedValue: repeatedValue)
//  }
//
//  /// The number of elements the Array stores.
//  public var count: Int { return _base.count }
//
//  /// The number of elements the Array can store without reallocation.
//  public var capacity: Int { return _base.capacity }
//
//  /// `true` if and only if the Array is empty.
//  public var isEmpty: Bool { return _base.isEmpty }
//
//  /**
//   subscript:
//
//   - parameter index: Int
//
//    - returns: Element
//  */
//  public subscript(index: Int) -> Element {
//    get { return _base[index] }
//    set {
//      _base[index] = newValue
//      guard count > 1 else { return }
//
//      switch index {
//        case _base.startIndex where _base[index.successor()] >= newValue: return
//        case _base.endIndex.predecessor() where _base[index.predecessor()] <= newValue: return
//        case _base.startIndex.successor() ..< _base.endIndex where _base.count > 2
//          && _base[index.successor()] >= newValue
//          && _base[index.predecessor()] <= newValue: return
//        default: sortElements()
//      }
//    }
//  }
//
//  /// Reserve enough space to store minimumCapacity elements.
//  ///
//  /// - Postcondition: `capacity >= minimumCapacity` and the array has
//  ///   mutable contiguous storage.
//  ///
//  /// - Complexity: O(`count`).
//  public mutating func reserveCapacity(minimumCapacity: Int) {
//    _base.reserveCapacity(minimumCapacity)
//  }
//
//  /// Insert `newElement` at index `i`.
//  ///
//  /// Invalidates all indices with respect to `self`.
//  ///
//  /// - Complexity: O(`self.count`).
//  ///
//  /// - Requires: `atIndex <= count`.
//  public mutating func insert(newElement: Element, atIndex i: Int) {
//    append(newElement)
//  }
//
//  /// Insert `newElements` at index `i`.
//  ///
//  /// Invalidates all indices with respect to `self`.
//  ///
//  /// - Complexity: O(`self.count + newElements.count`).
//  public mutating func insertContentsOf<S:CollectionType
//    where S.Generator.Element == Element>(newElements: S, at i: Int)
//  {
//    appendContentsOf(newElements)
//  }
//
//  /**
//   init:
//
//   - parameter buffer: ContiguousArray<Element>._Buffer
//  */
//  public init(_ buffer: _Buffer) {
//    _base = Base(buffer)
//  }
//}
//
//
///// Operator form of `appendContentsOf`.
//public func +=<Element, S: SequenceType
//  where S.Generator.Element == Element>(inout lhs: FilteredArray<Element>, rhs: S)
//{
//  lhs._base += rhs
//  lhs.sortElements()
//}
//
//extension FilteredArray: ArrayLiteralConvertible {
//  /**
//   init:
//
//   - parameter elements: Element...
//  */
//  public init(arrayLiteral elements: Element...) {
//    self.init(elements)
//  }
}

extension FilteredArray: CustomStringConvertible {
  public var description: String {
    var result = "["
//    result += "owner: \(owner == nil ? "nil" : owner!.description!)"
//    var first = true
//    for item in self {
//      if first { first = false } else { result += ", " }
//      debugPrint(item, terminator: "", toStream: &result)
//    }
    result += "]"
    return result
  }

}

do {
  let identifier = ObjectIdentifier(someArray._owner!)
  identifier.uintValue
//  weak var owner = someArray._owner
//  if owner != nil {
//    let bufferPointer = ManagedBufferPointer<_ArrayBody, Int>(unsafeBufferObject: owner)
//    someArray._owner! === owner!
    malloc_size(UnsafePointer(unsafeAddressOf(someArray._owner!)))
    someArray = [1, 2, 3, 4]
  let identifier2 = ObjectIdentifier(someArray._owner!)
  identifier2.uintValue
//    someArray._owner! === owner
//    if let owner = owner {
    malloc_size(UnsafePointer(unsafeAddressOf(someArray._owner!)))
//    }

//var filteredSomeArray = FilteredArray<Int>(bufferPointer: ManagedBufferPointer<_ArrayBody, Int>(unsafeBufferObject: owner))
//    _fixLifetime(owner)
    "wtf"
//  }

}