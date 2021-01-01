//
//  Functions.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation

/// Returns `data` decoded into an integer.
internal func _chunkSize(_ data: Data.SubSequence) -> Int {
  let byte1 = UInt32(data[data.startIndex].byteSwapped)
  let byte2 = UInt32(data[data.startIndex + 1].byteSwapped)
  let byte3 = UInt32(data[data.startIndex + 2].byteSwapped)
  let byte4 = UInt32(data[data.startIndex + 3].byteSwapped)

  let size = byte4 << 24 | byte3 << 16 | byte2 << 8 | byte1
  return Int(size)
}

/// Evaluates a `Bool` producing closure and deliberately
/// throws an error when the closure returns `false`.
///
/// - Parameter condition: The closure to evaluate.
/// - Throws: `Error.StructurallyUnsound` when `condition` evaluates to `false`.
internal func _require(_ condition: @autoclosure () throws  -> Bool) throws {
  guard try condition() else { throw Error.StructurallyUnsound }
}

///// Returns a closure for calculating the distance from an integer index to the end of `data`.
//internal func _remainingCount(_ data: Data.SubSequence) -> (Int) -> Int {
//  return {
//    data.distance(from: $0, to: data.endIndex)
//  }
//}
