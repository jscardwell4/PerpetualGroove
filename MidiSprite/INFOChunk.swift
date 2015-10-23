//
//  INFOChunk.swift
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

/** Parses the info chunk of the file */
struct INFOChunk {
  let ifil: SubChunk  // file version
  let isng: SubChunk  // sound engine, less than 257 bytes, missing assume 'EMU8000'
  let inam: SubChunk  // bank name, less than 257 bytes, ignore if missing
  let irom: SubChunk? // ROM, less than 257 bytes, ignore if missing
  let iver: SubChunk? // ROM version
  let icrd: SubChunk? // creation date, less than 257 bytes, ignore if missing
  let ieng: SubChunk? // sound designers, less than 257 bytes, ignore if missing
  let iprd: SubChunk? // intended product, less than 257 bytes, ignore if missing
  let icop: SubChunk? // copywrite, less than 257 bytes, ignore if missing
  let icmt: SubChunk? // comment, less than 65,537 bytes, ignore if missing
  let isft: SubChunk? // creation tools, less than 257 bytes, ignore if missing

  typealias Error = SF2File.Error

  /**
  initWithBytes:

  - parameter bytes: C
  */
  init<C:CollectionType where C.Generator.Element == Byte,
                              C.Index == Int, C.SubSequence.Generator.Element == Byte,
                              C.SubSequence:CollectionType, C.SubSequence.Index == Int,
                              C.SubSequence.SubSequence == C.SubSequence>(bytes: C) throws
  {
    let byteCount = bytes.count
    guard byteCount > 4 else { throw Error.StructurallyUnsound }
    guard String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercaseString == "info" else {
      throw Error.StructurallyUnsound
    }

    var i = bytes.startIndex + 4 
    var ifil: SubChunk?
    var isng: SubChunk?
    var inam: SubChunk?
    var irom: SubChunk?
    var iver: SubChunk?
    var icrd: SubChunk?
    var ieng: SubChunk?
    var iprd: SubChunk?
    var icop: SubChunk?
    var icmt: SubChunk?
    var isft: SubChunk?

    while i + 8  < bytes.endIndex {

      let chunkSize = Int(Byte4(bytes[i + 4 ..< i + 8]).bigEndian)
      guard i + 8 + chunkSize <= bytes.endIndex else { throw Error.StructurallyUnsound }
      let chunkData = bytes[i ..< i + 8 + chunkSize]

      guard let chunk = SubChunk(bytes: chunkData) else { throw Error.StructurallyUnsound }
      switch chunk {
        case .Version(.IFIL, _): guard ifil == nil else { throw Error.StructurallyUnsound }; ifil = chunk
        case .Text(.ISNG, _):    guard isng == nil else { throw Error.StructurallyUnsound }; isng = chunk
        case .Text(.INAM, _):    guard inam == nil else { throw Error.StructurallyUnsound }; inam = chunk
        case .Text(.IROM, _):    guard irom == nil else { throw Error.StructurallyUnsound }; irom = chunk
        case .Version(.IVER, _): guard iver == nil else { throw Error.StructurallyUnsound }; iver = chunk
        case .Text(.ICRD, _):    guard icrd == nil else { throw Error.StructurallyUnsound }; icrd = chunk
        case .Text(.IENG, _):    guard ieng == nil else { throw Error.StructurallyUnsound }; ieng = chunk
        case .Text(.IPRD, _):    guard iprd == nil else { throw Error.StructurallyUnsound }; iprd = chunk
        case .Text(.ICOP, _):    guard icop == nil else { throw Error.StructurallyUnsound }; icop = chunk
        case .Text(.ICMT, _):    guard icmt == nil else { throw Error.StructurallyUnsound }; icmt = chunk
        case .Text(.ISFT, _):    guard isft == nil else { throw Error.StructurallyUnsound }; isft = chunk
        default:                 throw Error.StructurallyUnsound
      }
      i += 8 + chunkSize
    }

    guard ifil != nil && isng != nil && inam != nil else { throw Error.StructurallyUnsound }
    self.ifil = ifil!
    self.isng = isng!
    self.inam = inam!
    self.irom = irom
    self.iver = iver
    self.icrd = icrd
    self.ieng = ieng
    self.iprd = iprd
    self.icop = icop
    self.icmt = icmt
    self.isft = isft
  }

