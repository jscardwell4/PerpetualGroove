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

let elements0 = MoonKitTest.integersXXLarge0
let elements1 = MoonKitTest.integersXXLarge1
let elements2 = MoonKitTest.integersXXLarge2
let elements3 = MoonKitTest.integersXXLarge3
let elements4 = MoonKitTest.integersXXLarge4
let elements5 = MoonKitTest.integersXXLarge5
let elements6 = MoonKitTest.integersXXLarge6
let elements7 = MoonKitTest.integersXXLarge7
let elements8 = MoonKitTest.integersXXLarge8
let elements9 = MoonKitTest.integersXXLarge9
let ranges: [Range<Int>] = srandomRanges(seed: 0, count: 10, indices: MoonKitTest.integersXXLarge0.indices, coverage: 0.00025, limit: 5000)

final class OrderedSetPerformanceTests: XCTestCase {


  var orderedSet1: OrderedSet<Int> = []
  var orderedSet2: OrderedSet<Int> = []

  var nativeSet: Set<Int> = []
  var nativeSet2: Set<Int> = []

  override func setUp() {
    touch(ranges)
    touch(elements0)
    touch(elements1)
    touch(elements2)
    touch(elements3)
    touch(elements4)
    touch(elements5)
    touch(elements6)
    touch(elements7)
    touch(elements8)
    touch(elements9)

    orderedSet1 = []
    orderedSet2 = OrderedSet<Int>(elements0)
    nativeSet = []
    nativeSet2 = Set<Int>(elements0)
  }


  func testCreationPerformance() {
    measureBlock { 
      autoreleasepool {
      _ = OrderedSet(elements0)
      _ = OrderedSet(elements1)
      _ = OrderedSet(elements2)
      _ = OrderedSet(elements3)
      _ = OrderedSet(elements4)
      _ = OrderedSet(elements5)
      _ = OrderedSet(elements6)
      _ = OrderedSet(elements7)
      _ = OrderedSet(elements8)
      _ = OrderedSet(elements9)
      }
    }
  }

