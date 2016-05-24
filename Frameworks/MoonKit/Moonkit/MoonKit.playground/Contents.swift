import Foundation
import MoonKit


let wtf = UnsafeMutablePointer<Int?>.alloc(10)
wtf.memory
wtf.initialize(nil)
wtf.memory
wtf.initialize(20)
wtf.memory
strideof(Int)
alignof(Int)
strideof(Int?)
alignof(Int?)
