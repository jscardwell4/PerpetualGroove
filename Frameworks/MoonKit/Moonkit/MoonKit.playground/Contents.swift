import Foundation
import MoonKit

let wtf = UInt64(93)
_countLeadingZeros(Int64(wtf))
UInt64.max
UInt.max

let maxUInt = UInt.max
UInt._sizeInBits
let leading = maxUInt & 0xFFFFFFFF00000000 >> 32
let trailing = maxUInt & 0x00000000FFFFFFFF
//let wtf = [true, false, true]
//let wtfIndexes = wtf.lazy.enumerate().lazy.map({$0.0})
_countLeadingZeros(Int64(leading))
_countLeadingZeros(Int64(trailing))
//print(Array(wtfIndexes.generate()))
UInt8.max
let i = Int64(2359829)
_countLeadingZeros(i)
countLeadingZeros(i)
let u = UInt64(i)
countLeadingZeros(u)
countLeadingZeros(Int64.max)
countLeadingZeros(UInt64.max)
String(255, radix: 2)
let storage = UnsafeMutablePointer<UInt>.alloc(4)
var bitMap = BitMap(uninitializedStorage: storage, bitCount: 3 * Int(UInt._sizeInBits))
//bitMap.initializeToZero()
for i in 0.stride(to: 192, by: 3) {
  bitMap[i] = true
}
let word = storage.memory
print("String.init(word, radix:2): \(String(word, radix: 2))")
print("String.init(word, radix:8): \(String(word, radix: 8))")
print("String.init(word, radix:10): \(String(word, radix: 10))")
print("String.init(word, radix:16): \(String(word, radix: 16))")

print("rawContentsOf word(radix:2): ", terminator: ""); print(String(rawContentsOf: word, radix: 2))
print("rawContentsOf word(radix:8): ", terminator: ""); print(String(rawContentsOf: word, radix: 8))
print("rawContentsOf word(radix:10): ", terminator: ""); print(String(rawContentsOf: word, radix: 10))
print("rawContentsOf word(radix:16): ", terminator: ""); print(String(rawContentsOf: word, radix: 16))

for (i, v) in [0, 1, 2, 3, 4, 5].enumerate() where v % 2 == 0 {
  print(i, v)
}

print(bitMap)
print(bitMap.nonZeroBits)
for index in bitMap.nonZeroBits { assert(bitMap[index]) }
bitMap[3] = false
print(bitMap)
bitMap[0] = false
print(bitMap)

