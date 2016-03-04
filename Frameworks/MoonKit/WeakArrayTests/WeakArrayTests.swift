//
//  WeakArrayTests.swift
//  WeakArrayTests
//
//  Created by Jason Cardwell on 3/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
@testable import MoonKit

func XCTAssertEqualObjects<T:AnyObject>(@autoclosure expression1: () throws -> T?,
                                        @autoclosure _ expression2: () throws -> T?,
                                        @autoclosure _ message: () -> String = "",
                                                       file: StaticString = #file,
                                                       line: UInt = #line)
{
  let result1 = try? expression1() ?? nil
  let result2 = try? expression2() ?? nil

  let message = message()
  if let result1 = result1, result2 = result2 where result1 === result2 { return }
  let result1String = "\(result1)", result2String = "\(result2)"
  let prefix = "'\(result1String)' !== '\(result2String)'\(message.isEmpty ? "" : ": "))"
  XCTFail("\(prefix)\(message)", file: file, line: line)
}

final class WeakArrayTests: XCTestCase {

  final class TestClass {}

  func testCreation() {
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    var weakArray: WeakArray<TestClass> = [testClass1, testClass2, testClass3]
    XCTAssertEqual(weakArray.count, 3)
    XCTAssertNotNil(weakArray[0])
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass2)
    XCTAssertEqualObjects(weakArray[2], testClass3)
  }

  func testInsertion() {
    var weakArray = WeakArray<TestClass>()
    XCTAssertEqual(weakArray.count, 0)
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    weakArray.append(testClass1)
    XCTAssertEqual(weakArray.count, 1)
    weakArray.append(testClass2)
    XCTAssertEqual(weakArray.count, 2)
    weakArray.append(testClass3)
    XCTAssertEqual(weakArray.count, 3)
    weakArray.append(TestClass())
    XCTAssertEqual(weakArray.count, 4)
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass2)
    XCTAssertEqualObjects(weakArray[2], testClass3)
    XCTAssertNil(weakArray[3])
  }

  func testReplaceRange() {
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    var weakArray: WeakArray<TestClass> = [testClass1, testClass2, testClass3]
    defer { _fixLifetime(weakArray) }
    let testClass4 = TestClass(), testClass5 = TestClass()
    weakArray.replaceRange(1 ..< 3, with: [testClass4, testClass5] as Array<TestClass?>)
    XCTAssertEqual(weakArray.count, 3)
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass4)
    XCTAssertEqualObjects(weakArray[2], testClass5)
    weakArray.replaceRange(0 ..< 1, with: [testClass1, testClass2, testClass3] as Array<TestClass?>)
    XCTAssertEqual(weakArray.count, 5)
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass2)
    XCTAssertEqualObjects(weakArray[2], testClass3)
    XCTAssertEqualObjects(weakArray[3], testClass4)
    XCTAssertEqualObjects(weakArray[4], testClass5)

  }

  func testGenerator() {
    let array = [TestClass(), TestClass(), TestClass(), TestClass()]
    let weakArray = WeakArray<TestClass>(array)
    for (i, element) in weakArray.enumerate() {
      XCTAssertEqualObjects(element, array[i])
    }
  }

  func testCOW() {
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    var weakArray1: WeakArray<TestClass> = [testClass1, testClass2, testClass3]
    let weakArray2 = weakArray1
    weakArray1.removeAtIndex(0)
    XCTAssertEqual(weakArray1.count, 2)
    XCTAssertEqual(weakArray2.count, 3)
  }

  func testBufferCreation() {
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    var weakArray = WeakArrayBuffer<TestClass>([testClass1, testClass2, testClass3])
    XCTAssertEqual(weakArray.count, 3)
    XCTAssertNotNil(weakArray[0])
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass2)
    XCTAssertEqualObjects(weakArray[2], testClass3)
  }

  func testBufferInsertion() {
    var weakArray = WeakArrayBuffer<TestClass>(minimumCapacity: 4)
    XCTAssertEqual(weakArray.count, 0)
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    weakArray.append(testClass1)
    XCTAssertEqual(weakArray.count, 1)
    weakArray.append(testClass2)
    XCTAssertEqual(weakArray.count, 2)
    weakArray.append(testClass3)
    XCTAssertEqual(weakArray.count, 3)
    weakArray.append(TestClass())
    XCTAssertEqual(weakArray.count, 4)
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass2)
    XCTAssertEqualObjects(weakArray[2], testClass3)
    XCTAssertNil(weakArray[3])
  }

  func testBufferReplaceRange() {
    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
    var weakArray = WeakArrayBuffer<TestClass>(minimumCapacity: 6)
    weakArray.append(testClass1)
    weakArray.append(testClass2)
    weakArray.append(testClass3)
    defer { _fixLifetime(weakArray) }
    let testClass4 = TestClass(), testClass5 = TestClass()
    weakArray.replaceRange(1 ..< 3, with: [testClass4, testClass5] as Array<TestClass?>)
    XCTAssertEqual(weakArray.count, 3)
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass4)
    XCTAssertEqualObjects(weakArray[2], testClass5)
    weakArray.replaceRange(0 ..< 1, with: [testClass1, testClass2, testClass3] as Array<TestClass?>)
    XCTAssertEqual(weakArray.count, 5)
    XCTAssertEqualObjects(weakArray[0], testClass1)
    XCTAssertEqualObjects(weakArray[1], testClass2)
    XCTAssertEqualObjects(weakArray[2], testClass3)
    XCTAssertEqualObjects(weakArray[3], testClass4)
    XCTAssertEqualObjects(weakArray[4], testClass5)

  }

  func testBufferGenerator() {
    let array = [TestClass(), TestClass(), TestClass(), TestClass()]
    let weakArray = WeakArrayBuffer<TestClass>(array)
    for (i, element) in weakArray.enumerate() {
      XCTAssertEqualObjects(element, array[i])
    }
  }

