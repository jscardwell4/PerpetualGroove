//
//  BitMap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

/// A wrapper around a bitmap storage with room for at least bitCount bits.
/// This is a modified version of the `_BitMap` struct found in the swift stdlib source code
public struct BitMap: CollectionType {
  public let storage: UnsafeMutablePointer<UInt>
  public let bitCount: Int

  public static func wordIndex(i: UInt) -> UInt { return i / UInt._sizeInBits }

  public static func bitIndex(i: UInt) -> UInt { return i % UInt._sizeInBits }

  public static func wordsFor(bitCount: Int) -> Int { return (bitCount + sizeof(UInt) - 1) / sizeof(UInt) }

  public var count: Int {
    var result = 0
    let words = UnsafeBufferPointer(start: storage, count: numberOfWords)
    for word in words where word > 0 {
      for bit in 0 ..< UInt._sizeInBits where word & (1 << bit) != 0 {
        result += 1
      }
    }
    return result
  }

  public init(storage: UnsafeMutablePointer<UInt>, bitCount: Int) {
    self.bitCount = bitCount
    self.storage = storage
  }

  public var startIndex: Index { return Index(bitMap: self, offset: -1).successor() }
  public var endIndex: Index { return Index(bitMap: self, offset: bitCount) }

  public func generate() -> Generator {
    return Generator(index: count > 0 ? startIndex : endIndex)
  }
  public var numberOfWords: Int { return BitMap.wordsFor(bitCount) }

  public func initializeToZero() { for i in 0 ..< numberOfWords { (storage + i).initialize(0) } }

  public subscript(index: Index) -> Bool {
    get { return self[index.offset] }
    set { self[index.offset] = newValue }
  }

  public var nonZeroBits: [Int] { return indices.map { $0.offset } }

  public subscript(offset: Int) -> Bool {
    @warn_unused_result
    get {
      precondition(offset < Int(bitCount) && offset >= 0, "invalid offset: \(offset)")
      let idx = UInt(offset)
      let word = storage[Int(BitMap.wordIndex(idx))]
      let bit = word & (1 << BitMap.bitIndex(idx))
      return bit != 0
    }
    nonmutating set {
      precondition(offset < Int(bitCount) && offset >= 0, "invalid offset: \(offset)")
      let idx = UInt(offset)
      let wordIdx = BitMap.wordIndex(idx)
      if newValue {
        storage[Int(wordIdx)] =
          storage[Int(wordIdx)] | (1 << BitMap.bitIndex(idx))
      } else {
        storage[Int(wordIdx)] =
          storage[Int(wordIdx)] & ~(1 << BitMap.bitIndex(idx))
      }
    }
  }
}

extension BitMap {
  public struct Generator: GeneratorType {
    internal var index: BitMap.Index
    public mutating func next() -> Bool? {
      guard index.bitMap.bitCount > index.offset else { return nil }
      let result = index.bitMap[index.offset]
      let nextIndex = index.successor()
      index = nextIndex > index ? nextIndex : Index(bitMap: index.bitMap, offset: index.bitMap.bitCount)
      return result
    }
  }
}

extension BitMap {
  public struct Index: BidirectionalIndexType, Comparable {
    internal let bitMap: BitMap
    internal let offset: Int

    public func predecessor() -> Index {
      var previousOffset = offset
      repeat { previousOffset -= 1 } while !bitMap[previousOffset] && previousOffset > 0
      return Index(bitMap: bitMap, offset: previousOffset)
    }
    public func successor() -> Index {
      var nextOffset = offset
      repeat { nextOffset +=  1 } while !bitMap[nextOffset] && nextOffset < bitMap.bitCount
      return Index(bitMap: bitMap, offset: nextOffset)
    }
  }
}

public func ==(lhs: BitMap.Index, rhs: BitMap.Index) -> Bool {
  return lhs.offset == rhs.offset
}

public func <(lhs: BitMap.Index, rhs: BitMap.Index) -> Bool {
  return lhs.offset < rhs.offset
}

extension BitMap: CustomStringConvertible {
  public var description: String {
    var result = "(total words: \(numberOfWords); total bits: \(bitCount)) "
    let buffer = UnsafeBufferPointer(start: storage, count: numberOfWords)

    result += buffer.enumerate().map({"word \($0): \(String(rawContentsOf: $1, radix: 2))"}).joinWithSeparator("\n")

    return result
  }
}

public struct BitMapIndexGenerator: GeneratorType {
  let bitMap: BitMap
  var index: Int
  public mutating func next() -> Int? {
    guard index < bitMap.bitCount else { return nil }
    defer { index += 1 }
    guard !bitMap[index] else { return index }
    repeat {
      index += 1
    } while index < bitMap.bitCount && !bitMap[index]
    return bitMap[index] ? index : nil
  }
}
