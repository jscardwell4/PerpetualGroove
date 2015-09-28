import Foundation
import UIKit
import MoonKit

var tree: Tree<Int> = [30, 9, 72, 7, 27, 3, 23, 29, 12, 49, 78, 73, 92, 58, 42, 40, 44, 65, 87]
//print(tree)
tree.replace(72, with: 4)
tree.remove([78, 58, 12])
tree.insert([-1, 99, 5])
tree.replace([3, 4, 5], with: [13, 14, 15])

//print(tree)
//print(tree.treeDescription)

