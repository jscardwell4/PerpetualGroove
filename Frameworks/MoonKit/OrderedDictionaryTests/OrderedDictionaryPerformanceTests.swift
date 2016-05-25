//
//  OrderedDictionaryPerformanceTests.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/24/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit


final class OrderedDictionaryPerformanceTests: XCTestCase {

  var elements1: [(String, Int)] = Array(zip(randomStringsLarge1, randomIntegersLarge1))
  var elements2: [(String, Int)] = Array(zip(randomStringsLarge2, randomIntegersLarge2))
  var elements3: [(String, Int)] = Array(zip(randomStringsMedium1, randomIntegersMedium1))

  func setup() {
    elements1 = Array(zip(randomStringsLarge1, randomIntegersLarge1))
    elements2 = Array(zip(randomStringsLarge2, randomIntegersLarge2))
    elements3 = Array(zip(randomStringsMedium1, randomIntegersMedium1))
  }

  func performanceWork(createDictionary: (capacity: Int) -> OrderedDictionary<String, Int>) -> () -> Void {
    var dictionary = createDictionary(capacity: 2048)
    return {
      for (key, value) in self.elements1 { dictionary[key] = value }
      for (key, _) in self.elements2 { dictionary[key] = nil }
      for (key, value) in self.elements3 { dictionary[key] = value }
    }
  }

  func testInsertValueForKeyPerformance() {
    var orderedDictionary = OrderedDictionary<String, Int>()
    measureBlock {
      for (key, value) in self.elements1 { orderedDictionary.insertValue(value, forKey: key) }
    }
  }

  func testRemoveValueForKeyPerformance() {
    var orderedDictionary = OrderedDictionary<String, Int>(elements1)
    measureBlock {
      for (key, _) in self.elements1 { orderedDictionary.removeValueForKey(key) }
    }
  }

  func testOverallPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedDictionary<String, Int>(minimumCapacity: $0) })
  }

  func testOverallPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedDictionary<String, Int>() })
  }
  
}
