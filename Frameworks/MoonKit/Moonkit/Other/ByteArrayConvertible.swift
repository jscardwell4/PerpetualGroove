//
//  Bytes.swift
//  MoonKit
//
//  Created by Jason Cardwell on 11/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public protocol ByteArrayConvertible: Equatable, Coding, DataConvertible {
  var bytes: [Byte] { get }
  init(_ bytes: [Byte])
  init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S)
}

public extension ByteArrayConvertible {
  init?(coder: NSCoder) {
    var length = 0
    let bytes = coder.decodeBytesWithReturnedLength(&length)
    self.init(UnsafeMutableBufferPointer<Byte>(start: UnsafeMutablePointer<Byte>(bytes), count: length))
  }
  func encodeWithCoder(coder: NSCoder) {
    let bytes = self.bytes
    coder.encodeBytes(bytes, length: bytes.count)
  }
}


public func ==<B:ByteArrayConvertible>(lhs: B, rhs: B) -> Bool {
  let leftBytes = lhs.bytes, rightBytes = rhs.bytes
  guard leftBytes.count == rightBytes.count else { return false }
  for (leftByte, rightByte) in zip(leftBytes, rightBytes) {
    guard leftByte  == rightByte else { return false }
  }
  return true
}
extension ByteArrayConvertible {
  public init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S) { self.init(Array(bytes)) }
}

extension UInt: ByteArrayConvertible {
  public var bytes: [Byte] { return sizeof(UInt.self) == 8 ? UInt64(self).bytes : UInt32(self).bytes }
  public init(_ bytes: [Byte]) {
    self = sizeof(UInt.self) == 8 ? UInt(UInt64(bytes)) : UInt(UInt32(bytes))
  }
}

extension Int: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt(self).bytes }
  public init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S) { self = Int(UInt(bytes)) }
}


extension UInt8: ByteArrayConvertible {
  public var bytes: [Byte] { return [self] }
  public init(_ bytes: [Byte]) {
    guard let byte = bytes.first else { self = 0; return }
    self = byte
  }
}
extension Int8: ByteArrayConvertible {
  public var bytes: [Byte] { return [UInt8(self)] }
  public init(_ bytes: [Byte]) { self = Int8(UInt8(bytes)) }
}

extension UInt16: ByteArrayConvertible {
  public var bytes: [Byte] { return [Byte(self >> 8 & 0xFF), Byte(self & 0xFF)] }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count < 3 else { self = UInt16(bytes[count - 2 ..< count]); return }
    switch bytes.count {
    case 2:
      self = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    case 1:
      self = UInt16(bytes[0])
    default:
      self = 0
    }
  }
}
extension Int16: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt16(self).bytes }
  public init(_ bytes: [Byte]) { self = Int16(UInt16(bytes)) }
}

extension UInt32: ByteArrayConvertible {
  public var bytes: [Byte] {
    return [Byte(self >> 24 & 0xFF), Byte(self >> 16 & 0xFF), Byte(self >> 8 & 0xFF), Byte(self & 0xFF)]
  }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count > 2 else { self = UInt32(UInt16(bytes)); return }
    self = UInt32(UInt16(bytes[0 ..< count - 2])) << 16 | UInt32(UInt32(bytes[count - 2 ..< count]))
  }
}
extension Int32: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt32(self).bytes }
  public init(_ bytes: [Byte]) { self = Int32(UInt32(bytes)) }
}

extension UInt64: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt32(self >> 32 & 0xFFFFFFFF).bytes  + UInt32(self & 0xFFFFFFFF).bytes }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count > 4 else { self = UInt64(UInt32(bytes)); return }
    self = UInt64(UInt32(bytes[0 ..< count - 4])) << 32 | UInt64(UInt32(bytes[count - 4 ..< count]))
  }
}
extension Int64: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt64(self).bytes }
  public init(_ bytes: [Byte]) { self = Int64(UInt64(bytes)) }
}
