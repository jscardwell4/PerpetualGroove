//: Playground - noun: a place where people can play
import Foundation
import UIKit
import MoonKit
import CoreAudio
import CoreMIDI
import SpriteKit

let node = SKNode()

let identifier = ObjectIdentifier(node)
var identifierUInt = identifier.uintValue
String(identifierUInt, radix: 16, uppercase: true)
var pieces: [UInt8] = []

pieces.append(UInt8(identifierUInt & 0xFF))
pieces.append(UInt8((identifierUInt >> 8) & 0xFF))
pieces.append(UInt8((identifierUInt >> 16) & 0xFF))
pieces.append(UInt8((identifierUInt >> 24) & 0xFF))
pieces.append(UInt8((identifierUInt >> 32) & 0xFF))
pieces.append(UInt8((identifierUInt >> 40) & 0xFF))
pieces.append(UInt8((identifierUInt >> 48) & 0xFF))
pieces.append(UInt8((identifierUInt >> 56) & 0xFF))

print(pieces.map { String($0, radix: 16, uppercase: true) })

var rebuiltIdentifierUInt: UInt = 0
for (shift, value) in zip([0, 8, 16, 24, 32, 40, 48, 56], pieces) {
  rebuiltIdentifierUInt |= UInt(value) << UInt(shift)
}
String(rebuiltIdentifierUInt, radix: 16, uppercase: true)
identifierUInt == rebuiltIdentifierUInt

let chunks = withUnsafePointer(&identifierUInt) {
  (pointer: UnsafePointer<UInt>) -> [UInt8] in
  var idPointer = UnsafeMutablePointer<UInt8>(pointer)
  var result: [UInt8] = []
  for _ in 0 ... 7 { result.append(idPointer.memory); idPointer = idPointer.successor() }
  return result
}
print(chunks)