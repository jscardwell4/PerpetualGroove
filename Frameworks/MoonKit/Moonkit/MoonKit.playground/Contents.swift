import Foundation
import MoonKit

/*
				16
		4				36
	1		9		25	49
*/

let tree: Tree<Int> = [1, 4, 9, 16, 25, 36, 49]

print(tree.debugDescription)

var result = tree.find({$0 < 25}, {$0 == 25})
result
print("\n")
result = tree.find({$0 < 20}, {$0 == 20})
result
print("\n")
result = tree.findNearestNotGreaterThan({$0 < 20}, {$0 == 20})
result
print("\n")
result = tree.findNearestNotLessThan({$0 < 20}, {$0 == 20})
result
