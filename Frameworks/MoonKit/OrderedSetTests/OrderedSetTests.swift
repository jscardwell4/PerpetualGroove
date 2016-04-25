//
//  OrderedSetTests.swift
//  OrderedSetTests
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import Nimble
//import MoonKitTest
@testable import MoonKitTest

func randomIntegers(count: Int, _ range: Range<Int>) -> [Int] {
  func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
  var result = Array<Int>(minimumCapacity: count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

func randomRange(count: Int, coverage: Double) -> Range<Int> {
  let length = Int(Double(count) * coverage)
  let end = Int(arc4random()) % count
  let start = max(0, end - length)
  return start ..< end
}

let randoms1 = randomIntegers(10000, 0 ..< 2000)
let randoms2 = randomIntegers(10000, 0 ..< 2000)
let randoms3 = randomIntegers(50000, 0 ..< 10000)
let randoms4 = randomIntegers(50000, 0 ..< 10000)
let randoms5 = randomIntegers(500, 0 ..< 250)
let randoms6 = randomIntegers(500, 0 ..< 250)

final class OrderedSetTests: XCTestCase {

  func perform<
    S:SetType where S.Generator.Element == Int, S.Element == Int
    >(@noescape createTarget: (values: [Int]) -> S, execute: (target: S, values: [Int]) -> Void) -> () -> Void
  {
    var target = createTarget(values: randoms1)
    return {
      autoreleasepool { execute(target: target, values: randoms2) }
    }

  }

  func performanceWork<
    S:SetType
    where S.Generator.Element == Int, S.Element == Int
    >(createSet: (capacity: Int) -> S) -> () -> Void
  {

    return {
      var set = createSet(capacity: 2048)
      for value in randoms1 { set.insert(value) }
      for value in randoms2 { set.remove(value) }
      set.unionInPlace(randoms2)
      set.subtractInPlace(randoms1)
      set.exclusiveOrInPlace(randoms1)
      set.intersectInPlace(randoms2)
    }
  }
/*
  func testCreation() {
    var orderedSet = OrderedSet<Int>(minimumCapacity: 8)
    expect(orderedSet.capacity) >= 8
    expect(orderedSet).to(haveCount(0))

    orderedSet = [1, 2, 3, 4, 5]
    expect(orderedSet.capacity) >= 5
    expect(orderedSet).to(haveCount(5))

    let randoms = randomIntegers(100000, 1 ..< 1000)

    orderedSet = OrderedSet(randoms)
    let set = Set(randoms)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testInsertion() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    expect(orderedSet1).to(haveCount(1))
    expect(orderedSet1[0]) == 1
    expect(orderedSet1) == [1]

    orderedSet1.insert(2)
    expect(orderedSet1).to(haveCount(2))
    expect(orderedSet1[1]) == 2
    expect(orderedSet1) == [1, 2]

    orderedSet1.insert(3)
    expect(orderedSet1).to(haveCount(3))
    expect(orderedSet1[2]) == 3
    expect(orderedSet1) == [1, 2, 3]

    orderedSet1.insert(4)
    expect(orderedSet1).to(haveCount(4))
    expect(orderedSet1[3]) == 4
    expect(orderedSet1) == [1, 2, 3, 4]

    orderedSet1.insert(5)
    expect(orderedSet1).to(haveCount(5))
    expect(orderedSet1[4]) == 5
    expect(orderedSet1) == [1, 2, 3, 4, 5]

    orderedSet1.insert(6, atIndex: 2)
    expect(orderedSet1).to(haveCount(6))
    expect(orderedSet1[2]) == 6
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5]

    orderedSet1.appendContentsOf([5, 6, 7, 8])
    expect(orderedSet1).to(haveCount(8))
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
    expect(orderedSet2).to(haveCount(1))
    expect(orderedSet2[0]) == "one"
    expect(orderedSet2) == ["one"]

    orderedSet2.insert("two")
    expect(orderedSet2).to(haveCount(2))
    expect(orderedSet2[1]) == "two"
    expect(orderedSet2) == ["one", "two"]

    orderedSet2.insert("three")
    expect(orderedSet2).to(haveCount(3))
    expect(orderedSet2[2]) == "three"
    expect(orderedSet2) == ["one", "two", "three"]

    orderedSet2.insert("four")
    expect(orderedSet2).to(haveCount(4))
    expect(orderedSet2[3]) == "four"
    expect(orderedSet2) == ["one", "two", "three", "four"]

    orderedSet2.insert("five")
    expect(orderedSet2).to(haveCount(5))
    expect(orderedSet2[4]) == "five"
    expect(orderedSet2) == ["one", "two", "three", "four", "five"]

    orderedSet2.insert("six", atIndex: 2)
    expect(orderedSet2).to(haveCount(6))
    expect(orderedSet2[2]) == "six"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five"]

    orderedSet2.appendContentsOf(["five", "six", "seven", "eight"])
    expect(orderedSet2).to(haveCount(8))
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
      for i in randoms1 { orderedSet.insert(i) }
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
      var orderedSet = OrderedSet<Int>(randoms1)
      for i in randoms1 { orderedSet.remove(i) }
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
    var orderedSet = OrderedSet<Int>(randoms1)
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: randoms2[range])
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
    expect(orderedSet).to(notBeSubsetOf([1, 2, 4]))
  }

  func testStrictSubsetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 4]))
  }

  func testSupersetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).to(beSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beSupersetOf([1, 2]))
    expect(orderedSet).to(notBeSupersetOf([1, 2, 4]))
  }

  func testStrictSupersetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSupersetOf([1, 2]))
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 4]))
  }

  func testDisjointWith() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeDisjointWith([1, 4, 5]))
    expect(orderedSet).to(beDisjointWith([4, 5]))
    expect(orderedSet).to(notBeDisjointWith([1, 2, 3, 4, 5]))
  }

  func testUnion() {
    var orderedSet = OrderedSet(randoms1)
    orderedSet.unionInPlace(randoms2)
    var set = Set(randoms1)
    set.unionInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testUnionPerformance() {
    let work = perform({OrderedSet<Int>($0)}, execute: {_ = $0.union($1)})
    measureBlock(work)
  }

  func testIntersection() {
    var orderedSet = OrderedSet(randoms1)
    orderedSet.intersectInPlace(randoms2)
    var set = Set(randoms1)
    set.intersectInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testIntersectionPerformance() {
    let work = perform({OrderedSet<Int>($0)}, execute: {_ = $0.intersect($1)})
    measureBlock(work)
  }

  func testSubtract() {
    var orderedSet = OrderedSet(randoms1)
    orderedSet.subtractInPlace(randoms2)
    var set = Set(randoms1)
    set.subtractInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testSubtractPerformance() {
    let work = perform({OrderedSet<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXOR() {
    var orderedSet = OrderedSet(randoms1)
    var set = Set(randoms1)
    set.exclusiveOrInPlace(randoms2)
    orderedSet.exclusiveOrInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testXORPerformance() {
    let work = perform({OrderedSet<Int>($0)}, execute: {_ = $0.exclusiveOr($1)})
    measureBlock(work)
  }

  func testPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedSet<Int>(minimumCapacity: $0) })
  }

  func testPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedSet<Int>() })
  }

  func testCreation2() {
    var orderedSet = OrderedSet2<Int>(minimumCapacity: 8)
    expect(orderedSet.capacity) >= 8
    expect(orderedSet).to(haveCount(0))

    orderedSet = [1, 2, 3, 4, 5]
    expect(orderedSet.capacity) >= 5
    expect(orderedSet).to(haveCount(5))

    let randoms = randomIntegers(100000, 1 ..< 1000)

    orderedSet = OrderedSet2(randoms)
    let set = Set(randoms)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testInsertion2() {
    var orderedSet1 = OrderedSet2<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    expect(orderedSet1).to(haveCount(1))
    expect(orderedSet1[0]) == 1
    expect(orderedSet1) == [1]

    orderedSet1.insert(2)
    expect(orderedSet1).to(haveCount(2))
    expect(orderedSet1[1]) == 2
    expect(orderedSet1) == [1, 2]

    orderedSet1.insert(3)
    expect(orderedSet1).to(haveCount(3))
    expect(orderedSet1[2]) == 3
    expect(orderedSet1) == [1, 2, 3]

    orderedSet1.insert(4)
    expect(orderedSet1).to(haveCount(4))
    expect(orderedSet1[3]) == 4
    expect(orderedSet1) == [1, 2, 3, 4]

    orderedSet1.insert(5)
    expect(orderedSet1).to(haveCount(5))
    expect(orderedSet1[4]) == 5
    expect(orderedSet1) == [1, 2, 3, 4, 5]

    orderedSet1.insert(6, atIndex: 2)
    expect(orderedSet1).to(haveCount(6))
    expect(orderedSet1[2]) == 6
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5]

    orderedSet1.appendContentsOf([5, 6, 7, 8])
    expect(orderedSet1).to(haveCount(8))
    expect(orderedSet1[6]) == 7
    expect(orderedSet1[7]) == 8
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 7, 8]

    orderedSet1.insertContentsOf([1, 3, 9, 10], at: 6)
    expect(orderedSet1).to(haveCount(10))
    expect(orderedSet1[6]) == 9
    expect(orderedSet1[7]) == 10
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 9, 10, 7, 8]

    var orderedSet2 = OrderedSet2<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    expect(orderedSet2).to(haveCount(1))
    expect(orderedSet2[0]) == "one"
    expect(orderedSet2) == ["one"]

    orderedSet2.insert("two")
    expect(orderedSet2).to(haveCount(2))
    expect(orderedSet2[1]) == "two"
    expect(orderedSet2) == ["one", "two"]

    orderedSet2.insert("three")
    expect(orderedSet2).to(haveCount(3))
    expect(orderedSet2[2]) == "three"
    expect(orderedSet2) == ["one", "two", "three"]

    orderedSet2.insert("four")
    expect(orderedSet2).to(haveCount(4))
    expect(orderedSet2[3]) == "four"
    expect(orderedSet2) == ["one", "two", "three", "four"]

    orderedSet2.insert("five")
    expect(orderedSet2).to(haveCount(5))
    expect(orderedSet2[4]) == "five"
    expect(orderedSet2) == ["one", "two", "three", "four", "five"]

    orderedSet2.insert("six", atIndex: 2)
    expect(orderedSet2).to(haveCount(6))
    expect(orderedSet2[2]) == "six"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five"]

    orderedSet2.appendContentsOf(["five", "six", "seven", "eight"])
    expect(orderedSet2).to(haveCount(8))
    expect(orderedSet2[6]) == "seven"
    expect(orderedSet2[7]) == "eight"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "seven", "eight"]

    orderedSet2.insertContentsOf(["one", "three", "nine", "ten"], at: 6)
    expect(orderedSet2).to(haveCount(10))
    expect(orderedSet2[6]) == "nine"
    expect(orderedSet2[7]) == "ten"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "nine", "ten", "seven", "eight"]

  }

  func testInsertionPerformance2() {
    measureBlock {
      var orderedSet = OrderedSet2<Int>()
      for i in randoms1 { orderedSet.insert(i) }
    }
  }

  func testResize2() {
    var orderedSet1 = OrderedSet2<Int>(minimumCapacity: 8)
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

    var orderedSet2 = OrderedSet2<String>(minimumCapacity: 8)
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

  func testDeletion2() {
    var orderedSet1: OrderedSet2<Int> = [1, 2, 3]
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

    var orderedSet2: OrderedSet2<String> = ["one", "two", "three"]
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

  func testDeletePerformance2() {
    measureBlock {
      var orderedSet = OrderedSet2<Int>(randoms1)
      for i in randoms1 { orderedSet.remove(i) }
    }
  }

  func testReplaceRange2() {
    var orderedSet: OrderedSet2<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(0 ..< 5, with: [5, 4, 3, 2, 1])
    expect(orderedSet) == [5, 4, 3, 2, 1, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(5 ..< 10, with: [0])
    expect(orderedSet) == [5, 4, 3, 2, 1, 0]
  }

  func testReplaceRangePerformance2() {
    measureBlock {
      var orderedSet = OrderedSet2<Int>(randoms1)
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: randoms2[range])
      }
    }
  }

  func testCOW2() {
    let orderedSet1: OrderedSet2<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    expect(orderedSet1) == orderedSet2

    orderedSet2.insert(4)
    expect(orderedSet1) != orderedSet2
  }

  func testSubscriptAccessors2() {
    var orderedSet: OrderedSet2<Int> = [1, 2, 3]
    expect(orderedSet[0]) == 1
    expect(orderedSet[1]) == 2
    expect(orderedSet[2]) == 3
  }

  func testSubsetOf2() {
    let orderedSet: OrderedSet2<Int> = [1, 2, 3]
    expect(orderedSet).to(beSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeSubsetOf([1, 2, 4]))
  }

  func testStrictSubsetOf2() {
    let orderedSet: OrderedSet2<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 4]))
  }

  func testSupersetOf2() {
    let orderedSet: OrderedSet2<Int> = [1, 2, 3]
    expect(orderedSet).to(beSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beSupersetOf([1, 2]))
    expect(orderedSet).to(notBeSupersetOf([1, 2, 4]))
  }

  func testStrictSupersetOf2() {
    let orderedSet: OrderedSet2<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSupersetOf([1, 2]))
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 4]))
  }

  func testDisjointWith2() {
    let orderedSet: OrderedSet2<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeDisjointWith([1, 4, 5]))
    expect(orderedSet).to(beDisjointWith([4, 5]))
    expect(orderedSet).to(notBeDisjointWith([1, 2, 3, 4, 5]))
  }

  func testUnion2() {
    var orderedSet = OrderedSet2(randoms1)
    orderedSet.unionInPlace(randoms2)
    var set = Set(randoms1)
    set.unionInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }


  func testUnionPerformance2() {
    let work = perform({OrderedSet2<Int>($0)}, execute: {_ = $0.union($1)})
    measureBlock(work)
  }

  func testIntersection2() {
    var orderedSet = OrderedSet2(randoms1)
    orderedSet.intersectInPlace(randoms2)
    var set = Set(randoms1)
    set.intersectInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testIntersectionPerformance2() {
    let work = perform({OrderedSet2<Int>($0)}, execute: {_ = $0.intersect($1)})
    measureBlock(work)
  }

  func testSubtract2() {
    var orderedSet = OrderedSet2(randoms1)
    orderedSet.subtractInPlace(randoms2)
    var set = Set(randoms1)
    set.subtractInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testSubtractPerformance2() {
    let work = perform({OrderedSet2<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXOR2() {
    var orderedSet = OrderedSet2(randoms1)
    var set = Set(randoms1)
    set.exclusiveOrInPlace(randoms2)
    orderedSet.exclusiveOrInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testXORPerformance2() {
    let work = perform({OrderedSet2<Int>($0)}, execute: {_ = $0.exclusiveOr($1)})
    measureBlock(work)
  }

  func testPerformanceWithCapacityReserved2() {
    measureBlock(performanceWork { OrderedSet2<Int>(minimumCapacity: $0) })
  }
  
  func testPerformanceWithoutCapacityReserved2() {
    measureBlock(performanceWork { _ in OrderedSet2<Int>() })
  }

  func testCreation3() {
    var orderedSet = OrderedSet3<Int>(minimumCapacity: 8)
    expect(orderedSet.capacity) >= 8
    expect(orderedSet).to(haveCount(0))

    orderedSet = [1, 2, 3, 4, 5]
    expect(orderedSet.capacity) >= 5
    expect(orderedSet).to(haveCount(5))

    let randoms = randomIntegers(100000, 1 ..< 1000)

    orderedSet = OrderedSet3(randoms)
    let set = Set(randoms)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testInsertion3() {
    var orderedSet1 = OrderedSet3<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    expect(orderedSet1).to(haveCount(1))
    expect(orderedSet1[0]) == 1
    expect(orderedSet1) == [1]

    orderedSet1.insert(2)
    expect(orderedSet1).to(haveCount(2))
    expect(orderedSet1[1]) == 2
    expect(orderedSet1) == [1, 2]

    orderedSet1.insert(3)
    expect(orderedSet1).to(haveCount(3))
    expect(orderedSet1[2]) == 3
    expect(orderedSet1) == [1, 2, 3]

    orderedSet1.insert(4)
    expect(orderedSet1).to(haveCount(4))
    expect(orderedSet1[3]) == 4
    expect(orderedSet1) == [1, 2, 3, 4]

    orderedSet1.insert(5)
    expect(orderedSet1).to(haveCount(5))
    expect(orderedSet1[4]) == 5
    expect(orderedSet1) == [1, 2, 3, 4, 5]

    orderedSet1.insert(6, atIndex: 2)
    expect(orderedSet1).to(haveCount(6))
    expect(orderedSet1[2]) == 6
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5]

    orderedSet1.appendContentsOf([5, 6, 7, 8])
    expect(orderedSet1).to(haveCount(8))
    expect(orderedSet1[6]) == 7
    expect(orderedSet1[7]) == 8
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 7, 8]

    orderedSet1.insertContentsOf([1, 3, 9, 10], at: 6)
    expect(orderedSet1).to(haveCount(10))
    expect(orderedSet1[6]) == 9
    expect(orderedSet1[7]) == 10
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 9, 10, 7, 8]

    var orderedSet2 = OrderedSet3<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    expect(orderedSet2).to(haveCount(1))
    expect(orderedSet2[0]) == "one"
    expect(orderedSet2) == ["one"]

    orderedSet2.insert("two")
    expect(orderedSet2).to(haveCount(2))
    expect(orderedSet2[1]) == "two"
    expect(orderedSet2) == ["one", "two"]

    orderedSet2.insert("three")
    expect(orderedSet2).to(haveCount(3))
    expect(orderedSet2[2]) == "three"
    expect(orderedSet2) == ["one", "two", "three"]

    orderedSet2.insert("four")
    expect(orderedSet2).to(haveCount(4))
    expect(orderedSet2[3]) == "four"
    expect(orderedSet2) == ["one", "two", "three", "four"]

    orderedSet2.insert("five")
    expect(orderedSet2).to(haveCount(5))
    expect(orderedSet2[4]) == "five"
    expect(orderedSet2) == ["one", "two", "three", "four", "five"]

    orderedSet2.insert("six", atIndex: 2)
    expect(orderedSet2).to(haveCount(6))
    expect(orderedSet2[2]) == "six"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five"]

    orderedSet2.appendContentsOf(["five", "six", "seven", "eight"])
    expect(orderedSet2).to(haveCount(8))
    expect(orderedSet2[6]) == "seven"
    expect(orderedSet2[7]) == "eight"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "seven", "eight"]

    orderedSet2.insertContentsOf(["one", "three", "nine", "ten"], at: 6)
    expect(orderedSet2).to(haveCount(10))
    expect(orderedSet2[6]) == "nine"
    expect(orderedSet2[7]) == "ten"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "nine", "ten", "seven", "eight"]

  }

  func testInsertionPerformance3() {
    measureBlock {
      var orderedSet = OrderedSet3<Int>()
      for i in randoms1 { orderedSet.insert(i) }
    }
  }

  func testResize3() {
    var orderedSet1 = OrderedSet3<Int>(minimumCapacity: 8)
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

    var orderedSet2 = OrderedSet3<String>(minimumCapacity: 8)
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

  func testDeletion3() {
    var orderedSet1: OrderedSet3<Int> = [1, 2, 3]
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

    var orderedSet2: OrderedSet3<String> = ["one", "two", "three"]
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

  func testDeletePerformance3() {
    measureBlock {
      var orderedSet = OrderedSet3<Int>(randoms1)
      for i in randoms1 { orderedSet.remove(i) }
    }
  }

  func testReplaceRange3() {
    var orderedSet: OrderedSet3<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(0 ..< 5, with: [5, 4, 3, 2, 1])
    expect(orderedSet) == [5, 4, 3, 2, 1, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(5 ..< 10, with: [0])
    expect(orderedSet) == [5, 4, 3, 2, 1, 0]
  }

  func testReplaceRangePerformance3() {
    measureBlock {
      var orderedSet = OrderedSet3<Int>(randoms1)
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: randoms2[range])
      }
    }
  }

  func testCOW3() {
    let orderedSet1: OrderedSet3<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    expect(orderedSet1) == orderedSet2

    orderedSet2.insert(4)
    expect(orderedSet1) != orderedSet2
  }

  func testSubscriptAccessors3() {
    var orderedSet: OrderedSet3<Int> = [1, 2, 3]
    expect(orderedSet[0]) == 1
    expect(orderedSet[1]) == 2
    expect(orderedSet[2]) == 3
  }

  func testSubsetOf3() {
    let orderedSet: OrderedSet3<Int> = [1, 2, 3]
    expect(orderedSet).to(beSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeSubsetOf([1, 2, 4]))
  }

  func testStrictSubsetOf3() {
    let orderedSet: OrderedSet3<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 4]))
  }

  func testSupersetOf3() {
    let orderedSet: OrderedSet3<Int> = [1, 2, 3]
    expect(orderedSet).to(beSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beSupersetOf([1, 2]))
    expect(orderedSet).to(notBeSupersetOf([1, 2, 4]))
  }

  func testStrictSupersetOf3() {
    let orderedSet: OrderedSet3<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSupersetOf([1, 2]))
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 4]))
  }

  func testDisjointWith3() {
    let orderedSet: OrderedSet3<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeDisjointWith([1, 4, 5]))
    expect(orderedSet).to(beDisjointWith([4, 5]))
    expect(orderedSet).to(notBeDisjointWith([1, 2, 3, 4, 5]))
  }

  func testUnion3() {
    var orderedSet = OrderedSet3(randoms1)
    orderedSet.unionInPlace(randoms2)
    var set = Set(randoms1)
    set.unionInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }


  func testUnionPerformance3() {
    let work = perform({OrderedSet3<Int>($0)}, execute: {_ = $0.union($1)})
    measureBlock(work)
  }

  func testIntersection3() {
    var orderedSet = OrderedSet3(randoms1)
    orderedSet.intersectInPlace(randoms2)
    var set = Set(randoms1)
    set.intersectInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testIntersectionPerformance3() {
    let work = perform({OrderedSet3<Int>($0)}, execute: {_ = $0.intersect($1)})
    measureBlock(work)
  }

  func testSubtract3() {
    var orderedSet = OrderedSet3(randoms1)
    orderedSet.subtractInPlace(randoms2)
    var set = Set(randoms1)
    set.subtractInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testSubtractPerformance3() {
    let work = perform({OrderedSet3<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXOR3() {
    var orderedSet = OrderedSet3(randoms1)
    var set = Set(randoms1)
    set.exclusiveOrInPlace(randoms2)
    orderedSet.exclusiveOrInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testXORPerformance3() {
    let work = perform({OrderedSet3<Int>($0)}, execute: {_ = $0.exclusiveOr($1)})
    measureBlock(work)
  }

  func testPerformanceWithCapacityReserved3() {
    measureBlock(performanceWork { OrderedSet3<Int>(minimumCapacity: $0) })
  }
  
  func testPerformanceWithoutCapacityReserved3() {
    measureBlock(performanceWork { _ in OrderedSet3<Int>() })
  }
  func testBucketPositionMap() {
    let capacity = 30
    let bucketPositionMapStorage = UnsafeMutablePointer<Int>.alloc(capacity * 2)
    let bucketPositionMap = BucketPositionMap(storage: bucketPositionMapStorage, capacity: capacity)
    let hashValues = [
       1,  2, 23, 28,  8,
      24,  5, 26, 21, 29,
      19,  9, 10, 27, 12,
      16, 14, 15, 11,  6,
       4, 22, 23,  7,  3
    ]
    for (i, offset) in hashValues.enumerate() {
      bucketPositionMap[i] = Bucket(offset: offset, capacity: capacity)
    }
    expect(bucketPositionMap.endIndex) == 25
    expect(bucketPositionMap.offsetForIndex(2)) == 2
    expect(bucketPositionMap.offsetForIndex(5)) == 5
    expect(bucketPositionMap.offsetForIndex(11)) == 11
    expect(bucketPositionMap.offsetForIndex(12)) == 12
    expect(bucketPositionMap.offsetForIndex(21)) == 21
    bucketPositionMap.removeBucketAt(3) // 28
    expect(bucketPositionMap.offsetForIndex(2)) == 2
    expect(bucketPositionMap.offsetForIndex(5)) == 6
    expect(bucketPositionMap.offsetForIndex(11)) == 12
    expect(bucketPositionMap.offsetForIndex(12)) == 13
    expect(bucketPositionMap.offsetForIndex(21)) == 22
    expect(bucketPositionMap.endIndex) == 24
    bucketPositionMap.removeBucketAt(11) // 9
    expect(bucketPositionMap.offsetForIndex(2)) == 2
    expect(bucketPositionMap.offsetForIndex(5)) == 6
    expect(bucketPositionMap.offsetForIndex(11)) == 13
    expect(bucketPositionMap.offsetForIndex(12)) == 14
    expect(bucketPositionMap.offsetForIndex(21)) == 23
    expect(bucketPositionMap.endIndex) == 23
    bucketPositionMap.removeBucketAt(19) // 6
    expect(bucketPositionMap.offsetForIndex(2)) == 2
    expect(bucketPositionMap.offsetForIndex(5)) == 6
    expect(bucketPositionMap.offsetForIndex(11)) == 13
    expect(bucketPositionMap.offsetForIndex(12)) == 14
    expect(bucketPositionMap.offsetForIndex(21)) == 24
    expect(bucketPositionMap.endIndex) == 22

    for offset in [13, 17, 18, 20, 25, 28, 9, 6] {
      bucketPositionMap.appendBucket(Bucket(offset: offset, capacity: capacity))
    }

    for i in 0 ..< capacity {
      expect(bucketPositionMap.offsetForIndex(i)) == i
    }

  }
*/
  func testCreation4() {
    var orderedSet = OrderedSet4<Int>(minimumCapacity: 8)
    expect(orderedSet.capacity) >= 8
    expect(orderedSet).to(haveCount(0))

    orderedSet = [1, 2, 3, 4, 5]
    expect(orderedSet.capacity) >= 5
    expect(orderedSet).to(haveCount(5))

    let randoms = randomIntegers(100000, 1 ..< 1000)

    orderedSet = OrderedSet4(randoms)
    let set = Set(randoms)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testInsertion4() {
    var orderedSet1 = OrderedSet4<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    expect(orderedSet1).to(haveCount(1))
    expect(orderedSet1[0]) == 1
    expect(orderedSet1) == [1]

    orderedSet1.insert(2)
    expect(orderedSet1).to(haveCount(2))
    expect(orderedSet1[1]) == 2
    expect(orderedSet1) == [1, 2]

    orderedSet1.insert(3)
    expect(orderedSet1).to(haveCount(3))
    expect(orderedSet1[2]) == 3
    expect(orderedSet1) == [1, 2, 3]

    orderedSet1.insert(4)
    expect(orderedSet1).to(haveCount(4))
    expect(orderedSet1[3]) == 4
    expect(orderedSet1) == [1, 2, 3, 4]

    orderedSet1.insert(5)
    expect(orderedSet1).to(haveCount(5))
    expect(orderedSet1[4]) == 5
    expect(orderedSet1) == [1, 2, 3, 4, 5]

    orderedSet1.insert(6, atIndex: 2)
    expect(orderedSet1).to(haveCount(6))
    expect(orderedSet1[2]) == 6
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5]

    orderedSet1.appendContentsOf([5, 6, 7, 8])
    expect(orderedSet1).to(haveCount(8))
    expect(orderedSet1[6]) == 7
    expect(orderedSet1[7]) == 8
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 7, 8]

    orderedSet1.insertContentsOf([1, 3, 9, 10], at: 6)
    expect(orderedSet1).to(haveCount(10))
    expect(orderedSet1[6]) == 9
    expect(orderedSet1[7]) == 10
    expect(orderedSet1) == [1, 2, 6, 3, 4, 5, 9, 10, 7, 8]

    var orderedSet2 = OrderedSet4<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    expect(orderedSet2).to(haveCount(1))
    expect(orderedSet2[0]) == "one"
    expect(orderedSet2) == ["one"]

    orderedSet2.insert("two")
    expect(orderedSet2).to(haveCount(2))
    expect(orderedSet2[1]) == "two"
    expect(orderedSet2) == ["one", "two"]

    orderedSet2.insert("three")
    expect(orderedSet2).to(haveCount(3))
    expect(orderedSet2[2]) == "three"
    expect(orderedSet2) == ["one", "two", "three"]

    orderedSet2.insert("four")
    expect(orderedSet2).to(haveCount(4))
    expect(orderedSet2[3]) == "four"
    expect(orderedSet2) == ["one", "two", "three", "four"]

    orderedSet2.insert("five")
    expect(orderedSet2).to(haveCount(5))
    expect(orderedSet2[4]) == "five"
    expect(orderedSet2) == ["one", "two", "three", "four", "five"]

    orderedSet2.insert("six", atIndex: 2)
    expect(orderedSet2).to(haveCount(6))
    expect(orderedSet2[2]) == "six"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five"]

    orderedSet2.appendContentsOf(["five", "six", "seven", "eight"])
    expect(orderedSet2).to(haveCount(8))
    expect(orderedSet2[6]) == "seven"
    expect(orderedSet2[7]) == "eight"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "seven", "eight"]

    orderedSet2.insertContentsOf(["one", "three", "nine", "ten"], at: 6)
    expect(orderedSet2).to(haveCount(10))
    expect(orderedSet2[6]) == "nine"
    expect(orderedSet2[7]) == "ten"
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "nine", "ten", "seven", "eight"]

  }

  func testInsertionPerformance4() {
    measureBlock {
      var orderedSet = OrderedSet4<Int>()
      for i in randoms1 { orderedSet.insert(i) }
    }
  }

  func testResize4() {
    var orderedSet1 = OrderedSet4<Int>(minimumCapacity: 8)
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

    var orderedSet2 = OrderedSet4<String>(minimumCapacity: 8)
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

  func testDeletion4() {
    var orderedSet1: OrderedSet4<Int> = [1, 2, 3]
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

    var orderedSet2: OrderedSet4<String> = ["one", "two", "three"]
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

  func testDeletePerformance4() {
    measureBlock {
      var orderedSet = OrderedSet4<Int>(randoms1)
      for i in randoms1 { orderedSet.remove(i) }
    }
  }

  func testReplaceRange4() {
    var orderedSet: OrderedSet4<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(0 ..< 5, with: [5, 4, 3, 2, 1])
    expect(orderedSet) == [5, 4, 3, 2, 1, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(5 ..< 10, with: [0])
    expect(orderedSet) == [5, 4, 3, 2, 1, 0]
  }

  func testReplaceRangePerformance4() {
    measureBlock {
      var orderedSet = OrderedSet4<Int>(randoms1)
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: randoms2[range])
      }
    }
  }

  func testCOW4() {
    let orderedSet1: OrderedSet4<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    expect(orderedSet1) == orderedSet2

    orderedSet2.insert(4)
    expect(orderedSet1) != orderedSet2
  }

  func testSubscriptAccessors4() {
    var orderedSet: OrderedSet4<Int> = [1, 2, 3]
    expect(orderedSet[0]) == 1
    expect(orderedSet[1]) == 2
    expect(orderedSet[2]) == 3
  }

  func testSubsetOf4() {
    let orderedSet: OrderedSet4<Int> = [1, 2, 3]
    expect(orderedSet).to(beSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeSubsetOf([1, 2, 4]))
  }

  func testStrictSubsetOf4() {
    let orderedSet: OrderedSet4<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(orderedSet).to(notBeStrictSubsetOf([1, 2, 4]))
  }

  func testSupersetOf4() {
    let orderedSet: OrderedSet4<Int> = [1, 2, 3]
    expect(orderedSet).to(beSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beSupersetOf([1, 2]))
    expect(orderedSet).to(notBeSupersetOf([1, 2, 4]))
  }

  func testStrictSupersetOf4() {
    let orderedSet: OrderedSet4<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 3]))
    expect(orderedSet).to(beStrictSupersetOf([1, 2]))
    expect(orderedSet).to(notBeStrictSupersetOf([1, 2, 4]))
  }

  func testDisjointWith4() {
    let orderedSet: OrderedSet4<Int> = [1, 2, 3]
    expect(orderedSet).to(notBeDisjointWith([1, 4, 5]))
    expect(orderedSet).to(beDisjointWith([4, 5]))
    expect(orderedSet).to(notBeDisjointWith([1, 2, 3, 4, 5]))
  }

  func testUnion4() {
    var orderedSet = OrderedSet4(randoms1)
    orderedSet.unionInPlace(randoms2)
    var set = Set(randoms1)
    set.unionInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }


  func testUnionPerformance4() {
    let work = perform({OrderedSet4<Int>($0)}, execute: {_ = $0.union($1)})
    measureBlock(work)
  }

  func testIntersection4() {
    var orderedSet = OrderedSet4(randoms1)
    orderedSet.intersectInPlace(randoms2)
    var set = Set(randoms1)
    set.intersectInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testIntersectionPerformance4() {
    let work = perform({OrderedSet4<Int>($0)}, execute: {_ = $0.intersect($1)})
    measureBlock(work)
  }

  func testSubtract4() {
    var orderedSet = OrderedSet4(randoms1)
    orderedSet.subtractInPlace(randoms2)
    var set = Set(randoms1)
    set.subtractInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testSubtractPerformance4() {
    let work = perform({OrderedSet4<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXOR4() {
    var orderedSet = OrderedSet4(randoms1)
    var set = Set(randoms1)
    set.exclusiveOrInPlace(randoms2)
    orderedSet.exclusiveOrInPlace(randoms2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testXORPerformance4() {
    let work = perform({OrderedSet4<Int>($0)}, execute: {_ = $0.exclusiveOr($1)})
    measureBlock(work)
  }

  func testPerformanceWithCapacityReserved4() {
    measureBlock(performanceWork { OrderedSet4<Int>(minimumCapacity: $0) })
  }
  
  func testPerformanceWithoutCapacityReserved4() {
    measureBlock(performanceWork { _ in OrderedSet4<Int>() })
  }
}
