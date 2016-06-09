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

  func stringIntegerPairs(index: Int) -> [(String, Int)] {
    switch self {
    case .XXSmall:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsXXSmall1, MoonKitTest.integersXXSmall1))
      case 2:  return Array(zip(MoonKitTest.stringsXXSmall2, MoonKitTest.integersXXSmall2))
      case 3:  return Array(zip(MoonKitTest.stringsXXSmall3, MoonKitTest.integersXXSmall3))
      case 4:  return Array(zip(MoonKitTest.stringsXXSmall4, MoonKitTest.integersXXSmall4))
      case 5:  return Array(zip(MoonKitTest.stringsXXSmall5, MoonKitTest.integersXXSmall5))
      case 6:  return Array(zip(MoonKitTest.stringsXXSmall6, MoonKitTest.integersXXSmall6))
      case 7:  return Array(zip(MoonKitTest.stringsXXSmall7, MoonKitTest.integersXXSmall7))
      case 8:  return Array(zip(MoonKitTest.stringsXXSmall8, MoonKitTest.integersXXSmall8))
      case 9:  return Array(zip(MoonKitTest.stringsXXSmall9, MoonKitTest.integersXXSmall9))
      default: return Array(zip(MoonKitTest.stringsXXSmall0, MoonKitTest.integersXXSmall0))

      }
    case .XSmall:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsXSmall1, MoonKitTest.integersXSmall1))
      case 2:  return Array(zip(MoonKitTest.stringsXSmall2, MoonKitTest.integersXSmall2))
      case 3:  return Array(zip(MoonKitTest.stringsXSmall3, MoonKitTest.integersXSmall3))
      case 4:  return Array(zip(MoonKitTest.stringsXSmall4, MoonKitTest.integersXSmall4))
      case 5:  return Array(zip(MoonKitTest.stringsXSmall5, MoonKitTest.integersXSmall5))
      case 6:  return Array(zip(MoonKitTest.stringsXSmall6, MoonKitTest.integersXSmall6))
      case 7:  return Array(zip(MoonKitTest.stringsXSmall7, MoonKitTest.integersXSmall7))
      case 8:  return Array(zip(MoonKitTest.stringsXSmall8, MoonKitTest.integersXSmall8))
      case 9:  return Array(zip(MoonKitTest.stringsXSmall9, MoonKitTest.integersXSmall9))
      default: return Array(zip(MoonKitTest.stringsXSmall0, MoonKitTest.integersXSmall0))

      }
    case .Small:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsSmall1, MoonKitTest.integersSmall1))
      case 2:  return Array(zip(MoonKitTest.stringsSmall2, MoonKitTest.integersSmall2))
      case 3:  return Array(zip(MoonKitTest.stringsSmall3, MoonKitTest.integersSmall3))
      case 4:  return Array(zip(MoonKitTest.stringsSmall4, MoonKitTest.integersSmall4))
      case 5:  return Array(zip(MoonKitTest.stringsSmall5, MoonKitTest.integersSmall5))
      case 6:  return Array(zip(MoonKitTest.stringsSmall6, MoonKitTest.integersSmall6))
      case 7:  return Array(zip(MoonKitTest.stringsSmall7, MoonKitTest.integersSmall7))
      case 8:  return Array(zip(MoonKitTest.stringsSmall8, MoonKitTest.integersSmall8))
      case 9:  return Array(zip(MoonKitTest.stringsSmall9, MoonKitTest.integersSmall9))
      default: return Array(zip(MoonKitTest.stringsSmall0, MoonKitTest.integersSmall0))

      }
    case .Medium:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsMedium1, MoonKitTest.integersMedium1))
      case 2:  return Array(zip(MoonKitTest.stringsMedium2, MoonKitTest.integersMedium2))
      case 3:  return Array(zip(MoonKitTest.stringsMedium3, MoonKitTest.integersMedium3))
      case 4:  return Array(zip(MoonKitTest.stringsMedium4, MoonKitTest.integersMedium4))
      case 5:  return Array(zip(MoonKitTest.stringsMedium5, MoonKitTest.integersMedium5))
      case 6:  return Array(zip(MoonKitTest.stringsMedium6, MoonKitTest.integersMedium6))
      case 7:  return Array(zip(MoonKitTest.stringsMedium7, MoonKitTest.integersMedium7))
      case 8:  return Array(zip(MoonKitTest.stringsMedium8, MoonKitTest.integersMedium8))
      case 9:  return Array(zip(MoonKitTest.stringsMedium9, MoonKitTest.integersMedium9))
      default: return Array(zip(MoonKitTest.stringsMedium0, MoonKitTest.integersMedium0))

      }
    case .Large:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsLarge1, MoonKitTest.integersLarge1))
      case 2:  return Array(zip(MoonKitTest.stringsLarge2, MoonKitTest.integersLarge2))
      case 3:  return Array(zip(MoonKitTest.stringsLarge3, MoonKitTest.integersLarge3))
      case 4:  return Array(zip(MoonKitTest.stringsLarge4, MoonKitTest.integersLarge4))
      case 5:  return Array(zip(MoonKitTest.stringsLarge5, MoonKitTest.integersLarge5))
      case 6:  return Array(zip(MoonKitTest.stringsLarge6, MoonKitTest.integersLarge6))
      case 7:  return Array(zip(MoonKitTest.stringsLarge7, MoonKitTest.integersLarge7))
      case 8:  return Array(zip(MoonKitTest.stringsLarge8, MoonKitTest.integersLarge8))
      case 9:  return Array(zip(MoonKitTest.stringsLarge9, MoonKitTest.integersLarge9))
      default: return Array(zip(MoonKitTest.stringsLarge0, MoonKitTest.integersLarge0))

      }
    case .XLarge:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsXLarge1, MoonKitTest.integersXLarge1))
      case 2:  return Array(zip(MoonKitTest.stringsXLarge2, MoonKitTest.integersXLarge2))
      case 3:  return Array(zip(MoonKitTest.stringsXLarge3, MoonKitTest.integersXLarge3))
      case 4:  return Array(zip(MoonKitTest.stringsXLarge4, MoonKitTest.integersXLarge4))
      case 5:  return Array(zip(MoonKitTest.stringsXLarge5, MoonKitTest.integersXLarge5))
      case 6:  return Array(zip(MoonKitTest.stringsXLarge6, MoonKitTest.integersXLarge6))
      case 7:  return Array(zip(MoonKitTest.stringsXLarge7, MoonKitTest.integersXLarge7))
      case 8:  return Array(zip(MoonKitTest.stringsXLarge8, MoonKitTest.integersXLarge8))
      case 9:  return Array(zip(MoonKitTest.stringsXLarge9, MoonKitTest.integersXLarge9))
      default: return Array(zip(MoonKitTest.stringsXLarge0, MoonKitTest.integersXLarge0))

      }
    case .XXLarge:
      switch index {
      case 1:  return Array(zip(MoonKitTest.stringsXXLarge1, MoonKitTest.integersXXLarge1))
      case 2:  return Array(zip(MoonKitTest.stringsXXLarge2, MoonKitTest.integersXXLarge2))
      case 3:  return Array(zip(MoonKitTest.stringsXXLarge3, MoonKitTest.integersXXLarge3))
      case 4:  return Array(zip(MoonKitTest.stringsXXLarge4, MoonKitTest.integersXXLarge4))
      case 5:  return Array(zip(MoonKitTest.stringsXXLarge5, MoonKitTest.integersXXLarge5))
      case 6:  return Array(zip(MoonKitTest.stringsXXLarge6, MoonKitTest.integersXXLarge6))
      case 7:  return Array(zip(MoonKitTest.stringsXXLarge7, MoonKitTest.integersXXLarge7))
      case 8:  return Array(zip(MoonKitTest.stringsXXLarge8, MoonKitTest.integersXXLarge8))
      case 9:  return Array(zip(MoonKitTest.stringsXXLarge9, MoonKitTest.integersXXLarge9))
      default: return Array(zip(MoonKitTest.stringsXXLarge0, MoonKitTest.integersXXLarge0))

      }
    }
  }
}

