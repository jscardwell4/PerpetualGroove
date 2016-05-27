//
//  main.swift
//  GenerateTestData
//
//  Created by Jason Cardwell on 5/27/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

guard Process.arguments.count == 2 else { exit(1) }

guard let count = Int(Process.arguments[1]) else { exit(1) }

func randomIntegers(count: Int, _ range: Range<Int>) -> [Int] {
  func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
  var result: [Int] = []
  result.reserveCapacity(count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

var fileOut = ""
print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", toStream: &fileOut)
print("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">", toStream: &fileOut)
print("<plist version=\"1.0\">", toStream: &fileOut)
print("<dict>", toStream: &fileOut)

let integers = randomIntegers(count, 0 ..< count / 2)

print("  <key>integers</key>", toStream: &fileOut)
print("  <array>", toStream: &fileOut)

for integer in integers {
  print("    <integer>\(integer)</integer>", toStream: &fileOut)
}

print("  </array>", toStream: &fileOut)

let strings = integers.map(String.init)

print("  <key>strings</key>", toStream: &fileOut)
print("  <array>", toStream: &fileOut)

for string in strings {
  print("    <string>\(string)</string>", toStream: &fileOut)
}

print("  </array>", toStream: &fileOut)
print("</dict>", toStream: &fileOut)
print("</plist>", toStream: &fileOut)
print("", toStream: &fileOut)


print(fileOut)
