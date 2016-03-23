//
//  OrderedSetTests.swift
//  OrderedSetTests
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import Nimble
@testable import MoonKit

final class OrderedSetTests: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  func performanceWork<
    S:SetType
    where S.Generator.Element == Int, S.Element == Int
    >(@noescape createSet: (capacity: Int) -> S) -> () -> Void
  {
    let randoms1 = randomIntegers(1000, 0 ..< 500)
    let randoms2 = randomIntegers(1000, 0 ..< 500)

    var set = createSet(capacity: 2000)

    return {
      autoreleasepool { for value in randoms1 { set.insert(value) } }
      autoreleasepool { for value in randoms2 { set.remove(value) } }
      autoreleasepool { set.unionInPlace(randoms2) }
      autoreleasepool { set.subtractInPlace(randoms1) }
      autoreleasepool { set.exclusiveOrInPlace(randoms1) }
      autoreleasepool { set.intersectInPlace(randoms2) }
    }
  }

  func randomIntegers(count: Int, _ range: Range<Int>) -> [Int] {
    guard count > 0 else { return [] }
    func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
    var result = Array<Int>(minimumCapacity: count)
    for _ in 0 ..< count { result.append(randomInt()) }
    return result
  }

  // MARK: - Baseline
  //

  func testBaselinePerformanceWithCapacityReserved() {
    measureBlock(performanceWork { _ in Set<Int>() })
  }

  func testBaselinePerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in Set<Int>() })
  }

  // MARK: - OrderedSetHashMap
  //

  func testHashMapCreation() {
    let hashMap1 = OrderedSetHashMap()

    expect(hashMap1.capacity) <= 2
    expect(hashMap1).to(haveCount(0))

    let hashMap2 = OrderedSetHashMap(minimumCapacity: 24)
    expect(hashMap2.capacity) >= 24
    expect(hashMap2).to(haveCount(0))

    let randoms = randomIntegers(10, 1 ..< 100)
    let hashMap3 = OrderedSetHashMap(randoms)
    let set3 = Set(randoms)
    expect(hashMap3).to(haveCount(set3.count))
    expect(hashMap3.sort()).to(equal(set3.sort()))

    let hashMap4 = [1, 2, 3, 4]
    let set4 = [1, 2, 3, 4]
    expect(hashMap4).to(haveCount(set4.count))
    expect(hashMap4.sort()).to(equal(set4.sort()))
  }

  func testHashMapInsertion() {
    var hashMap = OrderedSetHashMap(minimumCapacity: 8)

    hashMap.insert(1)
    expect(hashMap.count) == 1
    expect(hashMap).to(contain(1))

    hashMap.insert(2)
    expect(hashMap.count) == 2
    expect(hashMap).to(contain(2))

    hashMap.insert(3)
    expect(hashMap.count) == 3
    expect(hashMap).to(contain(3))

    hashMap.insert(4)
    expect(hashMap.count) == 4
    expect(hashMap).to(contain(4))

    hashMap.insert(5)
    expect(hashMap.count) == 5
    expect(hashMap).to(contain(5))
  }

  func testHashMapResize() {
    var hashMap = OrderedSetHashMap(minimumCapacity: 4)
    expect(hashMap.capacity) <= 8
    for i in 1 ... 9 { hashMap.insert(i) }
    expect(hashMap.capacity) > 8
  }

  func testHashMapDeletion() {
    var hashMap: OrderedSetHashMap = [1, 2, 3]
    expect(hashMap).to(haveCount(3))
    expect(hashMap).to(contain(1, 2, 3))
    hashMap.remove(2)
    expect(hashMap).to(haveCount(2))
    expect(hashMap).to(contain(1, 3))
    expect(hashMap.contains(2)).to(beFalse())
    hashMap.remove(1)
    expect(hashMap).to(haveCount(1))
    expect(hashMap).to(contain(3))
    expect(hashMap.contains(1)).to(beFalse())
    expect(hashMap.contains(2)).to(beFalse())
    hashMap.insert(2)
    expect(hashMap).to(haveCount(2))
    expect(hashMap).to(contain(3, 2))
    expect(hashMap.contains(1)).to(beFalse())
    hashMap.insert(1)
    expect(hashMap).to(haveCount(3))
    expect(hashMap).to(contain(1, 2, 3))
  }

  func testHashMapCOW() {
    let hashMap1: OrderedSetHashMap = [1, 2, 3]
    var hashMap2 = hashMap1
    expect(hashMap1).to(haveCount(3))
    expect(hashMap2).to(haveCount(3))

    hashMap2.insert(4)
    expect(hashMap1).to(haveCount(3))
    expect(hashMap2).to(haveCount(4))
  }

  func testHashMapSubsetOf() {
    let hashMap: OrderedSetHashMap = [1, 2, 3]
    expect(hashMap).to(beSubsetOf([1, 2, 3]))
    expect(hashMap).to(beSubsetOf([1, 2, 3, 4]))
    expect(hashMap).to(notBeSubsetOf([1, 2, 4]))
  }

  func testHashMapStrictSubsetOf() {
    let hashMap: OrderedSetHashMap = [1, 2, 3]
    expect(hashMap).to(notBeStrictSubsetOf([1, 2, 3]))
    expect(hashMap).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(hashMap).to(notBeStrictSubsetOf([1, 2, 4]))
  }

  func testHashMapSupersetOf() {
    let hashMap: OrderedSetHashMap = [1, 2, 3]
    expect(hashMap).to(beSupersetOf([1, 2, 3]))
    expect(hashMap).to(beSupersetOf([1, 2]))
    expect(hashMap).to(notBeSupersetOf([1, 2, 4]))
  }

  func testHashMapStrictSupersetOf() {
    let hashMap: OrderedSetHashMap = [1, 2, 3]
    expect(hashMap).to(notBeStrictSupersetOf([1, 2, 3]))
    expect(hashMap).to(beStrictSupersetOf([1, 2]))
    expect(hashMap).to(notBeStrictSupersetOf([1, 2, 4]))
  }

  func testHashMapDisjointWith() {
    let hashMap: OrderedSetHashMap = [1, 2, 3]
    expect(hashMap).to(notBeDisjointWith([1, 4, 5]))
    expect(hashMap).to(beDisjointWith([4, 5]))
    expect(hashMap).to(notBeDisjointWith([1, 2, 3, 4, 5]))
  }

  func testHashMapUnion() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var hashMap = OrderedSetHashMap(randoms1)
    var set = Set(randoms1)
    hashMap.unionInPlace(randoms2)
    set.unionInPlace(randoms2)
    expect(hashMap).to(haveCount(set.count))
    expect(hashMap).to(beSubsetOf(set))
  }

  func testHashMapIntersection() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var hashMap = OrderedSetHashMap(randoms1)
    var set = Set(randoms1)
    hashMap.intersectInPlace(randoms2)
    set.intersectInPlace(randoms2)
    expect(hashMap).to(haveCount(set.count))
    expect(hashMap).to(beSubsetOf(set))
  }

  func testHashMapSubtract() {

    var hashMap1: OrderedSetHashMap = [
       14,   30,  177,  182,    3,  198,   58,  167,  108,  103,   23,   90,    5,  195,   63,  116,  11,  107,  105,  164,
      193,   71,  114,  145,    9,   44,  152,   35,  197,  135,   15,   97,  137,   22,  129,  183, 178,   57,   69,   91,
      159,   41,   49,  132,   74,  120,  102,   42,  158,  130,   67,  190,  176,  142,  180,  156, 127,    7,   43,   16,
       51,   26,   73,   66,   79,   65,  165,   24,   83,   72,   70,  109,   19,  170,  160,   86,  80,  113,  111,   10,
      136,  121,   55,  147,  157,   48,   33,   94,  174,  199,    4,  162,  140,   17,  154,   77,  99,  196,   28,   84,
        6,   50,  131,   12,  134,   25,  118,   78,   45,   37,    2,   98,  188,  101,  146,  123, 117,  141,   27,  181,
       87,   76,  163,   21,  143,  184,  173,  171,  100,   85,   56,   89,  186,  155,   18,   53,  62,   93,   20,   38,
      179,   59,   39,   46,   34,   95,   81,  168,  150,   96,  115,   64,  104,  110,   31,  175,   8,  151,  128,  172,
       40,   82,   13,  192,  122,   60,    1,   75,  138,  185,  161,  149,  139,  133,   54,  112,  92,  126,  187,  119
    ]

    var hashMap2: OrderedSetHashMap = [
        30,  177,  182,    3,  198,   32,   58,  167,  108,  153,  103,   90,    5,  195,   63,   11,  116,  107,  105,  193,
       189,   71,  145,    9,  114,   44,  152,   35,  197,  135,   15,   29,   97,  191,  137,   22,  129,  183,  178,   36,
        69,  194,  159,   91,   41,   49,  132,   74,  120,  102,   42,  158,  166,   47,   67,  130,  190,  176,  125,  142,
       169,  180,  156,  127,    7,   43,   16,   51,   26,   73,   61,   66,   79,   65,  165,   24,   83,   72,   70,   19,
       109,  148,   88,  170,  160,  136,  113,   80,   10,  147,  121,   55,  111,  157,   48,   33,   94,  174,  199,    4,
       162,  140,   17,  154,   77,   68,   99,  196,   28,   84,    6,   50,  144,  131,  124,  134,   25,  118,   78,   45,
        37,    2,   98,  188,  117,  123,  146,  101,  141,   27,   76,  163,  143,  184,  173,  171,  100,   52,   85,   89,
       186,  155,   62,   18,   53,  106,   93,   20,   38,  179,   59,   39,   46,   34,   95,   81,  168,  150,   96,  115,
        64,  104,   31,  175,    8,  151,  128,  172,   40,   82,  192,  122,   60,    1,   75,  138,  149,  139,   54,  112,
        92,  126,  187, 119
    ]

    let expected: OrderedSetHashMap = [14, 12, 23, 164, 181, 87, 21, 56, 57, 110, 13, 86, 185, 161, 133]

    var set: Set<Int> = [
       14,   30,  177,  182,    3,  198,   58,  167,  108,  103,   23,   90,    5,  195,   63,  116,  11,  107,  105,  164,
      193,   71,  114,  145,    9,   44,  152,   35,  197,  135,   15,   97,  137,   22,  129,  183, 178,   57,   69,   91,
      159,   41,   49,  132,   74,  120,  102,   42,  158,  130,   67,  190,  176,  142,  180,  156, 127,    7,   43,   16,
       51,   26,   73,   66,   79,   65,  165,   24,   83,   72,   70,  109,   19,  170,  160,   86,  80,  113,  111,   10,
      136,  121,   55,  147,  157,   48,   33,   94,  174,  199,    4,  162,  140,   17,  154,   77,  99,  196,   28,   84,
        6,   50,  131,   12,  134,   25,  118,   78,   45,   37,    2,   98,  188,  101,  146,  123, 117,  141,   27,  181,
       87,   76,  163,   21,  143,  184,  173,  171,  100,   85,   56,   89,  186,  155,   18,   53,  62,   93,   20,   38,
      179,   59,   39,   46,   34,   95,   81,  168,  150,   96,  115,   64,  104,  110,   31,  175,   8,  151,  128,  172,
       40,   82,   13,  192,  122,   60,    1,   75,  138,  185,  161,  149,  139,  133,   54,  112,  92,  126,  187,  119
    ]

    expect(hashMap1).to(haveCount(set.count))
    expect(hashMap1).to(beSubsetOf(set))

    let result = hashMap1.subtract(hashMap2)
    let expectedResult = set.subtract(hashMap2)

    expect(result).to(haveCount(expectedResult.count))
    expect(result).to(beSubsetOf(expectedResult))

    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var hashMap3 = OrderedSetHashMap(randoms1)
    var set3 = Set(randoms1)
    measureBlock {
      hashMap3.subtractInPlace(randoms2)
    }
    set3.subtractInPlace(randoms2)
    expect(hashMap3).to(haveCount(set3.count))
  }

  func testHashMapXOR() {

    var hashMap1: OrderedSetHashMap = [
       14,   30,  177,  182,    3,  198,   58,  167,  108,  103,   23,   90,    5,  195,   63,  116,  11,  107,  105,  164,
      193,   71,  114,  145,    9,   44,  152,   35,  197,  135,   15,   97,  137,   22,  129,  183, 178,   57,   69,   91,
      159,   41,   49,  132,   74,  120,  102,   42,  158,  130,   67,  190,  176,  142,  180,  156, 127,    7,   43,   16,
       51,   26,   73,   66,   79,   65,  165,   24,   83,   72,   70,  109,   19,  170,  160,   86,  80,  113,  111,   10,
      136,  121,   55,  147,  157,   48,   33,   94,  174,  199,    4,  162,  140,   17,  154,   77,  99,  196,   28,   84,
        6,   50,  131,   12,  134,   25,  118,   78,   45,   37,    2,   98,  188,  101,  146,  123, 117,  141,   27,  181,
       87,   76,  163,   21,  143,  184,  173,  171,  100,   85,   56,   89,  186,  155,   18,   53,  62,   93,   20,   38,
      179,   59,   39,   46,   34,   95,   81,  168,  150,   96,  115,   64,  104,  110,   31,  175,   8,  151,  128,  172,
       40,   82,   13,  192,  122,   60,    1,   75,  138,  185,  161,  149,  139,  133,   54,  112,  92,  126,  187,  119
    ]

    var hashMap2: OrderedSetHashMap = [
        30,  177,  182,    3,  198,   32,   58,  167,  108,  153,  103,   90,    5,  195,   63,   11,  116,  107,  105,  193,
       189,   71,  145,    9,  114,   44,  152,   35,  197,  135,   15,   29,   97,  191,  137,   22,  129,  183,  178,   36,
        69,  194,  159,   91,   41,   49,  132,   74,  120,  102,   42,  158,  166,   47,   67,  130,  190,  176,  125,  142,
       169,  180,  156,  127,    7,   43,   16,   51,   26,   73,   61,   66,   79,   65,  165,   24,   83,   72,   70,   19,
       109,  148,   88,  170,  160,  136,  113,   80,   10,  147,  121,   55,  111,  157,   48,   33,   94,  174,  199,    4,
       162,  140,   17,  154,   77,   68,   99,  196,   28,   84,    6,   50,  144,  131,  124,  134,   25,  118,   78,   45,
        37,    2,   98,  188,  117,  123,  146,  101,  141,   27,   76,  163,  143,  184,  173,  171,  100,   52,   85,   89,
       186,  155,   62,   18,   53,  106,   93,   20,   38,  179,   59,   39,   46,   34,   95,   81,  168,  150,   96,  115,
        64,  104,   31,  175,    8,  151,  128,  172,   40,   82,  192,  122,   60,    1,   75,  138,  149,  139,   54,  112,
        92,  126,  187, 119
    ]

    let expected: OrderedSetHashMap = [
        14,   12,   23,  164,  181,   87,   21,   56,   57,  110,   13,   86,  185,  161,  133,   68,   32,  153,  144,  124,
       189,   29,   52,  191,   36,  194,  106,  166,   47,  125,  169,   61,   88,  148
    ]

    let result = hashMap1.exclusiveOr(hashMap2)
    XCTAssertTrue(result.sort().elementsEqual(expected.sort()), "\(result) does not equal \(expected)")

//    let randoms1 = randomIntegers(500, 1 ..< 200)
//    let randoms2 = randomIntegers(500, 1 ..< 200)
//    var hashMap = OrderedSetHashMap(randoms1)
//    var set = Set(randoms1)
//    hashMap.exclusiveOrInPlace(randoms2)
//    set.exclusiveOrInPlace(randoms2)
//    XCTAssertEqual(hashMap.count, set.count)
  }

  func testHashMapPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedSetHashMap(minimumCapacity: $0) })
  }

  func testHashMapPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedSetHashMap() })
  }

  // MARK: - _OrderedSet

  func DISABLEDtest_OrderedSetCreation() {
    var orderedSet = _OrderedSet<Int>(minimumCapacity: 8)
    XCTAssertGreaterThanOrEqual(orderedSet.capacity, 8)
    XCTAssertEqual(orderedSet.count, 0)

    orderedSet = [1, 2, 3, 4, 5]
    XCTAssertGreaterThanOrEqual(orderedSet.capacity, 5)
    XCTAssertEqual(orderedSet.count, 5)

    let randoms = randomIntegers(100000, 1 ..< 1000)
    orderedSet = _OrderedSet(randoms)
    let set = Set(randoms)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func DISABLEDtest_OrderedSetInsertion() {
    var orderedSet1 = _OrderedSet<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    XCTAssertEqual(orderedSet1.count, 1)
    XCTAssertEqual(orderedSet1[0], 1)
    XCTAssertTrue(orderedSet1.elementsEqual([1]))

    orderedSet1.insert(2)
    XCTAssertEqual(orderedSet1.count, 2)
    XCTAssertEqual(orderedSet1[1], 2)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2]))

    orderedSet1.insert(3)
    XCTAssertEqual(orderedSet1.count, 3)
    XCTAssertEqual(orderedSet1[2], 3)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))

    orderedSet1.insert(4)
    XCTAssertEqual(orderedSet1.count, 4)
    XCTAssertEqual(orderedSet1[3], 4)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4]))

    orderedSet1.insert(5)
    XCTAssertEqual(orderedSet1.count, 5)
    XCTAssertEqual(orderedSet1[4], 5)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5]))

    var orderedSet2 = _OrderedSet<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    XCTAssertEqual(orderedSet2.count, 1)
    XCTAssertEqual(orderedSet2[0], "one")
    XCTAssertTrue(orderedSet2.elementsEqual(["one"]))

    orderedSet2.insert("two")
    XCTAssertEqual(orderedSet2.count, 2)
    XCTAssertEqual(orderedSet2[1], "two")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two"]))

    orderedSet2.insert("three")
    XCTAssertEqual(orderedSet2.count, 3)
    XCTAssertEqual(orderedSet2[2], "three")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))

    orderedSet2.insert("four")
    XCTAssertEqual(orderedSet2.count, 4)
    XCTAssertEqual(orderedSet2[3], "four")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four"]))

    orderedSet2.insert("five")
    XCTAssertEqual(orderedSet2.count, 5)
    XCTAssertEqual(orderedSet2[4], "five")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five"]))
  }

  func DISABLEDtest_OrderedSetResize() {
    var orderedSet1 = _OrderedSet<Int>(minimumCapacity: 8)
    orderedSet1.insert(1)
    orderedSet1.insert(2)
    orderedSet1.insert(3)
    orderedSet1.insert(4)
    orderedSet1.insert(5)
    orderedSet1.insert(6)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6]))
    orderedSet1.insert(7)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7]))
    orderedSet1.insert(8)
    orderedSet1.insert(9)
    orderedSet1.insert(10)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))

    var orderedSet2 = _OrderedSet<String>(minimumCapacity: 8)
    orderedSet2.insert("one")
    orderedSet2.insert("two")
    orderedSet2.insert("three")
    orderedSet2.insert("four")
    orderedSet2.insert("five")
    orderedSet2.insert("six")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six"]))
    orderedSet2.insert("seven")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven"]))
    orderedSet2.insert("eight")
    orderedSet2.insert("nine")
    orderedSet2.insert("ten")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]))
  }

  func DISABLEDtest_OrderedSetDeletion() {
    var orderedSet1: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))
    orderedSet1.removeAtIndex(1)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 3]))
    orderedSet1.removeAtIndex(0)
    XCTAssertTrue(orderedSet1.elementsEqual([3]))
    orderedSet1.insert(2)
    orderedSet1.insert(1)
    XCTAssertTrue(orderedSet1.elementsEqual([3, 2, 1]))

    var orderedSet2: _OrderedSet<String> = ["one", "two", "three"]
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))
    orderedSet2.removeAtIndex(1)
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "three"]))
    orderedSet2.removeAtIndex(0)
    XCTAssertTrue(orderedSet2.elementsEqual(["three"]))
    orderedSet2.insert("two")
    orderedSet2.insert("one")
    XCTAssertTrue(orderedSet2.elementsEqual(["three", "two", "one"]))
  }

  func DISABLEDtest_OrderedSetCOW() {
    var orderedSet1: _OrderedSet<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    XCTAssertTrue(orderedSet1.owner === orderedSet2.owner)
    XCTAssertTrue(orderedSet1.buffer.storage === orderedSet2.buffer.storage)

    orderedSet2.insert(4)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))
    XCTAssertTrue(orderedSet2.elementsEqual([1, 2, 3, 4]))
    XCTAssertFalse(orderedSet1.owner === orderedSet2.owner)
    XCTAssertFalse(orderedSet1.buffer.storage === orderedSet2.buffer.storage)
  }

  func DISABLEDtest_OrderedSetSubscriptAccessors() {
    var orderedSet: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertEqual(orderedSet[0], 1)
    XCTAssertEqual(orderedSet[1], 2)
    XCTAssertEqual(orderedSet[2], 3)
  }

  func DISABLEDtest_OrderedSetSubsetOf() {
    let orderedSet: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertTrue(orderedSet.isSubsetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isSubsetOf([1, 2, 3, 4]))
    XCTAssertFalse(orderedSet.isSubsetOf([1, 2, 4]))
  }

  func DISABLEDtest_OrderedSetStrictSubsetOf() {
    let orderedSet: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertFalse(orderedSet.isStrictSubsetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isStrictSubsetOf([1, 2, 3, 4]))
    XCTAssertFalse(orderedSet.isStrictSubsetOf([1, 2, 4]))
  }

  func DISABLEDtest_OrderedSetSupersetOf() {
    let orderedSet: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertTrue(orderedSet.isSupersetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isSupersetOf([1, 2]))
    XCTAssertFalse(orderedSet.isSupersetOf([1, 2, 4]))
  }

  func DISABLEDtest_OrderedSetStrictSupersetOf() {
    let orderedSet: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertFalse(orderedSet.isStrictSupersetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isStrictSupersetOf([1, 2]))
    XCTAssertFalse(orderedSet.isStrictSupersetOf([1, 2, 4]))
  }

  func DISABLEDtest_OrderedSetDisjointWith() {
    let orderedSet: _OrderedSet<Int> = [1, 2, 3]
    XCTAssertFalse(orderedSet.isDisjointWith([1, 4, 5]))
    XCTAssertTrue(orderedSet.isDisjointWith([4, 5]))
    XCTAssertFalse(orderedSet.isDisjointWith([1, 2, 3, 4, 5]))
  }
  
  func DISABLEDtest_OrderedSetUnion() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)

    var orderedSet = _OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.unionInPlace(randoms2)
    set.unionInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func DISABLEDtest_OrderedSetIntersection() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = _OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.intersectInPlace(randoms2)
    set.intersectInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func DISABLEDtest_OrderedSetSubtract() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = _OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.subtractInPlace(randoms2)
    set.subtractInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func DISABLEDtest_OrderedSetXOR() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = _OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.exclusiveOrInPlace(randoms2)
    set.exclusiveOrInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func DISABLEDtest_OrderedSetPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { _OrderedSet<Int>(minimumCapacity: $0) })
  }

  func DISABLEDtest_OrderedSetPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in _OrderedSet<Int>() })
  }

  // MARK: - OrderedSet

  func testOrderedSetCreation() {
    var orderedSet = OrderedSet<Int>(minimumCapacity: 8)
    XCTAssertGreaterThanOrEqual(orderedSet.capacity, 8)
    XCTAssertEqual(orderedSet.count, 0)

    orderedSet = [1, 2, 3, 4, 5]
    XCTAssertGreaterThanOrEqual(orderedSet.capacity, 5)
    XCTAssertEqual(orderedSet.count, 5)

    let randoms = randomIntegers(100000, 1 ..< 1000)

    orderedSet = OrderedSet(randoms)
    let set = Set(randoms)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func testOrderedSetInsertion() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)

    orderedSet1.insert(1)
    XCTAssertEqual(orderedSet1.count, 1)
    XCTAssertEqual(orderedSet1[0], 1)
    XCTAssertTrue(orderedSet1.elementsEqual([1]))

    orderedSet1.insert(2)
    XCTAssertEqual(orderedSet1.count, 2)
    XCTAssertEqual(orderedSet1[1], 2)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2]))

    orderedSet1.insert(3)
    XCTAssertEqual(orderedSet1.count, 3)
    XCTAssertEqual(orderedSet1[2], 3)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))

    orderedSet1.insert(4)
    XCTAssertEqual(orderedSet1.count, 4)
    XCTAssertEqual(orderedSet1[3], 4)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4]))

    orderedSet1.insert(5)
    XCTAssertEqual(orderedSet1.count, 5)
    XCTAssertEqual(orderedSet1[4], 5)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5]))

    var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)

    orderedSet2.insert("one")
    XCTAssertEqual(orderedSet2.count, 1)
    XCTAssertEqual(orderedSet2[0], "one")
    XCTAssertTrue(orderedSet2.elementsEqual(["one"]))

    orderedSet2.insert("two")
    XCTAssertEqual(orderedSet2.count, 2)
    XCTAssertEqual(orderedSet2[1], "two")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two"]))

    orderedSet2.insert("three")
    XCTAssertEqual(orderedSet2.count, 3)
    XCTAssertEqual(orderedSet2[2], "three")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))

    orderedSet2.insert("four")
    XCTAssertEqual(orderedSet2.count, 4)
    XCTAssertEqual(orderedSet2[3], "four")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four"]))

    orderedSet2.insert("five")
    XCTAssertEqual(orderedSet2.count, 5)
    XCTAssertEqual(orderedSet2[4], "five")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five"]))
  }

  func testOrderedSetResize() {
    var orderedSet1 = OrderedSet<Int>(minimumCapacity: 8)
    orderedSet1.insert(1)
    orderedSet1.insert(2)
    orderedSet1.insert(3)
    orderedSet1.insert(4)
    orderedSet1.insert(5)
    orderedSet1.insert(6)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6]))
    orderedSet1.insert(7)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7]))
    orderedSet1.insert(8)
    orderedSet1.insert(9)
    orderedSet1.insert(10)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))

    var orderedSet2 = OrderedSet<String>(minimumCapacity: 8)
    orderedSet2.insert("one")
    orderedSet2.insert("two")
    orderedSet2.insert("three")
    orderedSet2.insert("four")
    orderedSet2.insert("five")
    orderedSet2.insert("six")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six"]))
    orderedSet2.insert("seven")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven"]))
    orderedSet2.insert("eight")
    orderedSet2.insert("nine")
    orderedSet2.insert("ten")
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]))
  }

  func testOrderedSetDeletion() {
    var orderedSet1: OrderedSet<Int> = [1, 2, 3]
    XCTAssertTrue(orderedSet1.elementsEqual([1, 2, 3]))
    orderedSet1.removeAtIndex(1)
    XCTAssertTrue(orderedSet1.elementsEqual([1, 3]))
    orderedSet1.removeAtIndex(0)
    XCTAssertTrue(orderedSet1.elementsEqual([3]))
    orderedSet1.insert(2)
    orderedSet1.insert(1)
    XCTAssertTrue(orderedSet1.elementsEqual([3, 2, 1]))

    var orderedSet2: OrderedSet<String> = ["one", "two", "three"]
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "two", "three"]))
    orderedSet2.removeAtIndex(1)
    XCTAssertTrue(orderedSet2.elementsEqual(["one", "three"]))
    orderedSet2.removeAtIndex(0)
    XCTAssertTrue(orderedSet2.elementsEqual(["three"]))
    orderedSet2.insert("two")
    orderedSet2.insert("one")
    XCTAssertTrue(orderedSet2.elementsEqual(["three", "two", "one"]))
  }

  func testOrderedSetCOW() {
    let orderedSet1: OrderedSet<Int> = [1, 2, 3]
    var orderedSet2 = orderedSet1
    XCTAssertTrue(orderedSet1.elementsEqual(orderedSet2))

    orderedSet2.insert(4)
    XCTAssertFalse(orderedSet1.elementsEqual(orderedSet2))
  }

  func testOrderedSetSubscriptAccessors() {
    var orderedSet: OrderedSet<Int> = [1, 2, 3]
    XCTAssertEqual(orderedSet[0], 1)
    XCTAssertEqual(orderedSet[1], 2)
    XCTAssertEqual(orderedSet[2], 3)
  }

  func testOrderedSetSubsetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    XCTAssertTrue(orderedSet.isSubsetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isSubsetOf([1, 2, 3, 4]))
    XCTAssertFalse(orderedSet.isSubsetOf([1, 2, 4]))
  }

  func testOrderedSetStrictSubsetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    XCTAssertFalse(orderedSet.isStrictSubsetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isStrictSubsetOf([1, 2, 3, 4]))
    XCTAssertFalse(orderedSet.isStrictSubsetOf([1, 2, 4]))
  }

  func testOrderedSetSupersetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    XCTAssertTrue(orderedSet.isSupersetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isSupersetOf([1, 2]))
    XCTAssertFalse(orderedSet.isSupersetOf([1, 2, 4]))
  }

  func testOrderedSetStrictSupersetOf() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    XCTAssertFalse(orderedSet.isStrictSupersetOf([1, 2, 3]))
    XCTAssertTrue(orderedSet.isStrictSupersetOf([1, 2]))
    XCTAssertFalse(orderedSet.isStrictSupersetOf([1, 2, 4]))
  }

  func testOrderedSetDisjointWith() {
    let orderedSet: OrderedSet<Int> = [1, 2, 3]
    XCTAssertFalse(orderedSet.isDisjointWith([1, 4, 5]))
    XCTAssertTrue(orderedSet.isDisjointWith([4, 5]))
    XCTAssertFalse(orderedSet.isDisjointWith([1, 2, 3, 4, 5]))
  }

  func testOrderedSetUnion() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.unionInPlace(randoms2)
    set.unionInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func testOrderedSetIntersection() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.intersectInPlace(randoms2)
    set.intersectInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func testOrderedSetSubtract() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.subtractInPlace(randoms2)
    set.subtractInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func testOrderedSetXOR() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var orderedSet = OrderedSet(randoms1)
    var set = Set(randoms1)
    orderedSet.exclusiveOrInPlace(randoms2)
    set.exclusiveOrInPlace(randoms2)
    XCTAssertEqual(orderedSet.count, set.count)
  }

  func testOrderedSetPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { OrderedSet<Int>(minimumCapacity: $0) })
  }

  func testOrderedSetPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in OrderedSet<Int>() })
  }

}
