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

public func +<F:ForwardIndexType>(lhs: F, rhs: F.Distance) -> F { return lhs.advancedBy(rhs) }
public func -<F:ForwardIndexType>(lhs: F, rhs: F.Distance) -> F { return lhs.advancedBy(-rhs) }
public func +<F:ForwardIndexType>(lhs: F.Distance, rhs: F) -> F { return rhs.advancedBy(lhs) }
public func -<F:ForwardIndexType>(lhs: F.Distance, rhs: F) -> F { return rhs.advancedBy(-lhs) }


public func +=<F:ForwardIndexType>(inout lhs: F, rhs: F.Distance) { lhs.advanceBy(rhs) }
public func -=<F:ForwardIndexType>(inout lhs: F, rhs: F.Distance) { lhs.advanceBy(-rhs) }

public prefix  func ++<F:ForwardIndexType>(inout x: F) -> F { x.increment(); return x }
public postfix func ++<F:ForwardIndexType>(inout x: F) -> F { let xʹ = x; x.increment(); return xʹ }

public prefix  func --<B:BidirectionalIndexType>(inout x: B) -> B { x.decrement(); return x }
public postfix func --<B:BidirectionalIndexType>(inout x: B) -> B { let xʹ = x; x.decrement(); return xʹ }

public func ⟷<F:ForwardIndexType>(lhs: F, rhs: F) -> F.Distance { return lhs.distanceTo(rhs) }