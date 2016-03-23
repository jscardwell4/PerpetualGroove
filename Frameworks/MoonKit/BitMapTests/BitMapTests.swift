//
//  BitMapTests.swift
//  BitMapTests
//
//  Created by Jason Cardwell on 3/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import Nimble
@testable import MoonKit

final class BitMapTests: XCTestCase {

  func setBitsInBitMap(bitMap: BitMap, count: Int) {
    assert(count > 0 && count < bitMap.count)
    var bits: Set<Int> = []
    while bits.count < count {
      bits.insert(Int(arc4random()) % bitMap.count)
    }
    for bit in bits { bitMap[bit] = true }
  }

  func bitMapWithCapacity(capacity: Int) -> BitMap {
    let storage = storageWithCapacity(capacity)
    let bitMap = BitMap(uninitializedStorage: storage, bitCount: capacity)
    return bitMap
  }

  func storageWithCapacity(capacity: Int) -> UnsafeMutablePointer<UInt> {
    let wordCount = BitMap.wordsFor(capacity)
    let storage = UnsafeMutablePointer<UInt>.alloc(wordCount)
    return storage
  }

  func testBitMapCreation() {
    let capacity = 256
    let storage = storageWithCapacity(capacity)
    let bitMap = BitMap(uninitializedStorage: storage, bitCount: capacity)
    expect(bitMap.count).to(be(capacity))
    expect(bitMap.buffer.baseAddress) == storage
  }

  func testSubscriptByOffset() {
    var bitMap = bitMapWithCapacity(256)
    bitMap[10] = true
    expect(bitMap[10]).to(beTrue())
    bitMap[20] = true
    expect(bitMap[20]).to(beTrue())
    bitMap[30] = true
    expect(bitMap[30]).to(beTrue())
    bitMap[30] = false
    expect(bitMap[30]).to(beFalse())
    bitMap[20] = false
    expect(bitMap[20]).to(beFalse())
    bitMap[10] = false
    expect(bitMap[10]).to(beFalse())
  }

  func testNonZeroBits() {
    let capacity = 256
    var bitMap = bitMapWithCapacity(capacity)
    let expectedNonZeroCount = 100
    setBitsInBitMap(bitMap, count: expectedNonZeroCount)
    var expectedNonZeroBits: [Int] = []
    for i in 0 ..< capacity where bitMap[i] { expectedNonZeroBits.append(i) }
    expect(expectedNonZeroBits).to(haveCount(expectedNonZeroCount))
    expect(bitMap.nonZeroCount).to(be(expectedNonZeroCount))
    let actualNonZeroCount = bitMap.nonZeroCount
    let actualNonZeroBits = bitMap.nonZeroBits
    expect(actualNonZeroBits).to(haveCount(expectedNonZeroCount))
    expect(actualNonZeroBits).to(equal(expectedNonZeroBits))
  }

}
