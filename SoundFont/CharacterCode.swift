//
//  CharacterCode.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation

/// A type for representing a chunk's four character identifier.
public struct CharacterCode: Equatable {

  /// The four character code.
  public let value: String

  /// Initializing with raw bytes.
  ///
  /// - Parameter bytes: The collection of bytes from which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `bigEndian` doesn't have enough bytes.
  public init<C>(bytes: C) throws where C:Collection, C.Element == UInt8 {
    guard bytes.count > 3 else {
      throw Error.StructurallyUnsound
    }
    value = String(unsafeUninitializedCapacity: 4) {
      _ = $0.initialize(from: bytes.prefix(4))
      return 4
    }
  }

}

extension CharacterCode: CustomStringConvertible {
  public var description: String { value }
}

extension CharacterCode: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) { self.value = value }
}
