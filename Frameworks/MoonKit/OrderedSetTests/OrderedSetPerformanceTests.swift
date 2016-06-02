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

  let elements0: [Int] = MoonKitTest.integersXXLarge0
  let elements1: [Int] = MoonKitTest.integersXXLarge1
  let elements2: [Int] = MoonKitTest.integersXXLarge2
  let elements3: [Int] = MoonKitTest.integersXXLarge3
  let elements4: [Int] = MoonKitTest.integersXXLarge4
  let elements5: [Int] = MoonKitTest.integersXXLarge5
  let elements6: [Int] = MoonKitTest.integersXXLarge6
  let elements7: [Int] = MoonKitTest.integersXXLarge7
  let elements8: [Int] = MoonKitTest.integersXXLarge8
  let elements9: [Int] = MoonKitTest.integersXXLarge9
  let ranges: [Range<Int>] = srandomRanges(seed: 0, count: 10, indices: MoonKitTest.integersXXLarge0.indices, coverage: 0.00025, limit: 5000)

  var orderedSet1: OrderedSet<Int> = []
  var orderedSet2: OrderedSet<Int> = []

  override func setUp() {
    _ = ranges
    orderedSet1 = []
    orderedSet2 = OrderedSet<Int>(elements0)
  }


  func testCreationPerformance() {
    measureBlock { 
      _ = OrderedSet(self.elements0)
      _ = OrderedSet(self.elements1)
      _ = OrderedSet(self.elements2)
      _ = OrderedSet(self.elements3)
      _ = OrderedSet(self.elements4)
      _ = OrderedSet(self.elements5)
      _ = OrderedSet(self.elements6)
      _ = OrderedSet(self.elements7)
      _ = OrderedSet(self.elements8)
      _ = OrderedSet(self.elements9)
    }
  }

  func testInsertionPerformance() {
    measureBlock {
        var set = self.orderedSet1
        for i in self.elements0 { set.insert(i) }
    }
  }

  func testDeletePerformance() {
    measureBlock {
        var set = self.orderedSet2
        for i in self.elements0 { set.remove(i) }
    }
  }

  func testReplaceRangePerformance() {
    var count = orderedSet2.count
    var ranges: [(remove: Range<Int>, insert: Range<Int>)] = []
    ranges.reserveCapacity(1000)
    let coverage = 0.00025
    srandom(0)
    for _ in 0 ..< 1000 {
      let removeRange = srandomRange(count: count, coverage: coverage)
      let insertRange = srandomRange(indices: elements1.indices, coverage: coverage)
      ranges.append((removeRange, insertRange))
      count = count - removeRange.count + insertRange.count
      guard count > 0 else { break }
    }

    measureBlock {
        var set = self.orderedSet2
        for (removeRange, insertRange) in ranges {
          set.replaceRange(removeRange, with: self.elements1[insertRange])
        }
    }
  }

  func testUnionPerformance() {
    measureBlock {
        _ = self.orderedSet2.union(self.elements1)
    }
  }
  
  func testIntersectionPerformance() {
    measureBlock {
        _ = self.orderedSet2.intersect(self.elements1)
    }
  }

  func testSubtractPerformance() {
    measureBlock {
        _ = self.orderedSet2.subtract(self.elements1)
    }
  }

  func testXORPerformance() {
    measureBlock {
        _ = self.orderedSet2.exclusiveOr(self.elements1)
    }
  }

  func testUnionInPlacePerformance() {
    measureBlock {
        self.orderedSet2.unionInPlace(self.elements1)
    }
  }
  
  func testIntersectionInPlacePerformance() {
    measureBlock {
        var orderedSet = self.orderedSet2
        orderedSet.intersectInPlace(self.elements1)
    }
  }

  func testSubtractInPlacePerformance() {
    measureBlock {
        var orderedSet = self.orderedSet2
        orderedSet.subtractInPlace(self.elements1)
    }
  }

  func testXORInPlacePerformance() {
    measureBlock {
        var orderedSet = self.orderedSet2
       orderedSet.exclusiveOrInPlace(self.elements1)
    }
  }

  func testOverallPerformance() {
    measureBlock {
        var set = self.orderedSet1
        for value in self.elements0 { set.insert(value) }
        for value in self.elements1 { set.remove(value) }
        set.unionInPlace(self.elements1)
        set.subtractInPlace(self.elements0)
        set.exclusiveOrInPlace(self.elements0)
        set.intersectInPlace(self.elements1)
    }
  }

  func testSubsetOfPerformance() {
    measureBlock {
        let set = self.orderedSet2
        for other in [self.elements0, self.elements1, self.elements2, self.elements3, self.elements4, self.elements5, self.elements6, self.elements7, self.elements8, self.elements9] {
          _ = set.isSubsetOf(other)
        }
    }
  }

  func testStrictSubsetOfPerformance() {
    measureBlock {
        let set = self.orderedSet2
        for other in [self.elements0, self.elements1, self.elements2, self.elements3, self.elements4, self.elements5, self.elements6, self.elements7, self.elements8, self.elements9] {
          _ = set.isStrictSubsetOf(other)
        }
    }
  }

  func testSupersetOfPerformance() {
    measureBlock {
        let set = self.orderedSet2
        let other = self.elements3
        for range in self.ranges {
          _ = set.isSupersetOf(other[range])
        }
    }
  }

  func testStrictSupersetOfPerformance() {
    measureBlock {
        let set = self.orderedSet2
        let other = self.elements3
        for range in self.ranges {
          _ = set.isStrictSupersetOf(other[range])
        }
    }
  }

  func testDisjointWithPerformance() {
    measureBlock {
        let set = self.orderedSet2
        let other = self.elements3
        for range in self.ranges {
          _ = set.isDisjointWith(other[range])
        }
    }
  }


}
