import Foundation
import MoonKit
import XCPlayground

var sortedArray1 = SortedArray<Int>()
sortedArray1.append(4)
sortedArray1.append(1)
sortedArray1.append(4)
sortedArray1.append(40)
sortedArray1.append(8)
sortedArray1.append(2)
sortedArray1.append(11)
sortedArray1

var sortedArray2: SortedArray<Int> = [3, 12, 1, 66, 351, 33, -13]
sortedArray2[4] = 0
sortedArray2


sortedArray1.appendContentsOf(sortedArray2)
var sortedArray3 = sortedArray1
sortedArray1.removeRange(2...7)
sortedArray3

struct IntervalBox: Comparable, CustomStringConvertible {
  let interval: HalfOpenInterval<Int>
  var description: String { return interval.description }
}

func == (lhs: IntervalBox, rhs: IntervalBox) -> Bool { return lhs.interval.start == rhs.interval.start }
func < (lhs: IntervalBox, rhs: IntervalBox) -> Bool { return lhs.interval.start < rhs.interval.start }

var sortedArray4: SortedArray<IntervalBox> = []

sortedArray4.append(IntervalBox(interval: 3..<24))
sortedArray4.append(IntervalBox(interval: 33..<97))
sortedArray4.append(IntervalBox(interval: 124..<224))
sortedArray4.append(IntervalBox(interval: 24..<33))
sortedArray4.append(IntervalBox(interval: 224..<244))
sortedArray4.append(IntervalBox(interval: 244..<267))
sortedArray4.append(IntervalBox(interval: 97..<124))

func isOrderedBefore(x: Int) -> (IntervalBox) -> Bool { return { $0.interval.end <= x } }
func predicate(x: Int) -> (IntervalBox) -> Bool { return { $0.interval ∋ x } }

sortedArray4.indexOf(isOrderedBefore: isOrderedBefore(96), predicate: predicate(96))
sortedArray4.indexOf(isOrderedBefore: isOrderedBefore(99), predicate: predicate(99))
sortedArray4.indexOf(isOrderedBefore: isOrderedBefore(311), predicate: predicate(311))
sortedArray4.indexOf(isOrderedBefore: isOrderedBefore(244), predicate: predicate(244))
