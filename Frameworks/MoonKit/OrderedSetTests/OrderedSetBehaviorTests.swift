//
//  OrderedSetBehaviorTests.swift
//  OrderedSetTests
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

final class OrderedSetBehaviorTests: XCTestCase {

  func testCreation() {
    var orderedSet = OrderedSet<Int>(minimumCapacity: 8)
    expect(orderedSet.capacity) >= 8
    guard expect(orderedSet).to(haveCount(0)) else { return }

    orderedSet = [1, 2, 3, 4, 5]
    expect(orderedSet.capacity) >= 5
    guard expect(orderedSet).to(haveCount(5)) else { return }

    orderedSet = OrderedSet(MoonKitTest.randomIntegersSmall1)
    let set = Set(MoonKitTest.randomIntegersSmall1)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testInsertion() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    guard expect(orderedSet1).to(haveCount(1)) else { return }
    guard expect(orderedSet1[0]).to(equal(1)) else { return }
    guard expect(orderedSet1).to(equal([1])) else { return }

    orderedSet1.insert(2)
    guard expect(orderedSet1).to(haveCount(2)) else { return }
    guard expect(orderedSet1[1]).to(equal(2)) else { return }
    guard expect(orderedSet1).to(equal([1, 2])) else { return }

    orderedSet1.insert(3)
    guard expect(orderedSet1).to(haveCount(3)) else { return }
    guard expect(orderedSet1[2]).to(equal(3)) else { return }
    guard expect(orderedSet1).to(equal([1, 2, 3])) else { return }

    orderedSet1.insert(4)
    guard expect(orderedSet1).to(haveCount(4)) else { return }
    guard expect(orderedSet1[3]).to(equal(4)) else { return }
    guard expect(orderedSet1).to(equal([1, 2, 3, 4])) else { return }

    orderedSet1.insert(5)
    guard expect(orderedSet1).to(haveCount(5)) else { return }
    guard expect(orderedSet1[4]).to(equal(5)) else { return }
    guard expect(orderedSet1).to(equal([1, 2, 3, 4, 5])) else { return }

    orderedSet1.insert(6, atIndex: 2)
    guard expect(orderedSet1).to(haveCount(6)) else { return }
    guard expect(orderedSet1[2]).to(equal(6)) else { return }
    guard expect(orderedSet1).to(equal([1, 2, 6, 3, 4, 5])) else { return }

    orderedSet1.appendContentsOf([5, 6, 7, 8])
    guard expect(orderedSet1).to(haveCount(8)) else { return }
    guard expect(orderedSet1[6]).to(equal(7)) else { return }
    guard expect(orderedSet1[7]).to(equal(8)) else { return }
    guard expect(orderedSet1).to(equal([1, 2, 6, 3, 4, 5, 7, 8])) else { return }

    orderedSet1.insertContentsOf([1, 3, 9, 10], at: 6)
    expect(orderedSet1).to(haveCount(10))
    guard expect(orderedSet1[6]).to(equal(9)) else { return }
    guard expect(orderedSet1[7]).to(equal(10)) else { return }
    guard expect(orderedSet1).to(equal([1, 2, 6, 3, 4, 5, 9, 10, 7, 8])) else { return }

    var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    guard expect(orderedSet2).to(haveCount(1)) else { return }
    guard expect(orderedSet2[0]).to(equal("one")) else { return }
    guard expect(orderedSet2).to(equal(["one"])) else { return }

    orderedSet2.insert("two")
    guard expect(orderedSet2).to(haveCount(2)) else { return }
    guard expect(orderedSet2[1]).to(equal("two")) else { return }
    guard expect(orderedSet2).to(equal(["one", "two"])) else { return }

    orderedSet2.insert("three")
    guard expect(orderedSet2).to(haveCount(3)) else { return }
    guard expect(orderedSet2[2]).to(equal("three")) else { return }
    guard expect(orderedSet2).to(equal(["one", "two", "three"])) else { return }

    orderedSet2.insert("four")
    guard expect(orderedSet2).to(haveCount(4)) else { return }
    guard expect(orderedSet2[3]).to(equal("four")) else { return }
    guard expect(orderedSet2).to(equal(["one", "two", "three", "four"])) else { return }

    orderedSet2.insert("five")
    guard expect(orderedSet2).to(haveCount(5)) else { return }
    guard expect(orderedSet2[4]).to(equal("five")) else { return }
    guard expect(orderedSet2).to(equal(["one", "two", "three", "four", "five"])) else { return }

    orderedSet2.insert("six", atIndex: 2)
    guard expect(orderedSet2).to(haveCount(6)) else { return }
    guard expect(orderedSet2[2]).to(equal("six")) else { return }
    guard expect(orderedSet2).to(equal(["one", "two", "six", "three", "four", "five"])) else { return }

    orderedSet2.appendContentsOf(["five", "six", "seven", "eight"])
    guard expect(orderedSet2).to(haveCount(8)) else { return }
    guard expect(orderedSet2[6]).to(equal("seven")) else { return }
    guard expect(orderedSet2[7]).to(equal("eight")) else { return }
    guard expect(orderedSet2).to(equal(["one", "two", "six", "three", "four", "five", "seven", "eight"])) else { return }

    orderedSet2.insertContentsOf(["one", "three", "nine", "ten"], at: 6)
    expect(orderedSet2).to(haveCount(10))
    guard expect(orderedSet2[6]).to(equal("nine")) else { return }
    guard expect(orderedSet2[7]).to(equal("ten")) else { return }
    expect(orderedSet2) == ["one", "two", "six", "three", "four", "five", "nine", "ten", "seven", "eight"]

  }

