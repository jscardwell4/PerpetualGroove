import Foundation
import UIKit
import MoonKit

let nsuuid = NSUUID()
var bytes = UnsafeMutablePointer<UInt8>.alloc(16)
nsuuid.getUUIDBytes(bytes)
print(nsuuid.description)
let bytesBuffer = UnsafeBufferPointer(start: bytes, count: 16)
print(Array(bytesBuffer))
let nsuuid2 = NSUUID(UUIDBytes: bytes)
print(nsuuid2)

let uuid = UUID(nsuuid)
print(uuid.bytes)