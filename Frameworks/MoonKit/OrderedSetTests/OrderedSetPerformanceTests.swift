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

enum Size {
  case XXSmall, XSmall, Small, Medium, Large, XLarge, XXLarge

  var count: Int {
    switch self {
      case .XXSmall: return 100
      case .XSmall:  return 250
      case .Small:   return 500
      case .Medium:  return 10_000
      case .Large:   return 50_000
      case .XLarge:  return 100_000
      case .XXLarge: return 200_000
    }
  }

  func integers(index: Int) -> [Int] {
    switch self {
    case .XXSmall:
      switch index {
      case 1:  return MoonKitTest.integersXXSmall1
      case 2:  return MoonKitTest.integersXXSmall2
      case 3:  return MoonKitTest.integersXXSmall3
      case 4:  return MoonKitTest.integersXXSmall4
      case 5:  return MoonKitTest.integersXXSmall5
      case 6:  return MoonKitTest.integersXXSmall6
      case 7:  return MoonKitTest.integersXXSmall7
      case 8:  return MoonKitTest.integersXXSmall8
      case 9:  return MoonKitTest.integersXXSmall9
      default: return MoonKitTest.integersXXSmall0

      }
    case .XSmall:
      switch index {
      case 1:  return MoonKitTest.integersXSmall1
      case 2:  return MoonKitTest.integersXSmall2
      case 3:  return MoonKitTest.integersXSmall3
      case 4:  return MoonKitTest.integersXSmall4
      case 5:  return MoonKitTest.integersXSmall5
      case 6:  return MoonKitTest.integersXSmall6
      case 7:  return MoonKitTest.integersXSmall7
      case 8:  return MoonKitTest.integersXSmall8
      case 9:  return MoonKitTest.integersXSmall9
      default: return MoonKitTest.integersXSmall0

      }
    case .Small:
      switch index {
      case 1:  return MoonKitTest.integersSmall1
      case 2:  return MoonKitTest.integersSmall2
      case 3:  return MoonKitTest.integersSmall3
      case 4:  return MoonKitTest.integersSmall4
      case 5:  return MoonKitTest.integersSmall5
      case 6:  return MoonKitTest.integersSmall6
      case 7:  return MoonKitTest.integersSmall7
      case 8:  return MoonKitTest.integersSmall8
      case 9:  return MoonKitTest.integersSmall9
      default: return MoonKitTest.integersSmall0

      }
    case .Medium:
      switch index {
      case 1:  return MoonKitTest.integersMedium1
      case 2:  return MoonKitTest.integersMedium2
      case 3:  return MoonKitTest.integersMedium3
      case 4:  return MoonKitTest.integersMedium4
      case 5:  return MoonKitTest.integersMedium5
      case 6:  return MoonKitTest.integersMedium6
      case 7:  return MoonKitTest.integersMedium7
      case 8:  return MoonKitTest.integersMedium8
      case 9:  return MoonKitTest.integersMedium9
      default: return MoonKitTest.integersMedium0

      }
    case .Large:
      switch index {
      case 1:  return MoonKitTest.integersLarge1
      case 2:  return MoonKitTest.integersLarge2
      case 3:  return MoonKitTest.integersLarge3
      case 4:  return MoonKitTest.integersLarge4
      case 5:  return MoonKitTest.integersLarge5
      case 6:  return MoonKitTest.integersLarge6
      case 7:  return MoonKitTest.integersLarge7
      case 8:  return MoonKitTest.integersLarge8
      case 9:  return MoonKitTest.integersLarge9
      default: return MoonKitTest.integersLarge0

      }
    case .XLarge:
      switch index {
      case 1:  return MoonKitTest.integersXLarge1
      case 2:  return MoonKitTest.integersXLarge2
      case 3:  return MoonKitTest.integersXLarge3
      case 4:  return MoonKitTest.integersXLarge4
      case 5:  return MoonKitTest.integersXLarge5
      case 6:  return MoonKitTest.integersXLarge6
      case 7:  return MoonKitTest.integersXLarge7
      case 8:  return MoonKitTest.integersXLarge8
      case 9:  return MoonKitTest.integersXLarge9
      default: return MoonKitTest.integersXLarge0

      }
    case .XXLarge:
      switch index {
      case 1:  return MoonKitTest.integersXXLarge1
      case 2:  return MoonKitTest.integersXXLarge2
      case 3:  return MoonKitTest.integersXXLarge3
      case 4:  return MoonKitTest.integersXXLarge4
      case 5:  return MoonKitTest.integersXXLarge5
      case 6:  return MoonKitTest.integersXXLarge6
      case 7:  return MoonKitTest.integersXXLarge7
      case 8:  return MoonKitTest.integersXXLarge8
      case 9:  return MoonKitTest.integersXXLarge9
      default: return MoonKitTest.integersXXLarge0

      }
    }
  }
}

