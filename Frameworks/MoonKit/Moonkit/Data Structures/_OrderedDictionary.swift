//
//  _OrderedDictionary.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/7/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

internal let maxLoadFactorInverse = 1/0.75

protocol _OrderedDictionary: MutableKeyValueCollection, DictionaryLiteralConvertible, RangeReplaceableCollectionType {

  associatedtype Buffer:_OrderedDictionaryBuffer

  associatedtype Index:IntegerType = Int

  var buffer: Buffer { get }

  var capacity: Int { get }

  func cloneBuffer(newCapacity: Int) -> Buffer

  mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool)

  init(minimumCapacity: Int)

  init(buffer: Buffer)

}

