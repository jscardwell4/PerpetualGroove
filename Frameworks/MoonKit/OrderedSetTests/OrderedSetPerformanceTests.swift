//
//  OrderedSetPerformanceTests.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/24/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

final class OrderedSetPerformanceTests: XCTestCase {

  var elements1: [Int] = randomIntegersLarge1
  var elements2: [Int] = randomIntegersLarge2
  var orderedSet1: OrderedSet<Int> = []
  var orderedSet2: OrderedSet<Int> = []

  override func setUp() {
    elements1 = randomIntegersLarge1
    elements2 = randomIntegersLarge2
    orderedSet1 = []
    orderedSet2 = OrderedSet<Int>(elements1)
  }

  func testInsertionPerformance() {
    measureBlock {
      var set = self.orderedSet1
      for i in self.elements1 { set.insert(i) }
    }
  }

  func testDeletePerformance() {
    measureBlock {
      var set = self.orderedSet2
      for i in self.elements1 { set.remove(i) }
    }
  }

  func testReplaceRangePerformance() {
    measureBlock {
      var set = self.orderedSet2
      for _ in 0 ..< 100 {
        let range = randomRange(set.count, coverage: 0.25)
        set.replaceRange(range, with: self.elements2[range])
      }
    }
  }

  func testUnionPerformance() {
    measureBlock {
      _ = self.orderedSet2.union(self.elements2)
    }
  }
  
  func testIntersectionPerformance() {
    measureBlock {
      _ = self.orderedSet2.intersect(self.elements2)
    }
  }

  func testSubtractPerformance() {
    measureBlock {
      _ = self.orderedSet2.subtract(self.elements2)
    }
  }

  func testXORPerformance() {
    measureBlock {
      _ = self.orderedSet2.exclusiveOr(self.elements2)
    }
  }

  func testOverallPerformance() {
    measureBlock {
      var set = self.orderedSet1
      for value in self.elements1 { set.insert(value) }
      for value in self.elements2 { set.remove(value) }
      _ = set.union(self.elements2)
      _ = set.subtract(self.elements1)
      _ = set.exclusiveOr(self.elements1)
      _ = set.intersect(self.elements2)
    }
  }

}
