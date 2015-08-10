//
//  RegularExpression.swift
//  MSKit
//
//  Created by Jason Cardwell on 3/24/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//
// Adapted from GitHub Gist 'mattt / regex.swift'

import Foundation

public struct RegularExpression {

  // MARK: - Stored properties

  public let regex: NSRegularExpression?

  // MARK: - Computed properties

  public var pattern: String? { return regex?.pattern }
  public var options: NSRegularExpressionOptions? { return regex?.options }
  public var numberOfCaptureGroups: Int? { return regex?.numberOfCaptureGroups }

  // MARK: - Nested classes

  /** Struct to hold text checking result data */
  public struct Match: CustomStringConvertible {
    public let captures: [Capture?]
    public var range: Range<String.UTF16Index> {
      guard let fullCapture = captures[0] else {
        fatalError("all match values should have a capture representing overall match")
      }
      return fullCapture.range
    }
    public var string: String {
      guard let fullCapture = captures[0] else {
        fatalError("all match values should have a capture representing overall match")
      }
      return fullCapture.string
    }
    public let matchedString: String

    public var description: String { return "{\n\t" + "\n\t".join(compressed(captures).map { $0.description }) + "\n}" }

    /**
    Intialize by converting a text checking result given the string it checked

    - parameter result: NSTextCheckingResult
    - parameter string: String The string from which `result` was derived
    */
    public init?(result: NSTextCheckingResult, string: String) {
      guard result.range.location != NSNotFound else { return nil }
      matchedString = string
      captures = (0 ..< result.numberOfRanges).map { Capture(group: $0, range: result.rangeAtIndex($0), string: string) }
    }
  }

  /** Struct to hold text checking result data for a single capture group */
  public struct Capture: CustomStringConvertible {

    public let group: Int
    public let range: Range<String.UTF16Index>
    public let _string: String.UTF16View
    public let string: String

    public var description: String { return "{group: \(group), range: \(range), string: \(string)}" }

    /**
    Initialize by converting an `NSRange` obtained via an `NSTextCheckingResult`

    - parameter c: Int The capture group
    - parameter r: NSRange The range of the capture
    - parameter s: String The full string
    */
    public init?(group g: Int, range r: NSRange, string s: String) {
      guard r.location != NSNotFound && r.location + r.length <= s.utf16.count else { return nil }
      group = g

      let start = String.UTF16Index(r.location)
      let end = advance(start, r.length)
      range = start ..< end
      _string = s.utf16[range]
      guard let string = String(_string) else { return nil }
      self.string = string
    }

  }

  // MARK: - Initializers

  /**
  initWithPattern:options:

  - parameter pattern: String
  - parameter options: NSRegularExpressionOptions = nil
  */
  public init(pattern: String, options: NSRegularExpressionOptions = NSRegularExpressionOptions(rawValue: 0)) {
    do {
      regex = try NSRegularExpression(pattern: pattern, options: options)
    } catch  {
      regex = nil
    }
  }

  // MARK: - Private helpers

  /**
  options:

  - parameter anchored: Bool

  - returns: NSMatchingOptions
  */
  private func options(anchored anchored: Bool) -> NSMatchingOptions {
    return anchored ? [.Anchored] : []
  }

  /**
  range:overString:

  - parameter r: Range<String.Index>?
  - parameter s: String

  - returns: NSRange
  */
  private func range(r: Range<String.Index>?, overString s: String) -> NSRange {
    guard let r = r else { return s.range }

    return s.convertRange(r)
  }

  // MARK: - Confirming and counting matches

  /**
  Pattern matching method

  - parameter s: String
  - parameter a: Bool = false

  - returns: Bool
  */
  public func patternMatch(s: String, anchored a: Bool = false) -> Bool {
    guard let regex = regex else { return false }
    return regex.numberOfMatchesInString(s, options: options(anchored: a), range: s.range) > 0
  }

  /**
  numberOfMatchesInString:anchored:range:

  - parameter string: String
  - parameter anchored: Bool = false
  - parameter range: Range<String.Index>? = nil

  - returns: Int
  */
  public func numberOfMatchesInString(s: String, anchored a: Bool = false, range r: Range<String.Index>? = nil) -> Int {
    guard let regex = regex else { return 0 }
    return regex.numberOfMatchesInString(s, options: options(anchored: a), range: range(r, overString: s))
  }

  // MARK: - Obtaining matches

  /**
  match:anchored:range:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil

  - returns: [Match]
  */
  public func match(s: String, anchored a: Bool = false, range r: Range<String.Index>? = nil) -> [Match] {
    guard let regex = regex else { return [] }
    return regex.matchesInString(s, options: options(anchored: a), range: range(r, overString: s)).flatMap {
      Match(result: $0, string: s)
    }
  }

