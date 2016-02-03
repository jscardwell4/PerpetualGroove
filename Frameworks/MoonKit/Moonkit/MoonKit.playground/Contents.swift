import Foundation
import MoonKit

let x: Int8 = 0
String(binaryBytes: x.bytes)
let y: Int8 = -0
String(binaryBytes: y.bytes)
//let wtf1 = pow(2, sizeof(Int8) * 8 - 1)
//let wtf2 = abs(y)
//String(binaryBytes: Int8(wtf1 + Int(y)))

let bitPattern: UInt8 = 0b11111111
let fromPattern = Int8(bitPattern: bitPattern)
func isSignMinus(value: Int) -> Bool {
  let totalBits = sizeof(Int) * 8 - 1
  let signBit = value >> totalBits
  return signBit != 0
}

isSignMinus(20)
isSignMinus(-6)
isSignMinus(0)
isSignMinus(-0)

__inline_signbitd(-24.0)
exp(24.0)

modf(-23.45)