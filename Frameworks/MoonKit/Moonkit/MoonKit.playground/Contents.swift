import Foundation
import MoonKit
import XCPlayground

var set: OrderedSet<Int> = [4, 2, 6, 3]
set[..<2]
set.append(9)
set.insert(33)
set.appendContentsOf([3, 6, 7, 22])
set ∋ 4

