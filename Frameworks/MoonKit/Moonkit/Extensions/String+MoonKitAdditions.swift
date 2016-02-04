//
//  String+MoonKitAdditions.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/15/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation


// finally, extend String to have a slicing subscript for these types:
extension String {
  public subscript(r: RangeStart<String.Index>) -> String {
    return self[r.start..<self.endIndex]
  }
  public subscript(r: RangeEnd<String.Index>) -> String {
    return self[self.startIndex..<r.end]
  }
}

extension String: StringValueConvertible {
  public var stringValue: String { return self }
}

extension String: ByteArrayConvertible {
  public var bytes: [Byte] { return Array(utf8) }
  public init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S) {
    self.init(Array(bytes))
  }

  public init(var _ bytes: [Byte]) {
    var i = bytes.count - 1
    guard i > 0 else { self = ""; return }
    while i > -1 && bytes[i] == Byte(0) { i-- }
    guard i > 0 else { self = ""; return }
    if i++ == bytes.count - 1 { bytes.append(Byte(0)) }
    bytes = Array(bytes[0 ..< i])
    guard let s = String(bytes: bytes, encoding: NSUTF8StringEncoding) else { self = ""; return }
    self = s
  }
}

public extension String {

  public static let Space:       String = " "
  public static let Newline:     String = "\n"
  public static let Tab:         String = "\t"
  public static let CommaSpace:  String = ", "
  public static let Quote:       String = "'"
  public static let DoubleQuote: String = "\""

  public var length: Int { return characters.count }
  public var count: Int { return characters.count }

  public init(@autoclosure subbingNil expr: () -> String?) { self = expr() ?? "nil" }

  /**
  init:radix:uppercase:var:

  - parameter v: T
  - parameter radix: Int
  - parameter uppercase: Bool = false
  - parameter pad: Int
  */
  public init<T : _SignedIntegerType>(_ v: T, radix: Int, uppercase: Bool = false, var pad: Int) {
    self = String(v, radix: radix, uppercase: uppercase)
    guard pad > 0 else { return }
    let s = v < 0 ? self[startIndex.advancedBy(1)..<] : self
    pad -= s.utf16.count
    guard pad > 0 else { return }
    let ps = String(count: pad, repeatedValue: Character("0")) + s
    self = v < 0 ? "-\(ps)" : ps
  }

  public init<S:SequenceType where S.Generator.Element == Byte>(hexBytes: S) {
    self = " ".join(hexBytes.map({String($0, radix: 16, uppercase: true, pad: 2)}))
  }
  public init<B:ByteArrayConvertible>(hexBytes: B) { self.init(hexBytes: hexBytes.bytes) }

  public init(binaryBytes: [Byte]) {
    var groups = binaryBytes.map({String(String($0, radix: 2, uppercase: true, pad: 4, group: 4).characters.reverse())})
    while groups.count > 1 && groups.first == "0000" { groups.removeAtIndex(0) }
    self = " ".join(groups)
  }
  public init<B:ByteArrayConvertible>(binaryBytes: B) { self.init(binaryBytes: binaryBytes.bytes) }

  public init(items: [Any], separator: String = " ", terminator: String = "\n") {
    self = items.map({String($0)}).joinWithSeparator(separator) + terminator
  }

  /**
  init:radix:uppercase:var:group:separator:

  - parameter v: T
  - parameter radix: Int
  - parameter uppercase: Bool = false
  - parameter pad: Int
  - parameter group: Int = 0
  - parameter separator: String = " "
  */
  public init<T : UnsignedIntegerType>(_ v: T,
                                       radix: Int,
                                       uppercase: Bool = false,
                                   var pad: Int,
                                       group: Int = 0,
                                       separator: String = " ")
  {
    self = String(v, radix: radix, uppercase: uppercase)
    guard pad > 0 else { return }
    pad -= utf16.count
    if pad > 0 { self = String(count: pad, repeatedValue: Character("0")) + self }
    guard group > 0 && characters.count > group else { return }
    let characterGroups = characters.segment(group, options: .PadFirstGroup(Character("0"))).flatMap({String($0)})
//    if dropLeadingEmptyGroups {
//      let emptyGroup = String(count: group, repeatedValue: Character("0"))
//      while characterGroups.count > 1 && characterGroups.first == emptyGroup { characterGroups.removeAtIndex(0) }
//    }
    self = separator.join(characterGroups)
  }

