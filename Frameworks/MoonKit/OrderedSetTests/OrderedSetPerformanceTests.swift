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

  func setup() {
    elements1 = randomIntegersLarge1
    elements2 = randomIntegersLarge2
  }

  func performanceWork<
    S:SetType
    where S.Generator.Element == Int
    >(createSet: (capacity: Int) -> S) -> () -> Void
  {
    return {
      var set = createSet(capacity: 2048)
      defer { _fixLifetime(set) }
      for value in self.elements1 { set.insert(value) }
      for value in self.elements2 { set.remove(value) }
      set.unionInPlace(self.elements2)
      set.subtractInPlace(self.elements1)
      set.exclusiveOrInPlace(self.elements1)
      set.intersectInPlace(self.elements2)
    }
  }

  func testInsertionPerformance() {
    var orderedSet = OrderedSet<Int>()
    measureBlock {
      for i in self.elements1 { orderedSet.insert(i) }
    }
  }

  func testDeletePerformance() {
    var orderedSet = OrderedSet<Int>(elements1)
    measureBlock {
      for i in self.elements1 { orderedSet.remove(i) }
    }
  }

  func testReplaceRangePerformance() {
    var orderedSet = OrderedSet<Int>(elements1)
    measureBlock {
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: self.elements2[range])
      }
    }
  }

  func testUnionPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.union($1)})
    measureBlock(work)
  }
  
  func testIntersectionPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.intersect($1)})
    measureBlock(work)
  }

  func testSubtractPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXORPerformance() {
    let work = performWithIntegers(target: {OrderedSet<Int>($0)}, execute: {_ = $0.exclusiveOr($1)})
    measureBlock(work)
  }

  func testOverallPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedSet<Int>(minimumCapacity: $0) })
  }

  func testOverallPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedSet<Int>() })
  }

}
