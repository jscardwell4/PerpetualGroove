//: Playground - noun: a place where people can play
import Foundation
import MoonKit
import AudioToolbox


class MyMetaEvent {
  private let size: Int
  private let mem : UnsafeMutablePointer<UInt8>

  let metaEventPtr : UnsafeMutablePointer<MIDIMetaEvent>

  init(type: UInt8, data: [UInt8]) {
    // Allocate memory of the required size:
    size = sizeof(MIDIMetaEvent) + data.count
    mem = UnsafeMutablePointer<UInt8>.alloc(size)
    // Convert pointer:
    metaEventPtr = UnsafeMutablePointer(mem)

    // Fill data:
    metaEventPtr.memory.metaEventType = type
    metaEventPtr.memory.dataLength = UInt32(data.count)
    memcpy(mem + 8, data, data.count)
  }

  deinit {
    // Release the allocated memory:
    mem.dealloc(size)
  }
}