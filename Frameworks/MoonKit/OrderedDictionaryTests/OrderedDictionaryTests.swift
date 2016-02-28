//
//  OrderedDictionaryTests.swift
//  OrderedDictionaryTests
//
//  Created by Jason Cardwell on 2/25/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
@testable import MoonKit

final class OrderedDictionaryTests: XCTestCase {
    
  func testCreation() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)
    XCTAssertGreaterThanOrEqual(orderedDictionary1.capacity, 8)
    XCTAssertEqual(orderedDictionary1.count, 0)

    orderedDictionary1 = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5]
    XCTAssertGreaterThanOrEqual(orderedDictionary1.capacity, 5)
    XCTAssertEqual(orderedDictionary1.count, 5)

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)
    XCTAssertGreaterThanOrEqual(orderedDictionary2.capacity, 8)
    XCTAssertEqual(orderedDictionary2.count, 0)

    orderedDictionary2 = [1: "one", 2: "two", 3: "three", 4: "four", 5: "five"]
    XCTAssertGreaterThanOrEqual(orderedDictionary2.capacity, 5)
    XCTAssertEqual(orderedDictionary2.count, 5)
  }

  func testInsertion() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)

    orderedDictionary1["one"] = 1
    XCTAssertEqual(orderedDictionary1.count, 1)
    XCTAssertEqual(orderedDictionary1["one"], 1)
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1]))

    orderedDictionary1["two"] = 2
    XCTAssertEqual(orderedDictionary1.count, 2)
    XCTAssertEqual(orderedDictionary1["two"], 2)
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2]))

    orderedDictionary1["three"] = 3
    XCTAssertEqual(orderedDictionary1.count, 3)
    XCTAssertEqual(orderedDictionary1["three"], 3)
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3]))

    orderedDictionary1["four"] = 4
    XCTAssertEqual(orderedDictionary1.count, 4)
    XCTAssertEqual(orderedDictionary1["four"], 4)
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3, 4]))

    orderedDictionary1["five"] = 5
    XCTAssertEqual(orderedDictionary1.count, 5)
    XCTAssertEqual(orderedDictionary1["five"], 5)
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3, 4, 5]))

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)

    orderedDictionary2[1] = "one"
    XCTAssertEqual(orderedDictionary2.count, 1)
    XCTAssertEqual(orderedDictionary2[1], "one")
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one"]))

    orderedDictionary2[2] = "two"
    XCTAssertEqual(orderedDictionary2.count, 2)
    XCTAssertEqual(orderedDictionary2[2], "two")
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two"]))

    orderedDictionary2[3] = "three"
    XCTAssertEqual(orderedDictionary2.count, 3)
    XCTAssertEqual(orderedDictionary2[3], "three")
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three"]))

    orderedDictionary2[4] = "four"
    XCTAssertEqual(orderedDictionary2.count, 4)
    XCTAssertEqual(orderedDictionary2[4], "four")
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three", "four"]))

    orderedDictionary2[5] = "five"
    XCTAssertEqual(orderedDictionary2.count, 5)
    XCTAssertEqual(orderedDictionary2[5], "five")
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three", "four", "five"]))
  }

  func testResize() {
    var orderedDictionary1 = OrderedDictionary<String, Int>(minimumCapacity: 8)
    orderedDictionary1["one"] = 1
    orderedDictionary1["two"] = 2
    orderedDictionary1["three"] = 3
    orderedDictionary1["four"] = 4
    orderedDictionary1["five"] = 5
    orderedDictionary1["six"] = 6
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3, 4, 5, 6]))
    orderedDictionary1["seven"] = 7
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3, 4, 5, 6, 7]))
    orderedDictionary1["eight"] = 8
    orderedDictionary1["nine"] = 9
    orderedDictionary1["ten"] = 10
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))

    var orderedDictionary2 = OrderedDictionary<Int, String>(minimumCapacity: 8)
    orderedDictionary2[1] = "one"
    orderedDictionary2[2] = "two"
    orderedDictionary2[3] = "three"
    orderedDictionary2[4] = "four"
    orderedDictionary2[5] = "five"
    orderedDictionary2[6] = "six"
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three", "four", "five", "six"]))
    orderedDictionary2[7] = "seven"
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three", "four", "five", "six", "seven"]))
    orderedDictionary2[8] = "eight"
    orderedDictionary2[9] = "nine"
    orderedDictionary2[10] = "ten"
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]))

  }

  func testDeletion() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 2, 3]))
    orderedDictionary1["two"] = nil
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([1, 3]))
    orderedDictionary1["one"] = nil
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([3]))
    orderedDictionary1["two"] = 2
    orderedDictionary1["one"] = 1
    XCTAssertTrue(orderedDictionary1.values.elementsEqual([3, 2, 1]))

    var orderedDictionary2: OrderedDictionary<Int, String> = [1: "one", 2: "two", 3: "three"]
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "two", "three"]))
    orderedDictionary2[2] = nil
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["one", "three"]))
    orderedDictionary2[1] = nil
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["three"]))
    orderedDictionary2[2] = "two"
    orderedDictionary2[1] = "one"
    XCTAssertTrue(orderedDictionary2.values.elementsEqual(["three", "two", "one"]))

  }

  func testCOW() {
    var orderedDictionary1: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    var orderedDictionary2 = orderedDictionary1
    XCTAssertTrue(orderedDictionary1.owner === orderedDictionary2.owner)
    XCTAssertTrue(orderedDictionary1.buffer.storage === orderedDictionary2.buffer.storage)

    orderedDictionary2["four"] = 4
    XCTAssertFalse(orderedDictionary1.owner === orderedDictionary2.owner)
    XCTAssertFalse(orderedDictionary1.buffer.storage === orderedDictionary2.buffer.storage)
  }


  func testSubscriptAccessors() {
    var orderedDictionary: OrderedDictionary<String, Int> = ["one": 1, "two": 2, "three": 3]
    XCTAssertEqual(orderedDictionary["two"], 2)
    let (k, v) = orderedDictionary[1]
    XCTAssertEqual(k, "two")
    XCTAssertEqual(v, 2)
  }

  func testPerformanceWithCapacityReserved() {
    measureBlock {
      var d = OrderedDictionary<Int, String>(minimumCapacity: 1500)
      for i in 0 ..< 1000 { d[i] = String(i) }
      for i in 0.stride(to: 1000, by: 3) { d[i] = nil }
      for i in 1000 ..< 1200 { d[i] = String(i) }
    }
  }

  func testPerformanceWithoutCapacityReserved() {
    measureBlock {
      var d: OrderedDictionary<Int, String> = [:]
      for i in 0 ..< 1000 { d[i] = String(i) }
      for i in 0.stride(to: 1000, by: 3) { d[i] = nil }
      for i in 1000 ..< 1200 { d[i] = String(i) }
    }

  }

}
