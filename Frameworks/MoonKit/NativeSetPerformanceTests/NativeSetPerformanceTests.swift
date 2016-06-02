//
//  NativeSetPerformanceTests.swift
//  NativeSetPerformanceTests
//
//  Created by Jason Cardwell on 5/31/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

final class NativeSetPerformanceTests: XCTestCase {

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

  var nativeSet: Set<Int> = []
  var nativeSet2: Set<Int> = []

  override func setUp() {
    _ = ranges
    nativeSet = []
    nativeSet2 = Set<Int>(elements0)
  }

  func testCreationPerformance() {
    measureBlock {
      _ = Set(self.elements0)
      _ = Set(self.elements1)
      _ = Set(self.elements2)
      _ = Set(self.elements3)
      _ = Set(self.elements4)
      _ = Set(self.elements5)
      _ = Set(self.elements6)
      _ = Set(self.elements7)
      _ = Set(self.elements8)
      _ = Set(self.elements9)
    }
  }

 func testInsertionPerformance() {
    measureBlock {
        var set = self.nativeSet
        for i in self.elements0 { set.insert(i) }
    }
  }

  func testDeletePerformance() {
    measureBlock {
        var set = self.nativeSet2
        for i in self.elements0 { set.remove(i) }
    }
  }

  func testUnionPerformance() {
    measureBlock {
        _ = self.nativeSet2.union(self.elements1)
    }
  }
  
  func testIntersectionPerformance() {
    measureBlock {
        _ = self.nativeSet2.intersect(self.elements1)
    }
  }

  func testSubtractPerformance() {
    measureBlock {
        _ = self.nativeSet2.subtract(self.elements1)
    }
  }

  func testXORPerformance() {
    measureBlock {
        _ = self.nativeSet2.exclusiveOr(self.elements1)
    }
  }

  func testUnionInPlacePerformance() {
    measureBlock {
        self.nativeSet2.unionInPlace(self.elements1)
    }
  }
  
  func testIntersectionInPlacePerformance() {
    measureBlock {
        var nativeSet = self.nativeSet2
        nativeSet.intersectInPlace(self.elements1)
    }
  }

  func testSubtractInPlacePerformance() {
    measureBlock {
        var nativeSet = self.nativeSet2
        nativeSet.subtractInPlace(self.elements1)
    }
  }

  func testXORInPlacePerformance() {
    measureBlock {
        var nativeSet = self.nativeSet2
       nativeSet.exclusiveOrInPlace(self.elements1)
    }
  }

  func testOverallPerformance() {
    measureBlock {
        var set = self.nativeSet
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
        let set = self.nativeSet2
        for other in [self.elements0, self.elements1, self.elements2, self.elements3, self.elements4, self.elements5, self.elements6, self.elements7, self.elements8, self.elements9] {
          _ = set.isSubsetOf(other)
        }
    }
  }

  func testStrictSubsetOfPerformance() {
    measureBlock {
        let set = self.nativeSet2
        for other in [self.elements0, self.elements1, self.elements2, self.elements3, self.elements4, self.elements5, self.elements6, self.elements7, self.elements8, self.elements9] {
          _ = set.isStrictSubsetOf(other)
        }
    }
  }

  func testSupersetOfPerformance() {
    measureBlock {
        let set = self.nativeSet2
        let other = self.elements3
        for range in self.ranges {
          _ = set.isSupersetOf(other[range])
        }
    }
  }

  func testStrictSupersetOfPerformance() {
    measureBlock {
        let set = self.nativeSet2
        let other = self.elements3
        for range in self.ranges {
          _ = set.isStrictSupersetOf(other[range])
        }
    }
  }

  func testDisjointWithPerformance() {
    measureBlock {
        let set = self.nativeSet2
        let other = self.elements3
        for range in self.ranges {
          _ = set.isDisjointWith(other[range])
        }
    }
  }


}
