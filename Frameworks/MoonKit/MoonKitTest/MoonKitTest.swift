//
//  MoonKitTest.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/15/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
@_exported import Nimble
import MoonKit

public final class MoonKitTest {

  public static let integersXXSmall0 = srandomIntegers(seed: 0, count: 100, range: 0 ..< 50)
  public static let integersXXSmall1 = srandomIntegers(seed: 1, count: 100, range: 0 ..< 50)
  public static let integersXXSmall2 = srandomIntegers(seed: 2, count: 100, range: 0 ..< 50)
  public static let integersXXSmall3 = srandomIntegers(seed: 3, count: 100, range: 0 ..< 50)
  public static let integersXXSmall4 = srandomIntegers(seed: 4, count: 100, range: 0 ..< 50)
  public static let integersXXSmall5 = srandomIntegers(seed: 5, count: 100, range: 0 ..< 50)
  public static let integersXXSmall6 = srandomIntegers(seed: 6, count: 100, range: 0 ..< 50)
  public static let integersXXSmall7 = srandomIntegers(seed: 7, count: 100, range: 0 ..< 50)
  public static let integersXXSmall8 = srandomIntegers(seed: 8, count: 100, range: 0 ..< 50)
  public static let integersXXSmall9 = srandomIntegers(seed: 9, count: 100, range: 0 ..< 50)

  public static let integersXSmall0  = srandomIntegers(seed: 0, count: 250, range: 0 ..< 125)
  public static let integersXSmall1  = srandomIntegers(seed: 1, count: 250, range: 0 ..< 125)
  public static let integersXSmall2  = srandomIntegers(seed: 2, count: 250, range: 0 ..< 125)
  public static let integersXSmall3  = srandomIntegers(seed: 3, count: 250, range: 0 ..< 125)
  public static let integersXSmall4  = srandomIntegers(seed: 4, count: 250, range: 0 ..< 125)
  public static let integersXSmall5  = srandomIntegers(seed: 5, count: 250, range: 0 ..< 125)
  public static let integersXSmall6  = srandomIntegers(seed: 6, count: 250, range: 0 ..< 125)
  public static let integersXSmall7  = srandomIntegers(seed: 7, count: 250, range: 0 ..< 125)
  public static let integersXSmall8  = srandomIntegers(seed: 8, count: 250, range: 0 ..< 125)
  public static let integersXSmall9  = srandomIntegers(seed: 9, count: 250, range: 0 ..< 125)

  public static let integersSmall0   = srandomIntegers(seed: 0, count: 500, range: 0 ..< 250)
  public static let integersSmall1   = srandomIntegers(seed: 1, count: 500, range: 0 ..< 250)
  public static let integersSmall2   = srandomIntegers(seed: 2, count: 500, range: 0 ..< 250)
  public static let integersSmall3   = srandomIntegers(seed: 3, count: 500, range: 0 ..< 250)
  public static let integersSmall4   = srandomIntegers(seed: 4, count: 500, range: 0 ..< 250)
  public static let integersSmall5   = srandomIntegers(seed: 5, count: 500, range: 0 ..< 250)
  public static let integersSmall6   = srandomIntegers(seed: 6, count: 500, range: 0 ..< 250)
  public static let integersSmall7   = srandomIntegers(seed: 7, count: 500, range: 0 ..< 250)
  public static let integersSmall8   = srandomIntegers(seed: 8, count: 500, range: 0 ..< 250)
  public static let integersSmall9   = srandomIntegers(seed: 9, count: 500, range: 0 ..< 250)

  public static let integersMedium0  = srandomIntegers(seed: 0, count: 10000, range: 0 ..< 2000)
  public static let integersMedium1  = srandomIntegers(seed: 1, count: 10000, range: 0 ..< 2000)
  public static let integersMedium2  = srandomIntegers(seed: 2, count: 10000, range: 0 ..< 2000)
  public static let integersMedium3  = srandomIntegers(seed: 3, count: 10000, range: 0 ..< 2000)
  public static let integersMedium4  = srandomIntegers(seed: 4, count: 10000, range: 0 ..< 2000)
  public static let integersMedium5  = srandomIntegers(seed: 5, count: 10000, range: 0 ..< 2000)
  public static let integersMedium6  = srandomIntegers(seed: 6, count: 10000, range: 0 ..< 2000)
  public static let integersMedium7  = srandomIntegers(seed: 7, count: 10000, range: 0 ..< 2000)
  public static let integersMedium8  = srandomIntegers(seed: 8, count: 10000, range: 0 ..< 2000)
  public static let integersMedium9  = srandomIntegers(seed: 9, count: 10000, range: 0 ..< 2000)