  public enum PadType { case Prefix, Suffix }

  /**
  pad:count:type:

  - parameter p: String
  - parameter count: Int
  - parameter type: PadType = .Suffix

  - returns: String
  */
  public func pad(p: String, count: Int, type: PadType = .Suffix) -> String {
    guard utf16.count < count else { return self }
    let padCount = p.utf16.count
    let delta = count - utf16.count
    guard padCount > 0 && delta > 0 else { return self }
    let padString = p * (delta / padCount)
    switch type {
      case .Prefix: return padString + self
      case .Suffix: return self + padString
    }
  }

  /** Returns the string converted to 'dash-case' */
  public var dashCaseString: String {
    guard !isDashCase else { return self }
    if isCamelCase { return "-".join(split(~/"(?<=\\p{Ll})(?=\\p{Lu})").map {$0.lowercaseString}) }
    else { return camelCaseString.dashCaseString }
  }

  /** Returns the string with the first character converted to lowercase */
  public var lowercaseFirst: String {
    guard count > 1 else { return lowercaseString }
    return self[startIndex ..< startIndex.advancedBy(1)].lowercaseString + self[startIndex.advancedBy(1) ..< endIndex]
  }

  /** Returns the string with the first character converted to uppercase */
  public var uppercaseFirst: String {
    guard count > 1 else { return uppercaseString }
    return self[startIndex ..< startIndex.advancedBy(1)].uppercaseString + self[startIndex.advancedBy(1) ..< endIndex]
  }

  /** Returns the string converted to 'camelCase' */
  public var camelCaseString: String {

    guard !isCamelCase else { return self }

    var components = split(~/"(?<=\\p{Ll})(?=\\p{Lu})|(?<=\\p{Lu})(?=\\p{Lu})|(\\p{Z}|\\p{P})")

    guard components.count > 0 else { return self }

    var i = 0
    while i < components.count && components[i] ~= ~/"^\\p{Lu}$" { components[i] = components[i++].lowercaseString }

    if i++ == 0 { components[0] = components[0].lowercaseFirst }

    for j in i ..< components.count where components[j] ~= ~/"^\\p{Ll}" { components[j] = components[j].uppercaseFirst }

    return "".join(components)
  }

  /** Returns the string converted to 'PascalCase' */
  public var pascalCaseString: String {
    guard !isPascalCase else { return self }
    return camelCaseString.sub(~/"^(\\p{Ll}+)", {$0.string.uppercaseString})
  }

  public var isQuoted: Bool { return hasPrefix("\"") && hasSuffix("\"") }
  public var quoted: String { return isQuoted ? self : "\"\(self)\"" }
  public var unquoted: String { return isQuoted ? self[1..<length - 1] : self }

  public var isCamelCase: Bool { return ~/"^\\p{Ll}+((?:\\p{Lu}|\\p{N})+\\p{Ll}*)*$" ~= self }
  public var isPascalCase: Bool { return ~/"^\\p{Lu}+((?:\\p{Ll}|\\p{N})+\\p{Lu}*)*$" ~= self }
  public var isDashCase: Bool { return ~/"^\\p{Ll}+(-\\p{Ll}*)*$" ~= self }

  public var baseNameExt: (baseName: String, ext: String) {
    let urlRepresentation = NSURL(fileURLWithPath: (self as NSString).lastPathComponent)
    let baseName = urlRepresentation.URLByDeletingPathExtension?.lastPathComponent ?? ""
    let ext = urlRepresentation.pathExtension ?? ""
    return (baseName: baseName, ext: ext)
  }

