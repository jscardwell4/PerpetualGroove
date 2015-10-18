//
//  SDTAChunk.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
#if os(iOS)
  import MoonKit
  #else
  import MoonKitOSX
#endif

/** Parses the sdta chunk of the file */
struct SDTAChunk: CustomStringConvertible {

  let url: NSURL
  let smpl: Range<Int>?
  private var lastModified: NSDate?
  typealias Error = SF2File.Error

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:CollectionType 
    where C.Generator.Element == Byte,
          C.Index == Int, 
          C.SubSequence.Generator.Element == Byte,
          C.SubSequence:CollectionType, 
          C.SubSequence.Index == Int,
          C.SubSequence.SubSequence == C.SubSequence>(bytes: C, url: NSURL) throws
  {
    self.url = url
    do {
      var date: AnyObject?
      try url.getResourceValue(&date, forKey: NSURLContentModificationDateKey)
      lastModified = date as? NSDate
    } catch {
      logError(error)
    }
    let byteCount = bytes.count
    guard byteCount >= 4 && String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercaseString == "sdta" else {
      throw Error.SDTAStructurallyUnsound
    }

    if byteCount > 8 {
      guard String(bytes[bytes.startIndex + 4 ..< bytes.startIndex + 8]).lowercaseString == "smpl" else {
        throw Error.SDTAStructurallyUnsound
      }
      let smplSize = Int(Byte4(bytes[bytes.startIndex + 8 ..< bytes.startIndex + 12])!.bigEndian)
      guard byteCount >= smplSize + 12 else {
        throw Error.SDTAStructurallyUnsound
      }
      smpl = bytes.startIndex + 12 ..< bytes.startIndex + smplSize + 12
    } else {
      smpl = nil
    }
  }

  var description: String {
    var result = "SDTAChunk {\n"
    if let smpl = smpl { result += "  smpl: \(smpl.count) bytes\n" }
    result += "\n"
    return result
  }
}

