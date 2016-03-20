//
//  BitMapTests.swift
//  BitMapTests
//
//  Created by Jason Cardwell on 3/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
@testable import MoonKit

final class BitMapTests: XCTestCase {

  func bitMapWithCapacity(capacity: Int) -> BitMap {
    let storage = storageWithCapacity(capacity)
    let bitMap = BitMap(storage: storage, bitCount: capacity)
    return bitMap
  }

  func storageWithCapacity(capacity: Int) -> UnsafeMutablePointer<UInt> {
    let wordCount = BitMap.wordsFor(capacity)
    let storage = UnsafeMutablePointer<UInt>.alloc(wordCount)
    storage.initializeFrom(Repeat(count: wordCount, repeatedValue: UInt(0)))
    return storage
  }

  func testBitMapCreation() {
    let capacity = 256
    let storage = storageWithCapacity(capacity)
    let bitMap = BitMap(storage: storage, bitCount: capacity)
    XCTAssertEqual(bitMap.bitCount, capacity)
    XCTAssertEqual(bitMap.storage, storage)
  }

  func testSubscriptByOffset() {
    var bitMap = bitMapWithCapacity(256)
    bitMap[10] = true
    XCTAssertTrue(bitMap[10])
    bitMap[20] = true
    XCTAssertTrue(bitMap[20])
    bitMap[30] = true
    XCTAssertTrue(bitMap[30])
    bitMap[30] = false
    XCTAssertFalse(bitMap[30])
    bitMap[20] = false
    XCTAssertFalse(bitMap[20])
    bitMap[10] = false
    XCTAssertFalse(bitMap[10])
  }

  func testCount() {
    var bitMap = bitMapWithCapacity(256)
    XCTAssertEqual(bitMap.count, 0)
    bitMap[10] = true
    XCTAssertEqual(bitMap.count, 1)
    bitMap[20] = true
    XCTAssertEqual(bitMap.count, 2)
    bitMap[30] = true
    XCTAssertEqual(bitMap.count, 3)
    bitMap[30] = false
    XCTAssertEqual(bitMap.count, 2)
    bitMap[20] = false
    XCTAssertEqual(bitMap.count, 1)
    bitMap[10] = false
    XCTAssertEqual(bitMap.count, 0)
  }

}
