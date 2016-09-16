//
//  MIDIFileHeaderChunk.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct to hold the header chunk of a MIDI file */
struct MIDIFileHeaderChunk {
  let type = Byte4("MThd".utf8)
  let format: Byte2 = 1
  let length: Byte4 = 6
  let numberOfTracks: Byte2
  let division: Byte2 = 480

  var bytes: [Byte] {
    var result = type.bytes
    result.append(contentsOf: format.bytes)
    result.append(contentsOf: numberOfTracks.bytes)
    result.append(contentsOf: division.bytes)
    return result
  }

  /**
  init:numberOfTracks:division:

  - parameter f: Format
  - parameter n: Byte2
  - parameter d: Byte2
  */
  init(numberOfTracks n: Byte2) { numberOfTracks = n }

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:Collection>(bytes: C) throws where C.Iterator.Element == Byte,
                              C.Index == Int, C.SubSequence.Iterator.Element == Byte,
                              C.SubSequence:Collection, C.SubSequence.Index == Int,
                              C.SubSequence.SubSequence == C.SubSequence
  {
    guard bytes.count == 14 else {
      throw MIDIFileError(type: .invalidLength, reason: "Header chunk must be 14 bytes")
    }
    guard bytes[bytes.startIndex ..< bytes.startIndex.advanced(by: 4)].elementsEqual("MThd".utf8) else {
      throw MIDIFileError(type: .invalidHeader, reason: "Expected chunk header with type 'MThd'")
    }
    guard Byte4(6) == Byte4(bytes[bytes.startIndex + 4 ..< bytes.startIndex + 8]) else {
      throw MIDIFileError(type: .invalidLength, reason: "Header must specify length of 6")
    }
    guard 1 == Byte2(bytes[bytes.startIndex + 8 ..< bytes.startIndex + 10]) else {
      throw MIDIFileError(type: .fileStructurallyUnsound, reason: "Format must be 00 00 00 00, 00 00 00 01, 00 00 00 02")
    }
    numberOfTracks = Byte2(bytes[bytes.startIndex + 10 ..< bytes.startIndex + 12])
  }
}

extension MIDIFileHeaderChunk: CustomStringConvertible {
  var description: String {
    return "MThd\n\tformat: \(format)\n\tnumber of tracks: \(numberOfTracks)\n\tdivision: \(division)"
  }
}

extension MIDIFileHeaderChunk: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}
