//
//  HashableTuple.swift
//  MoonKit
//
//  Created by Jason Cardwell on 1/27/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct HashableTuple<Element1:Hashable,Element2:Hashable>: Hashable {
  public let element1: Element1
  public let element2: Element2
  public var hashValue: Int { return element1.hashValue ^ element1.hashValue }
  public init(_ element1: Element1, _ element2: Element2) {
    self.element1 = element1
    self.element2 = element2
  }
}

public func ==<T: Hashable, U:Hashable>(lhs: HashableTuple<T,U>, rhs: HashableTuple<T,U>) -> Bool {
  return lhs.element1 == rhs.element1 && lhs.element2 == rhs.element2
}
