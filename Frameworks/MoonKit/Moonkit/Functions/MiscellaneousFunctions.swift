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

public func dumpObjectIntrospection(obj: AnyObject, includeInheritance: Bool = false) {
  func descriptionForObject(objClass: AnyClass, inherited: Bool) -> String {
    var string = ""

    guard let objClassName = String(CString: class_getName(objClass), encoding: NSUTF8StringEncoding) else {
      return ""
    }

    string += inherited ? "inherited from \(objClassName):\n" : "Class: \(objClassName)\n"

    if !inherited {
      string += "size: \(class_getInstanceSize(objClass))\n"
      //      if let ivarLayout = String(UTF8String: UnsafePointer(class_getIvarLayout(objClass)))
      //        where !ivarLayout.isEmpty {
      //        string += "ivar layout: \(ivarLayout)\n"
      //      }
      //      if let weakIvarLayout = String(UTF8String: UnsafePointer(class_getWeakIvarLayout(objClass)))
      //        where !weakIvarLayout.isEmpty {
      //        string += "weak ivar layout: \(weakIvarLayout)\n"
      //      }
    }

    var outCount: UInt32 = 0
    let objClassIvars = class_copyIvarList(object_getClass(objClass), &outCount)
    if outCount > 0 {
      string += "class variables:\n"
      for ivar in UnsafeMutableBufferPointer(start: objClassIvars, count: numericCast(outCount)) {
        guard let ivarName = String(CString: ivar_getName(ivar), encoding: NSUTF8StringEncoding) else { continue }
        guard let ivarTypeEncoding = String(CString: ivar_getTypeEncoding(ivar),
                                            encoding: NSUTF8StringEncoding) else { continue }
        string += "\t\(ivarName) : \(ivarTypeEncoding)\n"
      }
    }
    outCount = 0
    let objClassInstanceIvars = class_copyIvarList(objClass, &outCount)
    if outCount > 0 {
      string += "instance variables:\n"
      for ivar in UnsafeMutableBufferPointer(start: objClassInstanceIvars, count: numericCast(outCount)) {
        guard let ivarName = String(CString: ivar_getName(ivar), encoding: NSUTF8StringEncoding) else { continue }
        guard let ivarTypeEncoding = String(CString: ivar_getTypeEncoding(ivar),
                                            encoding: NSUTF8StringEncoding) else { continue }
        string += "\t\(ivarName) : \(ivarTypeEncoding)\n"
      }
    }

    outCount = 0
    let objClassProperties = class_copyPropertyList(objClass, &outCount)
    if outCount > 0 {
      string += "properties:\n"
      for property in UnsafeMutableBufferPointer(start: objClassProperties, count: numericCast(outCount)) {
        guard let propertyName = String(CString: property_getName(property),
                                        encoding: NSUTF8StringEncoding) else { continue }
        guard let propertyAttributes = String(CString:  property_getAttributes(property),
                                              encoding: NSUTF8StringEncoding) else { continue }
        string += "\t\(propertyName) : \(propertyAttributes)\n"
      }
    }

    outCount = 0
    let objClassMethods = class_copyMethodList(object_getClass(objClass), &outCount)
    if outCount > 0 {
      string += "class methods:\n"
      for method in UnsafeMutableBufferPointer(start: objClassMethods, count: numericCast(outCount)) {
        let methodDescription = method_getDescription(method).memory
        let returnType = String(UTF8String: method_copyReturnType(method))!
        let allTypes = String(UTF8String: methodDescription.types)!
        let argumentTypes = allTypes[allTypes.startIndex.advancedBy(returnType.characters.count) ..< allTypes.endIndex]
        string += "\t\(methodDescription.name)  -> \(returnType)  arguments (\(method_getNumberOfArguments(method))): \(argumentTypes)\n"
      }
    }

    outCount = 0
    let objClassInstanceMethods = class_copyMethodList(objClass, &outCount)
    if outCount > 0 {
      string += "instance methods:\n"
      for method in UnsafeMutableBufferPointer(start: objClassInstanceMethods, count: numericCast(outCount)) {
        let methodDescription = method_getDescription(method).memory
        let returnType = String(UTF8String: method_copyReturnType(method))!
        let allTypes = String(UTF8String: methodDescription.types)!
        let argumentTypes = allTypes[allTypes.startIndex.advancedBy(returnType.characters.count) ..< allTypes.endIndex]
        string += "\t\(methodDescription.name)  -> \(returnType)  arguments (\(method_getNumberOfArguments(method))): \(argumentTypes)\n"
      }
    }

    outCount = 0
    let objClassProtocols = class_copyPropertyList(objClass, &outCount)
    if outCount > 0 {
      string += "conforms to:\n"
      for `protocol` in UnsafeMutableBufferPointer(start: objClassProtocols, count: numericCast(outCount)) {
        guard let protocolName = String(CString: property_getName(`protocol`),
                                        encoding: NSUTF8StringEncoding) else {
                                          continue
        }
        guard let protocolAttributes = String(CString:  property_getAttributes(`protocol`),
                                              encoding: NSUTF8StringEncoding) else { continue }
        string += "\t\(protocolName) : \(protocolAttributes)\n"
      }
    }

    return string
  }

  var currentClass: AnyClass = obj.dynamicType.self

  // dump the object's class
  print(descriptionForObject(currentClass, inherited: false))

  guard includeInheritance else { return }

  while let superclass = class_getSuperclass(currentClass) {
    print(descriptionForObject(superclass, inherited: true))
    currentClass = superclass
  }
  
}

public func pointerCast<T, U>(pointer: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<U> {
  return UnsafeMutablePointer<U>(pointer._rawValue)
}

public func pointerCast<T, U>(pointer: UnsafePointer<T>) -> UnsafePointer<U> {
  return UnsafePointer<U>(pointer._rawValue)
}

public func countLeadingZeros(i: Int64) -> Int { return numericCast(_countLeadingZeros(i)) }

public func countLeadingZeros(i: UInt) -> Int {
  let totalBits = UInt._sizeInBits
  for bit in (0 ..< totalBits).reverse() {
    guard i & (1 << bit) == 0 else {
      return numericCast(totalBits - (bit + 1))
    }
  }
  return numericCast(totalBits)
}

public func countLeadingZeros(i: UInt64) -> Int {
  // Split `i` into two so we don't overflow on conversion
  let leading = i >> 32
  var result = _countLeadingZeros(Int64(leading)) - 32
  guard result == 32 else { return 0 }
  let trailing = i & 0x00000000FFFFFFFF
  result += _countLeadingZeros(Int64(trailing)) - 32
  return numericCast(result)
}

/// Returns the next power of 2 that is equal to or greater than `x`
public func round2(x: Int) -> Int {
  return Int(_exp2(_ceil(_log2(Double(max(0, x))))))
}

/**
 No-op function intended to be used as a more noticeable way to force instantiation of lazy properties

 - parameter t: T
*/
@inline(never)
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

