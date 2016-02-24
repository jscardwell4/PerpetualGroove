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
public struct BitMap {
  public let values: UnsafeMutablePointer<UInt>
  public let bitCount: Int

  public static func wordIndex(i: UInt) -> UInt {
    return i / UInt._sizeInBits
  }

  public static func bitIndex(i: UInt) -> UInt {
    return i % UInt._sizeInBits
  }

  public static func wordsFor(bitCount: Int) -> Int {
    return (bitCount + sizeof(UInt) - 1) / sizeof(UInt)
  }

  public init(storage: UnsafeMutablePointer<UInt>, bitCount: Int) {
    self.bitCount = bitCount
    self.values = storage
  }

  public var numberOfWords: Int { return BitMap.wordsFor(bitCount) }

  public func initializeToZero() { for i in 0 ..< numberOfWords { (values + i).initialize(0) } }

  public subscript(i: Int) -> Bool {
    @warn_unused_result
    get {
      precondition(i < Int(bitCount) && i >= 0, "index out of bounds")
      let idx = UInt(i)
      let word = values[Int(BitMap.wordIndex(idx))]
      let bit = word & (1 << BitMap.bitIndex(idx))
      return bit != 0
    }
    nonmutating set {
      precondition(i < Int(bitCount) && i >= 0, "index out of bounds")
      let idx = UInt(i)
      let wordIdx = BitMap.wordIndex(idx)
      if newValue {
        values[Int(wordIdx)] =
          values[Int(wordIdx)] | (1 << BitMap.bitIndex(idx))
      } else {
        values[Int(wordIdx)] =
          values[Int(wordIdx)] & ~(1 << BitMap.bitIndex(idx))
      }
    }
  }
}

extension BitMap: CustomStringConvertible {
  public var description: String {
    var result = "(total words: \(numberOfWords); total bits: \(bitCount)) "

    result += "".join((0 ..< bitCount).map({self[$0] ? "1" : "0"}))

    return result
  }
}
