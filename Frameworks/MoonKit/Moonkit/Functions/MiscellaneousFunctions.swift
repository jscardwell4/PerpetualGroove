//
//  MiscellaneousFunctions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/8/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/**
nonce

- returns: String
*/
public func nonce() -> String { return NSUUID().UUIDString }

public func gcd(var a: Int, var _ b: Int) -> Int { while b != 0 { let t = b; b = a % b; a = t }; return a }
public func lcm(a: Int, _ b: Int) -> Int { return a / gcd(a, b) * b }

/**
dispatchToMain:block:

- parameter synchronous: Bool = false
- parameter block: dispatch_block_t
*/
public func dispatchToMain(synchronous synchronous: Bool = false, _ block: dispatch_block_t) {
  if NSThread.isMainThread() { block() }
  else if synchronous { dispatch_sync(dispatch_get_main_queue(), block) }
  else { dispatch_async(dispatch_get_main_queue(), block) }
}

/**
backgroundDispatch:

- parameter block: () -> Void
*/
public func backgroundDispatch(block: () -> Void) { dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block) }

/**
delayedDispatchToMain:block:

- parameter delay: Int
- parameter block: dispatch_block_t
*/
public func delayedDispatchToMain(delay: Double, _ block: dispatch_block_t) {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
    dispatch_get_main_queue(),
    block
  )
}

/**
typeName:

- parameter object: Any

- returns: String
*/
public func typeName(object: Any) -> String { return _stdlib_getDemangledTypeName(object) }

