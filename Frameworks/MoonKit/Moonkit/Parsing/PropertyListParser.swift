//
//  PropertyListParser.swift
//  MoonKit
//
//  Created by Jason Cardwell on 6/10/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public final class PropertyListParser {

  public var string: String { return scanner.string }
  public var idx: Int { get { return scanner.scanLocation } set { scanner.scanLocation = newValue } }

  private var contextStack: Stack<Context> = []
  private var objectStack: Stack<PropertyListValue> = []
  private var keyStack: Stack<String> = []
  private let scanner: NSScanner

  /** Parser error domain and error codes */
  public static let ErrorDomain = "PropertyListParserErrorDomain"
  public enum ErrorCode: Int { case Internal, InvalidSyntax }

  private func errorWithCode(code: ErrorCode,
                             _ reason: String?,
                               underlyingError: NSError? = nil) -> NSError
  {

    // Create the info dictionary for our new error object
    var info = [NSObject:AnyObject]()

    // Check if we have been provided with an underlying error
    if let providedUnderlyingError = underlyingError {

      // Check if we just added an existing error to the dicitonary in the above if clause
      if let existingError = info[NSUnderlyingErrorKey] as? NSError {

        // Add them both as an array
        info[NSUnderlyingErrorKey] = [existingError, providedUnderlyingError]

      }

        // Otherwise just add the underlying error provided
      else {

        info[NSUnderlyingErrorKey] = providedUnderlyingError

      }

    }

    // Check if we are given a reason for the error
    if let failureReason = reason {

      // Add the reason to our dictionary with the current scanner location appended
      info[NSLocalizedFailureReasonErrorKey] = "\(failureReason) near location \(idx)"

    }

    // Finally, set the pointer's memory to a new error object
    return NSError(domain: PropertyListParser.ErrorDomain, code: code.rawValue, userInfo: info)
  }

  private func dumpState(error: NSError? = nil) {
    print("scanner.atEnd? \(scanner.atEnd)\nidx: \(idx)")
    print("keyStack[\(keyStack.count)]: " + ", ".join(keyStack.map{"'\($0)'"}))
    print("contextStack[\(contextStack.count)]: " + ", ".join(contextStack.map{$0.rawValue}))
    print("objectStack[\(objectStack.count)]:\n" + "\n".join(objectStack.map{String($0)}))
    if error != nil {
      print("error: \(detailedDescriptionForError(error!, depth: 0))")
    }
  }

  private func internalError(reason: String?, underlyingError: NSError? = nil) -> NSError {
    return errorWithCode(.Internal, reason, underlyingError: underlyingError)
  }

  private func syntaxError(reason: String?, underlyingError: NSError? = nil) -> NSError {
    return errorWithCode(.InvalidSyntax, reason, underlyingError: underlyingError)
  }

  public init(string: String) {
    scanner = NSScanner(string: string)
  }

  private func addValueToTopObject(value: PropertyListValue) throws {

    if let context = contextStack.peek, object = objectStack.pop() {

      switch (context, object) {
      case (.Dictionary, .Dictionary(var d)):
        if let k = keyStack.pop() {
          d[k] = value
          objectStack.push(.Dictionary(d))
        } else {
          throw internalError("empty key stack")
        }

      case (.Array, .Array(let a)):
        objectStack.push(.Array(a + [value]))

      case (_, .Dictionary(_)),
           (_, .Array(_)):
        throw internalError("invalid context-object pairing: \(context)-\(object)")

      case (.Dictionary, _),
           (.Array, _):
        throw internalError("missing object in stack to receive new value")

      default:
        assert(false, "should be unreachable?")
      }

    } else if contextStack.isEmpty && objectStack.isEmpty {
      throw internalError("empty stacks")
    } else if contextStack.isEmpty {
      throw internalError("empty context stack")
    } else if objectStack.isEmpty {
      throw internalError("empty object stack")
    } else {
      throw internalError("an unknown internal error has occurred")
    }
  }

  /**
  scanFor:into:discardingComments:skipping:error:

  - parameter type: ScanType
  - parameter object: AnyObject?
  - parameter discardingComments: Bool = true
  - parameter skipCharacters: NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

  - returns: Bool
  */
  private func scanFor(type: ScanType,
            inout into object: AnyObject?,
    discardingComments: Bool = true,
              skipping skipCharacters: NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()) -> Bool
  {
    var success = false

    let currentSkipCharacters = scanner.charactersToBeSkipped
    scanner.charactersToBeSkipped = skipCharacters
    defer { scanner.charactersToBeSkipped = currentSkipCharacters }

    switch type {

    case .CharactersFromSet(let set):
      var scannedString: NSString?
      success = scanner.scanCharactersFromSet(set, intoString: &scannedString)
      if success { object = scannedString }

    case .UpToCharactersFromSet(let set):
      var scannedString: NSString?
      success = scanner.scanUpToCharactersFromSet(set, intoString: &scannedString)
      if success { object = scannedString }

    case .Text (let text):
      var scannedString: NSString?
      success = scanner.scanString(text, intoString: &scannedString)
      if success { object = scannedString }

    case .UpToText(let text):
      var scannedString: NSString?
      success = scanner.scanUpToString(text, intoString: &scannedString)
      if success { object = scannedString }

    case .Number:
      var scannedNumber: Double = 0
      success = scanner.scanDouble(&scannedNumber)
      if success { object = scannedNumber }

    }

    return success
  }

  private func scanXMLTag() throws {
    guard scanner.scanString("<?xml", intoString: nil) else { throw syntaxError("missing xml tag") }
    guard scanner.scanUpToString("?>", intoString: nil) else { throw syntaxError("open xml tag") }
    scanner.scanLocation += 2
  }

  private func scanDOCTYPETag() throws {
    guard scanner.scanString("<!DOCTYPE", intoString: nil) else { throw syntaxError("missing DOCTYPE tag") }
    guard scanner.scanUpToString(">", intoString: nil) else { throw syntaxError("open DOCTYPE tag") }
    scanner.scanLocation += 1
  }

  private func scanPlistOpenTag() throws {
    guard scanner.scanString("<plist", intoString: nil) else { throw syntaxError("missing plist tag") }
    guard scanner.scanUpToString(">", intoString: nil) else { throw syntaxError("open plist tag") }
    scanner.scanLocation += 1
  }

  private func parseDictionary() throws -> Bool {
    return false
  }

  private func parseArray() throws -> Bool {

    var success = false
    var scannedObject: AnyObject?

    // Try to scan the opening punctuation for an object
    if scanFor(.Text("<array>"), into: &scannedObject) {

      success = true
      objectStack.push(.Array([])) // Push a new array onto the object stack
      contextStack.push(.Array)    // Push the array context
      contextStack.push(.Value)    // Push the value context

    }

      // Then try to scan a comma separating another object key value pair
    else if scanFor(.Text(","), into: &scannedObject) {
        success = true
        contextStack.push(.Value)
    }

      // Lastly, try to scan the closing punctuation for an object
    else if scanFor(.Text("</array>"), into: &scannedObject) {

          // Pop context and object stacks
          if let context = contextStack.pop(), object = objectStack.pop() {

            switch (context, object) {
            case (_, _) where contextStack.peek == .Start:
              // Replace start context with end context if we have completed the root object
              contextStack.pop()
              contextStack.push(.End)
              objectStack.push(object)
              success = true

            case (.Array, .Array(_)):
              do {
                try addValueToTopObject(object)
                success = true
              } catch {
                throw error
              }

            case (_, .Array(_)):
              throw internalError("incorrect context popped off of stack")

            case (.Array, _):
              throw internalError("array absent from object stack")

            default:
              assert(false, "shouldn't this be unreachable?")
            }
          }

          else {
            throw internalError("one or both of context and object stacks is empty")
      }

    }
    return success
  }

  private func parseValue() throws -> Bool {
    return false
  }

  private func parseInteger() throws -> Bool {
    return false
  }

  private func parseReal() throws -> Bool {
    return false
  }

  private func parseBoolean() throws -> Bool {
    return false
  }

  private func parseString() throws -> Bool {
    return false
  }

  private func parseKey() throws -> Bool {
    return false
  }

  public func parse() throws -> PropertyListValue {

    // Start in a known context
    contextStack.push(.Start)

    // Scan while we have input, completing the root object will exit the loop even if text remains
    scanLoop: while !scanner.atEnd {

      // We must have a context on top of the context stack
      if let context = contextStack.peek {

        // Perform a context-appropriate action
        switch context {

          // To be valid, we must be able to scan an opening bracked of some kind
          case .Start:

            var didParse = false
            do {
              try scanXMLTag()
              try scanDOCTYPETag()
              try scanPlistOpenTag()

              didParse = try parseDictionary()
              if !didParse { didParse = try parseArray() }
            } catch { throw error }
            if !didParse { throw syntaxError("root tag must be a dict/array") }

          // Try to scan a number, a boolean, null, the start of an object, or the start of an array
          case .Value: do { if !(try parseValue()) { break scanLoop } } catch { throw error }

          // Try to scan a comma or curly bracket
          case .Dictionary: do { if !(try parseDictionary()) { break scanLoop } } catch { throw error }

          // Try to scan a comma or square bracket
          case .Array: do { if !(try parseArray()) { break scanLoop } } catch { throw error }

          // Try to scan a quoted string for use as a dictionary key
          case .Key: do { if !(try parseKey()) { break scanLoop } } catch { throw error }

          // Just break out of scan loop
          case .End:
            if !(scanner.atEnd) { throw syntaxError("parse completed but scanner is not at end") }
            break scanLoop
        }

      }


    }

    // If the root object ends the text we won't hit the `.End` case in our switch statement
    if !objectStack.isEmpty {

      // Make sure we don't have more than one object left in the stack
      if objectStack.count > 1 { throw internalError("objects left in stack") }

      // Otherwise pop the root object from the stack
      else { return objectStack.pop()! }

    } else { throw syntaxError("failed to parse anything") }

  }

}