final class MutableKeyValueCollectionTests<K:MutableKeyValueCollection where K.Key == String, K.Value == Int, K.Generator.Element == (String, Int)> {
  var emptyDictionary: K = K([])
  var loadedDictionary: K = K([])

  let size: Size

  let elements0: [(String, Int)]
  let elements1: [(String, Int)]
  let elements2: [(String, Int)]
  let elements3: [(String, Int)]
  let elements4: [(String, Int)]
  let elements5: [(String, Int)]
  let elements6: [(String, Int)]
  let elements7: [(String, Int)]
  let elements8: [(String, Int)]
  let elements9: [(String, Int)]

  init(size: Size) {
    self.size = size
    elements0 = size.stringIntegerPairs(0)
    elements1 = size.stringIntegerPairs(1)
    elements2 = size.stringIntegerPairs(2)
    elements3 = size.stringIntegerPairs(3)
    elements4 = size.stringIntegerPairs(4)
    elements5 = size.stringIntegerPairs(5)
    elements6 = size.stringIntegerPairs(6)
    elements7 = size.stringIntegerPairs(7)
    elements8 = size.stringIntegerPairs(8)
    elements9 = size.stringIntegerPairs(9)
  }

  func setUp() {
    emptyDictionary = K([])
    loadedDictionary = K(elements0)
  }

