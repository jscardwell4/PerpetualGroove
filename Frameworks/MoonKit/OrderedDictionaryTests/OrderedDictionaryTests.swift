//
//  OrderedDictionaryTests.swift
//  OrderedDictionaryTests
//
//  Created by Jason Cardwell on 2/25/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit


final class OrderedDictionaryTests: XCTestCase {

  func performanceWork(createDictionary: (capacity: Int) -> OrderedDictionary<String, Int>) -> () -> Void {
    return {
      var dictionary = createDictionary(capacity: 2048)
      for value in randomIntegersLarge1 { dictionary[String(value)] = value }
      for value in randomIntegersLarge2 { dictionary[String(value)] = nil }
      for value in randomIntegersMedium1 { dictionary[String(value)] = value }
    }
  }

  func testCreation() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)
    expect(orderedDictionary1.capacity) >= 8
    expect(orderedDictionary1).to(haveCount(0))

    orderedDictionary1 = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5]

    expect(orderedDictionary1.capacity) >= 5
    expect(orderedDictionary1).to(haveCount(5))

    let pairs1 = [("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5)]
    orderedDictionary1 = OrderedDictionary<String, Int>(elements: pairs1)
    expect(orderedDictionary1).to(haveCount(5))

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)
    expect(orderedDictionary2.capacity) >= 8
    expect(orderedDictionary2).to(haveCount(0))

    orderedDictionary2 = [1: "one", 2: "two", 3: "three", 4: "four", 5: "five"]
    expect(orderedDictionary2.capacity) >= 5
    expect(orderedDictionary2).to(haveCount(5))

    let pairs2 = [(1, "1"), (2, "2"), (3, "3"), (4, "4"), (5, "5")]
    orderedDictionary2 = OrderedDictionary<Int, String>(elements: pairs2)
    expect(orderedDictionary2).to(haveCount(5))
  }

  func testResize() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)
    orderedDictionary1["one"] = 1
    orderedDictionary1["two"] = 2
    orderedDictionary1["three"] = 3
    orderedDictionary1["four"] = 4
    orderedDictionary1["five"] = 5
    orderedDictionary1["six"] = 6
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5, 6]
    orderedDictionary1["seven"] = 7
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5, 6, 7]
    orderedDictionary1["eight"] = 8
    orderedDictionary1["nine"] = 9
    orderedDictionary1["ten"] = 10
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)
    orderedDictionary2[1] = "one"
    orderedDictionary2[2] = "two"
    orderedDictionary2[3] = "three"
    orderedDictionary2[4] = "four"
    orderedDictionary2[5] = "five"
    orderedDictionary2[6] = "six"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five", "six"]
    orderedDictionary2[7] = "seven"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five", "six", "seven"]
    orderedDictionary2[8] = "eight"
    orderedDictionary2[9] = "nine"
    orderedDictionary2[10] = "ten"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

  }

  func testCOW() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    var orderedDictionary2 = orderedDictionary1
    expect(orderedDictionary1) == orderedDictionary2

    orderedDictionary2["four"] = 4
    expect(orderedDictionary1) != orderedDictionary2
  }

  func testInsertValueForKey() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)

    orderedDictionary1.insertValue(1, forKey: "one")
    expect(orderedDictionary1).to(haveCount(1))
    expect(orderedDictionary1["one"]) == 1
    expect(orderedDictionary1.values) == [1]

    orderedDictionary1.insertValue(2, forKey: "two")
    expect(orderedDictionary1).to(haveCount(2))
    expect(orderedDictionary1["two"]) == 2
    expect(orderedDictionary1.values) == [1, 2]

    orderedDictionary1.insertValue(3, forKey: "three")
    expect(orderedDictionary1).to(haveCount(3))
    expect(orderedDictionary1["three"]) == 3
    expect(orderedDictionary1.values) == [1, 2, 3]

    orderedDictionary1.insertValue(4, forKey: "four")
    expect(orderedDictionary1).to(haveCount(4))
    expect(orderedDictionary1["four"]) == 4
    expect(orderedDictionary1.values) == [1, 2, 3, 4]

    orderedDictionary1.insertValue(5, forKey: "five")
    expect(orderedDictionary1).to(haveCount(5))
    expect(orderedDictionary1["five"]) == 5
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5]

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)

    orderedDictionary2.insertValue("one", forKey: 1)
    expect(orderedDictionary2).to(haveCount(1))
    expect(orderedDictionary2[1]) == "one"
    expect(orderedDictionary2.values) == ["one"]

    orderedDictionary2.insertValue("two", forKey: 2)
    expect(orderedDictionary2).to(haveCount(2))
    expect(orderedDictionary2[2]) == "two"
    expect(orderedDictionary2.values) == ["one", "two"]

    orderedDictionary2.insertValue("three", forKey: 3)
    expect(orderedDictionary2).to(haveCount(3))
    expect(orderedDictionary2[3]) == "three"
    expect(orderedDictionary2.values) == ["one", "two", "three"]

    orderedDictionary2.insertValue("four", forKey: 4)
    expect(orderedDictionary2).to(haveCount(4))
    expect(orderedDictionary2[4]) == "four"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four"]

    orderedDictionary2.insertValue("five", forKey: 5)
    expect(orderedDictionary2).to(haveCount(5))
    expect(orderedDictionary2[5]) == "five"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five"]
  }

  func testInsertValueForKeyPerformance() {
    measureBlock {
      var orderedDictionary = OrderedDictionary<String, Int>()
      for i in randomIntegersLarge1 { orderedDictionary.insertValue(i, forKey: String(i)) }
    }
  }

  func testRemoveAll() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1).toNot(beEmpty())
    orderedDictionary1.removeAll()
    expect(orderedDictionary1).to(beEmpty())

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2).toNot(beEmpty())
    orderedDictionary2.removeAll()
    expect(orderedDictionary2).to(beEmpty())
  }

  func testRemoveValueForKey() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.values) == [1, 2, 3]
    expect(orderedDictionary1.removeValueForKey("two")) == 2
    expect(orderedDictionary1.values) == [1, 3]
    expect(orderedDictionary1.removeValueForKey("two")).to(beNil())
    expect(orderedDictionary1.removeValueForKey("one")) == 1
    expect(orderedDictionary1.values) == [3]
    orderedDictionary1["two"] = 2
    orderedDictionary1["one"] = 1
    expect(orderedDictionary1.values) == [3, 2, 1]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    expect(orderedDictionary2.removeValueForKey(2)) == "two"
    expect(orderedDictionary2.values) == ["one", "three"]
    expect(orderedDictionary2.removeValueForKey(2)).to(beNil())
    expect(orderedDictionary2.removeValueForKey(1)) == "one"
    expect(orderedDictionary2.values) == ["three"]
    orderedDictionary2[2] = "two"
    orderedDictionary2[1] = "one"
    expect(orderedDictionary2.values) == ["three", "two", "one"]
  }

  func testRemoveValueForKeyPerformance() {
    measureBlock {
      var orderedDictionary = OrderedDictionary<String, Int>(elements: randomIntegersLarge1.map {(String($0), $0)})
      for i in randomIntegersLarge1 { orderedDictionary.removeValueForKey(String(i)) }
    }
  }

  func testSubscriptKeyAccessors() {
    var orderedDictionary: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary["two"]) == 2
    orderedDictionary["four"] = 4
    expect(orderedDictionary["four"]) == 4
    expect(orderedDictionary.keys) == ["one", "two", "three", "four"]
    expect(orderedDictionary.values) == [1, 2, 3, 4]
  }

  func testSubscriptIndexAccessors() {
    var orderedDictionary: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary[1]) == ("two", 2)
    orderedDictionary[2] = ("four", 4)
    expect(orderedDictionary[2]) == ("four", 4)
    expect(orderedDictionary.keys) == ["one", "two", "four"]
    expect(orderedDictionary.values) == [1, 2, 4]
  }

  func testSubscriptRangeAccessors() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    var slice1 = orderedDictionary1[1 ... 2]
    expect(slice1.keys) == ["two", "three"]
    expect(slice1.values) == [2, 3]
    slice1["four"] = 4
    expect(slice1.keys) == ["two", "three", "four"]
    expect(slice1.values) == [2, 3, 4]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1[1 ... 2] = slice1
    expect(orderedDictionary1.keys) == ["one", "two", "three", "four"]
    expect(orderedDictionary1.values) == [1, 2, 3, 4]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    var slice2 = orderedDictionary2[1 ... 2]
    expect(slice2.keys) == [2, 3]
    expect(slice2.values) == ["two", "three"]
    slice2[4] = "four"
    expect(slice2.keys) == [2, 3, 4]
    expect(slice2.values) == ["two", "three", "four"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    orderedDictionary2[1 ... 2] = slice2
    expect(orderedDictionary2.keys) == [1, 2, 3, 4]
    expect(orderedDictionary2.values) == ["one", "two", "three", "four"]
  }

  func testRemoveAtIndex() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.removeAtIndex(0)) == ("one", 1)
    expect(orderedDictionary1.removeAtIndex(1)) == ("three", 3)
    expect(orderedDictionary1.removeAtIndex(0)) == ("two", 2)

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.removeAtIndex(0)) == (1, "one")
    expect(orderedDictionary2.removeAtIndex(1)) == (3, "three")
    expect(orderedDictionary2.removeAtIndex(0)) == (2, "two")
  }

  func testIndexForKey() {
    let orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.indexForKey("one")) == 0
    expect(orderedDictionary1.indexForKey("two")) == 1
    expect(orderedDictionary1.indexForKey("three")) == 2
    expect(orderedDictionary1.indexForKey("four")).to(beNil())

    let orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.indexForKey(1)) == 0
    expect(orderedDictionary2.indexForKey(2)) == 1
    expect(orderedDictionary2.indexForKey(3)) == 2
    expect(orderedDictionary2.indexForKey(4)).to(beNil())
  }

  func testUpdateValueForKey() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.updateValue(4, forKey: "two")) == 2
    expect(orderedDictionary1.valueForKey("two")) == 4

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.updateValue("four", forKey: 2)) == "two"
    expect(orderedDictionary2.valueForKey(2)) == "four"
  }

  func testReplaceRange() {
    var orderedDictionary: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
                                                             "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10]
    orderedDictionary.replaceRange(0 ..< 5, with: [("five", 5), ("four", 4), ("three", 3), ("two", 2), ("one", 1)])
    expect(orderedDictionary) == (["five": 5, "four": 4, "three": 3, "two": 2, "one": 1,
                                  "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10] as OrderedDictionary<String, Int>)
    orderedDictionary.replaceRange(5 ..< 10, with: [("zero", 0)])
    expect(orderedDictionary) == (["five": 5, "four": 4, "three": 3, "two": 2, "one": 1, "zero": 0] as OrderedDictionary<String, Int>)
  }

  func testAppend() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1.append(("four", 4))
    expect(orderedDictionary1.keys) == ["one", "two", "three", "four"]
    expect(orderedDictionary1.values) == [1, 2, 3, 4]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    orderedDictionary2.append((4, "four"))
    expect(orderedDictionary2.keys) == [1, 2, 3, 4]
    expect(orderedDictionary2.values) == ["one", "two", "three", "four"]
  }

  func testAppendContentsOf() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1.appendContentsOf([("four", 4), ("five", 5)])
    expect(orderedDictionary1.keys) == ["one", "two", "three", "four", "five"]
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5]
    orderedDictionary1.appendContentsOf([("four", 4)])
    expect(orderedDictionary1.keys) == ["one", "two", "three", "four", "five"]
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    orderedDictionary2.appendContentsOf([(4, "four"), (5, "five")])
    expect(orderedDictionary2.keys) == [1, 2, 3, 4, 5]
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five"]
    orderedDictionary2.appendContentsOf([(4, "four")])
    expect(orderedDictionary2.keys) == [1, 2, 3, 4, 5]
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five"]
  }

  func testInsertAtIndex() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1.insert(("zero", 0), atIndex: 0)
    expect(orderedDictionary1.keys) == ["zero", "one", "two", "three"]
    expect(orderedDictionary1.values) == [0, 1, 2, 3]
    orderedDictionary1.insert(("two", 2), atIndex: 1)
    expect(orderedDictionary1.keys) == ["zero", "one", "two", "three"]
    expect(orderedDictionary1.values) == [0, 1, 2, 3]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    orderedDictionary2.insert((0, "zero"), atIndex: 0)
    expect(orderedDictionary2.keys) == [0, 1, 2, 3]
    expect(orderedDictionary2.values) == ["zero", "one", "two", "three"]
    orderedDictionary2.insert((2, "two"), atIndex: 1)
    expect(orderedDictionary2.keys) == [0, 1, 2, 3]
    expect(orderedDictionary2.values) == ["zero", "one", "two", "three"]
  }

  func testInsertContentsOfAtIndex() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1.insertContentsOf([("negative one", -1), ("zero", 0)], at: 0)
    expect(orderedDictionary1.keys) == ["negative one", "zero", "one", "two", "three"]
    expect(orderedDictionary1.values) == [-1, 0, 1, 2, 3]
    orderedDictionary1.insertContentsOf([("two", 2), ("three", 3)], at: 1)
    expect(orderedDictionary1.keys) == ["negative one", "zero", "one", "two", "three"]
    expect(orderedDictionary1.values) == [-1, 0, 1, 2, 3]
    orderedDictionary1.insertContentsOf([("three", 3), ("four", 4)], at: 3)
    expect(orderedDictionary1.keys) == ["negative one", "zero", "one", "four", "two", "three"]
    expect(orderedDictionary1.values) == [-1, 0, 1, 4, 2, 3]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    orderedDictionary2.insertContentsOf([(-1, "negative one"), (0, "zero")], at: 0)
    expect(orderedDictionary2.keys) == [-1, 0, 1, 2, 3]
    expect(orderedDictionary2.values) == ["negative one", "zero", "one", "two", "three"]
    orderedDictionary2.insertContentsOf([(2, "two"), (3, "three")], at: 1)
    expect(orderedDictionary2.keys) == [-1, 0, 1, 2, 3]
    expect(orderedDictionary2.values) == ["negative one", "zero", "one", "two", "three"]
    orderedDictionary2.insertContentsOf([(3, "three"), (4, "four")], at: 3)
    expect(orderedDictionary2.keys) == [-1, 0, 1, 4, 2, 3]
    expect(orderedDictionary2.values) == ["negative one", "zero", "one", "four", "two", "three"]
  }

  func testRemoveRange() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1.removeRange(1 ... 2)
    expect(orderedDictionary1.keys) == ["one"]
    expect(orderedDictionary1.values) == [1]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    orderedDictionary2.removeRange(1 ... 2)
    expect(orderedDictionary2.keys) == [1]
    expect(orderedDictionary2.values) == ["one"]
  }

  func testPrefix() {
    let orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    let result1 = orderedDictionary1.prefix(2)
    expect(result1.keys) == ["one", "two"]
    expect(result1.values) == [1, 2]

    let orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    let result2 = orderedDictionary2.prefix(2)
    expect(result2.keys) == [1, 2]
    expect(result2.values) == ["one", "two"]
  }

  func testSuffix() {
    let orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]
    expect(orderedDictionary1.values) == [1, 2, 3]
    let result1 = orderedDictionary1.suffix(2)
    expect(result1.keys) == ["two", "three"]
    expect(result1.values) == [2, 3]

    let orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    let result2 = orderedDictionary2.suffix(2)
    expect(result2.keys) == [2, 3]
    expect(result2.values) == ["two", "three"]
  }

  func testKeys() {
    let orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]

    let orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
  }

  func testValues() {
    let orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.values) == [1, 2, 3]

    let orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
  }

  func testEquatable() {
    let orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1 == orderedDictionary1).to(beTrue())
    expect(orderedDictionary1 == (["one": 1, "two": 2, "three": 3] as OrderedDictionary<String, Int>)).to(beTrue())
    expect(orderedDictionary1 == (["one": 3, "two": 2, "three": 3] as OrderedDictionary<String, Int>)).to(beFalse())
    expect(orderedDictionary1 == (["two": 2, "three": 3] as OrderedDictionary<String, Int>)).to(beFalse())
    expect(orderedDictionary1 == (["one": 1, "two": 2, "three": 3, "four": 4] as OrderedDictionary<String, Int>)).to(beFalse())

    let orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2 == orderedDictionary2).to(beTrue())
    expect(orderedDictionary2 == ([1: "one", 2: "two", 3: "three"] as OrderedDictionary<Int, String>)).to(beTrue())
    expect(orderedDictionary2 == ([1: "three", 2: "two", 3: "three"] as OrderedDictionary<Int, String>)).to(beFalse())
    expect(orderedDictionary2 == ([2: "two", 3: "three"] as OrderedDictionary<Int, String>)).to(beFalse())
    expect(orderedDictionary2 == ([1: "one", 2: "two", 3: "three", 4: "four"] as OrderedDictionary<Int, String>)).to(beFalse())
  }

  func testOverallPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedDictionary<String, Int>(minimumCapacity: $0) })
  }

  func testOverallPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedDictionary<String, Int>() })
  }

  func testContainerAsValue() {
    var orderedDictionary = OrderedDictionary<String, Array<Int>>()
    orderedDictionary["first"] = [1, 2, 3, 4]
    orderedDictionary["second"] = [5, 6, 7, 8]
    orderedDictionary["third"] = [9, 10]
    expect(orderedDictionary).to(haveCount(3))
    expect(orderedDictionary[0].1) == [1, 2, 3, 4]
    expect(orderedDictionary[1].1) == [5, 6, 7, 8]
    expect(orderedDictionary[2].1) == [9, 10]

    var array = orderedDictionary[1].1
    array.appendContentsOf([11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
    orderedDictionary["second"] = array
    expect(orderedDictionary[1].1) == [5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
  }

}