  public var pathEncoded: String { return urlPathEncoded }
  public var urlFragmentEncoded: String {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())
      ?? self
  }
  public var urlPathEncoded: String {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())
      ?? self
  }
  public var urlQueryEncoded: String {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
      ?? self
  }

  public var urlUserEncoded: String {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet())
      ?? self
  }

  public var pathDecoded: String { return self.stringByRemovingPercentEncoding ?? self }

  public var forwardSlashEncoded: String { return sub("/", "%2F") }
  public var forwardSlashDecoded: String { return sub("%2F", "/").sub("%2f", "/") }

  /**
  Returns the string with the specified amount of leading space in the form of space characters

  - parameter indent: Int
  - parameter preserveFirst: Bool = false

  - returns: String
  */
  public func indentedBy(indent: Int, preserveFirst: Bool = false, useTabs: Bool = false) -> String {
    let spacer = (useTabs ? "\t" : " ") * indent
    let result = "\n\(spacer)".join("\n".split(self))
    return preserveFirst ? result : spacer + result
  }

  public func appendToFile(file: String, separator: String = "\n") throws {
    let currentContent = try? String(contentsOfFile: file, encoding: NSUTF8StringEncoding)
    let unwrappedCurrentContent = currentContent ?? ""
    try "\(unwrappedCurrentContent)\(separator)\(self)".writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding)
  }

  /**
  Convenience for using variadic parameter to pass strings

  - parameter strings: String...

  - returns: String
  */
  public func join(strings: String...) -> String { return strings.joinWithSeparator(self) }
  public func join(strings: [String]) -> String { return strings.joinWithSeparator(self) }

  /**
  Convenience for joining string representations of `elements`

  - parameter elements: [T]

  - returns: String
  */
//  public func join<T>(elements: [T]) -> String { return join(elements.map { String($0) }) }

  /**
  Returns a string wrapped by `self`

  - parameter string: String

  - returns: String
  */
  public func wrap(string: String, separator: String? = nil) -> String {
    guard let separator = separator else { return self + string + self }
    guard let range = rangeOfString(separator) else { return self + string + self }

    return self[..<range.startIndex] + string + self[range.endIndex..<]
  }

  /**
  split:

  - parameter string: String

  - returns: [String]
  */
  public func split(string: String) -> [String] { return string.componentsSeparatedByString(self) }

  /**
  split:

  - parameter regex: RegularExpression

  - returns: [String]
  */
  public func split(regex: RegularExpression) -> [String] {
    let ranges = regex.matchRanges(self)
    guard ranges.count > 0 else { return [self] }
    return utf16.indices.split(ranges, noImplicitJoin: true).flatMap{String(utf16[$0])}
  }

  public var pathStack: Stack<String> { return Stack(Array((self as NSString).pathComponents.reverse())) }
  public var keypathStack: Stack<String> { return Stack(Array(".".split(self).reverse())) }

  // MARK: - Initializers

  public init(_ f: Float, precision: Int = -1) { self = String(Double(f), precision: precision) }

  public init(_ d: Double, precision: Int = -1) {

    switch precision {
    case Int.min ... -1:
      self = String(prettyNil: d)
    case 0:
      self = String(prettyNil: Int(d))
    default:
      let string = String(prettyNil: d)
      if let decimal = string.characters.indexOf(".") {
        self = ".".join(string[..<decimal], String(string[decimal.advancedBy(1)..<].characters.prefix(precision)))
      } else { self = string }
    }
  }

  public init<T>(prettyNil x: T?) {
    if let x = x { self = String(x) } else { self = "nil" }
  }

  /**
  initWithContentsOfFile:error:

  - parameter contentsOfFile: String
  - parameter error: NSErrorPointer = nil
  */
//  public init(contentsOfFile: String) throws {
//    let string = try NSString(contentsOfFile: contentsOfFile, encoding: NSUTF8StringEncoding)
//    self = string as String
//  }

  /**
  init:ofType:error:

  - parameter resource: String
  - parameter type: String?
  - parameter error: NSErrorPointer = nil
  */
  public init(contentsOfBundleResource resource: String, ofType type: String?) throws {
    let error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
    if let filePath = NSBundle.mainBundle().pathForResource(resource, ofType: type) {
      let string = try NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
      self = string as String
    } else { throw error }
  }

  /**
  initWithData:encoding:

  - parameter data: NSData
  - parameter encoding: UInt = NSUTF8StringEncoding
  */
