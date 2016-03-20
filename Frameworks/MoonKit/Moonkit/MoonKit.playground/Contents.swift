import Foundation
import MoonKit

let wtf = [true, false, true]
let wtfIndexes = wtf.lazy.enumerate().lazy.map({$0.0})
print(Array(wtfIndexes.generate()))

let storage = UnsafeMutablePointer<UInt>.alloc(4)
var bitMap = BitMap(storage: storage, bitCount: 4 * Int(UInt._sizeInBits))

for i in 0.stride(to: 256, by: 3) {
  bitMap[i] = true
}

bitMap[3 * 20 + 1]

for wtf in bitMap.nonZeroBits {
  print(wtf)
}

//for wtf in bitMap.indices {
//  print(wtf)
//}
//
//print(bitMap)
