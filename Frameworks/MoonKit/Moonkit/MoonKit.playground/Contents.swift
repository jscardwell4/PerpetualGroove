import Foundation
import UIKit
import MoonKit
import CoreImage

struct SomeStruct {
  let someString: String?
  let someNumber: UInt64
}

var someInstance = SomeStruct(someString: "A String", someNumber: 66)

let data = encode(someInstance)

let value = NSValue(bytes: data.bytes, objCType: "@")

String(CString:value.objCType, encoding: NSUTF8StringEncoding)

let someInstanceDecoded: SomeStruct = decode(data)


let bytes = withUnsafePointer(&someInstance) { (pointer:UnsafePointer<SomeStruct>) -> [Byte] in
  let size = sizeofValue(pointer.memory)
  var bytesPointer = UnsafeMutablePointer<Byte>(pointer)
  var bytesBufferPointer = UnsafeMutableBufferPointer<Byte>(start: bytesPointer, count: size)
  return Array(bytesBufferPointer)
}

var p = UnsafeMutablePointer<SomeStruct>.alloc(1)
var pByte = UnsafeMutablePointer<Byte>(p)
for byte in bytes {
  pByte.memory = byte
  pByte.advanceBy(1)
}
let someInstanceFromBytes = p.memory

let someValue = NSValue(value: someInstance)

var pp = UnsafeMutablePointer<SomeStruct>.alloc(1)
dump(someValue)
someValue.getValue(pp)

//let wtf = pp.memory