//  public init?(data: NSData, encoding: UInt = NSUTF8StringEncoding) { 
//    if let s = NSString(data: data, encoding: encoding) as? String { self = s } else { return nil }
//  }

  /**
  subscript:

  - parameter i: Int

  - returns: Character
  */
  public subscript (i: Int) -> Character {
    get { return self[i < 0 ? endIndex.advancedBy(i) : startIndex.advancedBy(i)] }
    mutating set { replaceRange(i...i, with: [newValue]) }
  }

  /**
  replaceRange:with:

  - parameter subRange: Range<Int>
  - parameter newElements: C
  */
  public mutating func replaceRange<C : CollectionType where C.Generator.Element == Character>(subRange: Range<Int>, with newElements: C) {
    let range = indexRangeFromIntRange(subRange)
    replaceRange(range, with: newElements)
  }

  /**
  substringFromRange:

  - parameter range: Range<Int>

  - returns: String
  */
  public func substringFromRange(range: Range<Int>) -> String { return self[range] }
  

  /**
  subscript:

  - parameter r: Range<Int>

  - returns: String
  */
  public subscript (r: Range<Int>) -> String {
    get { return self[indexRangeFromIntRange(r)] }
    mutating set { replaceRange(r, with: newValue.characters) }
  }

  /**
  subscript:

  - parameter r: Range<UInt>

  - returns: String
  */
  public subscript (r: Range<UInt>) -> String {
    let rangeStart: String.Index = startIndex.advancedBy(Int(r.startIndex))
    let rangeEnd:   String.Index = startIndex.advancedBy(Int(r.startIndex.distanceTo(r.endIndex)))
    let range: Range<String.Index> = Range<String.Index>(start: rangeStart, end: rangeEnd)
    return self[range]
  }

  /**
  subscript:

  - parameter r: NSRange

  - returns: String
  */
  public subscript (r: NSRange) -> String {
    let rangeStart: String.Index = startIndex.advancedBy(r.location)
    let rangeEnd:   String.Index = startIndex.advancedBy(r.location + r.length)
    let range: Range<String.Index> = Range<String.Index>(start: rangeStart, end: rangeEnd)
    return self[range]
  }

  public var indices: Range<String.Index> { return characters.indices }
  public var range: NSRange { return NSRange(location: 0, length: utf16.count) }

  /**
  Convert a `Range` to an `NSRange` over the string

  - parameter r: Range<String.Index>

  - returns: NSRange
  */
  public func convertRange(r: Range<String.Index>) -> NSRange {
    let location = r.startIndex == startIndex ? 0 : self[startIndex ..< r.startIndex].utf16.count
    let length = self[r].count
    return NSRange(location: location, length: length)
  }

  /**
  Convert an `NSRange` to a `Range` over the string

  - parameter r: NSRange

  - returns: Range<String.Index>?
  */
  public func convertRange(r: NSRange) -> Range<String.Index>? {
    let range = Range(start: UTF16Index(_offset: r.location), end: UTF16Index(_offset: r.location).advancedBy(r.length))
    guard let lhs = String(utf16[utf16.startIndex ..< range.startIndex]), rhs = String(utf16[range]) else { return nil }
    let start = startIndex.advancedBy(lhs.startIndex.distanceTo(lhs.endIndex))
    let end = start.advancedBy(rhs.startIndex.distanceTo(rhs.endIndex))
    return start ..< end
  }

  /**
  indexRangeFromIntRange:

  - parameter range: Range<Int>

  - returns: Range<String
  */
  public func indexRangeFromIntRange(range: Range<Int>) -> Range<String.Index> {
    assert(false, "we shouldn't be using this")
    let s = startIndex.advancedBy(range.startIndex)
    let e = startIndex.advancedBy(range.endIndex)
    return Range<String.Index>(start: s, end: e)
  }

}

// MARK: - Operators

/** predicates */
prefix operator ∀ {}
public prefix func ∀(predicate: String) -> NSPredicate! { return NSPredicate(format: predicate) }
public prefix func ∀(predicate: (String, [AnyObject]?)) -> NSPredicate! {
  return NSPredicate(format: predicate.0, argumentArray: predicate.1)
}

/** func for an operator that creates a string by repeating a string multiple times */
public func *(lhs: String, var rhs: Int) -> String { var s = ""; while rhs-- > 0 { s += lhs }; return s }