final class SetTypeTests<S:SetType where S.Element == Int, S.Generator.Element == Int> {

  var emptySet: S = S(minimumCapacity: 0)
  var loadedSet: S = S(minimumCapacity: 0)
  var loadedSubset: S = S(minimumCapacity: 0)
  var evenSet: S = S(minimumCapacity: 0)
  var oddSet: S = S(minimumCapacity: 0)

  let size: Size

  init(size: Size) {
    self.size = size
    elements0 = size.integers(0)
    elements1 = size.integers(1)
    elements2 = size.integers(2)
    elements3 = size.integers(3)
    elements4 = size.integers(4)
    elements5 = size.integers(5)
    elements6 = size.integers(6)
    elements7 = size.integers(7)
    elements8 = size.integers(8)
    elements9 = size.integers(9)
    ranges = srandomRanges(seed: 0, count: 10, indices: 0 ..< size.count, coverage: 0.25, limit: 5000)
    evenElements = evenNumbers(range: 0 ..< size.count * 2)
    oddElements = evenNumbers(range: 1 ..< (size.count * 2).successor())
    subelements0 = elements0.randomElements(size.count / 4)
    subelements1 = elements0.randomElements(size.count / 4)
    subelements2 = elements0.randomElements(size.count / 4)
    subelements3 = elements0.randomElements(size.count / 4)
    subelements4 = elements0.randomElements(size.count / 4)
    subelements5 = elements0.randomElements(size.count / 4)
    subelements6 = elements0.randomElements(size.count / 4)
    subelements7 = elements0.randomElements(size.count / 4)
    subelements8 = elements0.randomElements(size.count / 4)
    subelements9 = elements0.randomElements(size.count / 4)
  }

  let elements0: [Int]
  let elements1: [Int]
  let elements2: [Int]
  let elements3: [Int]
  let elements4: [Int]
  let elements5: [Int]
  let elements6: [Int]
  let elements7: [Int]
  let elements8: [Int]
  let elements9: [Int]
  let ranges: [Range<Int>]
  let evenElements: [Int]
  let oddElements: [Int]
  let subelements0: [Int]
  let subelements1: [Int]
  let subelements2: [Int]
  let subelements3: [Int]
  let subelements4: [Int]
  let subelements5: [Int]
  let subelements6: [Int]
  let subelements7: [Int]
  let subelements8: [Int]
  let subelements9: [Int]

  func setUp() {
    emptySet = S(minimumCapacity: 0)
    loadedSet = S(elements0)
    loadedSubset = S(subelements0)
    evenSet = S(evenElements)
    oddSet = S(oddElements)
  }

  func testCreationPerformance() {
    _ = S(elements0)
    _ = S(elements1)
    _ = S(elements2)
    _ = S(elements3)
    _ = S(elements4)
    _ = S(elements5)
    _ = S(elements6)
    _ = S(elements7)
    _ = S(elements8)
    _ = S(elements9)
  }

  func testInsertionPerformance() {
    var set = emptySet
    for element in elements0 { set.insert(element) }
  }

  func testDeletePerformance() {
    var set = loadedSet
    for element in elements0 { set.remove(element) }
  }

  func testUnionPerformance() {
    _ = loadedSet.union(elements1)
  }

  func testIntersectionPerformance() {
    _ = loadedSet.intersect(elements1)
  }

  func testSubtractPerformance() {
    _ = loadedSet.subtract(elements1)
  }

  func testXORPerformance() {
    _ = loadedSet.exclusiveOr(elements1)
  }

  func testUnionInPlacePerformance() {
    var set = loadedSet
    set.unionInPlace(elements1)
  }

  func testIntersectionInPlacePerformance() {
    var set = loadedSet
    set.intersectInPlace(elements1)
  }

  func testSubtractInPlacePerformance() {
    var set = loadedSet
    set.subtractInPlace(elements1)
  }

  func testXORInPlacePerformance() {
    var set = loadedSet
    set.exclusiveOrInPlace(elements1)
  }

  func testOverallPerformance() {
    var set = emptySet
    for value in elements0 { set.insert(value) }
    for value in elements1 { set.remove(value) }
    set.unionInPlace(elements1)
    set.subtractInPlace(elements0)
    set.exclusiveOrInPlace(elements0)
    set.intersectInPlace(elements1)
  }

