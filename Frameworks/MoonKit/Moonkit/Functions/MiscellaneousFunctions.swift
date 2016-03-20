//
//  MiscellaneousFunctions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/8/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public func branch(tuples: (() -> Bool, () -> Void)...) {
  for (predicate, action) in tuples {
    guard !predicate() else { action(); return }
  }
}

@inline(__always)
public func synchronized<R>(lock: AnyObject, @noescape block: () -> R) -> R {
  objc_sync_enter(lock)
  defer { objc_sync_exit(lock) }
  return block()
}

/**
nonce

- returns: String
*/
public func nonce() -> String { return NSUUID().UUIDString }


/// Returns the next power of 2 that is equal to or greater than `x`
public func round2(x: Int) -> Int {
  return Int(_exp2(_ceil(_log2(Double(max(0, x))))))
}

/**
 No-op function intended to be used as a more noticeable way to force instantiation of lazy properties

 - parameter t: T
*/
public func touch<T>(t: T) {}

public func gcd<T:ArithmeticType>(a: T, _ b: T) -> T {
  var a = a, b = b
  while !b.isZero {
    let t = b
    b = a % b
    a = t
  }
  return a
}
public func lcm<T:ArithmeticType>(a: T, _ b: T) -> T {
  return a / gcd(a, b) * b
}

public func reinterpretCast<T,U>(obj: T) -> U { return unsafeBitCast(obj, U.self) }

/**
typeName:

- parameter object: Any

- returns: String
*/
public func typeName(object: Any) -> String { return "\(object.dynamicType)" }

/** Ticks since last device reboot */
public var hostTicks: UInt64 { return mach_absolute_time() }

/** Nanoseconds since last reboot */
public var hostTime: UInt64 { return hostTicks * UInt64(nanosecondsPerHostTick.value) }

/** Ratio that represents the number of nanoseconds per host tick */
public var nanosecondsPerHostTick: Ratio<Int64> {
  var info = mach_timebase_info()
  mach_timebase_info(&info)
  return Int64(info.numer)∶Int64(info.denom)
}

