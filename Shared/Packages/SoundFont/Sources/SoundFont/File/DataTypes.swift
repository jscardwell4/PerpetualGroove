//
//  DataTypes.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

// MARK: - ChunkData

public protocol ChunkData
{
  init(bytes: Data) throws
}

// MARK: - CharacterCode

/// A type for representing a chunk's four character identifier. The codes are
/// normalized to use lower case letters.
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct CharacterCode: Hashable, Equatable
{
  /// The four character code.
  public let value: String
  
  /// Initializing with raw bytes.
  ///
  /// - Parameter bytes: The collection of bytes from which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `bigEndian` doesn't have enough bytes.
  public init(bytes: Data) throws
  {
    try _require(bytes.count >= 4)
    value = String(unsafeUninitializedCapacity: 4)
    {
      _ = $0.initialize(from: bytes.prefix(4))
      return 4
    }.lowercased()
  }
}

// MARK: CustomStringConvertible

@available(iOS 14.0, *)
@available(OSX 11.0, *)
extension CharacterCode: CustomStringConvertible
{
  public var description: String { value }
}

// MARK: ExpressibleByStringLiteral

@available(iOS 14.0, *)
@available(OSX 11.0, *)
extension CharacterCode: ExpressibleByStringLiteral
{
  public init(stringLiteral value: String) { self.value = value }
}

// MARK: - Size

/// A type for representing a chunk's byte size.
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct Size: ChunkData, Equatable
{
  /// The size in bytes.
  public let value: Int
  
  /// Initializing with raw bytes.
  ///
  /// - Notice: The bytes are expected to be big endian as this is how they are
  ///           stored in sound font files.
  ///
  /// - Parameter bytes: The collection of bytes from which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `bytes` doesn't have enough bytes.
  public init(bytes: Data) throws
  {
    guard bytes.count > 3 else { throw File.Error.StructurallyUnsound }
    let byte1 = UInt32(bytes[bytes.startIndex].byteSwapped)
    let byte2 = UInt32(bytes[bytes.index(bytes.startIndex, offsetBy: 1)].byteSwapped)
    let byte3 = UInt32(bytes[bytes.index(bytes.startIndex, offsetBy: 2)].byteSwapped)
    let byte4 = UInt32(bytes[bytes.index(bytes.startIndex, offsetBy: 3)].byteSwapped)
    let value = byte4 << 24 | byte3 << 16 | byte2 << 8 | byte1
    self.value = Int(value)
  }
  
  /// Initializing with a known size.
  ///
  /// - Parameter value: The size being represented.
  public init(_ value: Int) { self.value = value }
}

// MARK: - Version

/// A type for representing file version information.
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct Version: ChunkData, Equatable
{
  /// The part of the version to the left of the decimal place.
  public let major: UInt16
  
  /// The part of the version to the right of the decimal place.
  public let minor: UInt16
  
  /// Initializing with raw bytes.
  ///
  /// - Notice: The bytes are expected to be big endian as this is how they are
  ///           stored in sound font files.
  ///
  /// - Parameter bytes: The collection of bytes from which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `bigEndian` doesn't have enough bytes.
  public init(bytes: Data) throws
  {
    guard bytes.count > 3 else { throw File.Error.StructurallyUnsound }
    
    let byte1 = UInt16(bytes[bytes.startIndex].byteSwapped)
    let byte2 = UInt16(bytes[bytes.index(bytes.startIndex, offsetBy: 1)].byteSwapped)
    major = byte2 << 8 | byte1
    
    let byte3 = UInt16(bytes[bytes.index(bytes.startIndex, offsetBy: 2)].byteSwapped)
    let byte4 = UInt16(bytes[bytes.index(bytes.startIndex, offsetBy: 3)].byteSwapped)
    minor = byte4 << 8 | byte3
  }
}

// MARK: - ASCIIString

/// A type for text data within a file. The data is always 256 ASCII characters or fewer
/// with one or two `0` values to null terminate the string.
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct ASCIIString: ChunkData, Equatable
{
  /// The ASCII string.
  public let value: String
  
  /// Initializing with raw bytes.
  ///
  /// - Parameters:
  ///   - bytes: The collection of bytes from which to initialize.
  ///   - maxLength: The maximum number of characters to accept. Default is `256`.
  /// - Throws: `Error.StructurallyUnsound` if `bigEndian` doesn't have enough bytes.
  public init(bytes: Data, maxLength: Int = 256) throws
  {
    // Determine the actual length.
    let length: Int
    
    // Look for the null terminator.
    if let index = bytes.firstIndex(of: 0)
    {
      length = bytes.distance(from: bytes.startIndex, to: index)
    }
    else
    {
      // Otherwise assume the max length.
      length = min(bytes.count, maxLength)
    }
    
    value = String(unsafeUninitializedCapacity: length)
    {
      _ = $0.initialize(from: bytes)
      return length
    }
  }
  
  /// Initializing with raw bytes.
  ///
  /// - Parameter bytes: The collection of bytes from which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `bigEndian` doesn't have enough bytes.
  public init(bytes: Data) throws
  {
    try self.init(bytes: bytes, maxLength: 256)
  }
}

