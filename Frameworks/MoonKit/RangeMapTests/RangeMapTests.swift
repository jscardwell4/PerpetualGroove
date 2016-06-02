//
//  RangeMapTests.swift
//  RangeMapTests
//
//  Created by Jason Cardwell on 5/31/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

//TODO: Test appendContentsOf and overlapping ranges

final class RangeMapBehaviorTests: XCTestCase {
    
  let indexes = [
    29, 111, 46, 42, 98, 112, 27, 31, 30, 26, 37,
    36, 40, 38, 34, 32, 28, 47, 94, 96, 39, 44,
    45, 43, 97, 41, 35, 93, 95, 33
  ]
  let ranges = [26..<48, 93..<99, 111..<113]

  func testCreation() {
    let map1 = RangeMap<Int>()
    expect(map1.count) == 0
    expect(map1.indexCount) == 0
    expect(map1.headIndex).to(beNil())
    expect(map1.tailIndex).to(beNil())
    expect(map1.coverage).to(beNil())

    let map2 = RangeMap<Int>(indexes)
    expect(map2.count) == 3
    expect(map2.headIndex) == 26
    expect(map2.tailIndex) == 113
    expect(map2.coverage) == 26 ..< 113
    expect(map2.indexCount) == indexes.count
    expect(map2) == ranges

    let map3 = RangeMap<Int>(ranges)
    expect(map3.count) == 3
    expect(map3.headIndex) == 26
    expect(map3.tailIndex) == 113
    expect(map3.coverage) == 26 ..< 113
    expect(map3.indexCount) == indexes.count
    expect(map3) == ranges
    expect(map3) == map2
  }

  func testInsertion() {
    var map = RangeMap(ranges)
    expect(map.count) == 3
    expect(map.headIndex) == 26
    expect(map.tailIndex) == 113
    expect(map.coverage) == 26 ..< 113
    expect(map.indexCount) == indexes.count
    expect(map) == ranges

    map.insert(50)
    expect(map.count) == 4
    expect(map[1]) == 50 ..< 51
    expect(map.indexCount) == indexes.count + 1
    map.insert(49)
    expect(map.count) == 4
    expect(map[1]) == 49 ..< 51
    expect(map.indexCount) == indexes.count + 2
    map.insert(48)
    expect(map.count) == 3
    expect(map[0]) == 26 ..< 51
    expect(map.indexCount) == indexes.count + 3
  }

  func testInvert() {
    let map = RangeMap(ranges)
    expect(map.count) == 3
    expect(map.headIndex) == 26
    expect(map.tailIndex) == 113
    expect(map.coverage) == 26 ..< 113
    expect(map.indexCount) == indexes.count
    expect(map) == ranges

    let invertedMap = map.invert(coverage: 0 ..< 200)
    expect(invertedMap.count) == 4
    expect(invertedMap.headIndex) == 0
    expect(invertedMap.tailIndex) == 200
    expect(invertedMap.coverage) == 0 ..< 200
    expect(invertedMap.indexCount) == (0..<26).count + (48..<93).count + (99..<111).count + (113..<200).count
    expect(invertedMap) == [0..<26, 48..<93, 99..<111, 113..<200]

  }

}

final class RangeMapPerformanceTests: XCTestCase {

  let elements0 = MoonKitTest.integersXXLarge0
  let elementsSlice1 = {$0[0..<$0.startIndex.advancedBy($0.count / 2)]}(MoonKitTest.integersXXLarge0)
  let elementsSlice2 = {$0[$0.startIndex.advancedBy($0.count / 2) ..< $0.endIndex]}(MoonKitTest.integersXXLarge0)
  let coverage = {$0.minElement()! ... $0.maxElement()!}(MoonKitTest.integersXXLarge0)
  let baseRangeMap = RangeMap<Int>(MoonKitTest.integersXXLarge0)
  let baseSliceMap = {RangeMap<Int>($0[0..<$0.startIndex.advancedBy($0.count / 2)])}(MoonKitTest.integersXXLarge0)

  override func setUp() {
    _ = elements0
    _ = elementsSlice1
    _ = elementsSlice2
    _ = coverage
    _ = baseRangeMap
    _ = baseSliceMap
  }

  func testInsertElementPerformance() {
    measureBlock { 
      var rangeMap = RangeMap<Int>()
      for element in self.elements0 { rangeMap.insert(element) }
    }
  }

  func testInsertIndicesPerformance() {
    measureBlock { 
      var rangeMap = RangeMap<Int>()
      rangeMap.insert(self.elements0)
    }
  }

  func testAppendContentsOfPerformance() {
    let rangeMap2 = RangeMap<Int>(elementsSlice2)

    measureBlock {
      var rangeMap1 = self.baseSliceMap
      rangeMap1.appendContentsOf(rangeMap2)
    }
  }

  func testInvertPerformance() {
    measureBlock {
      _ = self.baseRangeMap.invert(coverage: self.coverage)
    }
  }

  func testInvertInPlacePerformance() {
    measureBlock {
      var rangeMap = self.baseRangeMap
      rangeMap.invertInPlace(coverage: self.coverage)
    }
  }

}