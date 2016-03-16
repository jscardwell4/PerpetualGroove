//
//  OrderedSetTests.swift
//  OrderedSetTests
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
@testable import MoonKit

final class OrderedSetTests: XCTestCase {

  func randomIntegers(count: Int, _ range: Range<Int>) -> [Int] {
    guard count > 0 else { return [] }
    func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
    var result = Array<Int>(minimumCapacity: count)
    for _ in 0 ..< count { result.append(randomInt()) }
    return result
  }

  func test_OrderedSetCreation() {
    measureBlock {
      var orderedSet = _OrderedSet<Int>(minimumCapacity: 8)
      XCTAssertGreaterThanOrEqual(orderedSet.capacity, 8)
      XCTAssertEqual(orderedSet.count, 0)

      orderedSet = [1, 2, 3, 4, 5]
      XCTAssertGreaterThanOrEqual(orderedSet.capacity, 5)
      XCTAssertEqual(orderedSet.count, 5)

      let randoms = self.randomIntegers(100000, 1 ..< 1000)
      orderedSet = _OrderedSet(randoms)
      let set = Set(randoms)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func test_OrderedSetInsertion() {
    measureBlock {
      var orderedSet1 = _OrderedSet<Int>(minimumCapacity: 8)

      orderedSet1.insert(1)
      XCTAssertEqual(orderedSet1.count, 1)
      XCTAssertEqual(orderedSet1[0], 1)
      XCTAssertTrue(orderedSet1.elementsEqual([1]))

      orderedSet1.insert(2)
      XCTAssertEqual(orderedSet1.count, 2)
      XCTAssertEqual(orderedSet1[1], 2)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2]))

      orderedSet1.insert(3)
      XCTAssertEqual(orderedSet1.count, 3)
      XCTAssertEqual(orderedSet1[2], 3)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))

      orderedSet1.insert(4)
      XCTAssertEqual(orderedSet1.count, 4)
      XCTAssertEqual(orderedSet1[3], 4)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4]))

      orderedSet1.insert(5)
      XCTAssertEqual(orderedSet1.count, 5)
      XCTAssertEqual(orderedSet1[4], 5)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5]))

      var orderedSet2 = _OrderedSet<String>(minimumCapacity: 8)

      orderedSet2.insert("one")
      XCTAssertEqual(orderedSet2.count, 1)
      XCTAssertEqual(orderedSet2[0], "one")
      XCTAssertTrue(orderedSet2.elementsEqual(["one"]))

      orderedSet2.insert("two")
      XCTAssertEqual(orderedSet2.count, 2)
      XCTAssertEqual(orderedSet2[1], "two")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two"]))

      orderedSet2.insert("three")
      XCTAssertEqual(orderedSet2.count, 3)
      XCTAssertEqual(orderedSet2[2], "three")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))

      orderedSet2.insert("four")
      XCTAssertEqual(orderedSet2.count, 4)
      XCTAssertEqual(orderedSet2[3], "four")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four"]))

      orderedSet2.insert("five")
      XCTAssertEqual(orderedSet2.count, 5)
      XCTAssertEqual(orderedSet2[4], "five")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five"]))
    }
  }

  func test_OrderedSetResize() {
    measureBlock {
      var orderedSet1 = _OrderedSet<Int>(minimumCapacity: 8)
      orderedSet1.insert(1)
      orderedSet1.insert(2)
      orderedSet1.insert(3)
      orderedSet1.insert(4)
      orderedSet1.insert(5)
      orderedSet1.insert(6)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6]))
      orderedSet1.insert(7)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7]))
      orderedSet1.insert(8)
      orderedSet1.insert(9)
      orderedSet1.insert(10)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))

      var orderedSet2 = _OrderedSet<String>(minimumCapacity: 8)
      orderedSet2.insert("one")
      orderedSet2.insert("two")
      orderedSet2.insert("three")
      orderedSet2.insert("four")
      orderedSet2.insert("five")
      orderedSet2.insert("six")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six"]))
      orderedSet2.insert("seven")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven"]))
      orderedSet2.insert("eight")
      orderedSet2.insert("nine")
      orderedSet2.insert("ten")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]))
    }
  }

  func test_OrderedSetDeletion() {
    measureBlock {
      var orderedSet1: _OrderedSet<Int> = [1, 2, 3]
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))
      orderedSet1.removeAtIndex(1)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 3]))
      orderedSet1.removeAtIndex(0)
      XCTAssertTrue(orderedSet1.elementsEqual([3]))
      orderedSet1.insert(2)
      orderedSet1.insert(1)
      XCTAssertTrue(orderedSet1.elementsEqual([3, 2, 1]))

      var orderedSet2: _OrderedSet<String> = ["one", "two", "three"]
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))
      orderedSet2.removeAtIndex(1)
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "three"]))
      orderedSet2.removeAtIndex(0)
      XCTAssertTrue(orderedSet2.elementsEqual(["three"]))
      orderedSet2.insert("two")
      orderedSet2.insert("one")
      XCTAssertTrue(orderedSet2.elementsEqual(["three", "two", "one"]))
    }
  }

  func test_OrderedSetCOW() {
    measureBlock {
      var orderedSet1: _OrderedSet<Int> = [1, 2, 3]
      var orderedSet2 = orderedSet1
      XCTAssertTrue(orderedSet1.owner === orderedSet2.owner)
      XCTAssertTrue(orderedSet1.buffer.storage === orderedSet2.buffer.storage)

      orderedSet2.insert(4)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))
      XCTAssertTrue(orderedSet2.elementsEqual([1, 2, 3, 4]))
      XCTAssertFalse(orderedSet1.owner === orderedSet2.owner)
      XCTAssertFalse(orderedSet1.buffer.storage === orderedSet2.buffer.storage)
    }
  }

  func test_OrderedSetSubscriptAccessors() {
    measureBlock {
      var orderedSet: _OrderedSet<Int> = [1, 2, 3]
      XCTAssertEqual(orderedSet[0], 1)
      XCTAssertEqual(orderedSet[1], 2)
      XCTAssertEqual(orderedSet[2], 3)
    }
  }

  func test_OrderedSetUnion() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)

      var orderedSet = _OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.unionInPlace(randoms2)
      set.unionInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func test_OrderedSetIntersection() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = _OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.intersectInPlace(randoms2)
      set.intersectInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func test_OrderedSetMinus() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = _OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.subtractInPlace(randoms2)
      set.subtractInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func test_OrderedSetXOR() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = _OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.exclusiveOrInPlace(randoms2)
      set.exclusiveOrInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func test_OrderedSetPerformanceWithCapacityReserved() {
    measureBlock {
      var s = _OrderedSet<Int>(minimumCapacity: 1500)
      for _ in 0 ..< 1000 { s.insert(numericCast(arc4random() % 1000 + 1)) }
      var removed = 0
      for _ in 0 ..< 500 { s.removeAtIndex(numericCast(arc4random()) % s.count) }
      for i in 1000 ..< 1200 { s.insert(i) }
    }
  }

  func test_OrderedSetPerformanceWithoutCapacityReserved() {
    measureBlock {
      var s: _OrderedSet<Int> = []
      for _ in 0 ..< 1000 { s.insert(numericCast(arc4random() % 1000 + 1)) }
      for _ in 0 ..< 500 { s.removeAtIndex(numericCast(arc4random()) % s.count) }
      for i in 1000 ..< 1200 { s.insert(i) }
    }
  }

  func testOrderedSetCreation() {
    measureBlock {
      var orderedSet = OrderedSet<Int>(minimumCapacity: 8)
      XCTAssertGreaterThanOrEqual(orderedSet.capacity, 8)
      XCTAssertEqual(orderedSet.count, 0)

      orderedSet = [1, 2, 3, 4, 5]
      XCTAssertGreaterThanOrEqual(orderedSet.capacity, 5)
      XCTAssertEqual(orderedSet.count, 5)

      let randoms = self.randomIntegers(100000, 1 ..< 1000)

      orderedSet = OrderedSet(randoms)
      let set = Set(randoms)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func testOrderedSetInsertion() {
    measureBlock {
      var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)

      orderedSet1.insert(1)
      XCTAssertEqual(orderedSet1.count, 1)
      XCTAssertEqual(orderedSet1[0], 1)
      XCTAssertTrue(orderedSet1.elementsEqual([1]))

      orderedSet1.insert(2)
      XCTAssertEqual(orderedSet1.count, 2)
      XCTAssertEqual(orderedSet1[1], 2)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2]))

      orderedSet1.insert(3)
      XCTAssertEqual(orderedSet1.count, 3)
      XCTAssertEqual(orderedSet1[2], 3)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))

      orderedSet1.insert(4)
      XCTAssertEqual(orderedSet1.count, 4)
      XCTAssertEqual(orderedSet1[3], 4)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4]))

      orderedSet1.insert(5)
      XCTAssertEqual(orderedSet1.count, 5)
      XCTAssertEqual(orderedSet1[4], 5)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5]))

      var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)

      orderedSet2.insert("one")
      XCTAssertEqual(orderedSet2.count, 1)
      XCTAssertEqual(orderedSet2[0], "one")
      XCTAssertTrue(orderedSet2.elementsEqual(["one"]))

      orderedSet2.insert("two")
      XCTAssertEqual(orderedSet2.count, 2)
      XCTAssertEqual(orderedSet2[1], "two")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two"]))

      orderedSet2.insert("three")
      XCTAssertEqual(orderedSet2.count, 3)
      XCTAssertEqual(orderedSet2[2], "three")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))

      orderedSet2.insert("four")
      XCTAssertEqual(orderedSet2.count, 4)
      XCTAssertEqual(orderedSet2[3], "four")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four"]))

      orderedSet2.insert("five")
      XCTAssertEqual(orderedSet2.count, 5)
      XCTAssertEqual(orderedSet2[4], "five")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five"]))
    }
  }

  func testOrderedSetResize() {
    measureBlock {
      var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)
      orderedSet1.insert(1)
      orderedSet1.insert(2)
      orderedSet1.insert(3)
      orderedSet1.insert(4)
      orderedSet1.insert(5)
      orderedSet1.insert(6)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6]))
      orderedSet1.insert(7)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7]))
      orderedSet1.insert(8)
      orderedSet1.insert(9)
      orderedSet1.insert(10)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))

      var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)
      orderedSet2.insert("one")
      orderedSet2.insert("two")
      orderedSet2.insert("three")
      orderedSet2.insert("four")
      orderedSet2.insert("five")
      orderedSet2.insert("six")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six"]))
      orderedSet2.insert("seven")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven"]))
      orderedSet2.insert("eight")
      orderedSet2.insert("nine")
      orderedSet2.insert("ten")
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]))
    }
  }

  func testOrderedSetDeletion() {
    measureBlock {
      var orderedSet1: OrderedSet<Int> = [1, 2, 3]
      XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))
      orderedSet1.removeAtIndex(1)
      XCTAssertTrue(orderedSet1.elementsEqual([1, 3]))
      orderedSet1.removeAtIndex(0)
      XCTAssertTrue(orderedSet1.elementsEqual([3]))
      orderedSet1.insert(2)
      orderedSet1.insert(1)
      XCTAssertTrue(orderedSet1.elementsEqual([3, 2, 1]))

      var orderedSet2: OrderedSet<String> = ["one", "two", "three"]
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))
      orderedSet2.removeAtIndex(1)
      XCTAssertTrue(orderedSet2.elementsEqual(["one", "three"]))
      orderedSet2.removeAtIndex(0)
      XCTAssertTrue(orderedSet2.elementsEqual(["three"]))
      orderedSet2.insert("two")
      orderedSet2.insert("one")
      XCTAssertTrue(orderedSet2.elementsEqual(["three", "two", "one"]))
    }
  }

  func testOrderedSetCOW() {
    measureBlock {
      var orderedSet1: OrderedSet<Int> = [1, 2, 3]
      var orderedSet2 = orderedSet1
      XCTAssertTrue(orderedSet1.elementsEqual(orderedSet2))

      orderedSet2.insert(4)
      XCTAssertFalse(orderedSet1.elementsEqual(orderedSet2))
    }
  }

  func testOrderedSetSubscriptAccessors() {
    measureBlock {
      var orderedSet: OrderedSet<Int> = [1, 2, 3]
      XCTAssertEqual(orderedSet[0], 1)
      XCTAssertEqual(orderedSet[1], 2)
      XCTAssertEqual(orderedSet[2], 3)
    }
  }

  func testOrderedSetUnion() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.unionInPlace(randoms2)
      set.unionInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func testOrderedSetIntersection() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.intersectInPlace(randoms2)
      set.intersectInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func testOrderedSetMinus() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.subtractInPlace(randoms2)
      set.subtractInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func testOrderedSetXOR() {
    measureBlock {
      let randoms1 = self.randomIntegers(100000, 1 ..< 1000)
      let randoms2 = self.randomIntegers(100000, 1 ..< 1000)
      var orderedSet = OrderedSet(randoms1)
      var set = Set(randoms1)
      orderedSet.exclusiveOrInPlace(randoms2)
      set.exclusiveOrInPlace(randoms2)
      XCTAssertEqual(orderedSet.count, set.count)
    }
  }

  func testOrderedSetPerformanceWithCapacityReserved() {
    measureBlock {
      var s = OrderedSet<Int>(minimumCapacity: 1500)
      for _ in 0 ..< 1000 { s.insert(numericCast(arc4random() % 1000 + 1)) }
      for _ in 0 ..< 500 { s.removeAtIndex(numericCast(arc4random()) % s.count) }
      for i in 1000 ..< 1200 { s.insert(i) }
    }
  }

  func testOrderedSetPerformanceWithoutCapacityReserved() {
    measureBlock {
      var s: OrderedSet<Int> = []
      for _ in 0 ..< 1000 { s.insert(numericCast(arc4random() % 1000 + 1)) }
      for _ in 0 ..< 500 { s.removeAtIndex(numericCast(arc4random()) % s.count) }
      for i in 1000 ..< 1200 { s.insert(i) }
    }
  }

}
