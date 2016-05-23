//
//  OrderedSetTests.swift
//  OrderedSetTests
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

final class OrderedSetTests: XCTestCase {

  func performanceWork<
    S:SetType
    where S.Generator.Element == Int
    >(createSet: (capacity: Int) -> S) -> () -> Void
  {

    return {
      var set = createSet(capacity: 2048)
      for value in randomIntegersLarge1 { set.insert(value) }
      for value in randomIntegersLarge2 { set.remove(value) }
      set.unionInPlace(randomIntegersLarge2)
      set.subtractInPlace(randomIntegersLarge1)
      set.exclusiveOrInPlace(randomIntegersLarge1)
      set.intersectInPlace(randomIntegersLarge2)
    }
  }

  func testCreation() {
    var orderedSet = OrderedSet<Int>(minimumCapacity: 8)
    expect(orderedSet.capacity) >= 8
    guard expect(orderedSet).to(haveCount(0)) else { return }

    orderedSet = [1, 2, 3, 4, 5]
    expect(orderedSet.capacity) >= 5
    guard expect(orderedSet).to(haveCount(5)) else { return }

    orderedSet = OrderedSet(randomIntegersLarge1)
    let set = Set(randomIntegersLarge1)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testInsertion() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    guard expect(orderedSet1).to(haveCount(1)) else { return }
    expect(orderedSet1[0]) == 1
    expect(orderedSet1) == [1]

    orderedSet1.insert(2)
    guard expect(orderedSet1).to(haveCount(2)) else { return }
    expect(orderedSet1[1]) == 2
    expect(orderedSet1) == [1, 2]

    orderedSet1.insert(3)
    guard expect(orderedSet1).to(haveCount(3)) else { return }
    expect(orderedSet1[2]) == 3
    expect(orderedSet1) == [1, 2, 3]

    orderedSet1.insert(4)
    guard expect(orderedSet1).to(haveCount(4)) else { return }
    expect(orderedSet1[3]) == 4
    expect(orderedSet1) == [1, 2, 3, 4]

    orderedSet1.insert(5)
    guard expect(orderedSet1).to(haveCount(5)) else { return }
    expect(orderedSet1[4]) == 5
    expect(orderedSet1) == [1, 2, 3, 4, 5]

    orderedSet1.insert(6, atIndex: 2)
    guard expect(orderedSet1).to(haveCount(6)) else { return }
    expect(orderedSet1[2]) == 6
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5]

