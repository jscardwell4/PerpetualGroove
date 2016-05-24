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

  func performanceWork<
    S:SetType
    where S.Generator.Element == Int
    >(createSet: (capacity: Int) -> S) -> () -> Void
  {

    return {
      var set = createSet(capacity: 2048)
      for value in randomIntegersLarge1 { set.insert(value) }
      for value in randomIntegersLarge2 { set.remove(value) }
      set.unionInPlace(randomIntegersLarge2)
      set.subtractInPlace(randomIntegersLarge1)
      set.exclusiveOrInPlace(randomIntegersLarge1)
      set.intersectInPlace(randomIntegersLarge2)
    }
  }

  func testInsertionPerformance() {
    measureBlock {
      var orderedSet = OrderedSet<Int>()
      for i in randomIntegersLarge1 { orderedSet.insert(i) }
    }
  }

  func testDeletePerformance() {
    measureBlock {
      var orderedSet = OrderedSet<Int>(randomIntegersLarge1)
      for i in randomIntegersLarge1 { orderedSet.remove(i) }
    }
  }

  func testReplaceRangePerformance() {
    measureBlock {
      var orderedSet = OrderedSet<Int>(randomIntegersLarge1)
      for _ in 0 ..< 100 {
        let range = randomRange(orderedSet.count, coverage: 0.25)
        orderedSet.replaceRange(range, with: randomIntegersLarge2[range])
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
