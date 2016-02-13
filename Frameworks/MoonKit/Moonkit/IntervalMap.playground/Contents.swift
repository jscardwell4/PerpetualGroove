//: Playground - noun: a place where people can play

import UIKit
import MoonKit

struct IntervalMap<Key:IntervalType, Value where Key.Bound:Hashable> {//: CollectionType {
  private var intervals: [Key] = []
  private var values: [Key.Bound:Value] = [:]

  typealias Index = Dictionary<Key.Bound, Value>.Index

  private mutating func sortIntervals() { intervals.sortInPlace { $0.start < $1.start } }

//  private init<C1:CollectionType, C2:CollectionType where C1.Generator.Element == Key, C2.Generator.Element == Value, C1.Index.Distance == C2.Index.Distance>(intervals: C1, values: C2) {
//    precondition(intervals.count == values.count)
//    self.intervals = Array(intervals)
//    self.values = Array(values)
//  }
//
//  private init<S:SequenceType where S.Generator.Element == (Key, Value)>(tuples: S) {
//    for tuple in tuples { intervals.append(tuple.0); values.append(tuple.1) }
//  }
//
  var startIndex: Index { return values.startIndex }
  var endIndex: Index { return values.endIndex }
  var count: Int { return values.count }

  private func intervalWithStart(start: Key.Bound) -> (Key, Int)? {
    guard let index = intervals.indexOf({$0.start == start}) else { return nil }
    return (intervals[index], index)
  }

  subscript(index: Index) -> (Key, Value) {
    get {
      let (intervalStart, value) = values[index]
      guard let (interval, _) = intervalWithStart(intervalStart) else { fatalError() }
      return (interval, value)
    }
    set {
      guard let (_, i) = intervalWithStart(newValue.0.start) else { fatalError() }
      intervals[i] = newValue.0
      values[newValue.0.start] = newValue.1
    }
  }

//  subscript(range: Range<Index>) -> IntervalMap<Key, Value> {
//    get {
//      let values = self.values[range]
//      return IntervalMap(tuples: zip(intervals[range], values[range]))
//    }
//    set {
//
//    }
//  }

}
"wtf"
Dictionary<Double,String>.Index.self