//
//  Weak.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public struct Weak<T:AnyObject>: Equatable, Hashable {
  public let hashValue: Int
  public private(set) weak var reference: T?
  public init(_ ref: T?) {
    guard let ref = ref else { hashValue = 0; return }
    reference = ref
    hashValue = Int(ObjectIdentifier(ref).uintValue)
  }
}

public func ==<T:AnyObject>(lhs: Weak<T>, rhs: Weak<T>) -> Bool { return lhs.hashValue == rhs.hashValue }

extension Weak: CustomStringConvertible {
  public var description: String {
    guard let object = reference else { return "nil" }
    return "\(object.dynamicType)(\(unsafeAddressOf(object))"
  }
}