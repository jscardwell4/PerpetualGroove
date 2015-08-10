//
//  MoonKit_Tests.swift
//  MoonKit Tests
//
//  Created by Jason Cardwell on 4/2/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import XCTest
import MoonKit

class MoonKit_Tests: XCTestCase {

  override class func initialize() {
    super.initialize()
    if self === MoonKit_Tests.self {
      LogManager.addTaggingTTYLogger()
      LogManager.addTaggingASLLogger()
    }
  }

  static let filePaths: [String] = {
    var filePaths: [String] = []
    if let bundlePath = NSUserDefaults.standardUserDefaults().stringForKey("XCTestedBundlePath"),
      bundle = NSBundle(path: bundlePath),
      example1JSONFilePath = bundle.pathForResource("example1", ofType: "json"),
      example2JSONFilePath = bundle.pathForResource("example2", ofType: "json"),
      example3JSONFilePath = bundle.pathForResource("example3", ofType: "json"),
      example4JSONFilePath = bundle.pathForResource("example4", ofType: "json"),
      example5JSONFilePath = bundle.pathForResource("example5", ofType: "json"),
      example6JSONFilePath = bundle.pathForResource("example6", ofType: "json")
    {
      filePaths.append(example1JSONFilePath)
      filePaths.append(example2JSONFilePath)
      filePaths.append(example3JSONFilePath)
      filePaths.append(example4JSONFilePath)
      filePaths.append(example5JSONFilePath)
      filePaths.append(example6JSONFilePath)
    }
    return filePaths
  }()