  public static let integersLarge0   = srandomIntegers(seed: 0, count: 50000, range: 0 ..< 10000)
  public static let integersLarge1   = srandomIntegers(seed: 1, count: 50000, range: 0 ..< 10000)
  public static let integersLarge2   = srandomIntegers(seed: 2, count: 50000, range: 0 ..< 10000)
  public static let integersLarge3   = srandomIntegers(seed: 3, count: 50000, range: 0 ..< 10000)
  public static let integersLarge4   = srandomIntegers(seed: 4, count: 50000, range: 0 ..< 10000)
  public static let integersLarge5   = srandomIntegers(seed: 5, count: 50000, range: 0 ..< 10000)
  public static let integersLarge6   = srandomIntegers(seed: 6, count: 50000, range: 0 ..< 10000)
  public static let integersLarge7   = srandomIntegers(seed: 7, count: 50000, range: 0 ..< 10000)
  public static let integersLarge8   = srandomIntegers(seed: 8, count: 50000, range: 0 ..< 10000)
  public static let integersLarge9   = srandomIntegers(seed: 9, count: 50000, range: 0 ..< 10000)

  public static let integersXLarge0  = srandomIntegers(seed: 0, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge1  = srandomIntegers(seed: 1, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge2  = srandomIntegers(seed: 2, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge3  = srandomIntegers(seed: 3, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge4  = srandomIntegers(seed: 4, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge5  = srandomIntegers(seed: 5, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge6  = srandomIntegers(seed: 6, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge7  = srandomIntegers(seed: 7, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge8  = srandomIntegers(seed: 8, count: 100000, range: 0 ..< 20000)
  public static let integersXLarge9  = srandomIntegers(seed: 9, count: 100000, range: 0 ..< 20000)

  public static let integersXXLarge0 = srandomIntegers(seed: 0, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge1 = srandomIntegers(seed: 1, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge2 = srandomIntegers(seed: 2, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge3 = srandomIntegers(seed: 3, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge4 = srandomIntegers(seed: 4, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge5 = srandomIntegers(seed: 5, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge6 = srandomIntegers(seed: 6, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge7 = srandomIntegers(seed: 7, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge8 = srandomIntegers(seed: 8, count: 200000, range: 0 ..< 40000)
  public static let integersXXLarge9 = srandomIntegers(seed: 9, count: 200000, range: 0 ..< 40000)

  public static let stringsXXSmall0  = integersXXSmall0.map {String($0)}
  public static let stringsXXSmall1  = integersXXSmall1.map {String($0)}
  public static let stringsXXSmall2  = integersXXSmall2.map {String($0)}
  public static let stringsXXSmall3  = integersXXSmall3.map {String($0)}
  public static let stringsXXSmall4  = integersXXSmall4.map {String($0)}
  public static let stringsXXSmall5  = integersXXSmall5.map {String($0)}
  public static let stringsXXSmall6  = integersXXSmall6.map {String($0)}
  public static let stringsXXSmall7  = integersXXSmall7.map {String($0)}
  public static let stringsXXSmall8  = integersXXSmall8.map {String($0)}
  public static let stringsXXSmall9  = integersXXSmall9.map {String($0)}

  public static let stringsXSmall0   = integersXSmall0.map {String($0)}
  public static let stringsXSmall1   = integersXSmall1.map {String($0)}
  public static let stringsXSmall2   = integersXSmall2.map {String($0)}
  public static let stringsXSmall3   = integersXSmall3.map {String($0)}
  public static let stringsXSmall4   = integersXSmall4.map {String($0)}
  public static let stringsXSmall5   = integersXSmall5.map {String($0)}
  public static let stringsXSmall6   = integersXSmall6.map {String($0)}
  public static let stringsXSmall7   = integersXSmall7.map {String($0)}
  public static let stringsXSmall8   = integersXSmall8.map {String($0)}
  public static let stringsXSmall9   = integersXSmall9.map {String($0)}

  public static let stringsSmall0    = integersSmall0.map {String($0)}
  public static let stringsSmall1    = integersSmall1.map {String($0)}
  public static let stringsSmall2    = integersSmall2.map {String($0)}
  public static let stringsSmall3    = integersSmall3.map {String($0)}
  public static let stringsSmall4    = integersSmall4.map {String($0)}
  public static let stringsSmall5    = integersSmall5.map {String($0)}
  public static let stringsSmall6    = integersSmall6.map {String($0)}
  public static let stringsSmall7    = integersSmall7.map {String($0)}
  public static let stringsSmall8    = integersSmall8.map {String($0)}
  public static let stringsSmall9    = integersSmall9.map {String($0)}

  public static let stringsMedium0   = integersMedium0.map {String($0)}
  public static let stringsMedium1   = integersMedium1.map {String($0)}
  public static let stringsMedium2   = integersMedium2.map {String($0)}
  public static let stringsMedium3   = integersMedium3.map {String($0)}
  public static let stringsMedium4   = integersMedium4.map {String($0)}
  public static let stringsMedium5   = integersMedium5.map {String($0)}
  public static let stringsMedium6   = integersMedium6.map {String($0)}
  public static let stringsMedium7   = integersMedium7.map {String($0)}
  public static let stringsMedium8   = integersMedium8.map {String($0)}
  public static let stringsMedium9   = integersMedium9.map {String($0)}

  public static let stringsLarge0    = integersLarge0.map {String($0)}
  public static let stringsLarge1    = integersLarge1.map {String($0)}
  public static let stringsLarge2    = integersLarge2.map {String($0)}
  public static let stringsLarge3    = integersLarge3.map {String($0)}
  public static let stringsLarge4    = integersLarge4.map {String($0)}
  public static let stringsLarge5    = integersLarge5.map {String($0)}
  public static let stringsLarge6    = integersLarge6.map {String($0)}
  public static let stringsLarge7    = integersLarge7.map {String($0)}
  public static let stringsLarge8    = integersLarge8.map {String($0)}
  public static let stringsLarge9    = integersLarge9.map {String($0)}

  public static let stringsXLarge0   = integersXLarge0.map {String($0)}
  public static let stringsXLarge1   = integersXLarge1.map {String($0)}
  public static let stringsXLarge2   = integersXLarge2.map {String($0)}
  public static let stringsXLarge3   = integersXLarge3.map {String($0)}
  public static let stringsXLarge4   = integersXLarge4.map {String($0)}
  public static let stringsXLarge5   = integersXLarge5.map {String($0)}
  public static let stringsXLarge6   = integersXLarge6.map {String($0)}
  public static let stringsXLarge7   = integersXLarge7.map {String($0)}
  public static let stringsXLarge8   = integersXLarge8.map {String($0)}
  public static let stringsXLarge9   = integersXLarge9.map {String($0)}

  public static let stringsXXLarge0  = integersXXLarge0.map {String($0)}
  public static let stringsXXLarge1  = integersXXLarge1.map {String($0)}
  public static let stringsXXLarge2  = integersXXLarge2.map {String($0)}
  public static let stringsXXLarge3  = integersXXLarge3.map {String($0)}
  public static let stringsXXLarge4  = integersXXLarge4.map {String($0)}
  public static let stringsXXLarge5  = integersXXLarge5.map {String($0)}
  public static let stringsXXLarge6  = integersXXLarge6.map {String($0)}
  public static let stringsXXLarge7  = integersXXLarge7.map {String($0)}
  public static let stringsXXLarge8  = integersXXLarge8.map {String($0)}
  public static let stringsXXLarge9  = integersXXLarge9.map {String($0)}

  public static let randomIntegersXXSmall1 = randomIntegers(count: 100, range: 0 ..< 50)
  public static let randomIntegersXXSmall2 = randomIntegers(count: 100, range: 0 ..< 50)

  public static let randomIntegersXSmall1  = randomIntegers(count: 250, range: 0 ..< 125)
  public static let randomIntegersXSmall2  = randomIntegers(count: 250, range: 0 ..< 125)

  public static let randomIntegersSmall1   = randomIntegers(count: 500, range: 0 ..< 250)
  public static let randomIntegersSmall2   = randomIntegers(count: 500, range: 0 ..< 250)

  public static let randomIntegersMedium1  = randomIntegers(count: 10000, range: 0 ..< 2000)
  public static let randomIntegersMedium2  = randomIntegers(count: 10000, range: 0 ..< 2000)

  public static let randomIntegersLarge1   = randomIntegers(count: 50000, range: 0 ..< 10000)
  public static let randomIntegersLarge2   = randomIntegers(count: 50000, range: 0 ..< 10000)

  public static let randomIntegersXLarge1  = randomIntegers(count: 100000, range: 0 ..< 20000)
  public static let randomIntegersXLarge2  = randomIntegers(count: 100000, range: 0 ..< 20000)

  public static let randomIntegersXXLarge1 = randomIntegers(count: 200000, range: 0 ..< 40000)
  public static let randomIntegersXXLarge2 = randomIntegers(count: 200000, range: 0 ..< 40000)

  public static let randomStringsXXSmall1  = randomIntegersXXSmall1.map {String($0)}
  public static let randomStringsXXSmall2  = randomIntegersXXSmall2.map {String($0)}

  public static let randomStringsXSmall1   = randomIntegersXSmall1.map {String($0)}
  public static let randomStringsXSmall2   = randomIntegersXSmall2.map {String($0)}

  public static let randomStringsSmall1    = randomIntegersSmall1.map {String($0)}
  public static let randomStringsSmall2    = randomIntegersSmall2.map {String($0)}

  public static let randomStringsMedium1   = randomIntegersMedium1.map {String($0)}
  public static let randomStringsMedium2   = randomIntegersMedium2.map {String($0)}

  public static let randomStringsLarge1    = randomIntegersLarge1.map {String($0)}
  public static let randomStringsLarge2    = randomIntegersLarge2.map {String($0)}

  public static let randomStringsXLarge1   = randomIntegersXLarge1.map {String($0)}
  public static let randomStringsXLarge2   = randomIntegersXLarge2.map {String($0)}

  public static let randomStringsXXLarge1  = randomIntegersXXLarge1.map {String($0)}
  public static let randomStringsXXLarge2  = randomIntegersXXLarge2.map {String($0)}

}

public func evenNumbers(range range: Range<Int>) -> [Int] {
  return range.startIndex % 2 == 0
    ? Array(range.startIndex.stride(to: range.endIndex, by: 2))
    : Array(range.startIndex.successor().stride(to: range.endIndex, by: 2))
}

public func oddNumbers(range range: Range<Int>) -> [Int] {
  return range.startIndex % 2 == 1
    ? Array(range.startIndex.stride(to: range.endIndex, by: 2))
    : Array(range.startIndex.successor().stride(to: range.endIndex, by: 2))
}

private func _randomIntegers(count count: Int, range: Range<Int>) -> [Int] {
  func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
  var result = Array<Int>(minimumCapacity: count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

/// Returns an array of `count` randomly generated integers within `range`. Integers generated with `arc4random`.
public func randomIntegers(count count: Int, range: Range<Int>) -> [Int] {
  return _randomIntegers(count: count, range: range)
}

/// Returns an array of `count` randomly generated integers within `range`. Integers generated with `random` after seeding with `seed`.
public func srandomIntegers(seed seed: UInt32, count: Int, range: Range<Int>) -> [Int] {
  srandom(seed)
  func randomInt() -> Int { return random() % range.count + range.startIndex }
  var result = Array<Int>(minimumCapacity: count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

private func _randomRange(indices indices: Range<Int>,
                                  limit: Int,
                                  coverage: Double,
                                  @noescape random: () -> Int) -> Range<Int>
{
  let count = indices.count
  guard count > 0 else { return indices }

  var resultCount = Int(Double(count) * coverage)
  if limit > 0 { resultCount = max(limit, resultCount) }
  let offset = indices.startIndex

  let end = random() % count + offset
  let start = max(offset, end - resultCount)

  return start ..< end
}

public func randomRange(indices indices: Range<Int>, coverage: Double, limit: Int = 0) -> Range<Int> {
  return _randomRange(indices: indices, limit: limit, coverage: coverage) { Int(arc4random()) }
}

public func srandomRange(seed seed: UInt32? = nil,
                              indices: Range<Int>,
                              coverage: Double,
                              limit: Int = 0) -> Range<Int>
{
  if let seed = seed { srandom(seed) }
  return _randomRange(indices: indices, limit: limit, coverage: coverage) { random() }
}

public func randomRanges(count count: Int,
                               indices: Range<Int>,
                               coverage: Double,
                               limit: Int = 0) -> [Range<Int>]
{
  var result: [Range<Int>] = []
  for _ in 0 ..< count { 
    result.append(randomRange(indices: indices, coverage: coverage, limit: limit))
  }
  return result
}

public func srandomRanges(seed seed: UInt32?,
                               count: Int,
                               indices: Range<Int>,
                               coverage: Double, limit: Int = 0) -> [Range<Int>]
{
  var result: [Range<Int>] = []
  if let seed = seed { srandom(seed) }
  for _ in 0 ..< count { 
    result.append(srandomRange(indices: indices, coverage: coverage, limit: limit))
  }
  return result
}

// MARK: - Extending Nimble
// MARK: -

// MARK: Tuple equality

public func equal<
  A:Equatable, B:Equatable
  >(expectedValue: (A, B)?) -> NonNilMatcherFunc<(A, B)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable
  >(expectedValue: (A, B, C)?) -> NonNilMatcherFunc<(A, B, C)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable
  >(expectedValue: (A, B, C, D)?) -> NonNilMatcherFunc<(A, B, C, D)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable
  >(expectedValue: (A, B, C, D, E)?) -> NonNilMatcherFunc<(A, B, C, D, E)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable, F:Equatable
  >(expectedValue: (A, B, C, D, E, F)?) -> NonNilMatcherFunc<(A, B, C, D, E, F)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func ==<
  A:Equatable, B:Equatable
  >(lhs: Expectation<(A, B)>, rhs: (A, B)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable
  >(lhs: Expectation<(A, B, C)>, rhs: (A, B, C)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable
  >(lhs: Expectation<(A, B, C, D)>, rhs: (A, B, C, D)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable
  >(lhs: Expectation<(A, B, C, D, E)>, rhs: (A, B, C, D, E)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable, F:Equatable
  >(lhs: Expectation<(A, B, C, D, E, F)>, rhs: (A, B, C, D, E, F)?)
{
  lhs.to(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable
  >(lhs: Expectation<(A, B)>, rhs: (A, B)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable
  >(lhs: Expectation<(A, B, C)>, rhs: (A, B, C)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable
  >(lhs: Expectation<(A, B, C, D)>, rhs: (A, B, C, D)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable
  >(lhs: Expectation<(A, B, C, D, E)>, rhs: (A, B, C, D, E)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable, F:Equatable
  >(lhs: Expectation<(A, B, C, D, E, F)>, rhs: (A, B, C, D, E, F)?)
{
  lhs.toNot(equal(rhs))
}

// MARK: SetType matchers

public func equal<
  S1: SequenceType,
  S2: SequenceType
  where S1.Generator.Element == S2.Generator.Element, S1.Generator.Element:Equatable
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    failureMessage.postfixMessage = "equal \(sequence)"
    guard let actual = try expression.evaluate() else { return false }
    return actual.elementsEqual(sequence)
  }
}

public func ==<
  S1: SequenceType,
  S2: SequenceType
  where S1.Generator.Element == S2.Generator.Element, S1.Generator.Element:Equatable
  >(lhs: Expectation<S1>, rhs: S2)
{
  lhs.to(equal(rhs))
}

public func !=<
  S1: SequenceType,
  S2: SequenceType
  where S1.Generator.Element == S2.Generator.Element, S1.Generator.Element:Equatable
  >(lhs: Expectation<S1>, rhs: S2)
{
  lhs.toNot(equal(rhs))
}

public func equal<
  S1: SequenceType,
  S2: SequenceType
where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2, isEquivalent: (S1.Generator.Element, S2.Generator.Element) -> Bool) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    failureMessage.postfixMessage = "equal"
    guard let actual = try expression.evaluate() else { return false }
    return actual.elementsEqual(sequence, isEquivalent: isEquivalent)
  }
}

public func beSubsetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a subset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isSubsetOf(sequence)
  }
}

public func beStrictSubsetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a strict subset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isStrictSubsetOf(sequence)
  }
}

public func beSupersetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a superset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isSupersetOf(sequence)
  }
}

public func beStrictSupersetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a strict superset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isStrictSupersetOf(sequence)
  }
}

public func beDisjointWith<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element, S1.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be disjoint with \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isDisjointWith(sequence)
  }
}
