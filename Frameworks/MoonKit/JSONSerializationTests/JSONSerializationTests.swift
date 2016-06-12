//
//  JSONSerializationTests.swift
//  JSONSerializationTests
//
//  Created by Jason Cardwell on 6/12/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

final class JSONSerializationTests: XCTestCase {

  static let filePaths: [String] = {
    var filePaths: [String] = []
    let allBundles = NSBundle.allBundles()
    let bundle = NSBundle(forClass: JSONSerializationTests.self)
    for i in 1 ... 6 {
      guard let path = bundle.pathForResource("example\(i)", ofType: "json") else {
      fatalError("failed to locate resource 'example\(i).json'")
      }
      filePaths.append(path)
    }
    return filePaths
  }()

  func testJSONValueTypeSimple() {
    let string = "I am a string"
    let bool = true
    let number: NSNumber = 1
    let array = ["item1", "item2"]
    let object: [String:Any] = ["key1": "value1", "key2": "value2"]

    let stringJSON = string.jsonValue
    switch stringJSON {
      case .String: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.String'")
    }
    expect(stringJSON.rawValue) == "\"I am a string\""

    let boolJSON = bool.jsonValue
    switch boolJSON {
      case .Boolean: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Boolean'")
    }
    expect(boolJSON.rawValue) == "true"

    let numberJSON = number.jsonValue
    switch numberJSON {
      case .Number: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Number'")
    }
    expect(numberJSON.rawValue) == "1"

    let arrayJSON = JSONValue(array)
    switch arrayJSON {
      case .Array?: break
      default: XCTFail("unexpected nil value when converting to `JSONValue` type")
    }
    expect(arrayJSON?.rawValue) === "[\"item1\",\"item2\"]"

    let objectJSON = JSONValue(object)

    switch objectJSON {
      case .Object?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Object'")
    }
    expect(objectJSON?.rawValue) == "{\"key1\":\"value1\",\"key2\":\"value2\"}"


  }

  func testJSONValueTypeComplex() {
    let array1: [Any] = ["item1", 2]
    let array1String = "[\"item1\",2]"
    let array2 = ["item1", "item2", "item3"]
    let array2String = "[\"item1\",\"item2\",\"item3\"]"
    let array: [Any] = [array1, array2, "item3", 4]
    let arrayString = "[\(array1String),\(array2String),\"item3\",4]"
    let dict1: [String:JSONValueConvertible] = ["key1": "value1", "key2": 2]
    let dict1String = "{\"key1\":\"value1\",\"key2\":2}"
    let dict2: [String:JSONValueConvertible] = ["key1": "value1", "key2": "value2"]
    let dict2String = "{\"key1\":\"value1\",\"key2\":\"value2\"}"
    let dict: OrderedDictionary<String, Any> = ["key1": dict1, "key2": dict2, "key3": "value3"]
    let dictString = "{\"key1\":\(dict1String),\"key2\":\(dict2String),\"key3\":\"value3\"}"
    let composite1: [Any] = [1, "two", array, dict]
    let composite1String = "[1,\"two\",\(arrayString),\(dictString)]"
    let composite2: OrderedDictionary<String, Any> = ["key1": 1, "key2": array, "key3": dict, "key4": "value4"]
    let composite2String = "{\"key1\":1,\"key2\":\(arrayString),\"key3\":\(dictString),\"key4\":\"value4\"}"

    let array1JSON = JSONValue(array1)
    switch array1JSON {
      case .Array?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Array")
    }
    expect(array1JSON?.rawValue) == array1String


    let array2JSON = JSONValue(array2)
    switch array2JSON {
      case .Array?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Array")
    }
    expect(array2JSON?.rawValue) == array2String

    let arrayJSON = JSONValue(array)
    switch arrayJSON {
      case .Array?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Array")
    }
    expect(arrayJSON?.rawValue) == arrayString

    let dict1JSON = JSONValue(dict1)
    switch dict1JSON {
      case .Object?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Object")
    }
    expect(dict1JSON?.rawValue) == dict1String


    let dict2JSON = JSONValue(dict2)
    switch dict2JSON {
      case .Object?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Object")
    }
    expect(dict2JSON?.rawValue) == dict2String

    let dictJSON = JSONValue(dict)
    switch dictJSON {
      case .Object?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Object")
    }
    expect(dictJSON?.rawValue) == dictString

    let composite1JSON = JSONValue(composite1)
    switch composite1JSON {
      case .Array?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Array")
    }
    expect(composite1JSON?.rawValue) == composite1String


    let composite2JSON = JSONValue(composite2)
    switch composite2JSON {
      case .Array?: break
      default: XCTFail("unexpected enumeration value, expected 'JSON.Array")
    }
    expect(composite2JSON?.rawValue) == composite2String

  }

