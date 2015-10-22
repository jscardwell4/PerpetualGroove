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
struct SDTAChunk {

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
      SDTAChunk.logError(error)
    }

    let byteCount = bytes.count
    guard byteCount >= 4
       && String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercaseString == "sdta" else
    {
      throw Error.StructurallyUnsound
    }

    if byteCount > 8 {
      guard String(bytes[bytes.startIndex + 4 ..< bytes.startIndex + 8]).lowercaseString == "smpl" else {
        throw Error.StructurallyUnsound
      }
      let smplSize = Int(Byte4(bytes[bytes.startIndex + 8 ..< bytes.startIndex + 12]).bigEndian)
      guard byteCount >= smplSize + 12 else {
        throw Error.StructurallyUnsound
      }
      smpl = bytes.startIndex + 12 ..< bytes.startIndex + smplSize + 12
    } else {
      smpl = nil
    }
  }

  var bytes: [Byte] {
    guard let smpl = smpl else { return "sdta".bytes + Byte4(0).bytes }
    var result = "sdtasmpl".bytes
    let smplBytes: [Byte]
    do {
      var date: AnyObject?
      try url.getResourceValue(&date, forKey: NSURLContentModificationDateKey)
      guard lastModified == nil || date as? NSDate == lastModified else { throw Error.FileOnDiskModified }
      guard let data = NSData(contentsOfURL: url) else { throw Error.ReadFailure }
      // Get a pointer to the underlying memory buffer
      let bytes = UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>(data.bytes), count: data.length)
      guard bytes.count > smpl.count else { throw Error.ReadFailure }
      smplBytes = Array(bytes[smpl])
    } catch {
      logError(error)
      smplBytes = []
    }

    result += Byte4(smplBytes.count).bytes
    result += smplBytes
    
    return result
  }

}

extension SDTAChunk: CustomStringConvertible {
  var description: String {
    var result = "SDTAChunk { "
    if let smpl = smpl { result += "  smpl: \(smpl) (\(smpl.count) bytes)" }
    result += " }"
    return result
  }
}
