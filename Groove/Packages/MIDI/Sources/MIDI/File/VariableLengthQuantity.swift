//
//  VariableLengthQuantity.swift
//  MIDI
//
//  Created by Jason Cardwell on 01/02/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

// MARK: - VariableLengthQuantity

/// Struct for converting values to MIDI variable length quanity representation
///
/// These numbers are represented 7 bits per byte, most significant bits first.
/// All bytes except the last have bit 7 set, and the last byte has bit 7 clear.
/// If the number is between 0 and 127, it is thus represented exactly as one byte.
public struct VariableLengthQuantity
{
  /// The variable length quantity as a stream of raw bytes.
  public let bytes: [UInt8]
  
  /// The variable length quantity equal to `0`.
  public static let zero = VariableLengthQuantity(0)
  
  /// The variable length quantity's represented value as a stream of raw bytes.
  public var representedValue: [UInt8]
  {
    // Split the variable length quantity's bytes into groups of 8.
    let groups = bytes.segment(8)
    
    // Create an array for accumulating the resolved 8-byte groups as a `UInt64`.
    var resolvedGroups: [UInt64] = []
    
    // Iterate the 8-byte groups.
    for group in groups
    {
      // Check that the group is not empty.
      guard !group.isEmpty else { continue }
      
      // Convert the group of 8 bytes into an unsigned 64 bit integer.
      var groupValue = UInt64(group[0])
      
      // Check that the value needs to be decoded.
      guard groupValue & 0x80 != 0
      else
      {
        resolvedGroups.append(groupValue)
        continue
      }
      
      // Filter the value to include only the bits contributing to the represented number.
      groupValue &= UInt64(0x7F)
      
      // Create a variable for tracking the index.
      var i = 1
      
      // Create a variable for holding the byte to test for the flag bit.
      var next = UInt8(0)
      
      // Repeat until the tested byte does not have the flag bit set.
      repeat
      {
        // Check that there is something left.
        guard i < group.count else { break }
        
        // Get the next byte to test.
        next = group[i]
        
        // Increment the index.
        i = i &+ 1
        
        // Update the group's value.
        groupValue = (groupValue << UInt64(7)) + UInt64(next & 0x7F)
      }
      while next & 0x80 != 0
      
      // Appended the decoded value for the group.
      resolvedGroups.append(groupValue)
    }
    
    // Create a flattened array of the bytes of the group values.
    var resolvedBytes = resolvedGroups.flatMap { $0.bytes }
    
    // Removing leading zeroes.
    while resolvedBytes.count > 1,
          resolvedBytes.first == 0 { resolvedBytes.remove(at: 0) }
    
    return resolvedBytes
  }
  
  /// Intializing with a stream of raw bytes.
  public init<S: Swift.Sequence>(bytes b: S)
  where S.Iterator.Element == UInt8 { bytes = Array(b) }
  
  /// Initialize from any `ByteArrayConvertible` type holding the represented value
  public init<B: ByteArrayConvertible>(_ value: B)
  {
    // Get the value's bytes as an unsigned 64-bit integer.
    var value = UInt64(bytes: value.bytes)
    
    // Initialize a buffer with the first 7 bits contributing to the represented value.
    var buffer = value & 0x7F
    
    while value >> 7 > 0
    {
      value = value >> 7
      buffer <<= 8
      buffer |= 0x80
      buffer += value & 0x7F
    }
    
    // Create an array for accumulating the variable length quantity's bytes.
    var result: [UInt8] = []
    
    repeat
    {
      result.append(UInt8(buffer & 0xFF))
      
      guard buffer & 0x80 != 0 else { break }
      
      buffer = buffer >> 8
    }
    while true
    
    // Remove leading zeroes.
    while let firstByte = result.first, result.count > 1,
          firstByte == 0 { result.remove(at: 0) }
    
    // Intialize `bytes` with the accumulated bytes.
    bytes = result
  }
  
  public var paddedDescription: String { description.padded(to: 6) }
}

// MARK: CustomStringConvertible

extension VariableLengthQuantity: CustomStringConvertible
{
  public var description: String { "\(UInt64(self))" }
}

// MARK: CustomDebugStringConvertible

extension VariableLengthQuantity: CustomDebugStringConvertible
{
  public var debugDescription: String
  {
    """
    \(type(of: self).self) {\
    bytes (hex, decimal): (\(String(hexBytes: bytes)), \(UInt64(bytes: bytes))); \
    representedValue (hex, decimal): \
    (\(String(hexBytes: representedValue)), \(UInt64(self)))}
    """
  }
}

// MARK: Conversions

public extension UInt64
{
  /// Initializing with a variable length quantity.
  init(_ quantity: VariableLengthQuantity) { self.init(bytes: quantity.bytes) }
}

public extension Int
{
  /// Initializing with a variable length quantity.
  init(_ quantity: VariableLengthQuantity) { self.init(bytes: quantity.bytes) }
}
