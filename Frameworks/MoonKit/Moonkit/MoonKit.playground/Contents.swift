import Foundation
import MoonKit

print(Array(zip([1, 2, 3], ["a", "b", "c", "d", "e"])))

var pointer1 = UnsafeMutablePointer<Int>.alloc(1)
var pointer2 = UnsafeMutablePointer<Int>.alloc(1)
pointer1.initialize(9)
pointer2.initialize(34)
pointer1.memory
pointer2.memory
swap(&pointer1, &pointer2)
pointer1.memory
pointer2.memory

var bufferStorage = UnsafeMutablePointer<Int>.alloc(10)
bufferStorage.initialize(1)
(bufferStorage + 1).initialize(2)
(bufferStorage + 2).initialize(3)
(bufferStorage + 3).initialize(4)
(bufferStorage + 4).initialize(5)
(bufferStorage + 5).initialize(6)
(bufferStorage + 6).initialize(7)
(bufferStorage + 7).initialize(8)
(bufferStorage + 8).initialize(9)
(bufferStorage + 9).initialize(10)

var bufferPointer = UnsafeMutableBufferPointer<Int>(start: bufferStorage, count: 10)

swap(&bufferPointer[3], &bufferPointer[4])

Array(bufferPointer)

alignof(String)
strideof(String)