extension PropertyListParser {
  /** Enumeration for specifying a type of scan to perform */
  private enum ScanType {
    case CharactersFromSet     (NSCharacterSet)
    case UpToCharactersFromSet (NSCharacterSet)
    case Text                  (String)
    case UpToText              (String)
    case Number
  }
}

extension PropertyListParser {
  /** Enumeration to represent the current parser state */
  private enum Context: String {
    case Start  = "start"
    case Dictionary = "dictionary"
    case Value  = "value"
    case Array  = "array"
    case Key    = "key"
    case End    = "end"
  }
}

enum PropertyListTag: String {

  case xml
  case DOCTYPE
  case plist
  case dict
  case key
  case integer
  case string
  case array
  case real
  case `true`
  case `false`
  case null

  var regex: RegularExpression {
    switch self {
    case .xml:
      return ~/"^\\s*<\\?xml\\s+version\\s*=\\s*\"[0-9.]+\"\\s+encoding\\s*=\\s*\"[^\"]+\"\\s*\\?>\\s*"
    case .DOCTYPE:
      return ~/"^\\s*<!DOCTYPE\\s+plist\\s+PUBLIC\\s+\"-//Apple//DTD PLIST 1.0//EN\"\\s+\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"\\s*>\\s*"
    case .plist:
      return ~/"^\\s*<plist\\s+version\\s*=\\s*\"[0-9.]+\"\\s*>((?:.|\\s)*)</plist>\\s*$"
    case .dict:
      return ~/"^\\s*<dict>((?:(?:.|\\s)(?!=<dict>))*)</dict>\\s*"
    case .key:
      return ~/"^\\s*<key>((?:.|\\s)*?)</key>\\s*"
    case .integer:
      return ~/"^\\s*<integer>((?:.|\\s)*)</integer>\\s*"
    case .string:
      return ~/"^\\s*<string>((?:.|\\s)*?)</string>\\s*"
    case .array:
      return ~/"^\\s*<array>((?:.|\\s)*)</array>\\s*"
    case .real:
      return ~/"^\\s*<real>((?:.|\\s)*?)</real>\\s*"
    case .`true`:
      return ~/"^\\s*<true\\s*/>\\s*"
    case .`false`:
      return ~/"^\\s*<false\\s*/>\\s*"
    case .null:
      return ~/"^\\s*<null\\s*/>\\s*"
    }
  }

}

