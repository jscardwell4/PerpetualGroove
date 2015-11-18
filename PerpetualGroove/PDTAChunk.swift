//
//  PDTAChunk.swift
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

/** Parses the pdta chunk of the file */
struct PDTAChunk {

  typealias Error = SF2File.Error

  let url: NSURL

  private var lastModified: NSDate?

  let phdr: SubChunk
  let pbag: SubChunk
  let pmod: SubChunk
  let pgen: SubChunk
  let inst: SubChunk
  let ibag: SubChunk
  let imod: SubChunk
  let igen: SubChunk
  let shdr: SubChunk

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
      PDTAChunk.logError(error)
    }

    let byteCount = bytes.count
    guard byteCount > 4 else { throw Error.StructurallyUnsound }
    guard String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercaseString == "pdta" else {
      throw Error.StructurallyUnsound
    }

    var i = bytes.startIndex + 4 
    var phdr: SubChunk?
    var pbag: SubChunk?
    var pmod: SubChunk?
    var pgen: SubChunk?
    var inst: SubChunk?
    var ibag: SubChunk?
    var imod: SubChunk?
    var igen: SubChunk?
    var shdr: SubChunk?

    while i + 8  < bytes.endIndex {

      let chunkSize = Int(Byte4(bytes[i + 4 ..< i + 8]).bigEndian)
      guard i + 8 + chunkSize <= bytes.endIndex else { throw Error.StructurallyUnsound }
      let chunkData = bytes[i ..< i + 8 + chunkSize]

      guard let chunk = SubChunk(bytes: chunkData, url: url) else { throw Error.StructurallyUnsound }

      switch chunk {
        case .Presets(.PHDR, _):
          guard phdr == nil else { throw Error.StructurallyUnsound }
          phdr = chunk
        case .Reference(.PBAG, _):
          guard pbag == nil else { throw Error.StructurallyUnsound }
          pbag = chunk
        case .Reference(.PMOD, _):
          guard pmod == nil else { throw Error.StructurallyUnsound }
          pmod = chunk
        case .Reference(.PGEN, _):
          guard pgen == nil else { throw Error.StructurallyUnsound }
          pgen = chunk
        case .Reference(.INST, _):
          guard inst == nil else { throw Error.StructurallyUnsound }
          inst = chunk
        case .Reference(.IBAG, _):
          guard ibag == nil else { throw Error.StructurallyUnsound }
          ibag = chunk
        case .Reference(.IMOD, _):
          guard imod == nil else { throw Error.StructurallyUnsound }
          imod = chunk
        case .Reference(.IGEN, _):
          guard igen == nil else { throw Error.StructurallyUnsound }
          igen = chunk
        case .Reference(.SHDR, _):
          guard shdr == nil else { throw Error.StructurallyUnsound }
          shdr = chunk
        default:
          throw Error.StructurallyUnsound
      }

      i += 8 + chunkSize
    }

    guard phdr != nil && pbag != nil && pmod != nil && pgen != nil && inst != nil 
       && ibag != nil && imod != nil && igen != nil && shdr != nil else
    {
      throw Error.StructurallyUnsound
    }

    self.phdr = phdr!
    self.pbag = pbag!
    self.pmod = pmod!
    self.pgen = pgen!
    self.inst = inst!
    self.ibag = ibag!
    self.imod = imod!
    self.igen = igen!
    self.shdr = shdr!
  }

  var bytes: [Byte] {
    var result: [Byte] = "pdta".bytes
    result += phdr.bytes
    result += pbag.bytes
    result += pmod.bytes
    result += pgen.bytes
    result += inst.bytes
    result += ibag.bytes
    result += imod.bytes
    result += igen.bytes
    result += shdr.bytes
    return result
  }

}

extension PDTAChunk {
  enum SubChunk: CustomStringConvertible {
    case Reference (ChunkType, ReferenceChunk)
    case Presets (ChunkType, PresetsChunk)

    var bytes: [Byte] {
      let type: ChunkType
      let chunkBytes: [Byte]
      switch self {
      case let .Reference(t, chunk): type = t; chunkBytes = chunk.bytes
      case let .Presets(t, chunk):    type = t; chunkBytes = chunk.bytes
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
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C, url: NSURL)
    {
      guard bytes.count > 4 else { return nil }
      let idx = bytes.startIndex
      switch ChunkType(bytes: bytes[idx ... idx + 3]) {
      case .Some(.PHDR):
        guard let presetsChunk = PresetsChunk(bytes: bytes) else { return nil }
        self = .Presets(presetsChunk.type, presetsChunk)
      default:
        guard let referenceChunk = ReferenceChunk(bytes, url) else { return nil }
        self = .Reference(referenceChunk.type, referenceChunk)
      }
    }

    var description: String {
      switch self {
        case .Presets(_, let presetsChunk):     return "\(presetsChunk)"
        case .Reference(_, let referenceChunk): return "\(referenceChunk)"
      }
    }

  }
}

// MARK: - ChunkType
extension PDTAChunk {
  enum ChunkType: String {
    case PHDR, PBAG, PMOD, PGEN, INST, IBAG, IMOD, IGEN, SHDR
    var bytes: [Byte] { return rawValue.lowercaseString.bytes }
    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C)
    {
      self.init(rawValue: String(bytes).uppercaseString)
    }
  }
}

