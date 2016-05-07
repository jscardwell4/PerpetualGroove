import Foundation
import MoonKit

var anArray: [Int] = [1, 2, 3, 4]
var aSlice: ArraySlice<Int> = anArray[1 ... 3]
aSlice.append(5)
anArray[1 ... 3] = aSlice
anArray