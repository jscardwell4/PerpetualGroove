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

  var elements0: [(String, Int)] = []
  var elements1: [(String, Int)] = []
  var elements2: [(String, Int)] = []
  var dictionary1: OrderedDictionary<String, Int> = [:]
  var dictionary2: OrderedDictionary<String, Int> = [:]

  override func setUp() {
    elements0 = Array(zip(MoonKitTest.stringsXXLarge0, MoonKitTest.integersXXLarge0))
    elements1 = Array(zip(MoonKitTest.stringsXXLarge1, MoonKitTest.integersXXLarge1))
    elements2 = Array(zip(MoonKitTest.stringsMedium0, MoonKitTest.integersMedium0))
    dictionary1 = [:]
    dictionary2 = OrderedDictionary<String, Int>(elements0)
  }

  func testInsertValueForKeyPerformance() {
    measureBlock {
      var dictionary = self.dictionary1
      for (key, value) in self.elements0 { dictionary.insertValue(value, forKey: key) }
    }
  }

  func testRemoveValueForKeyPerformance() {
    measureBlock {
      var dictionary = self.dictionary2
      for (key, _) in self.elements0 { dictionary.removeValueForKey(key) }
    }
  }

  func testOverallPerformance() {
    measureBlock {
      var dictionary = self.dictionary1
      for (key, value) in self.elements0 { dictionary[key] = value }
      for (key, _) in self.elements1 { dictionary[key] = nil }
      for (key, value) in self.elements2 { dictionary[key] = value }
    }
  }
  
}