  func testJSONValueRawValue() {

    func rawValueTest(rawValue: String, _ expectedValue: JSONValue?) {
      if expectedValue == nil && expectedValue != .Null {
        XCTAssert(JSONValue(rawValue: rawValue) == nil,
                  "unexpected json value resulted from raw value '\(rawValue)'")
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
    rawValueTest("{\"key1\": \"value1\", \"key2\": \"value2\"}",
                 .Object(["key1": .String("value1"), "key2": .String("value2")]) as JSONValue?)
    rawValueTest("null", .Null as JSONValue?)
  }

  func testJSONValueInflateKeyPaths() {
    guard let object = JSONValue(["key1": "value1", "key.two.has.paths": "value2"]) else {
      XCTFail("Failed to create JSONValue")
      return
    }
    expect(String(object)) == "{\"key1\":\"value1\",\"key.two.has.paths\":\"value2\"}"
    expect(String(object.inflatedValue)) == "{\"key1\":\"value1\",\"key\":{\"two\":{\"has\":{\"paths\":\"value2\"}}}}"
  }

  func testJSONSerialization() {
    let filePaths = self.dynamicType.filePaths
    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[0])
      expect(object.rawValue) == (try String(contentsOfFile: filePaths[0]))
    } catch {
      XCTFail("trouble parsing file '\(filePaths[0])'\nerror: \(error)")
    }

    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[1])
      expect(object.rawValue) == (try String(contentsOfFile: filePaths[1]))
    } catch {
      XCTFail("trouble parsing file '\(filePaths[1])'\nerror: \(error)")
    }

    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[1], options: .InflateKeypaths)
      expect(object.rawValue) != (try String(contentsOfFile: filePaths[1]))
    } catch {
      XCTFail("trouble parsing file '\(filePaths[1])'\nerror: \(error)")
    }

    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[2], options: .InflateKeypaths)
      expect(object.rawValue) != (try String(contentsOfFile: filePaths[2]))
    } catch {
      XCTFail("trouble parsing file '\(filePaths[2])'\nerror: \(error)")
    }

    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[3], options: .InflateKeypaths)
      expect(object.rawValue) != (try String(contentsOfFile: filePaths[3]))
    } catch {
      XCTFail("trouble parsing file '\(filePaths[3])'\nerror: \(error)")
    }

    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[4], options: .InflateKeypaths)
      expect(object.rawValue) != (try String(contentsOfFile: filePaths[4]))
    } catch {
      XCTFail("trouble parsing file '\(filePaths[4])'\nerror: \(error)")
    }

    do {
      let object = try JSONSerialization.objectByParsingFile(filePaths[5], options: .InflateKeypaths)
      expect(object.rawValue) != (try String(contentsOfFile: filePaths[5]))
      let objectValue = ObjectJSONValue(object)
      let insetsValue = objectValue?["title-edge-insets"]?.stringValue
      expect(insetsValue) == "{20, 20, 20, 20}"
    } catch {
      XCTFail("trouble parsing file '\(filePaths[5])'\nerror: \(error)")
    }

  }

  func testJSONSerialization_DirectiveParsingPerformance() {
    guard let bundlePath = NSUserDefaults.standardUserDefaults().stringForKey("XCTestedBundlePath"),
      bundle = NSBundle(path: bundlePath),
      filePath = bundle.pathForResource("Preset", ofType: "json")
    else {
      XCTFail("Failed to get resources for test")
      return
    }
    measureBlock {
      do {
        _ = try JSONSerialization.stringByParsingDirectivesForFile(filePath, options: .InflateKeypaths)
      } catch {
        XCTFail("failed to parse '\(filePath)'\nerror: \(error)")
      }
    }
  }

  func testJSONParser() {

    func parserTest(string: String, _ allowFragment: Bool, _ ignoreExcess: Bool, _ expectToFail: Bool) {
      let parser = JSONParser(string: string, allowFragment: allowFragment, ignoreExcess: ignoreExcess)
      if expectToFail {
        do { _ = try parser.parse(); XCTFail("expected parse for '\(string)' to fail") } catch {}
      } else {
        do { let object = try parser.parse(); expect(object.rawValue) == string }
        catch { XCTFail("failed to parse '\(string)'") }
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

}
