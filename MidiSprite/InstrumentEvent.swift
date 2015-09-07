//
//  InstrumentEvent.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct InstrumentEvent: TrackEvent {
  var time: CABarBeatTime = .start
  var bytes: [Byte] { return InstrumentEvent.headBytes + length + dataBytes + [0xF7] }

  private static let headBytes: [Byte] = [0xF0, 0x7E, 0x7F, 0x0B, 0x03, 0x00, 0x00]

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "fileType: \(fileType)",
      "url: \(url)",
      "time: \(time)(\(time.doubleValue); \(time.tickValue))"
    )
    result += "\n}"
    return result
  }

  enum FileType {
    case SF2, EXS
    var bytes: [Byte] { switch self { case .SF2: return "sf2".bytes; case .EXS: return "exs".bytes } }
  }

  var dataBytes: [Byte] { return fileType.bytes + url.absoluteString.bytes + [0x00, 0x00] }

  let fileType: FileType
  let url: NSURL

  /**
  Two 7-bit bytes: byte count of <data>, LSB first.

  This count is the number of bytes remaining in the message before the end-of-exclusive byte.
  */
  var length: [Byte] {
    let dataBytes = self.dataBytes
    guard dataBytes.count < 16384 else { fatalError("unable to fit length value into two seven-bit bytes") }
    var lengthBytes = Byte2(dataBytes.count).bytes
    if lengthBytes[0] != 0 {
      lengthBytes[0] <<= 1
      lengthBytes[0] |= (lengthBytes[1] & 0x80) >> 7
      lengthBytes[1] &= 0x7F
    }
    return lengthBytes
  }

  /**
  init:url:

  - parameter type: FileType
  - parameter url: NSURL
  */
  init(_ type: FileType, _ url: NSURL) { fileType = type; self.url = url }

}
