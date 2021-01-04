//
//  Functions.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation

/// Evaluates a `Bool` producing closure and deliberately
/// throws an error when the closure returns `false`.
///
/// - Parameter condition: The closure to evaluate.
/// - Throws: `Error.StructurallyUnsound` when `condition` evaluates to `false`.
internal func _require(_ condition: @autoclosure () throws -> Bool) throws {
  guard try condition() else { throw Error.StructurallyUnsound }
}

/// Parses a character code from the specified data and throws an error if it
/// does not match the specified code.
///
/// - Parameters:
///   - code: The code that should be parsed from `data`.
///   - data: The raw bytes from which to parse `code`.
/// - Throws: `Error.StructurallyUnsound` if `code` is not parsed from `data`.
/// - Returns: The parsed code equivalent to `code`.
@discardableResult
internal func _require(code: CharacterCode, data: Data) throws -> CharacterCode {
  let parsedCode = try CharacterCode(bytes: data)
  guard parsedCode == code else { throw Error.StructurallyUnsound }
  return parsedCode
}

/// Advances by the specified number of bytes.
///
/// - Parameters:
///   - data: The data to advance.
///   - amount: The number of bytes to advance.
/// - Returns: `data` with the first `amount` bytes dropped.
internal func _advance(_ data: Data, by amount: Int) -> Data.SubSequence {
  data.dropFirst(amount)
}

/////// Returns a closure for calculating the distance from an integer index to the end of `data`.
//internal func _remainingCount(_ data: Data) -> (Data.Index) -> Int {
//  { data.distance(from: $0, to: data.endIndex) }
//}
