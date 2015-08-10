//
//  BitArray.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/8/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation


/// Add boolean type support to the builtin bit enum

extension Bit: BooleanType, BooleanLiteralConvertible {
  public var boolValue: Bool { return self.rawValue == 1 }
  public init(booleanLiteral value: Bool) { self = value ? .One : .Zero }
}


/// The core bit array implementation

public struct BitArray: CollectionType {

  static var BitLimit = Int(round(log2(Double(UInt64.max))))
  public var rawValue: UInt64
  public var count = BitArray.BitLimit
  public var startIndex: Int { return 0 }
  public var endIndex: Int { return count }

  /** Initializers */
  public init(storage:Int = 0, count:Int = BitArray.BitLimit) { self.init(storage:UInt64(storage), count:count) }
  public init(storage:UInt64 = 0, count:Int = BitArray.BitLimit) { self.rawValue = storage; self.count = count }

  /** Subscripting */
  public subscript(i:Int) -> Bit {
    get { return Bit(booleanLiteral: isBitSet(i)) }
    set { if newValue.boolValue { setBit(i) } else { unsetBit(i) } }
  }

  public var isEmpty: Bool { return rawValue == 0 }

  /** Toggle an individual bit */
  public mutating func toggleBit(i:Int) {
    if i >= count { MSRaiseException(NSRangeException, reason: "i out of bounds", userinfo: nil) }
    if isBitSet(i) { unsetBit(i) } else { setBit(i) }
  }

  /** Set an individual bit */
  public mutating func setBit(i:Int) {
    if i >= count { MSRaiseException(NSRangeException, reason: "i out of bounds", userinfo: nil) }
    rawValue |= UInt64(1) << UInt64(i)
  }

  /** Unset an individual bit */
  public mutating func unsetBit(i:Int) {
    if i >= count { MSRaiseException(NSRangeException, reason: "i out of bounds", userinfo: nil) }
    rawValue &= ~(UInt64(1) << UInt64(i))
  }

  /** unsetting all bits */
  public mutating func unsetAllBits() { rawValue = 0 }

  /** Query whether an individual bit is set */
  public func isBitSet(i:Int) -> Bool {
    if i >= count { MSRaiseException(NSRangeException, reason: "i out of bounds", userinfo: nil) }
    return Bit(rawValue: Int(rawValue >> UInt64(i) & UInt64(1)))!.boolValue
  }

  /** The index of the most significant bit for currently stored value */
  public var mostSignificantBit: Int { var i = 0; for (idx, bit) in self.enumerate() { if bit { i = idx } }; return i }

}

// MARK: - Equatable

public func ==(lhs:BitArray, rhs:BitArray) -> Bool { return lhs.rawValue == rhs.rawValue && lhs.count == rhs.count }


// MARK: - NSNumber conversions

extension BitArray {
  public func toNumber() -> NSNumber { return NSNumber(unsignedLongLong: rawValue) }
  public static func fromNumber(number:NSNumber, count:Int = 0) -> BitArray {
    return self.init(storage:number.unsignedLongLongValue, count:count)
  }
}


// MARK: - Hashable

extension BitArray: Hashable { public var hashValue: Int { return Int(rawValue) } }


// MARK: - Printable

extension BitArray: CustomStringConvertible {
  public var description:String {
    var chars = [Character]()
      for (i, bit) in self.enumerate() {
        chars.append(Character("\(bit.rawValue)"))
        if i % 4 == 3 { chars.append(Character(" ")) }
      }
      if chars.last == " " { chars.removeLast() }
      var description = ""
      for char in Array(chars.reverse()) { char.writeTo(&description) }
    return description
  }
  public func toStringWithLabels(labels: [String], emptyLabel: String = "None") -> String {
    var components: [String] = []
    for (label, bit) in Zip2Sequence(labels, self) {
      if bit.boolValue { components += [label] }
    }
    if components.isEmpty { components += [emptyLabel] }
    return "|".join(components)
  }
}


// MARK: - RawOptionSetType

extension BitArray: Equatable, OptionSetType {
  public static func fromMask(raw: UInt64) -> BitArray  { return self.init(rawValue: raw) }
}


// MARK: - BooleanType

extension BitArray: BooleanType { public var boolValue: Bool { return rawValue != 0 } }


// MARK: - RawRepresentable

extension BitArray: RawRepresentable {
  public init(rawValue: UInt64) {
    self.init(storage: rawValue)
  }
  public func toRaw() -> UInt64 { return rawValue }
}


// MARK: - NilLiteralConvertible

extension BitArray: NilLiteralConvertible {
  public init(nilLiteral: Void) {
    self.init(rawValue: UInt64(0))
  }
  public static func convertFromNilLiteral() -> BitArray { return self.init(storage:0) }
}


// MARK: - SequenceType

extension BitArray: SequenceType { public func generate() -> BitArrayGenerator { return BitArrayGenerator(self) } }


// MARK: - BitwiseOperationsType

extension  BitArray: BitwiseOperationsType { public static var allZeros: BitArray { return self.init(storage:0) } }

public func &(lhs: BitArray, rhs: BitArray) -> BitArray {
  return BitArray(storage:lhs.rawValue & rhs.rawValue, count:max(lhs.count, rhs.count))
}
public func |(lhs: BitArray, rhs: BitArray) -> BitArray {
  return BitArray(storage:lhs.rawValue | rhs.rawValue, count:max(lhs.count, rhs.count))
}
public func ^(lhs: BitArray, rhs: BitArray) -> BitArray {
  return BitArray(storage:lhs.rawValue ^ rhs.rawValue, count:max(lhs.count, rhs.count))
}
public prefix func ~(bits: BitArray) -> BitArray { return BitArray(storage:~bits.rawValue, count:bits.count) }


// MARK: - Generator for enumerating over bits in BitArray

public struct BitArrayGenerator: GeneratorType {
  private let bits: BitArray
  private var bitIndex: Int = 0
  public init(_ value:BitArray) { bits = value }
  public mutating func next() -> Bit? {
    return (bitIndex < bits.count ? Bit(rawValue: Int((bits.rawValue >> UInt64(bitIndex++)) & UInt64(1))) : nil)
  }
}
