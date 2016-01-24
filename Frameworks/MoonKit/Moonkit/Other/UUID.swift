//
//  UUID.swift
//  MoonKit
//
//  Created by Jason Cardwell on 1/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct UUID: ByteArrayConvertible, StringValueConvertible {
  public let bytes: [Byte]
  public let stringValue: String

  public init() { self.init(NSUUID()) }
  public init(_ bytes: [Byte]) { self.init(NSUUID(UUIDBytes: bytes)) }
  public init?(_ string: String) { guard let object = NSUUID(UUIDString: string) else { return nil }; self.init(object) }
  public init(_ object: NSUUID) {
    let bytesPointer = UnsafeMutablePointer<Byte>.alloc(16)
    object.getUUIDBytes(bytesPointer)
    let bytesBuffer = UnsafeBufferPointer(start: bytesPointer, count: 16)
    bytes = Array(bytesBuffer)
    stringValue = object.UUIDString
    bytesPointer.destroy()
    bytesPointer.dealloc(16)
  }
}

extension UUID: CustomStringConvertible {
  public var description: String { return stringValue }
}

extension UUID: Hashable {
  public var hashValue: Int { return stringValue.hashValue }
}

extension UUID: JSONValueConvertible {
  public var jsonValue: JSONValue { return stringValue.jsonValue }
}

extension UUID: JSONValueInitializable {
  public init?(_ jsonValue: JSONValue?) {
    guard let string = String(jsonValue) else { return nil }
    self.init(string)
  }
}

public func ==(lhs: UUID, rhs: UUID) -> Bool { return lhs.stringValue == rhs.stringValue }