  func testResize() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)
    orderedSet1.insert(1)
    orderedSet1.insert(2)
    orderedSet1.insert(3)
    orderedSet1.insert(4)
    orderedSet1.insert(5)
    orderedSet1.insert(6)
    guard expect(orderedSet1).to(equal([1, 2, 3, 4, 5, 6])) else { return }
    orderedSet1.insert(7)
    guard expect(orderedSet1).to(equal([1, 2, 3, 4, 5, 6, 7])) else { return }
    orderedSet1.insert(8)
    orderedSet1.insert(9)
    orderedSet1.insert(10)
    guard expect(orderedSet1).to(equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])) else { return }

    var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)
    orderedSet2.insert("one")
    orderedSet2.insert("two")
    orderedSet2.insert("three")
    orderedSet2.insert("four")
    orderedSet2.insert("five")
    orderedSet2.insert("six")
    guard expect(orderedSet2).to(equal(["one", "two", "three", "four", "five", "six"])) else { return }
    orderedSet2.insert("seven")
    guard expect(orderedSet2).to(equal(["one", "two", "three", "four", "five", "six", "seven"])) else { return }
    orderedSet2.insert("eight")
    orderedSet2.insert("nine")
    orderedSet2.insert("ten")
    expect(orderedSet2) == ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
  }

  func testDeletion() {
    var orderedSet1: OrderedSet<Int> = [1, 2, 3]
    guard expect(orderedSet1).to(equal([1, 2, 3])) else { return }
    orderedSet1.removeAtIndex(1)
    guard expect(orderedSet1).to(equal([1, 3])) else { return }
    orderedSet1.removeAtIndex(0)
    guard expect(orderedSet1).to(equal([3])) else { return }
    orderedSet1.insert(2)
    orderedSet1.insert(1)
    guard expect(orderedSet1).to(equal([3, 2, 1])) else { return }
    orderedSet1.remove(2)
    guard expect(orderedSet1).to(equal([3, 1])) else { return }
    orderedSet1.remove(9)
    guard expect(orderedSet1).to(equal([3, 1])) else { return }
    orderedSet1.removeFirst()
    guard expect(orderedSet1).to(equal([1])) else { return }
    orderedSet1.appendContentsOf([2, 3, 4, 5, 6, 7, 8, 9, 10])
    guard expect(orderedSet1).to(equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])) else { return }
    orderedSet1.removeFirst(2)
    guard expect(orderedSet1).to(equal([3, 4, 5, 6, 7, 8, 9, 10])) else { return }
    orderedSet1.removeLast(4)
    guard expect(orderedSet1).to(equal([3, 4, 5, 6])) else { return }
    orderedSet1.removeRange(1 ..< 3)
    guard expect(orderedSet1).to(equal([3, 6])) else { return }
    orderedSet1.removeAll()
    expect(orderedSet1).to(beEmpty())

    var orderedSet2: OrderedSet<String> = ["one", "two", "three"]
    guard expect(orderedSet2).to(equal(["one", "two", "three"])) else { return }
    orderedSet2.removeAtIndex(1)
    guard expect(orderedSet2).to(equal(["one", "three"])) else { return }
    orderedSet2.removeAtIndex(0)
    guard expect(orderedSet2).to(equal(["three"])) else { return }
    orderedSet2.insert("two")
    orderedSet2.insert("one")
    guard expect(orderedSet2).to(equal(["three", "two", "one"])) else { return }
    orderedSet2.remove("two")
    guard expect(orderedSet2).to(equal(["three", "one"])) else { return }
    orderedSet2.remove("nine")
    guard expect(orderedSet2).to(equal(["three", "one"])) else { return }
    orderedSet2.removeFirst()
    guard expect(orderedSet2).to(equal(["one"])) else { return }
    orderedSet2.appendContentsOf(["two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"])
    guard expect(orderedSet2).to(equal(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"])) else { return }
    orderedSet2.removeFirst(2)
    guard expect(orderedSet2).to(equal(["three", "four", "five", "six", "seven", "eight", "nine", "ten"])) else { return }
    orderedSet2.removeLast(4)
    guard expect(orderedSet2).to(equal(["three", "four", "five", "six"])) else { return }
    orderedSet2.removeRange(1 ..< 3)
    guard expect(orderedSet2).to(equal(["three", "six"])) else { return }
    orderedSet2.removeAll()
    expect(orderedSet2).to(beEmpty())
  }

  func testReplaceRange() {
    var orderedSet: OrderedSet<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    orderedSet.replaceRange(0 ..< 5, with: [5, 4, 3, 2, 1])
    guard expect(orderedSet).to(equal([5, 4, 3, 2, 1, 6, 7, 8, 9, 10])) else { return }
    orderedSet.replaceRange(5 ..< 10, with: [0])
    expect(orderedSet) == [5, 4, 3, 2, 1, 0]
  }

  func testCOW() {
    let orderedSet1: OrderedSet<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    guard expect(orderedSet1).to(equal(orderedSet2)) else { return }

    orderedSet2.insert(4)
    expect(orderedSet1) != orderedSet2
  }

  func testSubscriptIndexAccessors() {
    var orderedSet: OrderedSet<Int> = [1, 2, 3]
    guard expect(orderedSet[0]).to(equal(1)) else { return }
    guard expect(orderedSet[1]).to(equal(2)) else { return }
    expect(orderedSet[2]) == 3
  }

  func testSubscriptRangAccssors() {
    var orderedSet: OrderedSet<Int> = [1, 2, 3]
    var slice1 = orderedSet[1 ... 2]
    guard expect(slice1).to(equal([2, 3])) else { return }
    slice1.append(4)
    guard expect(slice1).to(equal([2, 3, 4])) else { return }
    guard expect(orderedSet).to(equal([1, 2, 3])) else { return }
    orderedSet[1 ... 2] = slice1
    expect(orderedSet).to(equal([1, 2, 3, 4]))
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
    let orderedSet1: OrderedSet<Int> = [1, 2, 3]
    expect(orderedSet1).toNot(beDisjointWith([1, 4, 5] as Array<Int>))
    expect(orderedSet1).to(beDisjointWith([4, 5] as Array<Int>))
    expect(orderedSet1).toNot(beDisjointWith([1, 2, 3, 4, 5] as Array<Int>))

    let evens = evenNumbers(range: 0 ..< 500)
    let odds = oddNumbers(range: 0 ..< 500)
    let orderedSet2 = OrderedSet(evens)
    expect(orderedSet2).to(beDisjointWith(odds))
    expect(orderedSet2).toNot(beDisjointWith(evens))
  }

  func testUnion() {
    var orderedSet = OrderedSet(MoonKitTest.randomIntegersSmall1)
    orderedSet.unionInPlace(MoonKitTest.randomIntegersSmall2)
    var set = Set(MoonKitTest.randomIntegersSmall1)
    set.unionInPlace(MoonKitTest.randomIntegersSmall2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testIntersection() {
    var orderedSet = OrderedSet(MoonKitTest.randomIntegersSmall1)
    orderedSet.intersectInPlace(MoonKitTest.randomIntegersSmall2)
    var set = Set(MoonKitTest.randomIntegersSmall1)
    set.intersectInPlace(MoonKitTest.randomIntegersSmall2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testSubtract() {
    var orderedSet = OrderedSet(MoonKitTest.randomIntegersSmall1)
    orderedSet.subtractInPlace(MoonKitTest.randomIntegersSmall2)
    var set = Set(MoonKitTest.randomIntegersSmall1)
    set.subtractInPlace(MoonKitTest.randomIntegersSmall2)
    expect(orderedSet).to(haveCount(set.count))
  }

  func testXOR() {
    var orderedSet = OrderedSet(MoonKitTest.randomIntegersSmall1)
    var set = Set(MoonKitTest.randomIntegersSmall1)
    set.exclusiveOrInPlace(MoonKitTest.randomIntegersSmall2)
    orderedSet.exclusiveOrInPlace(MoonKitTest.randomIntegersSmall2)
    expect(orderedSet).to(haveCount(set.count))
  }
}