// MARK: - RawBytes

/// A type for chunks that store raw bytes.
public struct RawBytes: ChunkData
{
  /// The raw bytes.
  public let data: Data
  
  /// Initializing with raw bytes.
  ///
  /// - Parameter bytes: The bytes with which to initialize.
  /// - Throws: Never actually throws an error.
  public init(bytes: Data) throws { data = bytes }
}

// MARK: - PresetHeader

/// A structure for representing a preset header parsed while decoding a sound font file.
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct PresetHeader: Codable
{
  /// The name of the preset.
  public let name: String
  
  /// The program assigned to the preset.
  public let program: UInt8
  
  /// The bank assigned to the preset.
  public let bank: UInt8
  
  /// Initializing with known property values.
  public init(name: String, program: UInt8, bank: UInt8)
  {
    self.name = name
    self.program = program
    self.bank = bank
  }
  
  /// Initialize from the raw bytes of a sound font file.
  ///
  /// - Parameter data: The bytes with which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if `data` isn't a 38 byte preset header.
  public init?(data: Data.SubSequence) throws
  {
    // Check the size of the data.
    try _require(data.count == 38)
    
    // Decode the preset's name.
    name = String(bytes: data[..<(data.firstIndex(of: UInt8(0)) ?? data.startIndex + 20)])
    
    // Decode the program
    program = UInt8(UInt16(bytes: data[data.startIndex + 20 ... data.startIndex + 21])
                      .bigEndian)
    
    // Decode the bank.
    bank = UInt8(UInt16(bytes: data[data.startIndex + 22 ... data.startIndex + 23])
                  .bigEndian)
    
    // Check that the name is valid and that it is not the end marker for a list of
    // presets.
    guard name != "EOP", !name.isEmpty else { return nil }
  }
}

// MARK: Comparable

@available(iOS 14.0, *)
@available(OSX 11.0, *)
extension PresetHeader: Comparable
{
  /// Returns `true` iff the two preset headers have equal bank and program values.
  public static func == (lhs: PresetHeader, rhs: PresetHeader) -> Bool
  {
    lhs.bank == rhs.bank && lhs.program == rhs.program
  }
  
  /// Returns `true` iff the bank value of `lhs` is less than that of `rhs`
  /// or the bank values are equal and the program value of `lhs` is less than
  /// that of `rhs`.
  public static func < (lhs: PresetHeader, rhs: PresetHeader) -> Bool
  {
    lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program)
  }
}

// MARK: CustomStringConvertible

@available(iOS 14.0, *)
@available(OSX 11.0, *)
extension PresetHeader: CustomStringConvertible
{
  public var description: String
  {
    "PresetHeader {name: \(name); program: \(program); bank: \(bank)}"
  }
}

//#if os(iOS)
//// MARK: JSONValueConvertible
//
//@available(iOS 14.0, *)
//extension PresetHeader: JSONValueConvertible
//{
//  /// The preset header converted to a JSON object.
//  public var jsonValue: JSONValue { ["name": name, "program": program, "bank": bank] }
//}
//
//// MARK: JSONValueInitializable
//
//@available(iOS 14.0, *)
//extension PresetHeader: JSONValueInitializable
//{
//  /// Initializing from a JSON value. To be successful, `jsonValue` needs to be
//  /// a JSON object with keys 'name', 'program', and 'bank' with values convertible
//  /// to `String`, `UInt8`, and `UInt8`.
//  public init?(_ jsonValue: JSONValue?)
//  {
//    // Retrieve the property values.
//    guard let dict = ObjectJSONValue(jsonValue),
//          let name = String(dict["name"]),
//          let program = UInt8(dict["program"]),
//          let bank = UInt8(dict["bank"])
//    else
//    {
//      return nil
//    }
//    
//    // Initialize using the retrieved property values.
//    self = PresetHeader(name: name, program: program, bank: bank)
//  }
//}
//#endif