  func testSubscriptKeyPerformance() {
    for (key, _) in elements0 { _ = loadedDictionary[key] }
  }

  func testSubscriptIndexPerformance() {
    for index in loadedDictionary.indices { _ = loadedDictionary[index] }
  }

  func testIndexForKeyPerformance() {
    for (key, _) in elements0 { _ = loadedDictionary.indexForKey(key) }
  }

  func testValueForKeyPerformance() {
    for (key, _) in elements0 { _ = loadedDictionary.valueForKey(key) }
  }

  func testCreationPerformance() {
    _ = K(elements0)
    _ = K(elements1)
    _ = K(elements2)
    _ = K(elements3)
    _ = K(elements4)
    _ = K(elements5)
    _ = K(elements6)
    _ = K(elements7)
    _ = K(elements8)
    _ = K(elements9)
  }

  func testInsertValueForKeyPerformance() {
    var dictionary = emptyDictionary
    for (key, value) in elements0 { dictionary.insertValue(value, forKey: key) }
  }

  func testRemoveAtIndexPerformance() {
    var dictionary = loadedDictionary
    while dictionary.startIndex != dictionary.endIndex { dictionary.removeAtIndex(dictionary.startIndex) }
  }

  func testRemoveValueForKeyPerformance() {
    var dictionary = loadedDictionary
    for (key, _) in elements0 { dictionary.removeValueForKey(key) }
  }

  func testUpdateValueForKeyPerformance() {
    var dictionary = loadedDictionary
    for (key, value) in elements1 { dictionary.updateValue(value, forKey: key) }
  }

  func testOverallPerformance() {
    var dictionary = emptyDictionary
    for (key, value) in elements0 { dictionary[key] = value }
    for (key, _) in elements1 { dictionary[key] = nil }
    for (key, value) in elements2 { dictionary[key] = value }
  }

}

class OrderedDictionaryPerformanceTests: XCTestCase {

  static var _mutableKeyValueCollectionTests: MutableKeyValueCollectionTests<OrderedDictionary<String, Int>>?
  class var mutableKeyValueCollectionTests: MutableKeyValueCollectionTests<OrderedDictionary<String, Int>> {
    guard _mutableKeyValueCollectionTests == nil else { return _mutableKeyValueCollectionTests! }
    _mutableKeyValueCollectionTests = MutableKeyValueCollectionTests<OrderedDictionary<String, Int>>(size: size)
    return _mutableKeyValueCollectionTests!
  }

  class var size: Size { return .Large }

  override class func setUp() {
    _mutableKeyValueCollectionTests = MutableKeyValueCollectionTests<OrderedDictionary<String, Int>>(size: self.size)
  }

  override func setUp() { self.dynamicType.mutableKeyValueCollectionTests.setUp() }