public enum PropertyListValue {
  case Boolean(Bool)
  case String(Swift.String)
  case Array(Swift.Array<PropertyListValue>)
  case Dictionary(Swift.Dictionary<Swift.String, PropertyListValue>)
  case Integer(Int)
  case Real(Double)
  case Null
}

func parseTag(tag: PropertyListTag, input: String) -> (match: Bool, tagContent: String?, remainingInput: String?) {
  guard let match = tag.regex.match(input).first else { return (false, nil, input) }
  let tagContent = match[1]?.string
  let remainingInput = input[match.range.endIndex.samePositionIn(input)!..<]
  return (true, tagContent, remainingInput.isEmpty ? nil : remainingInput)
}

enum PropertyListPrimitive {
  case String (Swift.String)
  case Int (Swift.Int)
  case Double (Swift.Double)
  case Bool (Swift.Bool)
  case None
}

func parsePrimitive(input: String) -> (match: Bool, primitive: PropertyListPrimitive, remainingInput: String?) {
//  print("\n\n\(#function)  input = '\(input)'")

  let result: (Bool, PropertyListPrimitive, String?)
//  defer {
//    print("\(#function)  result: \(result)")
//  }

  var (match, tagContent, remainingInput) = parseTag(.string, input: input)
  guard !match else {
    guard let stringContent = tagContent else {
      // Throw error
      fatalError("invalid string tag")
    }
    result = (true, PropertyListPrimitive.String(stringContent), remainingInput)
    return result
  }
  (match, tagContent, remainingInput) = parseTag(.integer, input: input)
  guard !match else {
    guard let integerContent = tagContent, integer = Int(integerContent) else {
      // Throw error
      fatalError("invalid integer tag")
    }
    result = (true, PropertyListPrimitive.Int(integer), remainingInput)
    return result
  }
  (match, tagContent, remainingInput) = parseTag(.real, input: input)
  guard !match else {
    guard let realContent = tagContent, real = Double(realContent) else {
      // Throw error
      fatalError("invalid integer tag")
    }
    result = (true, PropertyListPrimitive.Double(real), remainingInput)
    return result
  }

  (match, tagContent, remainingInput) = parseTag(.`true`, input: input)
  guard !match else {
    result = (true, PropertyListPrimitive.Bool(true), remainingInput)
    return result
  }

  (match, tagContent, remainingInput) = parseTag(.`false`, input: input)
  guard !match else {
    result = (true, PropertyListPrimitive.Bool(false), remainingInput)
    return result
  }

  result = (false, PropertyListPrimitive.None, input)
  return result
}

