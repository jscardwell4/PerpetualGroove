//
//  Index.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/7/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension ForwardIndexType {
  public mutating func increment() { self = self.successor() }
  public mutating func advanceBy(n: Self.Distance) { self = advancedBy(n) }
  public mutating func advanceBy(n: Self.Distance, limit: Self) { self = advancedBy(n, limit: limit) }
}

public extension BidirectionalIndexType {
  public mutating func increment() { self = self.successor() }
  public mutating func decrement() { self = self.predecessor() }
  public mutating func advanceBy(n: Self.Distance) { self = advancedBy(n) }
  public mutating func advanceBy(n: Self.Distance, limit: Self) { self = advancedBy(n, limit: limit) }
}

