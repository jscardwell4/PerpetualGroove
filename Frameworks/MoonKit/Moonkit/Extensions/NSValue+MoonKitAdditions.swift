//
//  NSValue+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

//extension NSValue {
//
//  public convenience init<T>(var value: T) {
//    let bytes = withUnsafePointer(&value) { (pointer:UnsafePointer<T>) -> [Byte] in
//      let size = sizeofValue(pointer.memory)
//      let bytesPointer = UnsafePointer<Byte>(pointer)
//      let bytesBufferPointer = UnsafeBufferPointer<Byte>(start: bytesPointer, count: size)
//      return Array(bytesBufferPointer)
//    }
//    let objCType = "[S]".cStringUsingEncoding(NSUTF8StringEncoding)!
//    self.init(bytes: bytes, objCType: objCType)
//  }
//
//  public func getValue<T>() -> T {
//    let pointer = UnsafeMutablePointer<T>.alloc(1)
//    getValue(pointer)
//    return pointer.move()
//  }
//}