//: Playground - noun: a place where people can play

import UIKit
import MoonKit
import AudioToolbox


let url = NSBundle.mainBundle().URLForResource("SPYRO's Pure Oscillators", withExtension: "sf2")!
print(url)
var name = UnsafeMutablePointer<Unmanaged<CFString>?>()

CopyNameFromSoundBank(url, name)

name

var _info: [AnyObject] = []
var info: CFArray? = _info as CFArray

var wtf = UnsafeMutablePointer<CFArray?>(info)



CopyInstrumentInfoFromSoundBank(url, wtf)