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

  func performanceWork(createDictionary: (capacity: Int) -> OrderedDictionary<String, Int>) -> () -> Void {
    return {
      var dictionary = createDictionary(capacity: 2048)
      for value in randomIntegersLarge1 { dictionary[String(value)] = value }
      for value in randomIntegersLarge2 { dictionary[String(value)] = nil }
      for value in randomIntegersMedium1 { dictionary[String(value)] = value }
    }
  }

  func testInsertValueForKeyPerformance() {
    measureBlock {
      var orderedDictionary = OrderedDictionary<String, Int>()
      for i in randomIntegersLarge1 { orderedDictionary.insertValue(i, forKey: String(i)) }
    }
  }

  func testRemoveValueForKeyPerformance() {
    measureBlock {
      var orderedDictionary = OrderedDictionary<String, Int>(randomIntegersLarge1.map {(String($0), $0)})
      for i in randomIntegersLarge1 { orderedDictionary.removeValueForKey(String(i)) }
    }
  }

  func testOverallPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedDictionary<String, Int>(minimumCapacity: $0) })
  }

  func testOverallPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedDictionary<String, Int>() })
  }
  
}