func parseValue(input: String) -> (match: Bool, value: PropertyListValue, remainingInput: String?) {
//  print("\n\n\(#function)  input = '\(input)'")

  let result: (Bool, PropertyListValue, String?)
//  defer {
//    print("\(#function)  result: \(result)")
//  }

  let primitiveParse = parsePrimitive(input)
  guard !primitiveParse.match else {
    let remainingInput = primitiveParse.remainingInput != nil && primitiveParse.remainingInput!.isEmpty ? nil : primitiveParse.remainingInput
    switch primitiveParse.primitive {
      case .String(let s): result = (true, .String(s),  remainingInput)
      case .Int(let i):    result = (true, .Integer(i), remainingInput)
      case .Double(let d): result = (true, .Real(d),    remainingInput)
      case .Bool(let b):   result = (true, .Boolean(b), remainingInput)
      case .None:          result = (true, .Null,       remainingInput)
    }
    return result
  }

  let arrayParse = parseTag(.array, input: input)
  guard !arrayParse.match else {
    guard let arrayContent = arrayParse.tagContent else {
      // Throw error
      fatalError("invalid array tag")
    }
    let array = parseArrayContent(arrayContent)
    let remainingInput = arrayParse.remainingInput != nil && arrayParse.remainingInput!.isEmpty ? nil : arrayParse.remainingInput
    result = (true, .Array(array), remainingInput)
    return result
  }

  let dictParse = parseTag(.dict, input: input)
  guard dictParse.match else {
    // Throw error
    fatalError("failed to match primitive, array or dict inside array content")
  }
  guard let dictContent = dictParse.tagContent else {
    // Throw error
    fatalError("invalid dict tag")
  }
  let dict = parseDictContent(dictContent)
  let remainingInput = dictParse.remainingInput != nil && dictParse.remainingInput!.isEmpty ? nil : dictParse.remainingInput
  result = (true, .Dictionary(dict), remainingInput)
  return result
}

