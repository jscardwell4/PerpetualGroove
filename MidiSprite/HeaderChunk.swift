//
//  HeaderChunk.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Struct to hold the header chunk of a MIDI file */
struct HeaderChunk: MIDIChunk {
  typealias Format = MIDIFile.Format
  let type = Byte4("MThd".utf8)
  let length: Byte4 = 6
  let format: Format
  let numberOfTracks: Byte2
  let division: Byte2

  var description: String {
    let result = "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "type: MThd",
      "length: \(length)",
      "format: \(format)",
      "numberOfTracks: \(numberOfTracks)",
      "division: \(division)"
    ) + "\n}"
    return result
  }
  var bytes: [Byte] { return type.bytes + length.bytes + format.rawValue.bytes + numberOfTracks.bytes + division.bytes }

  /**
  init:numberOfTracks:division:

  - parameter f: Format
  - parameter n: Byte2
  - parameter d: Byte2
  */
  init(format f: Format, numberOfTracks n: Byte2, division d: Byte2) { format = f; numberOfTracks = n; division = d }

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:CollectionType where C.Generator.Element == Byte,
                              C.Index == Int, C.SubSequence.Generator.Element == Byte,
                              C.SubSequence:CollectionType, C.SubSequence.Index == Int,
                              C.SubSequence.SubSequence == C.SubSequence>(bytes: C) throws
  {
    guard bytes.count == 14 else {
      throw MIDIFileError(type: .InvalidLength, reason: "Header chunk must be 14 bytes")
    }
    guard bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(4)].elementsEqual("MThd".utf8) else {
      throw MIDIFileError(type: .InvalidHeader, reason: "Expected chunk header with type 'MThd'")
    }
    guard Byte4(6) == Byte4(bytes[bytes.startIndex.advancedBy(4) ..< bytes.startIndex.advancedBy(8)]) else {
      throw MIDIFileError(type: .InvalidLength, reason: "Header must specify length of 6")
    }
    guard let f = Format(rawValue: Byte2(bytes[bytes.startIndex.advancedBy(8) ..< bytes.startIndex.advancedBy(10)])) else {
      throw MIDIFileError(type: .FileStructurallyUnsound, reason: "Format must be 00 00 00 00, 00 00 00 01, 00 00 00 02")
    }
    format = f
    numberOfTracks = Byte2(bytes[bytes.startIndex.advancedBy(10) ..< bytes.startIndex.advancedBy(12)])
    division = Byte2(bytes[bytes.startIndex.advancedBy(12) ..< bytes.startIndex.advancedBy(14)])
  }
}