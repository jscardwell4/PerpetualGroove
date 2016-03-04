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
public func ∪<S:SetAlgebraType where S.Element == S>(lhs: S, rhs: S) -> S { return lhs.union(rhs) }
public func ∪=<S:SetAlgebraType where S.Element == S>(inout lhs: S, rhs: S) { lhs.unionInPlace(rhs) }
public func ∪<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.union(rhs) }
public func ∪=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.unionInPlace(rhs) }
public func ∪<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> S { var lhs = lhs; lhs ∪= rhs; return lhs }
public func ∪=<S:SetAlgebraType>(inout lhs: S, rhs: S.Element) { lhs.insert(rhs) }

// minus
public func ∖<S:SetAlgebraType where S.Element == S>(lhs: S, rhs: S) -> S { return lhs.subtract(rhs) }
public func ∖=<S:SetAlgebraType where S.Element == S>(inout lhs: S, rhs: S) { lhs.subtractInPlace(rhs) }
public func ∖<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.subtract(rhs) }
public func ∖=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.subtractInPlace(rhs) }
public func ∖<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> S { var lhs = lhs; lhs ∖= rhs; return lhs }
public func ∖=<S:SetAlgebraType>(inout lhs: S, rhs: S.Element) { lhs.remove(rhs) }

// intersect
public func ∩<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.intersect(rhs) }
public func ∩=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.intersectInPlace(rhs) }

// xor
public func ⊻<S:SetAlgebraType where S.Element == S>(lhs: S, rhs: S) -> S { return lhs.exclusiveOr(rhs) }
public func ⊻=<S:SetAlgebraType where S.Element == S>(inout lhs: S, rhs: S) { lhs.exclusiveOrInPlace(rhs) }
public func ⊻<S:SetAlgebraType>(lhs: S, rhs: S) -> S { return lhs.exclusiveOr(rhs) }
public func ⊻=<S:SetAlgebraType>(inout lhs: S, rhs: S) { lhs.exclusiveOrInPlace(rhs) }
public func ⊻<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> S { return lhs ⊻ S([rhs]) }
public func ⊻=<S:SetAlgebraType>(inout lhs: S, rhs: S.Element) { lhs ⊻= S([rhs]) }

// disjoint
public func !⚭<S:SetAlgebraType where S.Element == S>(lhs: S, rhs: S) -> Bool { return lhs.isDisjointWith(rhs) }
public func ⚭<S:SetAlgebraType where S.Element == S>(lhs: S, rhs: S) -> Bool { return !(lhs !⚭ rhs) }
public func !⚭<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return lhs.isDisjointWith(rhs) }
public func ⚭<S:SetAlgebraType>(lhs: S, rhs: S) -> Bool { return !(lhs !⚭ rhs) }
public func !⚭<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> Bool { return !lhs.contains(rhs) }
public func ⚭<S:SetAlgebraType>(lhs: S, rhs: S.Element) -> Bool { return lhs.contains(rhs) }

//public func ~=<O:OptionSetType>(lhs: O, rhs: O) -> Bool { return (lhs ∩ rhs) == lhs }
//public func !~=<O:OptionSetType>(lhs: O, rhs: O) -> Bool { return !(lhs ~= rhs) }

