//
//  Size.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation

/// A type for representing a chunk's byte size.
public struct Size: Equatable {

  /// The size in bytes.
  public let value: Int

  /// Initializing with raw bytes.
  ///
  /// - Notice: The bytes are expected to be big endian as this is how they are
  ///           stored in sound font files.
  ///
  /// - Parameter bytes: The collection of bytes from which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `bigEndian` doesn't have enough bytes.
  public init<C>(bytes: C) throws where C:Collection, C.Element == UInt8 {
    guard bytes.count > 3 else { throw Error.StructurallyUnsound }
    let byte1 = UInt32(bytes[bytes.startIndex].byteSwapped)
    let byte2 = UInt32(bytes[bytes.index(bytes.startIndex, offsetBy: 1)].byteSwapped)
    let byte3 = UInt32(bytes[bytes.index(bytes.startIndex, offsetBy: 2)].byteSwapped)
    let byte4 = UInt32(bytes[bytes.index(bytes.startIndex, offsetBy: 3)].byteSwapped)

    value = Int(byte4 << 24 | byte3 << 16 | byte2 << 8 | byte1)
  }

}
