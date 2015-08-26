//: Playground - noun: a place where people can play
import Foundation
import MoonKit
import AudioToolbox

let test: UInt64 = 4642901592163483648
//test.bytes
UInt64(UInt32(test >> 32 & 0xFFFFFFFF).bytes  + UInt32(test & 0xFFFFFFFF).bytes)
let wtf1 = test >> 32
let test1 = UInt32(wtf1)
UInt32(test >> 32 & 0xFFFFFFFFFF).bytes