//
//  Slider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import MoonKit

/**
Struct for converting values to MIDI variable length quanity representation

These numbers are represented 7 bits per byte, most significant bits first. All bytes except the last have bit 7 set, and the
last byte has bit 7 clear. If the number is between 0 and 127, it is thus represented exactly as one byte.
*/
struct VariableLengthQuantity: CustomStringConvertible {
  let bytes: [Byte]
  static let zero = VariableLengthQuantity(0)

  var description: String {
    let representedValue = self.representedValue
    let byteString = " ".join(bytes.map { String($0, radix: 16, uppercase: true, pad: 2) })
    let representedValueString = " ".join(representedValue.map { String($0, radix: 16, uppercase: true, pad: 2) })
    return "\(self.dynamicType.self) {" + "; ".join(
      "bytes: \(byteString) (\(UInt64(bytes)))",
      "representedValue: \(representedValueString) (\(UInt64(representedValue)))"
      ) + "}"
  }
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
          next = (i < group.count ? group[i++] : 0)
          groupValue = (groupValue << UInt64(7)) + UInt64(next & 0x7F)
        } while next & 0x80 != 0
      }
      resolvedGroups.append(groupValue)
    }
    var resolvedBytes = resolvedGroups.flatMap { $0.bytes }
    while let firstByte = resolvedBytes.first where resolvedBytes.count > 1 && firstByte == 0 { resolvedBytes.removeAtIndex(0) }
    return resolvedBytes
  }

  /**
  Initialize with bytes array already in converted format

  - parameter bytes: [Byte]
  */
  init(bytes: [Byte]) { self.bytes = bytes }

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
    while let firstByte = result.first where result.count > 1 && firstByte == 0 { result.removeAtIndex(0) }
    bytes = result
  }
}

// 372, 28
let q1 = VariableLengthQuantity(28)
Int(q1.representedValue)
let q2 = VariableLengthQuantity(372)
Int(q2.representedValue)

