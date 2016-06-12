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
    if !scanner.atEnd { print("scanner.string[idx..<]: \(scanner.string[scanner.string.startIndex.advancedBy(idx)..<])") }
    print("keyStack[\(keyStack.count)]: " + ", ".join(keyStack.map{"'\($0)'"}))
    print("contextStack[\(contextStack.count)]: " + ", ".join(contextStack.map{$0.rawValue}))
    print("objectStack[\(objectStack.count)]:\n" + "\n".join(objectStack.map{String($0)}))
    if error != nil {
      print("error: \(detailedDescriptionForError(error!, depth: 0))")
    }
  }

  private func internalError(reason: String?, underlyingError: NSError? = nil) -> NSError {
    let error = errorWithCode(.Internal, reason, underlyingError: underlyingError)
    dumpState(error)
    return error
  }

  private func syntaxError(reason: String?, underlyingError: NSError? = nil) -> NSError {
    let error = errorWithCode(.InvalidSyntax, reason, underlyingError: underlyingError)
    dumpState(error)
    return error
  }

  public init(string: String) {
    scanner = NSScanner.localizedScannerWithString(string) as! NSScanner
  }

  private func addValueToTopObject(value: PropertyListValue) throws {

    print("\(#function) value = \(value)")
    dumpState()

    if let context = contextStack.peek, object = objectStack.pop() {

      switch (context, object) {
      case (.Dictionary, .Dictionary(var d)):
        // Dictionary context with a dictionary on top of the stack
        guard let k = keyStack.pop() else {
          throw internalError("empty key stack")
        }
        d[k] = value
        objectStack.push(.Dictionary(d))

      case (.Array, .Array(let a)):
        // Array context with an array on top of the stack
        objectStack.push(.Array(a + [value]))

      case (_, .Dictionary(_)), // Some other context with a dictionary on top of the stack
           (_, .Array(_)):      // Some other context with an array on top of the stack
        throw internalError("invalid context-object pairing: \(context)-\(object)")

      case (.Dictionary, _), // Dictionary context without a dictionary on top of the stack
           (.Array, _):      // Array context without an array on top of the stack
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

  private func scanKey() throws -> String? {
    guard scanner.scanString("<key>", intoString: nil) else { return nil }
    var result: NSString?
    guard scanner.scanUpToString("</key>", intoString: &result) else { throw syntaxError("open key tag") }
    scanner.scanLocation += 6
    return result as? String
  }

  private func scanString() throws -> String? {
    guard scanner.scanString("<string>", intoString: nil) else { return nil }
    var result: NSString?
    guard scanner.scanUpToString("</string>", intoString: &result) else { throw syntaxError("open string tag") }
    scanner.scanLocation += 6
    return result as? String
  }

  private func scanInteger() throws -> Int? {
    guard scanner.scanString("<integer>", intoString: nil) else { return nil }
    var result: Int = 0
    guard scanner.scanInteger(&result) else { throw syntaxError("unable to scan an integer inside 'integer' tag") }
    guard scanner.scanString("</integer>", intoString: nil) else { throw syntaxError("open integer tag") }
    return result
  }

  private func scanReal() throws -> Double? {
    guard scanner.scanString("<real>", intoString: nil) else { return nil }
    var result: Double = 0
    guard scanner.scanDouble(&result) else { throw syntaxError("unable to scan a double inside 'real' tag") }
    guard scanner.scanString("</real>", intoString: nil) else { throw syntaxError("open real tag") }
    scanner.scanLocation += 6
    return result
  }

  private func scanBoolean() -> Bool? {
    if scanner.scanString("<true/>", intoString: nil) { return true }
    else if scanner.scanString("<false/>", intoString: nil) { return false }
    else { return nil }
  }

  private func parseDictionary() throws -> Bool {

    var success = false

    // Try to scan the opening punctuation for an object
    if scanner.scanString("<dict>", intoString: nil) {

      success = true
      objectStack.push(.Dictionary([:])) // Push a new dictionary onto the object stack
      contextStack.push(.Dictionary)     // Push dictionary context
      contextStack.push(.Key)            // Push key context

    }

    // Try to scan the closing punctuation for an object
    else if scanner.scanString("</dict>", intoString: nil) {

      // Pop context and object stacks
      guard let context = contextStack.pop(), object = objectStack.pop() else {
        throw internalError("one or both of context and object stacks is empty")
      }


      switch (context, object) {

        case (_, _) where contextStack.peek == .Start:
          // Replace start context with end context if we have completed the root object
          contextStack.pop()
          contextStack.push(.End)
          objectStack.push(object)
          success = true

        case (.Dictionary, .Dictionary(_)):
          do { try addValueToTopObject(object); success = true } catch { throw error }

        case (_, .Dictionary(_)):

          throw internalError("incorrect context popped off of stack")

        case (.Dictionary, _):
          throw internalError("dictionary absent from object stack")

        default:
          assert(false, "shouldn't this be unreachable?")
      }

    }

    // Otherwise assume we are in an open dictionary looking for more key-value pairs.
//    else if contextStack.peek == .Dictionary {
//      success = true
//      contextStack.push(.Key)
//    }

    return success
  }

  private func parseArray() throws -> Bool {

    var success = false

    // Try to scan the opening punctuation for an object
    if scanner.scanString("<array>", intoString: nil) {

      success = true
      objectStack.push(.Array([])) // Push a new array onto the object stack
      contextStack.push(.Array)    // Push the array context
      contextStack.push(.Value)    // Push the value context

    }

    // Try to scan the closing tag for an array
    else if scanner.scanString("</array>", intoString: nil) {

      // Pop context and object stacks
      guard let context = contextStack.pop(), object = objectStack.pop() else {
        throw internalError("one or both of context and object stacks is empty")
      }

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

    // Otherwise assume we are in an open array and looking for more values
//    else if contextStack.peek == .Array {
//      success = true
//      contextStack.push(.Value)
//    }


    return success
  }

  private func parseDate() throws -> Bool {
    return false
  }

  private func parseData() throws -> Bool {
    return false
  }

  private func parseValue() throws -> Bool {
    var success = false
    var value: PropertyListValue?

    guard contextStack.pop() == Context.Value else  {
      throw internalError("incorrect context popped off of stack")
    }

    // Try scanning a boolean
    if let boolean = scanBoolean() { value = .Boolean(boolean); success = true }

    // Try scanning an integer
    else if let integer = try scanInteger() { value = .Integer(integer); success = true }

    // Try scanning a real
    else if let real = try scanReal() { value = .Real(real); success = true }

    // Try scanning a string
    else if let string = try scanString() { value = .String(string); success = true }

    // Try scanning a dictionary
    else if try parseDictionary() { success = true }

    // Try scanning an array
    else if try parseArray() { success = true }

    // Otherwise we have failed to scan anything
    else { throw syntaxError("failed to parse value") }

    // If we have a value, add it to the top object in our stack
    if let v = value where success { try addValueToTopObject(v) }

    return success
  }

  private func parseKey() throws -> Bool {

    guard contextStack.pop() == .Key else {
      throw internalError("incorrect context popped off of stack")
    }

    guard contextStack.peek == .Dictionary else {
      throw internalError("context beneath 'key' should be 'dictionary'")
    }

    guard let key = try scanKey() else { return false }


    keyStack.push(key)
    contextStack.push(.Value)

    return true

  }

  public func parse() throws -> PropertyListValue {

    // Start in a known context
    contextStack.push(.Start)

    // Scan while we have input, completing the root object will exit the loop even if text remains
    scanLoop: while !scanner.atEnd {

      guard let context = contextStack.peek else {
        throw internalError("missing context on top of the stack")
      }

      print("scanLoop: context = \(context)")

      // Perform a context-appropriate action
      switch context {

        // To be valid, we must be able to scan an opening bracked of some kind
        case .Start:
          try scanXMLTag()
          try scanDOCTYPETag()
          try scanPlistOpenTag()

          guard try (parseDictionary() || parseArray()) else {
            throw syntaxError("root tag must be a dict/array")
          }

        // Try to scan a number, a boolean, null, the start of an object, or the start of an array
        case .Value: guard try parseValue() else { throw syntaxError("failed to scan value in 'Value' context") }

        // Try to scan a comma or curly bracket
        case .Dictionary: guard try parseDictionary() else { throw syntaxError("failed to scan dictionary in 'Dictionary' context") }

        // Try to scan a comma or square bracket
        case .Array: guard try parseArray() else { throw syntaxError("failed to scan array in 'Array' context") }

        // Try to scan a quoted string for use as a dictionary key
        case .Key: guard try parseKey() else { throw syntaxError("failed to scan key in 'Key' context") }

        // Just break out of scan loop
        case .End:
          guard scanner.scanString("</plist>", intoString: nil) else { throw syntaxError("open plist tag") }
          guard scanner.atEnd else { throw syntaxError("parse completed but scanner is not at end") }
          break scanLoop
      }

    }

    // If the root object ends the text we won't hit the `.End` case in our switch statement
    guard !objectStack.isEmpty else { throw syntaxError("failed to parse anything") }

    // Make sure we don't have more than one object left in the stack
    guard objectStack.count == 1 else { throw internalError("objects left in stack") }

    // Otherwise pop the root object from the stack
    return objectStack.pop()!

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

public enum PropertyListValue {
  case Boolean(Bool)
  case String(Swift.String)
  case Array(Swift.Array<PropertyListValue>)
  case Dictionary(Swift.Dictionary<Swift.String, PropertyListValue>)
  case Integer(Int)
  case Real(Double)
  case Date(NSDate)
  case Data(NSData)
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
