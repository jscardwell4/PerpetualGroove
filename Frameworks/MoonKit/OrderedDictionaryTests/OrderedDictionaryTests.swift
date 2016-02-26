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
    var orderedDictionary = __OrderedDictionary__<String, Int>(minimumCapacity: 8)
    XCTAssertGreaterThanOrEqual(orderedDictionary.capacity, 8)
    XCTAssertEqual(orderedDictionary.count, 0)

    orderedDictionary = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5]
    XCTAssertGreaterThanOrEqual(orderedDictionary.capacity, 5)
    XCTAssertEqual(orderedDictionary.count, 5)
  }

  func testInsertion() {
    var orderedDictionary = __OrderedDictionary__<String, Int>(minimumCapacity: 8)

    orderedDictionary["one"] = 1
    XCTAssertEqual(orderedDictionary.count, 1)
    XCTAssertEqual(orderedDictionary["one"], 1)
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1]))

    orderedDictionary["two"] = 2
    XCTAssertEqual(orderedDictionary.count, 2)
    XCTAssertEqual(orderedDictionary["two"], 2)
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2]))

    orderedDictionary["three"] = 3
    XCTAssertEqual(orderedDictionary.count, 3)
    XCTAssertEqual(orderedDictionary["three"], 3)
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3]))

    orderedDictionary["four"] = 4
    XCTAssertEqual(orderedDictionary.count, 4)
    XCTAssertEqual(orderedDictionary["four"], 4)
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3, 4]))

    orderedDictionary["five"] = 5
    XCTAssertEqual(orderedDictionary.count, 5)
    XCTAssertEqual(orderedDictionary["five"], 5)
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3, 4, 5]))
  }

  func testResize() {
    var orderedDictionary = __OrderedDictionary__<String, Int>(minimumCapacity: 8)
    orderedDictionary["one"] = 1
    orderedDictionary["two"] = 2
    orderedDictionary["three"] = 3
    orderedDictionary["four"] = 4
    orderedDictionary["five"] = 5
    orderedDictionary["six"] = 6
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3, 4, 5, 6]))
    orderedDictionary["seven"] = 7
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3, 4, 5, 6, 7]))
    orderedDictionary["eight"] = 8
    orderedDictionary["nine"] = 9
    orderedDictionary["ten"] = 10
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
  }

  func testDeletion() {
    var orderedDictionary: __OrderedDictionary__<String, Int> = ["one": 1, "two": 2, "three": 3]
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 2, 3]))
    orderedDictionary["two"] = nil
    XCTAssertTrue(orderedDictionary.values.elementsEqual([1, 3]))
    orderedDictionary["one"] = nil
    XCTAssertTrue(orderedDictionary.values.elementsEqual([3]))
    orderedDictionary["two"] = 2
    orderedDictionary["one"] = 1
    XCTAssertTrue(orderedDictionary.values.elementsEqual([3, 2, 1]))

  }

}
