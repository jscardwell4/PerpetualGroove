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

  var elements1: [Int] = []
  var elements2: [Int] = []
  var orderedSet1: OrderedSet<Int> = []
  var orderedSet2: OrderedSet<Int> = []

  override func setUp() {
    elements1 = MoonKitTest.integersXXLarge1
    elements2 = MoonKitTest.integersXXLarge2
    orderedSet1 = []
    orderedSet2 = OrderedSet<Int>(elements1)
    print("elements1.count = \(elements1.count)\nelements2.count = \(elements2.count)\norderedSet2.count = \(orderedSet2.count)")
  }

  func testInsertionPerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet1
        for i in self.elements1 { set.insert(i) }
      }
    }
  }

  func testDeletePerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet2
        for i in self.elements1 { set.remove(i) }
      }
    }
  }

  func testReplaceRangePerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet2
        for _ in 0 ..< 100 {
          let range = randomRange(set.count, coverage: 0.25)
          set.replaceRange(range, with: self.elements2[range])
        }
      }
    }
  }

  func testUnionPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.union(self.elements2)
      }
    }
  }
  
  func testIntersectionPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.intersect(self.elements2)
      }
    }
  }

  func testSubtractPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.subtract(self.elements2)
      }
    }
  }

  func testXORPerformance() {
    measureBlock {
      autoreleasepool {
        _ = self.orderedSet2.exclusiveOr(self.elements2)
      }
    }
  }

  func testUnionInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        self.orderedSet2.unionInPlace(self.elements2)
      }
    }
  }
  
  func testIntersectionInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        var orderedSet = self.orderedSet2
        orderedSet.intersectInPlace(self.elements2)
      }
    }
  }

  func testSubtractInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        var orderedSet = self.orderedSet2
        orderedSet.subtractInPlace(self.elements2)
      }
    }
  }

  func testXORInPlacePerformance() {
    measureBlock {
      autoreleasepool {
        var orderedSet = self.orderedSet2
       orderedSet.exclusiveOrInPlace(self.elements2)
      }
    }
  }

  func testOverallPerformance() {
    measureBlock {
      autoreleasepool {
        var set = self.orderedSet1
        for value in self.elements1 { set.insert(value) }
        for value in self.elements2 { set.remove(value) }
        set.unionInPlace(self.elements2)
        set.subtractInPlace(self.elements1)
        set.exclusiveOrInPlace(self.elements1)
        set.intersectInPlace(self.elements2)
      }
    }
  }

}