    orderedSet1.appendContentsOf([5, 6, 7, 8])
    guard expect(orderedSet1).to(haveCount(8)) else { return }
    expect(orderedSet1[6]) == 7
    expect(orderedSet1[7]) == 8
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 7, 8]

    orderedSet1.insertContentsOf([1, 3, 9, 10], at: 6)
    expect(orderedSet1).to(haveCount(10))
    expect(orderedSet1[6]) == 9
    expect(orderedSet1[7]) == 10
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 9, 10, 7, 8]

    var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    guard expect(orderedSet2).to(haveCount(1)) else { return }
    expect(orderedSet2[0]) == "one"
    expect(orderedSet2) == ["one"]

    orderedSet2.insert("two")
    guard expect(orderedSet2).to(haveCount(2)) else { return }
    expect(orderedSet2[1]) == "two"
    expect(orderedSet2) == ["one", "two"]

    orderedSet2.insert("three")
    guard expect(orderedSet2).to(haveCount(3)) else { return }
    expect(orderedSet2[2]) == "three"
    expect(orderedSet2) == ["one", "two", "three"]

    orderedSet2.insert("four")
    guard expect(orderedSet2).to(haveCount(4)) else { return }
    expect(orderedSet2[3]) == "four"
    expect(orderedSet2) == ["one", "two", "three", "four"]

    orderedSet2.insert("five")
    guard expect(orderedSet2).to(haveCount(5)) else { return }
    expect(orderedSet2[4]) == "five"
    expect(orderedSet2) == ["one", "two", "three", "four", "five"]

    orderedSet2.insert("six", atIndex: 2)
    guard expect(orderedSet2).to(haveCount(6)) else { return }
    expect(orderedSet2[2]) == "six"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five"]

    orderedSet2.appendContentsOf(["five", "six", "seven", "eight"])
    guard expect(orderedSet2).to(haveCount(8)) else { return }
    expect(orderedSet2[6]) == "seven"
    expect(orderedSet2[7]) == "eight"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "seven", "eight"]

    orderedSet2.insertContentsOf(["one", "three", "nine", "ten"], at: 6)
    expect(orderedSet2).to(haveCount(10))
    expect(orderedSet2[6]) == "nine"
    expect(orderedSet2[7]) == "ten"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "nine", "ten", "seven", "eight"]

  }

  func testInsertionPerformance() {
    measureBlock {
      var orderedSet = OrderedSet<Int>()
      for i in randomIntegersLarge1 { orderedSet.insert(i) }
    }
  }

  func testResize() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)
    orderedSet1.insert(1)
    orderedSet1.insert(2)
    orderedSet1.insert(3)
    orderedSet1.insert(4)
    orderedSet1.insert(5)
    orderedSet1.insert(6)
    expect(orderedSet1) == [1, 2, 3, 4, 5, 6]
    orderedSet1.insert(7)
    expect(orderedSet1) == [1, 2, 3, 4, 5, 6, 7]
    orderedSet1.insert(8)
    orderedSet1.insert(9)
    orderedSet1.insert(10)
    expect(orderedSet1) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)
    orderedSet2.insert("one")
    orderedSet2.insert("two")
    orderedSet2.insert("three")
    orderedSet2.insert("four")
    orderedSet2.insert("five")
    orderedSet2.insert("six")
    expect(orderedSet2) == ["one", "two", "three", "four", "five", "six"]
    orderedSet2.insert("seven")
    expect(orderedSet2) == ["one", "two", "three", "four", "five", "six", "seven"]
    orderedSet2.insert("eight")
    orderedSet2.insert("nine")
    orderedSet2.insert("ten")
    expect(orderedSet2) == ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
  }

  func testDeletion() {
    var orderedSet1: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet1) == [1, 2, 3]
    orderedSet1.removeAtIndex(1)
    expect(orderedSet1) == [1, 3]
    orderedSet1.removeAtIndex(0)
    expect(orderedSet1) == [3]
    orderedSet1.insert(2)
    orderedSet1.insert(1)
    expect(orderedSet1) == [3, 2, 1]
    orderedSet1.remove(2)
    expect(orderedSet1) == [3, 1]
    orderedSet1.remove(9)
    expect(orderedSet1) == [3, 1]
    orderedSet1.removeFirst()
    expect(orderedSet1) == [1]
    orderedSet1.appendContentsOf([2, 3, 4, 5, 6])
    expect(orderedSet1) == [1, 2, 3, 4, 5, 6]
    orderedSet1.removeFirst(2)
    expect(orderedSet1) == [3, 4, 5, 6]
    orderedSet1.removeRange(1 ..< 3)
    expect(orderedSet1) == [3, 6]
    orderedSet1.removeAll()
    expect(orderedSet1).to(beEmpty())

    var orderedSet2: OrderedSet<String> = ["one", "two", "three"]
    expect(orderedSet2) == ["one", "two", "three"]
    orderedSet2.removeAtIndex(1)
    expect(orderedSet2) == ["one", "three"]
    orderedSet2.removeAtIndex(0)
    expect(orderedSet2) == ["three"]
    orderedSet2.insert("two")
    orderedSet2.insert("one")
    expect(orderedSet2) == ["three", "two", "one"]
    orderedSet2.remove("two")
    expect(orderedSet2) == ["three", "one"]
    orderedSet2.remove("nine")
    expect(orderedSet2) == ["three", "one"]
    orderedSet2.removeFirst()
    expect(orderedSet2) == ["one"]
    orderedSet2.appendContentsOf(["two", "three", "four", "five", "six"])
    expect(orderedSet2) == ["one", "two", "three", "four", "five", "six"]
    orderedSet2.removeFirst(2)
    expect(orderedSet2) == ["three", "four", "five", "six"]
    orderedSet2.removeRange(1 ..< 3)
    expect(orderedSet2) == ["three", "six"]
    orderedSet2.removeAll()
    expect(orderedSet2).to(beEmpty())
  }

  func testDeletePerformance() {
    measureBlock {
      var orderedSet = OrderedSet<Int>(randomIntegersLarge1)
      for i in randomIntegersLarge1 { orderedSet.remove(i) }
    }
  }

  func testReplaceRange() {
    var orderedSet: OrderedSet<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(0 ..< 5, with: [5, 4, 3, 2, 1])
    expect(orderedSet) == [5, 4, 3, 2, 1, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(5 ..< 10, with: [0])
    expect(orderedSet) == [5, 4, 3, 2, 1, 0]
  }

  func testReplaceRangePerformance() {
    measureBlock {
      var orderedSet = OrderedSet<Int>(randomIntegersLarge1)
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: randomIntegersLarge2[range])
      }
    }
  }

  func testCOW() {
    let orderedSet1: OrderedSet<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    expect(orderedSet1) == orderedSet2

    orderedSet2.insert(4)
    expect(orderedSet1) != orderedSet2
  }

  func testSubscriptAccessors() {
    var orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet[0]) == 1
    expect(orderedSet[1]) == 2
    expect(orderedSet[2]) == 3
  }

  func testSubsetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).to(beSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).toNot(beSubsetOf([1, 2, 4]))
  }

  func testStrictSubsetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).toNot(beStrictSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).toNot(beStrictSubsetOf([1, 2, 4]))
  }

  func testSupersetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).to(beSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beSupersetOf([1, 2]))
    expect(orderedSet).toNot(beSupersetOf([1, 2, 4]))
  }

  func testStrictSupersetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).toNot(beStrictSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSupersetOf([1, 2]))
    expect(orderedSet).toNot(beStrictSupersetOf([1, 2, 4]))
  }

  func testDisjointWith() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).toNot(beDisjointWith([1, 4, 5] as Array<Int>))
    expect(orderedSet).to(beDisjointWith([4, 5] as Array<Int>))
    expect(orderedSet).toNot(beDisjointWith([1, 2, 3, 4, 5] as Array<Int>))
  }

  func testUnion() {
    var orderedSet = OrderedSet(randomIntegersLarge1)
    orderedSet.unionInPlace(randomIntegersLarge2)
    var set = Set(randomIntegersLarge1)
    set.unionInPlace(randomIntegersLarge2)
    expect(orderedSet).to(haveCount(set.count))
  }


  func testUnionPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.union($1)})
    measureBlock(work)
  }

  func testIntersection() {
    var orderedSet = OrderedSet(randomIntegersLarge1)
    orderedSet.intersectInPlace(randomIntegersLarge2)
    var set = Set(randomIntegersLarge1)
    set.intersectInPlace(randomIntegersLarge2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testIntersectionPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.intersect($1)})
    measureBlock(work)
  }

  func testSubtract() {
    var orderedSet = OrderedSet(randomIntegersLarge1)
    orderedSet.subtractInPlace(randomIntegersLarge2)
    var set = Set(randomIntegersLarge1)
    set.subtractInPlace(randomIntegersLarge2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testSubtractPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXOR() {
    var orderedSet = OrderedSet(randomIntegersLarge1)
    var set = Set(randomIntegersLarge1)
    set.exclusiveOrInPlace(randomIntegersLarge2)
    orderedSet.exclusiveOrInPlace(randomIntegersLarge2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testXORPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.exclusiveOr($1)})
    measureBlock(work)
  }

  func testOverallPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedSet<Int>(minimumCapacity: $0) })
  }
  
  func testOverallPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedSet<Int>() })
  }
}