func parseArrayContent(input: String) -> [PropertyListValue] {
//  print("\n\n\(#function)  input = '\(input)'")

  var result: [PropertyListValue] = []

  var remainingInput: String? = input
  while let currentInput = remainingInput {
    let (match, value, remainingInputʹ) = parseValue(currentInput)
    guard match else {
      // Throw error
      fatalError("failed to parse value where a value is expected")
    }

    result.append(value)
    remainingInput = remainingInputʹ
    if remainingInput != nil && remainingInput!.isEmpty { remainingInput = nil }
  }

//  print("\(#function)  result = \(result)")
  return result
}

func parseDictContent(input: String) -> [String:PropertyListValue] {
//  print("\n\n\(#function)  input = '\(input)'")

  var result: [String:PropertyListValue] = [:]

  var remainingInput: String? = input
  while let currentInput = remainingInput {
//    print("\n\ncurrentInput = '\(currentInput)'")
    let keyParse = parseTag(.key, input: currentInput)
    guard keyParse.match, let key = keyParse.tagContent, remainingInputʹ = keyParse.remainingInput else {
      // Throw error
      fatalError("invalid key tag or key tag without a matching value")
    }
    let (match, value, remainingInputʺ) = parseValue(remainingInputʹ)
    guard match else {
      // Throw error 
      fatalError("failed to parse value where value is expected")
    }
    result[key] = value
    remainingInput = remainingInputʺ
    if remainingInput != nil && remainingInput!.isEmpty { remainingInput = nil }
  }

//  print("\(#function)  result = \(result)")

  return result
}

func parsePropertyList(list: String) -> PropertyListValue {
//  print("\n\n\(#function)  list = '\(list)'")

  var (match, tagContent, remainingInput) = parseTag(.xml, input: list)

  guard match && remainingInput != nil else {
    // Throw error
    return .Null
  }

  (match, tagContent, remainingInput) = parseTag(.DOCTYPE, input: remainingInput!)
  guard match && remainingInput != nil else {
    // Throw error
    return .Null
  }

  (match, tagContent, remainingInput) = parseTag(.plist, input: remainingInput!)
  guard match, let plistContent = tagContent else {
    // Throw error
    return .Null
  }

  (match, tagContent, remainingInput) = parseTag(.dict, input: plistContent)

  guard match, let dictContent = tagContent else {
    (match, tagContent, remainingInput) = parseTag(.array, input: plistContent)
    guard match, let arrayContent = tagContent else {
      // Throw error
      return .Null
    }

//    print("arrayContent: \(arrayContent)")

    let array = parseArrayContent(arrayContent)
    return .Array(array)
  }

//  print(dictContent)
  let dict = parseDictContent(dictContent)
  return .Dictionary(dict)
}

