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
