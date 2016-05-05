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
  public let buffer: UnsafeMutableBufferPointer<UInt>

  public static func wordIndex(i: Int) -> Int { return i / Int(UInt._sizeInBits) }

  public static func bitIndex(i: Int) -> Int { return i % Int(UInt._sizeInBits) }

  public static func wordsFor(bitCount: Int) -> Int {
    let totalWords = (bitCount + Int._sizeInBits - 1) / Int._sizeInBits
    return totalWords
  }

  public let count: Int

  public var nonZeroCount: Int {
    var result = 0
    for word in buffer where word > 0 {
      for bit in 0 ..< UInt._sizeInBits where word & (1 << bit) != 0 {
        result += 1
      }
    }
    return result
  }

  public init(initializedStorage storage: UnsafeMutablePointer<UInt>, bitCount: Int) {
    count = bitCount
    buffer = UnsafeMutableBufferPointer(start: storage, count: BitMap.wordsFor(bitCount))
  }

  public init(uninitializedStorage storage: UnsafeMutablePointer<UInt>, bitCount: Int) {
    count = bitCount
    buffer = UnsafeMutableBufferPointer(start: storage, count: BitMap.wordsFor(bitCount))
    initializeToZero()
  }

  public var startIndex: Int { return 0 }
  public var endIndex: Int { return count }

  public var numberOfWords: Int { return buffer.count }

  public func initializeToZero() { for i in 0 ..< numberOfWords { buffer[i] = 0 } }
  public func initializeToOne() { for i in 0 ..< numberOfWords { buffer[i] = UInt.max } }

  public var firstSetBit: Int? { return nextSetBit(-1) }

  public func nextSetBit(start: Int) -> Int? {
    let numberOfWords = self.numberOfWords
    let bitsPerWord = Int(UInt._sizeInBits)
    var bitIndex: Int, wordIndex: Int

    switch start {
      case let s where s < 0: bitIndex = 0; wordIndex = 0
      case let s where s == bitsPerWord - 1: bitIndex = 0; wordIndex = BitMap.wordIndex(s) + 1
      default: bitIndex = BitMap.bitIndex(start + 1); wordIndex = BitMap.wordIndex(start + 1)
    }

    while wordIndex < numberOfWords {
      let word = buffer[wordIndex]
      guard word > 0 else {
        wordIndex += 1
        bitIndex = 0
        continue
      }
      let bitRange = bitIndex ..< (bitsPerWord - countLeadingZeros(word))
      for i in bitRange where word & (1 << UInt(i)) != 0 {
        return wordIndex * bitsPerWord + i
      }
      wordIndex += 1
      bitIndex = 0
    }

    return nil
  }

  public var lastSetBit: Int? { return previousSetBit(count) }

  public func previousSetBit(start: Int) -> Int? {
    let bitsPerWord = Int(UInt._sizeInBits)
    var bitIndex: Int, wordIndex: Int

    switch start {
      case count: bitIndex = bitsPerWord - 1; wordIndex = numberOfWords - 1
      case let s where BitMap.bitIndex(s) == 0: bitIndex = bitsPerWord - 1; wordIndex = BitMap.wordIndex(s) - 1
      default: bitIndex = BitMap.bitIndex(start - 1); wordIndex = BitMap.wordIndex(start - 1)
    }

    while wordIndex > -1 {
      let word = buffer[wordIndex]
      guard word > 0 else {
        wordIndex -= 1
        bitIndex = bitsPerWord - 1
        continue
      }
      
      for i in (0 ... bitIndex).reverse() where word & (1 << UInt(i)) != 0 {
        return wordIndex * bitsPerWord + i
      }
      wordIndex -= 1
      bitIndex = bitsPerWord - 1
    }

    return nil
  }

  public var nonZeroBits: [Int] {
    var result: [Int] = []
    let bitsPerWord = Int(UInt._sizeInBits)
    for (wordIndex, word) in buffer.enumerate() where word > 0 {
      let bitRange = 0 ..< (bitsPerWord - countLeadingZeros(word))
      for bitIndex in bitRange where self[wordIndex * bitsPerWord + bitIndex] {
        result.append(wordIndex * bitsPerWord + bitIndex)
      }
    }
    return result
  }

  public subscript(index: Int) -> Bool {
    @warn_unused_result
    get {
      precondition(index < count && index >= 0, "invalid offset: \(index)")
      return buffer[BitMap.wordIndex(index)] & (1 << UInt(BitMap.bitIndex(index))) != 0
    }
    nonmutating set {
      precondition(index < count && index >= 0, "invalid offset: \(index)")
      let wordIndex = BitMap.wordIndex(index)
      let bitIndex = UInt(BitMap.bitIndex(index))
      let word = buffer[wordIndex]
      buffer[wordIndex] = newValue ? word | (1 << bitIndex) : word & ~(1 << bitIndex)
    }
  }
}

extension BitMap: CustomStringConvertible {
  public var description: String {
    var result = "(total words: \(numberOfWords); total bits: \(count))\n"
    result += buffer.enumerate().map({
      "word \($0): \("0" * countLeadingZeros($1))\(String($1, radix: 2))"
    }).joinWithSeparator("\n")

    return result
  }
}