/*
 
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Subtests</key>
	<array>
		<dict>
			<key>PerformanceMetrics</key>
			<array>
				<dict>
					<key>BaselineAverage</key>
					<real>0.15525</real>
					<key>BaselineName</key>
					<string>Local Baseline</string>
					<key>Identifier</key>
					<string>com.apple.XCTPerformanceMetric_WallClockTime</string>
					<key>MaxPercentRegression</key>
					<integer>10</integer>
					<key>MaxPercentRelativeStandardDeviation</key>
					<integer>10</integer>
					<key>MaxRegression</key>
					<real>0.10000000000000001</real>
					<key>MaxStandardDeviation</key>
					<real>0.10000000000000001</real>
					<key>Measurements</key>
					<array>
						<real>0.11162454600000001</real>
						<real>0.18490079000000001</real>
						<real>0.16682532999999999</real>
						<real>0.166004442</real>
						<real>0.16396802799999999</real>
						<real>0.16736647800000001</real>
						<real>0.16668433599999999</real>
						<real>0.16198454400000001</real>
						<real>0.16385017700000001</real>
						<real>0.15839913</real>
					</array>
					<key>Name</key>
					<string>Time</string>
					<key>UnitOfMeasurement</key>
					<string>seconds</string>
				</dict>
			</array>
			<key>TestIdentifier</key>
			<string>OrderedDictionaryPerformanceTests/testInsertValueForKeyPerformance()</string>
			<key>TestName</key>
			<string>testInsertValueForKeyPerformance()</string>
			<key>TestObjectClass</key>
			<string>IDESchemeActionTestSummary</string>
			<key>TestStatus</key>
			<string>Success</string>
			<key>TestSummaryGUID</key>
			<string>6861729D-EA6D-44A3-A49B-97BEF04F4F27</string>
		</dict>
		<dict>
			<key>PerformanceMetrics</key>
			<array>
				<dict>
					<key>BaselineAverage</key>
					<real>0.38169999999999998</real>
					<key>BaselineName</key>
					<string>May 25, 2016, 7:20:52 AM</string>
					<key>Identifier</key>
					<string>com.apple.XCTPerformanceMetric_WallClockTime</string>
					<key>MaxPercentRegression</key>
					<integer>10</integer>
					<key>MaxPercentRelativeStandardDeviation</key>
					<integer>10</integer>
					<key>MaxRegression</key>
					<real>0.10000000000000001</real>
					<key>MaxStandardDeviation</key>
					<real>0.10000000000000001</real>
					<key>Measurements</key>
					<array>
						<real>0.39553471200000001</real>
						<real>0.39544263400000002</real>
						<real>0.40088641699999999</real>
						<real>0.40136458000000003</real>
						<real>0.40363773200000003</real>
						<real>0.39683162999999999</real>
						<real>0.39860546000000002</real>
						<real>0.39481618200000002</real>
						<real>0.402274309</real>
						<real>0.39425138599999998</real>
					</array>
					<key>Name</key>
					<string>Time</string>
					<key>UnitOfMeasurement</key>
					<string>seconds</string>
				</dict>
			</array>
			<key>TestIdentifier</key>
			<string>OrderedDictionaryPerformanceTests/testOverallPerformance()</string>
			<key>TestName</key>
			<string>testOverallPerformance()</string>
			<key>TestObjectClass</key>
			<string>IDESchemeActionTestSummary</string>
			<key>TestStatus</key>
			<string>Success</string>
			<key>TestSummaryGUID</key>
			<string>3285FC19-4502-4325-B48B-DC3262B73303</string>
		</dict>
		<dict>
			<key>FailureSummaries</key>
			<array>
				<dict>
					<key>FileName</key>
					<string>/Users/Moondeer/Projects/PerpetualGroove/Frameworks/MoonKit/OrderedDictionaryTests/OrderedDictionaryPerformanceTests.swift</string>
					<key>LineNumber</key>
					<integer>41</integer>
					<key>Message</key>
					<string>failed: Time average is 569% worse (max allowed: 10%).</string>
					<key>PerformanceFailure</key>
					<true/>
				</dict>
			</array>
			<key>PerformanceMetrics</key>
			<array>
				<dict>
					<key>BaselineAverage</key>
					<real>0.09171</real>
					<key>BaselineName</key>
					<string>Local Baseline</string>
					<key>Identifier</key>
					<string>com.apple.XCTPerformanceMetric_WallClockTime</string>
					<key>MaxPercentRegression</key>
					<integer>10</integer>
					<key>MaxPercentRelativeStandardDeviation</key>
					<integer>10</integer>
					<key>MaxRegression</key>
					<real>0.10000000000000001</real>
					<key>MaxStandardDeviation</key>
					<real>0.10000000000000001</real>
					<key>Measurements</key>
					<array>
						<real>0.61691075299999998</real>
						<real>0.61683504</real>
						<real>0.61665684799999998</real>
						<real>0.61645478399999998</real>
						<real>0.61712898400000005</real>
						<real>0.61524738599999995</real>
						<real>0.60780837700000001</real>
						<real>0.605083174</real>
						<real>0.611933108</real>
						<real>0.61072429299999997</real>
					</array>
					<key>Name</key>
					<string>Time</string>
					<key>UnitOfMeasurement</key>
					<string>seconds</string>
				</dict>
			</array>
			<key>TestIdentifier</key>
			<string>OrderedDictionaryPerformanceTests/testRemoveValueForKeyPerformance()</string>
			<key>TestName</key>
			<string>testRemoveValueForKeyPerformance()</string>
			<key>TestObjectClass</key>
			<string>IDESchemeActionTestSummary</string>
			<key>TestStatus</key>
			<string>Failure</string>
			<key>TestSummaryGUID</key>
			<string>E2AA730B-3D2F-40EB-9E77-7728726AD518</string>
		</dict>
	</array>
	<key>TestIdentifier</key>
	<string>OrderedDictionaryPerformanceTests</string>
	<key>TestName</key>
	<string>OrderedDictionaryPerformanceTests</string>
	<key>TestObjectClass</key>
	<string>IDESchemeActionTestSummaryGroup</string>
</dict>
</plist>

*/
