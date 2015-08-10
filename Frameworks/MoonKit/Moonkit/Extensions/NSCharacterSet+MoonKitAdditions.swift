//
//  NSCharacterSet+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

extension UInt16 {

  /**
  init:

  - parameter character: Character
  */
  public init?(_ character: Character) {
    let characterString = String(character)
    if characterString.utf16.count == 1 { self = Array(characterString.utf16).first! }
    else { return nil }
  }

}

extension UnicodeScalar {

  /**
  init:

  - parameter character: Character
  */
  public init(_ character: Character) { self = Array(String(character).unicodeScalars).first! }

}


extension NSCharacterSet {

  /**
  initWithCharacter:

  - parameter character: Character
  */
  public convenience init(character: Character) { self.init(charactersInString:String(character)) }

  public class var emptyCharacterSet: NSCharacterSet { return NSCharacterSet(charactersInString:"") }

}

/**
Get inverted character set

- parameter lhs: NSCharacterSet

- returns: NSCharacterSet The inverted set
*/
public prefix func ~(lhs: NSCharacterSet) -> NSCharacterSet { return lhs.invertedSet }

/**
Combine two character sets

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet

- returns: NSCharacterSet
*/
public func +(lhs: NSCharacterSet, rhs: NSCharacterSet) -> NSCharacterSet {
  var lbytes = [UInt8](count: 8192, repeatedValue: 0)
  lhs.bitmapRepresentation.getBytes(&lbytes, length: lbytes.capacity)
  var rbytes = [UInt8](count: 8192, repeatedValue: 0)
  rhs.bitmapRepresentation.getBytes(&rbytes, length: rbytes.capacity)

  let bytes = [(UInt8, UInt8)](Zip2Sequence<[UInt8], [UInt8]>(lbytes, rbytes)).map {$0 | $1}
  return NSCharacterSet(bitmapRepresentation: NSData(bytes:bytes, length:bytes.count))
}
public func +=(inout lhs: NSCharacterSet, rhs: NSCharacterSet) { lhs = lhs + rhs }
public func ∪(lhs: NSCharacterSet, rhs: NSCharacterSet) -> NSCharacterSet { return lhs + rhs }
public func ∪=(inout lhs: NSCharacterSet, rhs: NSCharacterSet) { lhs = lhs ∪ rhs }

public func ~=(lhs: NSCharacterSet, rhs: Character) -> Bool {
  let s = String(rhs).utf16
  let c = s[s.startIndex]
  return lhs ~= c
}

public func ~=(lhs: NSCharacterSet, rhs: unichar) -> Bool {
  return lhs.characterIsMember(rhs)
}

/**
Subtract rhs character set members from lhs character set

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet

- returns: NSCharacterSet
*/
public func -(lhs: NSCharacterSet, rhs: NSCharacterSet) -> NSCharacterSet {
  var lbytes = [UInt8](count: 8192, repeatedValue: 0)
  lhs.bitmapRepresentation.getBytes(&lbytes, length: lbytes.capacity)
  var rbytes = [UInt8](count: 8192, repeatedValue: 0)
  rhs.bitmapRepresentation.getBytes(&rbytes, length: rbytes.capacity)

  let bytes = [(UInt8, UInt8)](Zip2Sequence<[UInt8], [UInt8]>(lbytes, rbytes)).map {$0 & ~$1}
  return NSCharacterSet(bitmapRepresentation: NSData(bytes:bytes, length:bytes.count))
}
public func -=(inout lhs: NSCharacterSet, rhs: NSCharacterSet) { lhs = lhs - rhs }
public func ∖(lhs: NSCharacterSet, rhs: NSCharacterSet) -> NSCharacterSet { return lhs - rhs }
public func ∖(inout lhs: NSCharacterSet, rhs: NSCharacterSet) { lhs = lhs ∖ rhs }

/**
Intersection of two character sets

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet

- returns: NSCharacterSet
*/
public func ∩(lhs: NSCharacterSet, rhs: NSCharacterSet) -> NSCharacterSet {
  var lbytes = [UInt8](count: 8192, repeatedValue: 0)
  lhs.bitmapRepresentation.getBytes(&lbytes, length: lbytes.capacity)
  var rbytes = [UInt8](count: 8192, repeatedValue: 0)
  rhs.bitmapRepresentation.getBytes(&rbytes, length: rbytes.capacity)

  let bytes = [(UInt8, UInt8)](Zip2Sequence<[UInt8], [UInt8]>(lbytes, rbytes)).map {$0 & $1}
  return NSCharacterSet(bitmapRepresentation: NSData(bytes:bytes, length:bytes.count))
}
public func ∩=(inout lhs: NSCharacterSet, rhs: NSCharacterSet) { lhs = lhs ∩ rhs }

/**
Returns true if lhs is a superset of rhs

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet
- returns: Bool
*/
public func ⊃(lhs:NSCharacterSet, rhs:NSCharacterSet) -> Bool { return lhs.isSupersetOfSet(rhs) }

/**
Returns true if lhs is not a superset of rhs

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet
- returns: Bool
*/
public func ⊅(lhs: NSCharacterSet, rhs: NSCharacterSet) -> Bool { return !(lhs ⊃ rhs) }

/**
Returns true if lhs is a subset of rhs

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet
- returns: Bool
*/
public func ⊂(lhs: NSCharacterSet, rhs: NSCharacterSet) -> Bool { return rhs ⊃ lhs }

/**
Returns true if lhs is not a subset of rhs

- parameter lhs: NSCharacterSet
- parameter rhs: NSCharacterSet
- returns: Bool
*/
public func ⊄(lhs:NSCharacterSet, rhs:NSCharacterSet) -> Bool { return rhs ⊅ lhs }

/**
Returns true if character is a member of character set

- parameter lhs: Character
- parameter rhs: NSCharacterSet

- returns: Bool
*/
public func ∈(lhs: Character, rhs: NSCharacterSet) -> Bool {
  if let unichar = UInt16(lhs) { return rhs.characterIsMember(unichar) }
  else { return rhs.longCharacterIsMember(UnicodeScalar(lhs).value) }
}

/**
Returns true if character is not a member of character set

- parameter lhs: Character
- parameter rhs: NSCharacterSet

- returns: Bool
*/
public func ∉(lhs: Character, rhs: NSCharacterSet) -> Bool { return !(lhs ∈ rhs) }

/**
Returns true if character set has character as a member

- parameter lhs: NSCharacterSet
- parameter rhs: Character

- returns: Bool
*/
public func ∋(lhs: NSCharacterSet, rhs: Character) -> Bool { return rhs ∈ lhs }

/**
Returns true if character set does not have character as a member

- parameter lhs: NSCharacterSet
- parameter rhs: Character

- returns: Bool
*/
public func ∌(lhs: NSCharacterSet, rhs: Character) -> Bool { return rhs ∉ lhs }

