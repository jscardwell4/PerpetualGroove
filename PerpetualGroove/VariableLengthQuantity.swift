//
//  VariableLengthQuantity.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** 
Struct for converting values to MIDI variable length quanity representation

These numbers are represented 7 bits per byte, most significant bits first. All bytes except the last have bit 7 set,
and the last byte has bit 7 clear. If the number is between 0 and 127, it is thus represented exactly as one byte.
*/
struct VariableLengthQuantity {

  let bytes: [Byte]
  static let zero = VariableLengthQuantity(0)

  var representedValue: [Byte] {
    let groups = bytes.segment(8)
    var resolvedGroups: [UInt64] = []
    for group in groups {
      guard group.count > 0 else { continue }
      var groupValue = UInt64(group[0])
      if groupValue & 0x80 != 0 {
        groupValue &= UInt64(0x7F)
        var i = 1
        var next = Byte(0)
        repeat {
          next = (i < group.count ? {let n = group[i]; i += 1; return n}() : 0)
          groupValue = (groupValue << UInt64(7)) + UInt64(next & 0x7F)
        } while next & 0x80 != 0
      }
      resolvedGroups.append(groupValue)
    }
    var resolvedBytes = resolvedGroups.flatMap { $0.bytes }
    while let firstByte = resolvedBytes.first , resolvedBytes.count > 1 && firstByte == 0 { resolvedBytes.remove(at: 0) }
    return resolvedBytes
  }

  var intValue: Int { return Int(representedValue) }

  /**
  Initialize with sequence of bytes already in converted format

  - parameter b: S
  */
  init<S:Swift.Sequence>(bytes b: S) where S.Iterator.Element == Byte { bytes = Array(b) }

  /**
  Initialize from any `ByteArrayConvertible` type holding the represented value

  - parameter value: B
  */
  init<B:ByteArrayConvertible>(_ value: B) {
    var v = UInt64(value.bytes)
    var buffer = v & 0x7F
    while v >> 7 > 0 {
      v = v >> 7
      buffer <<= 8
      buffer |= 0x80
      buffer += v & 0x7F
    }
    var result: [Byte] = []
    repeat {
      result.append(UInt8(buffer & 0xFF))
      guard buffer & 0x80 != 0 else { break }
      buffer = buffer >> 8
    } while true
    while let firstByte = result.first , result.count > 1 && firstByte == 0 { result.remove(at: 0) }
    bytes = result
  }
}

extension VariableLengthQuantity: CustomStringConvertible {
  var description: String { return "\(UInt64(representedValue))" }
  var paddedDescription: String { return description.pad(" ", count: 6) }
}

extension VariableLengthQuantity: CustomDebugStringConvertible {
  var debugDescription: String {
    let representedValue = self.representedValue
    return "\(type(of: self).self) {" + "; ".join(
      "bytes (hex, decimal): (\(String(hexBytes: bytes)), \(UInt64(bytes)))",
      "representedValue (hex, decimal): (\(String(hexBytes: representedValue)), \(UInt64(representedValue)))"
      ) + "}"
  }
}

