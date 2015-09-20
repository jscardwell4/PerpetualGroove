//
//  MIDINodeHistory.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct MIDINodeHistory: RangeReplaceableCollectionType, MutableCollectionType {

  typealias Placement = MIDINode.Placement

  struct BreadCrumb { let time: CABarBeatTime; let placement: Placement }
  private var breadCrumbs: [BreadCrumb] = [] { didSet { breadCrumbs.sortInPlace { $0.time < $1.time } } }

  private var breadCrumbIndex: [CABarBeatTime:Int] = [:]

  /**
  generate

  - returns: IndexingGenerator<[BreadCrumb]>
  */
  func generate() -> IndexingGenerator<[BreadCrumb]> { return breadCrumbs.generate() }

  var startIndex: Int { return breadCrumbs.startIndex }
  var endIndex: Int { return breadCrumbs.endIndex }

  /**
  append:

  - parameter newElement: BreadCrumb
  */
  mutating func append(newElement: BreadCrumb) {
    if let idx = breadCrumbIndex[newElement.time] { breadCrumbs[idx] = newElement }
    else {
      breadCrumbIndex[newElement.time] = breadCrumbs.count
      breadCrumbs.append(newElement)
    }
  }

  /**
  subscript:

  - parameter position: Int

  - returns: Element
  */
  subscript(position: Int) -> BreadCrumb { get { return breadCrumbs[position] } set { breadCrumbs[position] = newValue } }

  /**
  replaceRange:with:

  - parameter subRange: Range<Int>
  - parameter newElements: C
  */
  mutating func replaceRange<C : CollectionType
    where C.Generator.Element == BreadCrumb>(subRange: Range<Int>, with newElements: C)
  {
    breadCrumbs.replaceRange(subRange, with: newElements)
  }

}

extension MIDINodeHistory: CustomStringConvertible {
  var description: String {
    return "MIDINodeHistory {\n" + ",\n\t".join(breadCrumbs.map({String($0)})) + "\n}"
  }
}

extension MIDINodeHistory: ArrayLiteralConvertible {
  init(arrayLiteral elements: BreadCrumb...) { breadCrumbs = elements }
}