  func testInsertionPerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet1
        for i in elements0 { set.insert(i) }
      }
    }
  }

  func testDeletePerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet2
        for i in elements0 { set.remove(i) }
      }
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
      autoreleasepool {
        var set = self.orderedSet2
        for (removeRange, insertRange) in ranges {
          guard set.indices.contains(removeRange) else { continue }
          set.replaceRange(removeRange, with: elements1[insertRange])
        }
      }
    }
  }

  func testUnionPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.union(elements1)
      }
    }
  }
  
  func testIntersectionPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.intersect(elements1)
      }
    }
  }

  func testSubtractPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.subtract(elements1)
      }
    }
  }

  func testXORPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.exclusiveOr(elements1)
      }
    }
  }

  func testUnionInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        self.orderedSet2.unionInPlace(elements1)
      }
    }
  }
  
  func testIntersectionInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        var orderedSet = self.orderedSet2
        orderedSet.intersectInPlace(elements1)
      }
    }
  }

  func testSubtractInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        var orderedSet = self.orderedSet2
        orderedSet.subtractInPlace(elements1)
      }
    }
  }

  func testXORInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        var orderedSet = self.orderedSet2
       orderedSet.exclusiveOrInPlace(elements1)
      }
    }
  }

  func testOverallPerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet1
        for value in elements0 { set.insert(value) }
        for value in elements1 { set.remove(value) }
        set.unionInPlace(elements1)
        set.subtractInPlace(elements0)
        set.exclusiveOrInPlace(elements0)
        set.intersectInPlace(elements1)
      }
    }
  }

  func testSubsetOfPerformance() {
    measureBlock {
      autoreleasepool {
        let set = self.orderedSet2
        for other in [elements0, elements1, elements2, elements3, elements4, elements5, elements6, elements7, elements8, elements9] {
          _ = set.isSubsetOf(other)
        }
      }
    }
  }

  func testStrictSubsetOfPerformance() {
    measureBlock {
      autoreleasepool {
        let set = self.orderedSet2
        for other in [elements0, elements1, elements2, elements3, elements4, elements5, elements6, elements7, elements8, elements9] {
          _ = set.isStrictSubsetOf(other)
        }
      }
    }
  }

  func testSupersetOfPerformance() {
    measureBlock {
      autoreleasepool {
        let set = self.orderedSet2
        let other = elements3
        for range in ranges {
          _ = set.isSupersetOf(other[range])
        }
      }
    }
  }

  func testStrictSupersetOfPerformance() {
    measureBlock {
      autoreleasepool {
        let set = self.orderedSet2
        let other = elements3
        for range in ranges {
          _ = set.isStrictSupersetOf(other[range])
        }
      }
    }
  }

  func testDisjointWithPerformance() {
    measureBlock {
      autoreleasepool {
        let set = self.orderedSet2
        let other = elements3
        for range in ranges {
          _ = set.isDisjointWith(other[range])
        }
      }
    }
  }

  func testNativeCreationPerformance() {
    measureBlock {
      autoreleasepool {
      _ = Set(elements0)
      _ = Set(elements1)
      _ = Set(elements2)
      _ = Set(elements3)
      _ = Set(elements4)
      _ = Set(elements5)
      _ = Set(elements6)
      _ = Set(elements7)
      _ = Set(elements8)
      _ = Set(elements9)
      }
    }
  }

  func testNativeInsertionPerformance() {
    measureBlock {
      autoreleasepool {
      var set = self.nativeSet
      for i in elements0 { set.insert(i) }
      }
    }
  }

  func testNativeDeletePerformance() {
    measureBlock {
      autoreleasepool {
      var set = self.nativeSet2
      for i in elements0 { set.remove(i) }
      }
    }
  }

  func testNativeUnionPerformance() {
    measureBlock {
      autoreleasepool {
      _ = self.nativeSet2.union(elements1)
      }
    }
  }

  func testNativeIntersectionPerformance() {
    measureBlock {
      autoreleasepool {
      _ = self.nativeSet2.intersect(elements1)
      }
    }
  }

  func testNativeSubtractPerformance() {
    measureBlock {
      autoreleasepool {
      _ = self.nativeSet2.subtract(elements1)
      }
    }
  }

  func testNativeXORPerformance() {
    measureBlock {
      autoreleasepool {
      _ = self.nativeSet2.exclusiveOr(elements1)
      }
    }
  }

  func testNativeUnionInPlacePerformance() {
    measureBlock {
      autoreleasepool {
      self.nativeSet2.unionInPlace(elements1)
      }
    }
  }

  func testNativeIntersectionInPlacePerformance() {
    measureBlock {
      autoreleasepool {
      var nativeSet = self.nativeSet2
      nativeSet.intersectInPlace(elements1)
      }
    }
  }

  func testNativeSubtractInPlacePerformance() {
    measureBlock {
      autoreleasepool {
      var nativeSet = self.nativeSet2
      nativeSet.subtractInPlace(elements1)
      }
    }
  }

  func testNativeXORInPlacePerformance() {
    measureBlock {
      autoreleasepool {
      var nativeSet = self.nativeSet2
      nativeSet.exclusiveOrInPlace(elements1)
      }
    }
  }

  func testNativeOverallPerformance() {
    measureBlock {
      autoreleasepool {
      var set = self.nativeSet
      for value in elements0 { set.insert(value) }
      for value in elements1 { set.remove(value) }
      set.unionInPlace(elements1)
      set.subtractInPlace(elements0)
      set.exclusiveOrInPlace(elements0)
      set.intersectInPlace(elements1)
      }
    }
  }

  func testNativeSubsetOfPerformance() {
    measureBlock {
      autoreleasepool {
      let set = self.nativeSet2
      for other in [elements0, elements1, elements2, elements3, elements4, elements5, elements6, elements7, elements8, elements9] {
        _ = set.isSubsetOf(other)
      }
      }
    }
  }

  func testNativeStrictSubsetOfPerformance() {
    measureBlock {
      autoreleasepool {
      let set = self.nativeSet2
      for other in [elements0, elements1, elements2, elements3, elements4, elements5, elements6, elements7, elements8, elements9] {
        _ = set.isStrictSubsetOf(other)
      }
      }
    }
  }

  func testNativeSupersetOfPerformance() {
    measureBlock {
      autoreleasepool {
      let set = self.nativeSet2
      let other = elements3
      for range in ranges {
        _ = set.isSupersetOf(other[range])
      }
      }
    }
  }

  func testNativeStrictSupersetOfPerformance() {
    measureBlock {
      autoreleasepool {
      let set = self.nativeSet2
      let other = elements3
      for range in ranges {
        _ = set.isStrictSupersetOf(other[range])
      }
      }
    }
  }

  func testNativeDisjointWithPerformance() {
    measureBlock {
      autoreleasepool {
      let set = self.nativeSet2
      let other = elements3
      for range in ranges {
        _ = set.isDisjointWith(other[range])
      }
      }
    }
  }

}
