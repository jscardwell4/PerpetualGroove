//: Playground - noun: a place where people can play
import Foundation
import UIKit
import MoonKit
import CoreAudio
import CoreMIDI

var maxUInt: UInt64 = UInt64.max
print(maxUInt)
maxUInt &= ~0xF
//maxUInt /= 100
//maxUInt *= 100
print(maxUInt)

let s = 0.5
secondsToNanoseconds(s)
nanosecondsToSeconds(secondsToNanoseconds(s))
secondsToNanoseconds(217513.627888829 - 217513.611224383)
218714399159549 - 218714378326221
var wtf = NSObject()
let rawWTF = UnsafeMutablePointer<RawByte>(withUnsafeMutablePointer(&wtf){$0})
rawWTF
debugPrint(rawWTF.memory)
let rawWTF2 = UnsafeMutablePointer<RawByte>(withUnsafeMutablePointer(&wtf){$0})
debugPrint(rawWTF2.memory)