  func testJSONValueTypeSimple() {
    let string = "I am a string"
    let bool = true
    let number: NSNumber = 1
    let array = ["item1", "item2"]
    let object = ["key1": "value1", "key2": "value2"]

    let stringJSON = string.jsonValue
    switch stringJSON { case .String: break; default: XCTFail("unexpected enumeration value, expected 'JSON.String'") }
    XCTAssertEqual(stringJSON.rawValue, "\"I am a string\"", "unexpected stringValue")

    let boolJSON = bool.jsonValue
    switch boolJSON { case .Boolean: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Boolean'") }
    XCTAssertEqual(boolJSON.rawValue, "true", "unexpected stringValue")

    let numberJSON = number.jsonValue
    switch numberJSON { case .Number: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Number'") }
    XCTAssertEqual(numberJSON.rawValue, "1", "unexpected stringValue")

    let arrayJSON = JSONValue(array)
    if arrayJSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch arrayJSON { case .Array: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Array'") }
      XCTAssertEqual(arrayJSON.rawValue, "[\"item1\",\"item2\"]", "unexpected stringValue")
    }

    let objectJSON = JSONValue(object)
    if objectJSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch objectJSON! { case .Object: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Object'") }
      XCTAssertEqual(objectJSON!.rawValue, "{\"key1\":\"value1\",\"key2\":\"value2\"}", "unexpected stringValue")
    }

  }

  func testJSONValueTypeComplex() {
    let array1 = ["item1", 2]
    let array1String = "[\"item1\",2]"
    let array2 = ["item1", "item2", "item3"]
    let array2String = "[\"item1\",\"item2\",\"item3\"]"
    let array = [array1, array2, "item3", 4]
    let arrayString = "[\(array1String),\(array2String),\"item3\",4]"
    let dict1 = ["key1": "value1", "key2": 2]
    let dict1String = "{\"key1\":\"value1\",\"key2\":2}"
    let dict2 = ["key1": "value1", "key2": "value2"]
    let dict2String = "{\"key1\":\"value1\",\"key2\":\"value2\"}"
    let dict: OrderedDictionary<String, Any> = ["key1": dict1, "key2": dict2, "key3": "value3"]
    let dictString = "{\"key1\":\(dict1String),\"key2\":\(dict2String),\"key3\":\"value3\"}"
    let composite1: [Any] = [1, "two", array, dict]
    let composite1String = "[1,\"two\",\(arrayString),\(dictString)]"
    let composite2: OrderedDictionary<String, Any> = ["key1": 1, "key2": array, "key3": dict, "key4": "value4"]
    let composite2String = "{\"key1\":1,\"key2\":\(arrayString),\"key3\":\(dictString),\"key4\":\"value4\"}"

    let array1JSON = JSONValue(array1)
    if array1JSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch array1JSON! { case .Array: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Array")}
      XCTAssertEqual(array1JSON!.rawValue, array1String)
    }
    let array2JSON = JSONValue(array2)
    if array2JSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch array2JSON { case .Array: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Array")}
      XCTAssertEqual(array2JSON.rawValue, array2String)
    }
    let arrayJSON = JSONValue(array)
    if arrayJSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch arrayJSON! { case .Array: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Array")}
      XCTAssertEqual(arrayJSON!.rawValue, arrayString)
    }
    let dict1JSON = JSONValue(dict1)
    if dict1JSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch dict1JSON! { case .Object: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Object")}
      XCTAssertEqual(dict1JSON!.rawValue, dict1String)
    }
    let dict2JSON = JSONValue(dict2)
    if dict2JSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch dict2JSON! { case .Object: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Object")}
      XCTAssertEqual(dict2JSON!.rawValue, dict2String)
    }
    let dictJSON = JSONValue(dict)
    if dictJSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch dictJSON! { case .Object: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Object")}
      XCTAssertEqual(dictJSON!.rawValue, dictString)
    }
    let composite1JSON = JSONValue(composite1)
    if composite1JSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch composite1JSON! { case .Array: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Array")}
      XCTAssertEqual(composite1JSON!.rawValue, composite1String)
    }
    let composite2JSON = JSONValue(composite2)
    if composite2JSON == nil { XCTFail("unexpected nil value when converting to `JSONValue` type")}
    else {
      switch composite2JSON! { case .Object: break; default: XCTFail("unexpected enumeration value, expected 'JSON.Object")}
      XCTAssertEqual(composite2JSON!.rawValue, composite2String)
    }

  }

  func testJSONValueRawValue() {

    func rawValueTest(rawValue: String, expectedValue: JSONValue?) {
      if expectedValue == nil && expectedValue != .Null {
        XCTAssert(JSONValue(rawValue: rawValue) == nil, "unexpected json value resulted from raw value '\(rawValue)'")
      } else if let jsonValue = JSONValue(rawValue: rawValue), expected = expectedValue {
        XCTAssertEqual(jsonValue, expected)
      } else {
        XCTFail("expected to create a json value out of raw value '\(rawValue)'")
      }
    }

    rawValueTest("\"I am a string\"", .String("I am a string") as JSONValue?)
    rawValueTest("true", .Boolean(true) as JSONValue?)
    rawValueTest("1", .Number(1) as JSONValue?)
    rawValueTest("[\"item1\", \"item2\"]", .Array([.String("item1"), .String("item2")]) as JSONValue?)
    rawValueTest("{\"key1\": \"value1\", \"key2\": \"value2\"}", .Object(["key1": .String("value1"), "key2": .String("value2")]) as JSONValue?)
    rawValueTest("null", .Null as JSONValue?)
  }

  func testInflate() {
    let dict: [String:AnyObject] = ["key1": "value1", "key.two.has.paths": "value2"]
    let inflatedDict = inflated(dict)
    XCTAssert(inflatedDict["key1"] as? NSObject == dict["key1"] as? NSObject)
    XCTAssert(inflatedDict["key"] as? NSObject == ["two":["has":["paths":"value2"]]] as NSObject)
    XCTAssert(inflatedDict["key.two.has.paths"] == nil)
    let orderedDict: OrderedDictionary<String, Any> = ["key1": "value1", "key.two.has.paths": "value2"]
    let inflatedOrderedDict = orderedDict.inflated()
    XCTAssert(inflatedOrderedDict["key1"] as? NSObject == orderedDict["key1"] as? NSObject)
    XCTAssert((((inflatedOrderedDict["key"] as? OrderedDictionary<String, Any>)?["two"] as? OrderedDictionary<String, Any>)?["has"] as? OrderedDictionary<String, Any>)?["paths"] as? String == "value2")
    XCTAssert(inflatedOrderedDict["key.two.has.paths"] == nil)
  }

  func testJSONValueInflateKeyPaths() {
    if let object = JSONValue(["key1": "value1", "key.two.has.paths": "value2"]) {
      XCTAssert(String(prettyNil: object) == "{\"key1\":\"value1\",\"key.two.has.paths\":\"value2\"}")
      XCTAssert(String(prettyNil: object.inflatedValue) == "{\"key1\":\"value1\",\"key\":{\"two\":{\"has\":{\"paths\":\"value2\"}}}}")
    }
  }

  func testJSONSerialization() {
    let filePaths = self.dynamicType.filePaths
    var error: NSError?
    if let object = JSONSerialization.objectByParsingFile(filePaths[0], error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[0])'")
    {
      let expectedStringValue = String(contentsOfFile: filePaths[0], encoding: NSUTF8StringEncoding, error: nil)!
      XCTAssertEqual(object.rawValue, expectedStringValue, "unexpected result from parse")
    } else { XCTFail("file parse failed to create an object") }

    error = nil
    if let object = JSONSerialization.objectByParsingFile(filePaths[1], error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[1])'")
    {
      let expectedStringValue = String(contentsOfFile: filePaths[1], encoding: NSUTF8StringEncoding, error: nil)!
      XCTAssertEqual(object.rawValue, expectedStringValue, "unexpected result from parse")
    } else { XCTFail("file parse failed to create an object") }

    error = nil
    if let object = JSONSerialization.objectByParsingFile(filePaths[2], options: .InflateKeypaths, error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[2])'")
    {
      let expectedStringValue = String(contentsOfFile: filePaths[2], encoding: NSUTF8StringEncoding, error: nil)!
      XCTAssertNotEqual(object.rawValue, expectedStringValue, "unexpected result from parse")
    } else { XCTFail("file parse failed to create an object") }

    error = nil
    if let object = JSONSerialization.objectByParsingFile(filePaths[1], options: .InflateKeypaths, error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[1])'")
    {
      let expectedStringValue = String(contentsOfFile: filePaths[1], encoding: NSUTF8StringEncoding, error: nil)!
      XCTAssertNotEqual(object.rawValue, expectedStringValue, "unexpected result from parse")
    } else { XCTFail("file parse failed to create an object") }

    error = nil
    if let object = JSONSerialization.objectByParsingFile(filePaths[3], options: .InflateKeypaths, error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[3])'")
    {

    } else { XCTFail("file parse failed to create an object") }

    error = nil
    if let object = JSONSerialization.objectByParsingFile(filePaths[4], options: .InflateKeypaths, error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[4])'")
    {

    } else { XCTFail("file parse failed to create an object") }

    error = nil
    if let object = JSONSerialization.objectByParsingFile(filePaths[5], options: .InflateKeypaths, error: &error)
      where !MSHandleError(error, message: "trouble parsing file '\(filePaths[5])'")
    {
      if let objectValue = ObjectJSONValue(object), insetsValue = objectValue["title-edge-insets"]?.stringValue {
        XCTAssertEqual(insetsValue, "{20, 20, 20, 20}")
      } else { XCTFail("could not get object value out of object") }
    } else { XCTFail("file parse failed to create an object") }
  }

  func testJSONSerialization_DirectiveParsingPerformance() {
    if let bundlePath = NSUserDefaults.standardUserDefaults().stringForKey("XCTestedBundlePath"),
      bundle = NSBundle(path: bundlePath),
      filePath = bundle.pathForResource("Preset", ofType: "json")
    {
      var error: NSError?
      var string: String?
      measureBlock {
        string = JSONSerialization.stringByParsingDirectivesForFile(filePath, options: .InflateKeypaths, error: &error)
      }
      XCTAssertFalse(MSHandleError(error))
      XCTAssertNotNil(string)
      MSLogDebug("result with directives parsed…\n\(string)")
    } else { XCTFail("could not get file path for 'Preset.json'") }
  }

  func testJSONParser() {

    func parserTest(string: String, allowFragment: Bool, ignoreExcess: Bool, expectToFail: Bool) {
      let parser = JSONParser(string: string, allowFragment: allowFragment, ignoreExcess: ignoreExcess)
      var error: NSError?
      if expectToFail { XCTAssert(parser.parse(error: &error) == nil, "expected parse for '\(string)' to fail") }
      else if let object = parser.parse(error: &error) {
        MSHandleError(error, message: "parse failed for '\(string)'")
        XCTAssert(object.rawValue == string, "unexpected raw value")
      } else {
        MSHandleError(error, message: "parse failed")
        XCTFail("failed to parse json into an object")
      }
    }

    parserTest("{\"key\":\"value\"}", false, false, false)
    parserTest("[1,2,3]", false, false, false)
    parserTest("\"I am a fragment\"", false, false, true)
    parserTest("\"I am a fragment\"", true, false, false)
    parserTest("true", true, false, false)
    parserTest("null", true, false, false)
    parserTest("42", true, false, false)
    parserTest("{\"key\":\"value\"}", true, false, false)
    parserTest("[1,2,3]", true, false, false)
  }

  func testMSDictionary() {
    let ordered: OrderedDictionary<String, AnyObject> = ["key1":1, "key2": "value2"]
    let castToDict = ordered as MSDictionary
    XCTAssert(ordered.count == castToDict.count)
    let dict: MSDictionary = ["key1":1, "key2": "value2"]
    let castToOrdered = dict as OrderedDictionary<NSObject, AnyObject>
    XCTAssert(dict.count == castToOrdered.count)
  }

  func testOrderedDictionary() {

    var orderedDictionary: OrderedDictionary<String, Int> = ["one": 1]
    orderedDictionary["two"] = 2
    orderedDictionary.setValue(3, forKey: "three")
    XCTAssert(Array(orderedDictionary.keys) == ["one", "two", "three"])

    XCTAssert(Array(orderedDictionary.valuesForKeys(["one", "two"]).keys) == ["one", "two"])

    var mappedOrderedDictionary = orderedDictionary.map({($0, $1)})
    XCTAssert(mappedOrderedDictionary.values[0].0 == "one")
    XCTAssert(mappedOrderedDictionary.values[0].1 == 1)

    var filteredOrderedDictionary = orderedDictionary.filter({$1 % 2 == 1})
    XCTAssert(Array(filteredOrderedDictionary.keys) == ["one", "three"])

    var reversedOrderedDictionary = orderedDictionary.reverse()
    XCTAssert(Array(reversedOrderedDictionary.keys) == ["three", "two", "one"])

    let msDictionary = MSDictionary(values: [4, 5, 6], forKeys: ["four", "five", "six"])

    let fromMSDictionary = msDictionary as? OrderedDictionary<NSObject, AnyObject>
    XCTAssert(fromMSDictionary != nil)

    let fromOrderedDictionaryfromMSDictionary = fromMSDictionary?._bridgeToObjectiveC()
    XCTAssert(fromOrderedDictionaryfromMSDictionary != nil)
  }

  func testOrderdSet() {
    var orderedSet: OrderedSet<String> = []
    orderedSet.append("one")
    orderedSet.append("two")
    orderedSet.append("three")
    XCTAssert(Array(orderedSet) == ["one", "two", "three"])

    let nsOrderedSet = NSOrderedSet(array: ["four", "five", "six"])
    let fromNSOrderedSet = nsOrderedSet as? OrderedSet<String>
    XCTAssert(fromNSOrderedSet != nil)

    let fromOrderedSetFromNSOrderedSet = fromNSOrderedSet?._bridgeToObjectiveC()
    XCTAssert(fromOrderedSetFromNSOrderedSet != nil)
  }

  func testMemoizePerformance() {
    let fibonacci = memoize {
      (fibonacci: (Double) -> Double, n: Double) -> Double in
      n < 2 ? n : fibonacci(n-1) + fibonacci(n-2)
    }
    measureBlock {
      let result = fibonacci(7587)
    }
  }

}
