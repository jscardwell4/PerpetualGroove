//
//  Bytes.swift
//  MoonKit
//
//  Created by Jason Cardwell on 11/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public typealias Byte = UInt8
public typealias Byte2 = UInt16
public typealias Byte4 = UInt32
public typealias Byte8 = UInt64

public protocol Coding {
  init?(coder: NSCoder)
  func encodeWithCoder(coder: NSCoder)
}

public protocol DataConvertible {
  var data: NSData { get }
  init?(data: NSData)
}

public extension DataConvertible where Self:Coding {
  var data: NSData {
    let data = NSMutableData()
    let coder = NSKeyedArchiver(forWritingWithMutableData: data)
    encodeWithCoder(coder)
    coder.finishEncoding()
    return data
  }
  init?(data: NSData) {
    let coder = NSKeyedUnarchiver(forReadingWithData: data)
    self.init(coder: coder)
  }
}