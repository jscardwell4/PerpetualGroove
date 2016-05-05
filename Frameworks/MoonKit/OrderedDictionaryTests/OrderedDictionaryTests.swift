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

  func testSubscriptKeyInsertion() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)

    orderedDictionary1["one"] = 1
    expect(orderedDictionary1).to(haveCount(1))
    expect(orderedDictionary1["one"]) == 1
    expect(orderedDictionary1.values) == [1]

    orderedDictionary1["two"] = 2
    expect(orderedDictionary1).to(haveCount(2))
    expect(orderedDictionary1["two"]) == 2
    expect(orderedDictionary1.values) == [1, 2]

    orderedDictionary1["three"] = 3
    expect(orderedDictionary1).to(haveCount(3))
    expect(orderedDictionary1["three"]) == 3
    expect(orderedDictionary1.values) == [1, 2, 3]

    orderedDictionary1["four"] = 4
    expect(orderedDictionary1).to(haveCount(4))
    expect(orderedDictionary1["four"]) == 4
    expect(orderedDictionary1.values) == [1, 2, 3, 4]

    orderedDictionary1["five"] = 5
    expect(orderedDictionary1).to(haveCount(5))
    expect(orderedDictionary1["five"]) == 5
    expect(orderedDictionary1.values) == [1, 2, 3, 4, 5]

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)

    orderedDictionary2[1] = "one"
    expect(orderedDictionary2).to(haveCount(1))
    expect(orderedDictionary2[1]) == "one"
    expect(orderedDictionary2.values) == ["one"]

    orderedDictionary2[2] = "two"
    expect(orderedDictionary2).to(haveCount(2))
    expect(orderedDictionary2[2]) == "two"
    expect(orderedDictionary2.values) == ["one", "two"]

    orderedDictionary2[3] = "three"
    expect(orderedDictionary2).to(haveCount(3))
    expect(orderedDictionary2[3]) == "three"
    expect(orderedDictionary2.values) == ["one", "two", "three"]

    orderedDictionary2[4] = "four"
    expect(orderedDictionary2).to(haveCount(4))
    expect(orderedDictionary2[4]) == "four"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four"]

    orderedDictionary2[5] = "five"
    expect(orderedDictionary2).to(haveCount(5))
    expect(orderedDictionary2[5]) == "five"
    expect(orderedDictionary2.values) == ["one", "two", "three", "four", "five"]
  }

  func testSubscriptKeyInsertionPerformance() {
    measureBlock {
      var orderedDictionary = OrderedDictionary<String, Int>()
      for i in randomIntegersLarge1 { orderedDictionary[String(i)] = i }
    }
  }

  func testSubscriptKeyDeletion() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.values) == [1, 2, 3]
    orderedDictionary1["two"] = nil
    expect(orderedDictionary1.values) == [1, 3]
    orderedDictionary1["one"] = nil
    expect(orderedDictionary1.values) == [3]
    orderedDictionary1["two"] = 2
    orderedDictionary1["one"] = 1
    expect(orderedDictionary1.values) == [3, 2, 1]
    orderedDictionary1.removeAll()
    expect(orderedDictionary1).to(beEmpty())

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
    orderedDictionary2[2] = nil
    expect(orderedDictionary2.values) == ["one", "three"]
    orderedDictionary2[1] = nil
    expect(orderedDictionary2.values) == ["three"]
    orderedDictionary2[2] = "two"
    orderedDictionary2[1] = "one"
    expect(orderedDictionary2.values) == ["three", "two", "one"]
    orderedDictionary2.removeAll()
    expect(orderedDictionary2).to(beEmpty())
  }

  func testSubscriptKeyDeletionPerformance() {
    measureBlock {
      var orderedDictionary = OrderedDictionary<String, Int>(elements: randomIntegersLarge1.map {(String($0), $0)})
      for i in randomIntegersLarge1 { orderedDictionary[String(i)] = nil }
    }
  }

  func testSubscriptAccessors() {
    var orderedDictionary: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary["two"]) == 2
    let (k, v) = orderedDictionary[1]
    expect(k) == "two"
    expect(v) == 2
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

  func testRemoveValueForKey() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.removeValueForKey("three")) == 3
    expect(orderedDictionary1.removeValueForKey("three")).to(beNil())

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.removeValueForKey(3)) == "three"
    expect(orderedDictionary2.removeValueForKey(3)).to(beNil())
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

  func testKeys() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.keys) == ["one", "two", "three"]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.keys) == [1, 2, 3]
  }

  func testValues() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1.values) == [1, 2, 3]

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2.values) == ["one", "two", "three"]
  }

  func testEquatable() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    expect(orderedDictionary1 == orderedDictionary1).to(beTrue())
    expect(orderedDictionary1 == (["one": 1, "two": 2, "three": 3] as OrderedDictionary<String, Int>)).to(beTrue())
    expect(orderedDictionary1 == (["one": 3, "two": 2, "three": 3] as OrderedDictionary<String, Int>)).to(beFalse())
    expect(orderedDictionary1 == (["two": 2, "three": 3] as OrderedDictionary<String, Int>)).to(beFalse())
    expect(orderedDictionary1 == (["one": 1, "two": 2, "three": 3, "four": 4] as OrderedDictionary<String, Int>)).to(beFalse())

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    expect(orderedDictionary2 == orderedDictionary2).to(beTrue())
    expect(orderedDictionary2 == ([1: "one", 2: "two", 3: "three"] as OrderedDictionary<Int, String>)).to(beTrue())
    expect(orderedDictionary2 == ([1: "three", 2: "two", 3: "three"] as OrderedDictionary<Int, String>)).to(beFalse())
    expect(orderedDictionary2 == ([2: "two", 3: "three"] as OrderedDictionary<Int, String>)).to(beFalse())
    expect(orderedDictionary2 == ([1: "one", 2: "two", 3: "three", 4: "four"] as OrderedDictionary<Int, String>)).to(beFalse())
  }

  func testOverallPerformanceWithCapacityReserved() {
    measureBlock {
      var d = OrderedDictionary<Int, String>(minimumCapacity: 1500)
      for i in 0 ..< 1000 { d[i] = String(i) }
      for i in 0.stride(to: 1000, by: 3) { d[i] = nil }
      for i in 1000 ..< 1200 { d[i] = String(i) }
    }
  }

  func testOverallPerformanceWithoutCapacityReserved() {
    measureBlock {
      var d: OrderedDictionary<Int, String> = [:]
      for i in 0 ..< 1000 { d[i] = String(i) }
      for i in 0.stride(to: 1000, by: 3) { d[i] = nil }
      for i in 1000 ..< 1200 { d[i] = String(i) }
    }

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