  func testSubsetOfPerformance() {
    for other in [elements0, elements1, elements2, elements3, elements4, elements5, elements6, elements7, elements8, elements9] {
      _ = loadedSubset.isSubsetOf(other)
    }
  }

  func testStrictSubsetOfPerformance() {
    for other in [elements0, elements1, elements2, elements3, elements4, elements5, elements6, elements7, elements8, elements9] {
      _ = loadedSubset.isStrictSubsetOf(other)
    }
  }

  func testSupersetOfPerformance() {
    for other in [subelements0, subelements1, subelements2, subelements3, subelements4, subelements5, subelements6, subelements7, subelements8, subelements9] {
      _ = loadedSet.isSupersetOf(other)
    }
  }

  func testStrictSupersetOfPerformance() {
    for other in [subelements0, subelements1, subelements2, subelements3, subelements4, subelements5, subelements6, subelements7, subelements8, subelements9] {
      _ = loadedSet.isStrictSupersetOf(other)
    }
  }

  func testDisjointWithPerformance() {
    for other in [subelements0, subelements1, subelements2, subelements3, subelements4, subelements5, subelements6, subelements7, subelements8, subelements9] {
      _ = loadedSubset.isDisjointWith(other)
    }
    _ = evenSet.isDisjointWith(oddSet)
    _ = oddSet.isDisjointWith(evenSet)
    _ = evenSet.isDisjointWith(oddElements)
    _ = oddSet.isDisjointWith(evenElements)
  }

}

class OrderedSetPerformanceTests: XCTestCase {

  static var _setTypeTests: SetTypeTests<OrderedSet<Int>>?
  class var setTypeTests: SetTypeTests<OrderedSet<Int>> {
    guard _setTypeTests == nil else { return _setTypeTests! }
    _setTypeTests = SetTypeTests<OrderedSet<Int>>(size: size)
    return _setTypeTests!
  }

  class var size: Size { return .Large }

  override class func setUp() {
    _setTypeTests = SetTypeTests(size: self.size)
  }

  override func setUp() { self.dynamicType.setTypeTests.setUp() }

  final func testCreationPerformance() { measureBlock { self.dynamicType.setTypeTests.testCreationPerformance() } }
  final func testInsertionPerformance() { measureBlock { self.dynamicType.setTypeTests.testInsertionPerformance() } }
  final func testDeletePerformance() { measureBlock { self.dynamicType.setTypeTests.testDeletePerformance() } }
  final func testUnionPerformance() { measureBlock { self.dynamicType.setTypeTests.testUnionPerformance() } }
  final func testIntersectionPerformance() { measureBlock { self.dynamicType.setTypeTests.testIntersectionPerformance() } }
  final func testSubtractPerformance() { measureBlock { self.dynamicType.setTypeTests.testSubtractPerformance() } }
  final func testXORPerformance() { measureBlock { self.dynamicType.setTypeTests.testXORPerformance() } }
  final func testUnionInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testUnionInPlacePerformance() } }
  final func testIntersectionInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testIntersectionInPlacePerformance() } }
  final func testSubtractInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testSubtractInPlacePerformance() } }
  final func testXORInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testXORInPlacePerformance() } }
  final func testOverallPerformance() { measureBlock { self.dynamicType.setTypeTests.testOverallPerformance() } }
  final func testSubsetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testSubsetOfPerformance() } }
  final func testStrictSubsetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testStrictSubsetOfPerformance() } }
  final func testSupersetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testSupersetOfPerformance() } }
  final func testStrictSupersetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testStrictSupersetOfPerformance() } }
  final func testDisjointWithPerformance() { measureBlock { self.dynamicType.setTypeTests.testDisjointWithPerformance() } }

  func testReplaceRangePerformance() {
    var count = self.dynamicType.setTypeTests.loadedSet.count
    var ranges: [(remove: Range<Int>, insert: Range<Int>)] = []
    ranges.reserveCapacity(1000)
    let coverage = 0.00025
    srandom(0)
    for _ in 0 ..< 1000 {
      let removeRange = srandomRange(indices: 0 ..< count, coverage: coverage)
      let insertRange = srandomRange(indices: self.dynamicType.setTypeTests.elements1.indices, coverage: coverage)
      ranges.append((removeRange, insertRange))
      count = count - removeRange.count + insertRange.count
      guard count > 0 else { break }
    }

    measureBlock {
      var set = self.dynamicType.setTypeTests.loadedSet
      for (removeRange, insertRange) in ranges {
        guard set.indices.contains(removeRange) else { continue }
        set.replaceRange(removeRange, with: self.dynamicType.setTypeTests.elements1[insertRange])
      }
    }
  }

}

