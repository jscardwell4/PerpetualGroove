//
//  NativeSetTests.swift
//  NativeSetTests
//
//  Created by Jason Cardwell on 3/24/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import Nimble
@testable import MoonKit

final class NativeSetTests: XCTestCase {

  func perform<
    S:SetType where S.Generator.Element == Int, S.Element == Int
    >(@noescape createTarget: (values: [Int]) -> S, execute: (target: S, values: [Int]) -> Void) -> () -> Void
  {
    let randoms1 = randomIntegers(10000, 0 ..< 2000)
    let randoms2 = randomIntegers(10000, 0 ..< 2000)
    var target = createTarget(values: randoms1)
    return {
      autoreleasepool { execute(target: target, values: randoms2) }
    }

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

  func testBaselinePerformanceWithCapacityReserved() {
    measureBlock(performanceWork { _ in Set<Int>() })
  }

  func testBaselinePerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in Set<Int>() })
  }

  func testCreation() {
    let nativeSet1 = NativeSet<Int>()

    expect(nativeSet1).to(haveCount(0))

    let nativeSet2 = NativeSet<Int>(minimumCapacity: 24)
    expect(nativeSet2).to(haveCount(0))

    let randoms = randomIntegers(10, 1 ..< 100)
    let nativeSet3 = NativeSet(randoms)
    let set3 = Set(randoms)
    expect(nativeSet3).to(haveCount(set3.count))
    expect(nativeSet3.sort()).to(equal(set3.sort()))

    let nativeSet4 = [1, 2, 3, 4]
    let set4 = [1, 2, 3, 4]
    expect(nativeSet4).to(haveCount(set4.count))
    expect(nativeSet4.sort()).to(equal(set4.sort()))
  }

  func testInsertion() {
    var nativeSet = NativeSet<Int>(minimumCapacity: 8)

    nativeSet.insert(1)
    expect(nativeSet.count) == 1
    expect(nativeSet).to(contain(1))

    nativeSet.insert(2)
    expect(nativeSet.count) == 2
    expect(nativeSet).to(contain(2))

    nativeSet.insert(3)
    expect(nativeSet.count) == 3
    expect(nativeSet).to(contain(3))

    nativeSet.insert(4)
    expect(nativeSet.count) == 4
    expect(nativeSet).to(contain(4))

    nativeSet.insert(5)
    expect(nativeSet.count) == 5
    expect(nativeSet).to(contain(5))
  }

  func testDeletion() {
    var nativeSet: NativeSet = [1, 2, 3]
    expect(nativeSet).to(haveCount(3))
    expect(nativeSet).to(contain(1, 2, 3))
    nativeSet.remove(2)
    expect(nativeSet).to(haveCount(2))
    expect(nativeSet).to(contain(1, 3))
    expect(nativeSet.contains(2)).to(beFalse())
    nativeSet.remove(1)
    expect(nativeSet).to(haveCount(1))
    expect(nativeSet).to(contain(3))
    expect(nativeSet.contains(1)).to(beFalse())
    expect(nativeSet.contains(2)).to(beFalse())
    nativeSet.insert(2)
    expect(nativeSet).to(haveCount(2))
    expect(nativeSet).to(contain(3, 2))
    expect(nativeSet.contains(1)).to(beFalse())
    nativeSet.insert(1)
    expect(nativeSet).to(haveCount(3))
    expect(nativeSet).to(contain(1, 2, 3))
  }

  func testCOW() {
    let nativeSet1: NativeSet = [1, 2, 3]
    var nativeSet2 = nativeSet1
    expect(nativeSet1).to(haveCount(3))
    expect(nativeSet2).to(haveCount(3))

    nativeSet2.insert(4)
    expect(nativeSet1).to(haveCount(3))
    expect(nativeSet2).to(haveCount(4))
  }

  func testSubsetOf() {
    let nativeSet: NativeSet = [1, 2, 3]
    expect(nativeSet).to(beSubsetOf([1, 2, 3]))
    expect(nativeSet).to(beSubsetOf([1, 2, 3, 4]))
    expect(nativeSet).to(notBeSubsetOf([1, 2, 4]))
  }

  func testStrictSubsetOf() {
    let nativeSet: NativeSet = [1, 2, 3]
    expect(nativeSet).to(notBeStrictSubsetOf([1, 2, 3]))
    expect(nativeSet).to(beStrictSubsetOf([1, 2, 3, 4]))
    expect(nativeSet).to(notBeStrictSubsetOf([1, 2, 4]))
  }

  func testSupersetOf() {
    let nativeSet: NativeSet = [1, 2, 3]
    expect(nativeSet).to(beSupersetOf([1, 2, 3]))
    expect(nativeSet).to(beSupersetOf([1, 2]))
    expect(nativeSet).to(notBeSupersetOf([1, 2, 4]))
  }

  func testStrictSupersetOf() {
    let nativeSet: NativeSet = [1, 2, 3]
    expect(nativeSet).to(notBeStrictSupersetOf([1, 2, 3]))
    expect(nativeSet).to(beStrictSupersetOf([1, 2]))
    expect(nativeSet).to(notBeStrictSupersetOf([1, 2, 4]))
  }

  func testDisjointWith() {
    let nativeSet: NativeSet = [1, 2, 3]
    expect(nativeSet).to(notBeDisjointWith([1, 4, 5]))
    expect(nativeSet).to(beDisjointWith([4, 5]))
    expect(nativeSet).to(notBeDisjointWith([1, 2, 3, 4, 5]))
  }

  func testUnion() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var nativeSet = NativeSet(randoms1)
    var set = Set(randoms1)
    nativeSet.unionInPlace(randoms2)
    set.unionInPlace(randoms2)
    expect(nativeSet).to(haveCount(set.count))
    expect(nativeSet).to(beSubsetOf(set))
  }

  func testIntersection() {
    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var nativeSet = NativeSet(randoms1)
    var set = Set(randoms1)
    nativeSet.intersectInPlace(randoms2)
    set.intersectInPlace(randoms2)
    expect(nativeSet).to(haveCount(set.count))
    expect(nativeSet).to(beSubsetOf(set))
  }

  func testSubtract() {

    var nativeSet1: NativeSet = [
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

    var nativeSet2: NativeSet = [
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

    let expected: NativeSet = [14, 12, 23, 164, 181, 87, 21, 56, 57, 110, 13, 86, 185, 161, 133]

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

    expect(nativeSet1).to(haveCount(set.count))
    expect(nativeSet1).to(beSubsetOf(set))

    let result = nativeSet1.subtract(nativeSet2)
    let expectedResult = set.subtract(nativeSet2)

    expect(result).to(haveCount(expectedResult.count))
    expect(result).to(beSubsetOf(expectedResult))

    let randoms1 = randomIntegers(100000, 1 ..< 1000)
    let randoms2 = randomIntegers(100000, 1 ..< 1000)
    var nativeSet3 = NativeSet(randoms1)
    var set3 = Set(randoms1)
    nativeSet3.subtractInPlace(randoms2)
    set3.subtractInPlace(randoms2)
    expect(nativeSet3).to(haveCount(set3.count))
  }

  func testSubtractPerformance() {
    let work = perform({NativeSet<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testStdlibSubtractPerformance() {
    let work = perform({Set<Int>($0)}, execute: {_ = $0.subtract($1)})
    measureBlock(work)
  }

  func testXOR() {

    var nativeSet1: NativeSet = [
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

    var nativeSet2: NativeSet = [
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

    let expected: NativeSet = [
      14,   12,   23,  164,  181,   87,   21,   56,   57,  110,   13,   86,  185,  161,  133,   68,   32,  153,  144,  124,
      189,   29,   52,  191,   36,  194,  106,  166,   47,  125,  169,   61,   88,  148
    ]

    let result = nativeSet1.exclusiveOr(nativeSet2)
    expect(result).to(beSubsetOf(expected))

    let randoms1 = randomIntegers(500, 1 ..< 200)
    let randoms2 = randomIntegers(500, 1 ..< 200)
    var nativeSet = NativeSet(randoms1)
    var set = Set(randoms1)
    nativeSet.exclusiveOrInPlace(randoms2)
    set.exclusiveOrInPlace(randoms2)
    expect(nativeSet).to(haveCount(set.count))
  }

  func testPerformanceWithCapacityReserved() {
    measureBlock(performanceWork { NativeSet<Int>(minimumCapacity: $0) })
  }

  func testPerformanceWithoutCapacityReserved() {
    measureBlock(performanceWork { _ in NativeSet<Int>() })
  }

}