  var bytes: [Byte] {
    var result: [Byte] = "INFO".bytes
    result += ifil.bytes
    result += isng.bytes
    result += inam.bytes
    if let irom = irom { result += irom.bytes }
    if let iver = iver { result += iver.bytes }
    if let icrd = icrd { result += icrd.bytes }
    if let ieng = ieng { result += ieng.bytes }
    if let iprd = iprd { result += iprd.bytes }
    if let icop = icop { result += icop.bytes }
    if let icmt = icmt { result += icmt.bytes }
    if let isft = isft { result += isft.bytes }
    return result
  }

}

extension INFOChunk {
  enum SubChunk: CustomStringConvertible {
    case Version (ChunkType, VersionChunk)
    case Text (ChunkType, TextChunk)

    var bytes: [Byte] {
      let type: ChunkType
      let chunkBytes: [Byte]
      switch self {
        case let .Version(t, chunk): type = t; chunkBytes = chunk.bytes
        case let .Text(t, chunk):    type = t; chunkBytes = chunk.bytes
      }
      let sizeBytes = Byte4(chunkBytes.count).bytes
      return type.bytes + sizeBytes + chunkBytes
    }

    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C)
    {
      guard bytes.count > 4 else { return nil }
      let idx = bytes.startIndex
      switch ChunkType(bytes: bytes[idx ... idx + 3]) {
        case .Some(.IFIL), .Some(.IVER):
          guard let versionChunk = VersionChunk(bytes: bytes) else { return nil }
          self = .Version(versionChunk.type, versionChunk)
        default:
          guard let textChunk = TextChunk(bytes: bytes) else { return nil }
          self = .Text(textChunk.type, textChunk)
      }
    }

    var description: String {
      switch self {
      case .Version(_, let versionChunk): return "\(versionChunk.major).\(versionChunk.minor)"
      case .Text(_, let textChunk):       return textChunk.text
      }
    }
  }
}

extension INFOChunk: CustomStringConvertible {
  var description: String {
    var result = "\n".join( "ifil: \(ifil)", "isng: \(isng)", "inam: \(inam)" )
    if let irom = irom { result += "irom: \(irom)\n" }
    if let iver = iver { result += "iver: \(iver)\n" }
    if let icrd = icrd { result += "icrd: \(icrd)\n" }
    if let ieng = ieng { result += "ieng: \(ieng)\n" }
    if let iprd = iprd { result += "iprd: \(iprd)\n" }
    if let icop = icop { result += "icop: \(icop)\n" }
    if let icmt = icmt { result += "icmt: \(icmt)\n" }
    if let isft = isft { result += "isft: \(isft)\n" }
    return result
  }
}

extension INFOChunk: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - ChunkType
extension INFOChunk {
  enum ChunkType: String {
    case IFIL, ISNG, INAM, IROM, IVER, ICRD, IENG, IPRD, ICOP, ICMT, ISFT
    var bytes: [Byte] { return rawValue.lowercaseString.bytes }
    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C)
    {
      let raw = String(bytes).uppercaseString
      self.init(rawValue: raw)
    }
  }
}

// MARK: - VersionChunk
extension INFOChunk {
  struct VersionChunk {
    let major: Byte2, minor: Byte2
    let type: ChunkType

    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C)
    {
      guard bytes.count == 12 else { return nil }
      let idx = bytes.startIndex
      guard let t = ChunkType(bytes: bytes[idx ... idx + 3]) else { return nil }
      type = t

      guard Byte4(bytes[idx + 4 ..< idx + 8]).bigEndian == 4 else { return nil }

      major = Byte2(bytes[idx + 8 ... idx + 9])
      minor = Byte2(bytes[idx + 10 ... idx + 11])
    }

    var bytes: [Byte] { return major.bytes + minor.bytes }
  }
}

// MARK: - TextChunk
extension INFOChunk {
  struct TextChunk {
    let type: ChunkType
    let text: String

    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C)
    {
      guard bytes.count > 8 else { return nil }
      let idx = bytes.startIndex
      guard let t = ChunkType(bytes: bytes[idx ... idx + 3]) else { return nil }
      type = t
      text = String(bytes[(idx + 4)..<])
    }

    var bytes: [Byte] { return text.bytes }
  }

}