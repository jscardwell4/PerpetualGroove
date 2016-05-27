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

  var elements1: [(String, Int)] = []
  var elements2: [(String, Int)] = []
  var elements3: [(String, Int)] = []
  var dictionary1: OrderedDictionary<String, Int> = [:]
  var dictionary2: OrderedDictionary<String, Int> = [:]

  override func setUp() {
    elements1 = Array(zip(MoonKitTest.randomStringsXLarge1, MoonKitTest.randomIntegersXLarge1))
    elements2 = Array(zip(MoonKitTest.randomStringsXLarge2, MoonKitTest.randomIntegersXLarge2))
    elements3 = Array(zip(MoonKitTest.randomStringsMedium1, MoonKitTest.randomIntegersMedium1))
    dictionary1 = [:]
    dictionary2 = OrderedDictionary<String, Int>(elements1)
  }

  func testInsertValueForKeyPerformance() {
    measureBlock {
      var dictionary = self.dictionary1
      for (key, value) in self.elements1 { dictionary.insertValue(value, forKey: key) }
    }
  }

  func testRemoveValueForKeyPerformance() {
    measureBlock {
      var dictionary = self.dictionary2
      for (key, _) in self.elements1 { dictionary.removeValueForKey(key) }
    }
  }

  func testOverallPerformance() {
    measureBlock {
      var dictionary = self.dictionary1
      for (key, value) in self.elements1 { dictionary[key] = value }
      for (key, _) in self.elements2 { dictionary[key] = nil }
      for (key, value) in self.elements3 { dictionary[key] = value }
    }
  }
  
}
