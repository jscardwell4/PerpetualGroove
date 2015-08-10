//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

let url = NSBundle.mainBundle().URLForResource("SPYRO's Pure Oscillators", withExtension: "sf2")
let data = NSData(contentsOfURL: url!)

data?.enumerateByteRangesUsingBlock({ (bytes:UnsafePointer<Void>, range:NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
  bytes
})


