//
//  BitArray.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/22/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

//private final class BitArrayStorage: ManagedBuffer<Int, Byte> {
//  class func create(capacity: Int) -> ByteArrayStorage {
//    return super.create(capacity) {
//      proto in
//      proto.withUnsafeMutablePointerToElements {
//        for i in 0 ..< proto.allocatedElementCount { ($0 + i).initialize(0) }
//      }
//      return proto.allocatedElementCount
//      } as! ByteArrayStorage
//  }
//
//  var capacity: Int { return value }
//}
//
//public struct BitArray {
//  private var storage: BitArrayStorage
//  public var capacityInBytes: Int { return storage.capacity }
//  public var capacityInBits: Int { return capacityInBytes * 8 }
//  public static func byteIndex(i: Int) -> Int { return Int(UInt(i) / 8) }
//  public static func bitIndex(i: Int) -> Int { return Int(UInt(i) % 8) }
//}