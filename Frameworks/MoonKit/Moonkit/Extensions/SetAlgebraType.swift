//
//  SetAlgebraType.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

// contains
public func ∈<S:SetAlgebraType>(lhs: S.Element, rhs: S) -> Bool { return rhs.contains(lhs) }
public func ∋<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> Bool { return lhs.contains(rhs) }

public func ∉<S:SetAlgebraType>(lhs: S.Element, rhs: S) -> Bool { return !(lhs ∈ rhs) }
public func ∌<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> Bool { return !(lhs ∋ rhs) }

// subset/superset
public func ⊂<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return lhs.isStrictSubsetOf(rhs)   }
public func ⊃<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return lhs.isStrictSupersetOf(rhs) }
public func ⊆<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return lhs.isSubsetOf(rhs)         }
public func ⊇<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return lhs.isSupersetOf(rhs)       }

public func ⊄<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return !(lhs ⊂ rhs) }
public func ⊅<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return !(lhs ⊃ rhs) }
public func ⊈<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return !(lhs ⊆ rhs) }
public func ⊉<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return !(lhs ⊇ rhs) }

// union
public func ∪<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.union(rhs) }
public func ∪=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.unionInPlace(rhs) }

// minus
public func ∖<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.subtract(rhs) }
public func ∖=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.subtractInPlace(rhs) }

// intersect
public func ∩<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.intersect(rhs) }
public func ∩=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.intersectInPlace(rhs) }

// xor
public func ⊻<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.exclusiveOr(rhs) }
public func ⊻=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.exclusiveOrInPlace(rhs) }

// disjoint
public func !⚭<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return lhs.isDisjointWith(rhs) }
public func ⚭<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return !(lhs ⚭ rhs) }

//public func ~=<O:OptionSetType>(lhs: O, rhs: O) -> Bool { return (lhs ∩ rhs) == lhs }
//public func !~=<O:OptionSetType>(lhs: O, rhs: O) -> Bool { return !(lhs ~= rhs) }