//  func testFilteredCreation() {
//    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
//    var weakArray: FilteredWeakArrayBuffer<TestClass> = [testClass1, testClass2, testClass3]
//    XCTAssertEqual(weakArray.count, 3)
//    XCTAssertNotNil(weakArray[0])
//    XCTAssertEqualObjects(weakArray[0], testClass1)
//    XCTAssertEqualObjects(weakArray[1], testClass2)
//    XCTAssertEqualObjects(weakArray[2], testClass3)
//  }
//
//  func testFilteredInsertion() {
//    var weakArray = FilteredWeakArrayBuffer<TestClass>()
//    XCTAssertEqual(weakArray.count, 0)
//    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
//    weakArray.append(testClass1)
//    XCTAssertEqual(weakArray.count, 1)
//    weakArray.append(testClass2)
//    XCTAssertEqual(weakArray.count, 2)
//    weakArray.append(testClass3)
//    XCTAssertEqual(weakArray.count, 3)
//    weakArray.append(TestClass())
//    XCTAssertEqual(weakArray.count, 3)
//    XCTAssertEqualObjects(weakArray[0], testClass1)
//    XCTAssertEqualObjects(weakArray[1], testClass2)
//    XCTAssertEqualObjects(weakArray[2], testClass3)
//  }
//
//  func testFilteredReplaceRange() {
//    let testClass1 = TestClass(), testClass2 = TestClass(), testClass3 = TestClass()
//    var weakArray: FilteredWeakArrayBuffer<TestClass> = [testClass1, testClass2, testClass3]
//    defer { _fixLifetime(weakArray) }
//    let testClass4 = TestClass(), testClass5 = TestClass()
//    weakArray.replaceRange(1 ..< 3, with: [testClass4, testClass5])
//    XCTAssertEqual(weakArray.count, 3)
//    XCTAssertEqualObjects(weakArray[0], testClass1)
//    XCTAssertEqualObjects(weakArray[1], testClass4)
//    XCTAssertEqualObjects(weakArray[2], testClass5)
//    weakArray.replaceRange(0 ..< 1, with: [testClass1, testClass2, testClass3])
//    XCTAssertEqual(weakArray.count, 5)
//    XCTAssertEqualObjects(weakArray[0], testClass1)
//    XCTAssertEqualObjects(weakArray[1], testClass2)
//    XCTAssertEqualObjects(weakArray[2], testClass3)
//    XCTAssertEqualObjects(weakArray[3], testClass4)
//    XCTAssertEqualObjects(weakArray[4], testClass5)
//
//  }
//
//  func testFilteredGenerator() {
//    let array = [TestClass(), TestClass(), TestClass(), TestClass()]
//    let weakArray = FilteredWeakArrayBuffer<TestClass>(array)
//    for (i, element) in weakArray.enumerate() {
//      XCTAssertEqualObjects(element, array[i])
//    }
//  }
//
}
