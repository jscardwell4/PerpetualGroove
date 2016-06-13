//
//  StackTests.swift
//  StackTests
//
//  Created by Jason Cardwell on 6/13/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import MoonKit

final class StackTests: XCTestCase {

  func testCreation() {
    let stack1 = Stack<Int>()
    expect(stack1.count) == 0
    expect(stack1.capacity) == 0
    expect(stack1) == []

    let stack2 = Stack<Int>([1, 2, 3, 4])
    expect(stack2.count) == 4
    expect(stack2.capacity) == 4
    expect(stack2) == [4, 3, 2, 1]

    let stack3 = Stack<Int>(minimumCapacity: 100)
    expect(stack3.count) == 0
    expect(stack3.capacity) == 100
    expect(stack3) == []
  }

  func testPush() {
    var stack1 = Stack<Int>(minimumCapacity: 4)
    expect(stack1.count) == 0
    expect(stack1.capacity) == 4
    expect(stack1) == []

    stack1.push(1)
    expect(stack1.count) == 1
    expect(stack1.capacity) == 4
    expect(stack1) == [1]

    stack1.push(2)
    expect(stack1.count) == 2
    expect(stack1.capacity) == 4
    expect(stack1) == [2, 1]

    stack1.push(3)
    expect(stack1.count) == 3
    expect(stack1.capacity) == 4
    expect(stack1) == [3, 2, 1]

    stack1.push(4)
    expect(stack1.count) == 4
    expect(stack1.capacity) == 4
    expect(stack1) == [4, 3, 2, 1]

    stack1.push(5)
    expect(stack1.count) == 5
    expect(stack1.capacity) == 10
    expect(stack1) == [5, 4, 3, 2, 1]

    var stack2 = stack1
    expect(stack2.count) == stack1.count
    expect(stack2.capacity) == stack1.capacity
    expect(stack2) == stack1

    stack2.push(6)
    expect(stack2.count) == 6
    expect(stack2.capacity) == 10
    expect(stack2) == [6, 5, 4, 3, 2, 1]
    expect(stack1.count) == 5
    expect(stack1.capacity) == 10
    expect(stack1) == [5, 4, 3, 2, 1]

  }

  func testPopAndPeek() {
    var stack1 = Stack<Int>([1, 2, 3, 4, 5])
    expect(stack1.count) == 5
    expect(stack1.capacity) == 5
    expect(stack1) == [5, 4, 3, 2, 1]
    expect(stack1.peek) == 5

    var poppedElement = stack1.pop()
    expect(poppedElement) == 5
    expect(stack1.count) == 4
    expect(stack1.capacity) == 5
    expect(stack1) == [4, 3, 2, 1]
    expect(stack1.peek) == 4

    poppedElement = stack1.pop()
    expect(poppedElement) == 4
    expect(stack1.count) == 3
    expect(stack1.capacity) == 5
    expect(stack1) == [3, 2, 1]
    expect(stack1.peek) == 3

    poppedElement = stack1.pop()
    expect(poppedElement) == 3
    expect(stack1.count) == 2
    expect(stack1.capacity) == 5
    expect(stack1) == [2, 1]
    expect(stack1.peek) == 2

    var stack2 = stack1

    poppedElement = stack2.pop()
    expect(poppedElement) == 2
    expect(stack2.count) == 1
    expect(stack2.capacity) == 5
    expect(stack2) == [1]
    expect(stack2.peek) == 1

    poppedElement = stack2.pop()
    expect(poppedElement) == 1
    expect(stack2.count) == 0
    expect(stack2.capacity) == 5
    expect(stack2) == []
    expect(stack2.peek).to(beNil())

    poppedElement = stack2.pop()
    expect(poppedElement).to(beNil())
    expect(stack2.count) == 0
    expect(stack2.capacity) == 5
    expect(stack2) == []
    expect(stack2.peek).to(beNil())

    expect(stack1.count) == 2
    expect(stack1.capacity) == 5
    expect(stack1) == [2, 1]
    expect(stack1.peek) == 2
  }

  func testReverse() {
    let stack1 = Stack<Int>([1, 2, 3, 4, 5])
    expect(stack1) == [5, 4, 3, 2, 1]

    let stack2 = stack1.reversed
    expect(stack2) == [1, 2, 3, 4, 5]

    var stack3 = stack2
    expect(stack3) == [1, 2, 3, 4, 5]

    stack3.reverse()
    expect(stack3) == [5, 4, 3, 2, 1]
    expect(stack2) == [1, 2, 3, 4, 5]
  }

/*
  func testCreationPerformance() {
    //TODO: Fill out stub
  }

  func testPushPerformance() {
    //TODO: Fill out stub
  }

  func testPopPerformance() {
    //TODO: Fill out stub
  }

  func testPeekPerformance() {
    //TODO: Fill out stub
  }

  func testReversePerformance() {
    //TODO: Fill out stub
  }
*/
}
/*
final class CompositeStackTests: XCTestCase {

  func testCreationPerformance() {
    //TODO: Fill out stub
  }

  func testPushPerformance() {
    //TODO: Fill out stub
  }

  func testPopPerformance() {
    //TODO: Fill out stub
  }

  func testPeekPerformance() {
    //TODO: Fill out stub
  }

  func testReversePerformance() {
    //TODO: Fill out stub
  }

}
 */