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

  let url: URL
  let smpl: CountableRange<Int>?

  fileprivate var lastModified: Date?

  typealias Error = SF2File.Error

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:Collection>(bytes: C, url: URL) throws 
    where C.Iterator.Element == Byte,
          C.Index == Int, 
          C.SubSequence.Iterator.Element == Byte,
          C.SubSequence:Collection, 
          C.SubSequence.Index == Int,
          C.SubSequence.SubSequence == C.SubSequence
  {
    self.url = url
    do {
      var date: AnyObject?
      try (url as NSURL).getResourceValue(&date, forKey: URLResourceKey.contentModificationDateKey)
      lastModified = date as? Date
    } catch {
      SDTAChunk.logError(error)
    }

    let byteCount = bytes.count
    guard byteCount >= 4
       && String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercased() == "sdta" else
    {
      throw Error.StructurallyUnsound
    }

    if byteCount > 8 {
      guard String(bytes[bytes.startIndex + 4 ..< bytes.startIndex + 8]).lowercased() == "smpl" else {
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
      try (url as NSURL).getResourceValue(&date, forKey: URLResourceKey.contentModificationDateKey)
      guard lastModified == nil || date as? Date == lastModified else { throw Error.FileOnDiskModified }
      guard let data = try? Data(contentsOf: url) else { throw Error.ReadFailure }
      // Get a pointer to the underlying memory buffer
      let bytes = UnsafeBufferPointer<Byte>(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count)
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
  var description: String { if let smpl = smpl { return "smpl: \(smpl) (\(smpl.count) bytes)" } else { return "" } }
}

extension SDTAChunk: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}