  final func testInsertValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testInsertValueForKeyPerformance() }
  }

  final func testRemoveValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testRemoveValueForKeyPerformance() }
  }

  final func testOverallPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testOverallPerformance() }
  }

  final func testSubscriptKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testSubscriptKeyPerformance() }
  }

  final func testSubscriptIndexPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testSubscriptIndexPerformance() }
  }

  final func testIndexForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testIndexForKeyPerformance() }
  }

  final func testValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testValueForKeyPerformance() }
  }

  final func testCreationPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testCreationPerformance() }
  }

  final func testRemoveAtIndexPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testRemoveAtIndexPerformance() }
  }

  final func testUpdateValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testUpdateValueForKeyPerformance() }
  }

  func testReplaceRangePerformance() {
    var count = self.dynamicType.mutableKeyValueCollectionTests.loadedDictionary.count
    var ranges: [(remove: Range<Int>, insert: Range<Int>)] = []
    ranges.reserveCapacity(1000)
    let coverage = 0.00025
    srandom(0)
    for _ in 0 ..< 1000 {
      let removeRange = srandomRange(indices: 0 ..< count, coverage: coverage)
      let insertRange = srandomRange(indices: self.dynamicType.mutableKeyValueCollectionTests.elements1.indices, coverage: coverage)
      ranges.append((removeRange, insertRange))
      count = count - removeRange.count + insertRange.count
      guard count > 0 else { break }
    }

    measureBlock {
      var dictionary = self.dynamicType.mutableKeyValueCollectionTests.loadedDictionary
      for (removeRange, insertRange) in ranges {
        guard dictionary.indices.contains(removeRange) else { continue }
        dictionary.replaceRange(removeRange, with: self.dynamicType.mutableKeyValueCollectionTests.elements1[insertRange])
      }
    }
  }
  
}

final class OrderedDictionaryPerformanceXXLargeTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .XXLarge }
}

final class OrderedDictionaryPerformanceXLargeTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .XLarge }
}

final class OrderedDictionaryPerformanceLargeTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .Large }
}

final class OrderedDictionaryPerformanceMediumTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .Medium }
}

final class OrderedDictionaryPerformanceSmallTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .Small }
}

final class OrderedDictionaryPerformanceXSmallTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .XSmall }
}

final class OrderedDictionaryPerformanceXXSmallTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .XXSmall }
}

class NativeDictionaryPerformanceTests: XCTestCase {

  static var _mutableKeyValueCollectionTests: MutableKeyValueCollectionTests<Dictionary<String, Int>>?
  class var mutableKeyValueCollectionTests: MutableKeyValueCollectionTests<Dictionary<String, Int>> {
    guard _mutableKeyValueCollectionTests == nil else { return _mutableKeyValueCollectionTests! }
    _mutableKeyValueCollectionTests = MutableKeyValueCollectionTests<Dictionary<String, Int>>(size: size)
    return _mutableKeyValueCollectionTests!
  }

  class var size: Size { return .Large }

  override class func setUp() {
    _mutableKeyValueCollectionTests = MutableKeyValueCollectionTests<Dictionary<String, Int>>(size: self.size)
  }

  override func setUp() { self.dynamicType.mutableKeyValueCollectionTests.setUp() }

  final func testInsertValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testInsertValueForKeyPerformance() }
  }

  final func testRemoveValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testRemoveValueForKeyPerformance() }
  }

  final func testOverallPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testOverallPerformance() }
  }

  final func testSubscriptKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testSubscriptKeyPerformance() }
  }

  final func testSubscriptIndexPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testSubscriptIndexPerformance() }
  }

  final func testIndexForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testIndexForKeyPerformance() }
  }

  final func testValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testValueForKeyPerformance() }
  }

  final func testCreationPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testCreationPerformance() }
  }

  final func testRemoveAtIndexPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testRemoveAtIndexPerformance() }
  }

  final func testUpdateValueForKeyPerformance() {
    measureBlock { self.dynamicType.mutableKeyValueCollectionTests.testUpdateValueForKeyPerformance() }
  }

}

final class NativeDictionaryPerformanceXXLargeTests: NativeDictionaryPerformanceTests {
  override class var size: Size { return .XXLarge }
}

final class NativeDictionaryPerformanceXLargeTests: NativeDictionaryPerformanceTests {
  override class var size: Size { return .XLarge }
}

final class NativeDictionaryPerformanceLargeTests: NativeDictionaryPerformanceTests {
  override class var size: Size { return .Large }
}

final class NativeDictionaryPerformanceMediumTests: NativeDictionaryPerformanceTests {
  override class var size: Size { return .Medium }
}

final class NativeDictionaryPerformanceSmallTests: NativeDictionaryPerformanceTests {
  override class var size: Size { return .Small }
}

final class NativeDictionaryPerformanceXSmallTests: NativeDictionaryPerformanceTests {
  override class var size: Size { return .XSmall }
}

final class NativeDictionaryPerformanceXXSmallTests: OrderedDictionaryPerformanceTests {
  override class var size: Size { return .XXSmall }
}