  /**
  firstMatch:anchored:range:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil

  - returns: Match?
  */
  public func firstMatch(string: String, anchored: Bool = false, range: Range<String.Index>? = nil) -> Match? {
    var result: Match?
    enumerateMatchesInString(string, anchored: anchored, range: range) { result = $0; $1 = true }
    return result
  }

  /**
  rangeOfFirstMatchInString:anchored:range:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil

  - returns: Range<String.Index>?
  */
  func rangeOfFirstMatchInString(s: String,
                        anchored a: Bool = false,
                           range r: Range<String.Index>? = nil) -> Range<String.Index>?
  {
    guard let regex = regex else { return nil }
    let firstMatchRange = regex.rangeOfFirstMatchInString(s, options: options(anchored: a), range: range(r, overString: s))
    guard firstMatchRange.location != NSNotFound else { return nil }
    return s.convertRange(firstMatchRange)
  }

  /**
  matchRanges:anchored:range:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil

  - returns: [Range<String.Index>]
  */
  func matchRanges(s: String, anchored a: Bool = false, range r: Range<String.Index>? = nil) -> [Range<String.UTF16Index>] {
    return match(s, anchored: a, range: r).map { $0.range }
  }

  // MARK: - Enumerating matches

  /**
  enumerateMatchesInString:anchored:range:usingBlock:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil
  - parameter block: (Match, inout Bool) -> Void
  */
  public func enumerateMatchesInString(s: String,
                              anchored a: Bool = false,
                                 range r: Range<String.Index>? = nil,
                            usingBlock block: (Match, inout Bool) -> Void)
  {
    guard let regex = regex else { return }

    regex.enumerateMatchesInString(s, options: options(anchored: a), range: range(r, overString: s)) {
      result, _, stop in

      guard let result = result else { return }

      var shouldStop = false
      if let match = Match(result: result, string: s) { block(match, &shouldStop) }
      if shouldStop { stop.memory = true }
    }

  }

  // MARK: - String manipulation

  /**
  stringByReplacingMatchesInString:anchored:range:withTemplate:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil
  - parameter t: String

  - returns: String
  */
  public func stringByReplacingMatchesInString(s: String,
                                      anchored a: Bool = false,
                                         range r: Range<String.Index>? = nil,
                                  withTemplate t: String) -> String
  {
    guard let regex = regex else { return s }
    return regex.stringByReplacingMatchesInString(s,
                                          options: options(anchored: a),
                                            range: range(r, overString: s),
                                     withTemplate: t)
  }

  /**
  stringByReplacingMatchesInString:anchored:range:usingBlock:

  - parameter s: String
  - parameter a: Bool = false
  - parameter r: Range<String.Index>? = nil
  - parameter block: (Match) -> String

  - returns: String
  */
  public func stringByReplacingMatchesInString(s: String,
                                      anchored a: Bool = false,
                                         range r: Range<String.Index>? = nil,
                                  usingBlock block: (Match) -> String) -> String
  {
    var result = s
    var offset = 0

    enumerateMatchesInString(s, anchored: a, range: r) {
      (match: Match, _) -> Void in

      let currentUTF16View = result.utf16

      let beforeCount = currentUTF16View.count

      let range = match.range
      let offsetRange = advance(range, amount: offset)

      let lhs = String(currentUTF16View[currentUTF16View.startIndex ..< offsetRange.startIndex])!
      let rhs = String(currentUTF16View[offsetRange.endIndex ..< currentUTF16View.endIndex])!
      let middle = block(match)

      result = lhs + middle + rhs

      let afterCount = result.utf16.count

      let delta = afterCount - beforeCount

      offset += delta

    }
    return result
  }

}

// MARK: - StringLiteralConvertible
extension RegularExpression: StringLiteralConvertible {
  public init(stringLiteral value: String) { self = RegularExpression(pattern: value) }
  public init(extendedGraphemeClusterLiteral value: String) { self = RegularExpression(pattern: value) }
  public init(unicodeScalarLiteral value: String) { self = RegularExpression(pattern: value) }
}

// MARK: - The pattern matching operator

/** pattern matching operator */
public func ~=(lhs: String, rhs: RegularExpression) -> Bool { return rhs ~= lhs }
public func ~=(lhs: RegularExpression, rhs: String) -> Bool { return lhs.patternMatch(rhs) }


// MARK: - String to RegularExpression operator

prefix operator ~/ {}

/** func for an operator that creates a regular expression from a string */
public prefix func ~/(pattern: String) -> RegularExpression { return RegularExpression(pattern: pattern) }