final class OrderedSetPerformanceXXLargeTests: OrderedSetPerformanceTests {
  override class var size: Size { return .XXLarge }
}

final class OrderedSetPerformanceXLargeTests: OrderedSetPerformanceTests {
  override class var size: Size { return .XLarge }
}

final class OrderedSetPerformanceLargeTests: OrderedSetPerformanceTests {
  override class var size: Size { return .Large }
}

final class OrderedSetPerformanceMediumTests: OrderedSetPerformanceTests {
  override class var size: Size { return .Medium }
}

final class OrderedSetPerformanceSmallTests: OrderedSetPerformanceTests {
  override class var size: Size { return .Small }
}

final class OrderedSetPerformanceXSmallTests: OrderedSetPerformanceTests {
  override class var size: Size { return .XSmall }
}

final class OrderedSetPerformanceXXSmallTests: OrderedSetPerformanceTests {
  override class var size: Size { return .XXSmall }
}

class NativeSetPerformanceTests: XCTestCase {

  static var _setTypeTests: SetTypeTests<Set<Int>>?
  class var setTypeTests: SetTypeTests<Set<Int>> {
    guard _setTypeTests == nil else { return _setTypeTests! }
    _setTypeTests = SetTypeTests<Set<Int>>(size: size)
    return _setTypeTests!
  }

  class var size: Size { return .Large }

  override class func setUp() {
    _setTypeTests = SetTypeTests(size: self.size)
  }

  override func setUp() { self.dynamicType.setTypeTests.setUp() }

  final func testCreationPerformance() { measureBlock { self.dynamicType.setTypeTests.testCreationPerformance() } }
  final func testInsertionPerformance() { measureBlock { self.dynamicType.setTypeTests.testInsertionPerformance() } }
  final func testDeletePerformance() { measureBlock { self.dynamicType.setTypeTests.testDeletePerformance() } }
  final func testUnionPerformance() { measureBlock { self.dynamicType.setTypeTests.testUnionPerformance() } }
  final func testIntersectionPerformance() { measureBlock { self.dynamicType.setTypeTests.testIntersectionPerformance() } }
  final func testSubtractPerformance() { measureBlock { self.dynamicType.setTypeTests.testSubtractPerformance() } }
  final func testXORPerformance() { measureBlock { self.dynamicType.setTypeTests.testXORPerformance() } }
  final func testUnionInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testUnionInPlacePerformance() } }
  final func testIntersectionInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testIntersectionInPlacePerformance() } }
  final func testSubtractInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testSubtractInPlacePerformance() } }
  final func testXORInPlacePerformance() { measureBlock { self.dynamicType.setTypeTests.testXORInPlacePerformance() } }
  final func testOverallPerformance() { measureBlock { self.dynamicType.setTypeTests.testOverallPerformance() } }
  final func testSubsetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testSubsetOfPerformance() } }
  final func testStrictSubsetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testStrictSubsetOfPerformance() } }
  final func testSupersetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testSupersetOfPerformance() } }
  final func testStrictSupersetOfPerformance() { measureBlock { self.dynamicType.setTypeTests.testStrictSupersetOfPerformance() } }
  final func testDisjointWithPerformance() { measureBlock { self.dynamicType.setTypeTests.testDisjointWithPerformance() } }

}

final class NativeSetPerformanceXXLargeTests: NativeSetPerformanceTests {
  override class var size: Size { return .XXLarge }
}

final class NativeSetPerformanceXLargeTests: NativeSetPerformanceTests {
  override class var size: Size { return .XLarge }
}

final class NativeSetPerformanceLargeTests: NativeSetPerformanceTests {
  override class var size: Size { return .Large }
}

final class NativeSetPerformanceMediumTests: NativeSetPerformanceTests {
  override class var size: Size { return .Medium }
}

final class NativeSetPerformanceSmallTests: NativeSetPerformanceTests {
  override class var size: Size { return .Small }
}

final class NativeSetPerformanceXSmallTests: NativeSetPerformanceTests {
  override class var size: Size { return .XSmall }
}

final class NativeSetPerformanceXXSmallTests: NativeSetPerformanceTests {
  override class var size: Size { return .XXSmall }
}