// MARK: - ReferencChunk
extension PDTAChunk {
  struct ReferenceChunk: CustomStringConvertible {
    let type: ChunkType
    let range: Range<Int>
    let url: NSURL

    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(_ bytes: C, _ url: NSURL)
    {
      self.url = url
      guard bytes.count > 7 else { return nil }
      var idx = bytes.startIndex
      guard let t = ChunkType(bytes: bytes[idx ... idx + 3]) else { return nil }
      type = t
      idx += 4
      let chunkSize = Int(Byte4(bytes[idx ..< idx + 4]).bigEndian)
      guard chunkSize + 8 == bytes.count else { return nil }
      idx += 4
      range = idx ..< bytes.endIndex
    }

    var bytes: [Byte] {
      do {
        guard let data = NSData(contentsOfURL: url) else { throw Error.ReadFailure }
        // Get a pointer to the underlying memory buffer
        let bytes = UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>(data.bytes), count: data.length)
        guard bytes.count > range.count else { throw Error.ReadFailure }
        return Array(bytes[range])
      } catch {
        logError(error)
        return []
      }
    }

    var description: String { return "\(url.lastPathComponent!): \(range) (\(range.count) bytes)" }
  }
}

// MARK: - PresetsChunk
extension PDTAChunk {
  struct PresetsChunk: CustomStringConvertible {
    let type: ChunkType
    let headers: [PresetHeader]

    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C)
    {
      guard bytes.count > 7 else { return nil }
      var idx = bytes.startIndex
      guard let t = ChunkType(bytes: bytes[idx ... idx + 3]) else { return nil }
      type = t
      idx += 4
      let chunkSize = Int(Byte4(bytes[idx ..< idx + 4]).bigEndian)
      guard chunkSize + 8 == bytes.count else { return nil }
      guard chunkSize % 38 == 0 else { return nil }
      idx += 4

      var headers: [PresetHeader] = []
      do {
        while idx < bytes.endIndex, let header = try PresetHeader(bytes: bytes[idx ..< idx + 38]) {
          headers.append(header)
          idx += 38
        }
      } catch {
        logError(error)
      }

      self.headers = headers
    }

    var bytes: [Byte] { return headers.flatMap({$0.bytes}) + PresetHeader.EOP.bytes }
    var description: String { return "\n".join(headers.map({$0.description})) }
  }
  
}
// MARK: - CustomStringCovnertible
extension PDTAChunk: CustomStringConvertible {
  var description: String {
    return "\n".join(
      "phdr:\n\(phdr.description.indentedBy(1, useTabs: true))",
      "pbag: \(pbag)",
      "pmod: \(pmod)",
      "pgen: \(pgen)",
      "inst: \(inst)",
      "ibag: \(ibag)",
      "imod: \(imod)",
      "igen: \(igen)",
      "shdr: \(shdr)"
    )
  }
}

extension PDTAChunk: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - PresetHeader
extension PDTAChunk {

  struct PresetHeader: CustomStringConvertible {

    let name: String
    let preset: Byte2
    let bank: Byte2
    let bagIndex: Byte2
    let library: Byte4
    let genre: Byte4
    let morphology: Byte4

    static let EOP: PresetHeader = PresetHeader()
    private init() { name = "EOP"; preset = 0; bank = 0; bagIndex = 0; library = 0; genre = 0; morphology = 0 }

    /**
    initWithBytes:

    - parameter bytes: C
    */
    init?<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index == Int, 
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType, 
            C.SubSequence.Index == Int,
            C.SubSequence.SubSequence == C.SubSequence>(bytes: C) throws
    {
      guard bytes.count == 38 else { throw Error.PresetHeaderInvalid }
      name       = String(bytes[bytes.startIndex ..< (bytes.indexOf(Byte(0)) ?? bytes.startIndex + 20)])
      preset     = Byte2(bytes[bytes.startIndex + 20 ... bytes.startIndex + 21]).bigEndian
      bank       = Byte2(bytes[bytes.startIndex + 22 ... bytes.startIndex + 23]).bigEndian
      bagIndex   = Byte2(bytes[bytes.startIndex + 24 ... bytes.startIndex + 25]).bigEndian
      library    = Byte4(bytes[bytes.startIndex + 26 ... bytes.startIndex + 29]).bigEndian
      genre      = Byte4(bytes[bytes.startIndex + 30 ... bytes.startIndex + 33]).bigEndian
      morphology = Byte4(bytes[bytes.startIndex + 34 ... bytes.startIndex + 37]).bigEndian
      if name == "EOP" || name.isEmpty { return nil }
    }

    var bytes: [Byte] {
      var result = name.bytes
      while result.count < 20 { result.append(Byte(0)) }
      result += preset.bytes
      result += bank.bytes
      result += bagIndex.bytes
      result += library.bytes
      result += genre.bytes
      result += morphology.bytes
      return result
    }

    var description: String {
      return "  ".join(
        "\(name.pad(" ", count: 20))",
        "preset: \("\(preset)".pad(" ", count: 3))",
        "bank: \("\(bank)".pad(" ", count: 3))",
        "bagIndex: \(bagIndex)"
      )
    }

  }

}
