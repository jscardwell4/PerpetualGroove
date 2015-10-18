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
struct PDTAChunk: CustomStringConvertible {

  typealias Error = SF2File.Error
  let url: NSURL
  private var lastModified: NSDate?
  let phdr: [PresetHeader]
  let pbag: Range<Int>
  let pmod: Range<Int>
  let pgen: Range<Int>
  let inst: Range<Int>
  let ibag: Range<Int>
  let imod: Range<Int>
  let igen: Range<Int>
  let shdr: Range<Int>

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
    guard byteCount > 4 else { throw Error.PDTAStructurallyUnsound }
    guard String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercaseString == "pdta" else {
      throw Error.PDTAStructurallyUnsound
    }
    var i = bytes.startIndex + 4 
    var phdr: [PresetHeader]?
    var pbag: Range<Int>?
    var pmod: Range<Int>?
    var pgen: Range<Int>?
    var inst: Range<Int>?
    var ibag: Range<Int>?
    var imod: Range<Int>?
    var igen: Range<Int>?
    var shdr: Range<Int>?
    while i + 8  < bytes.endIndex {
      let chunkType = String(bytes[i ..< i + 4])
      let chunkSize = Int(Byte4(bytes[i + 4 ..< i + 8])!.bigEndian)
      guard byteCount >= i + 8 + chunkSize - bytes.startIndex else { throw Error.PDTAStructurallyUnsound }
      let chunkData = bytes[i + 8 ..< i + 8 + chunkSize]
      func uniqueAssign(inout value: Range<Int>?) {
        guard case .None = value else { return }
        value = chunkData.indices
      }
      switch chunkType!.lowercaseString {
        case "phdr":
          guard phdr == nil && chunkSize % 38 == 0 else { throw Error.PDTAStructurallyUnsound }
          var j = chunkData.startIndex
          var presetHeaders: [PresetHeader] = []
          while j < chunkData.endIndex, let presetHeader = try PresetHeader(bytes: chunkData[j ..< j + 38]) {
            presetHeaders.append(presetHeader)
            j += 38
          }
          phdr = presetHeaders
        case "pbag": uniqueAssign(&pbag)
        case "pmod": uniqueAssign(&pmod)
        case "pgen": uniqueAssign(&pgen)
        case "inst": uniqueAssign(&inst)
        case "ibag": uniqueAssign(&ibag)
        case "imod": uniqueAssign(&imod)
        case "igen": uniqueAssign(&igen)
        case "shdr": uniqueAssign(&shdr)
        default: continue
      }
      i += 8 + chunkSize
    }

    guard phdr != nil && pbag != nil && pmod != nil && pgen != nil && inst != nil 
       && ibag != nil && imod != nil && igen != nil && shdr != nil else
    {
      throw Error.PDTAStructurallyUnsound
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

  var description: String {
    var result = "PDTAChunk {\n"
    result += "  phdr: [\n" + ",\n".join(phdr.map({$0.description.indentedBy(4)})) + "\n  ]\n"
    result += "  pbag: \(pbag.count) bytes\n"
    result += "  pmod: \(pmod.count) bytes\n"
    result += "  pgen: \(pgen.count) bytes\n"
    result += "  inst: \(inst.count) bytes\n"
    result += "  ibag: \(ibag.count) bytes\n"
    result += "  imod: \(imod.count) bytes\n"
    result += "  igen: \(igen.count) bytes\n"
    result += "  shdr: \(shdr.count) bytes\n"
    result += "\n}"
    return result
  }
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
      preset     = Byte2(bytes[bytes.startIndex + 20 ... bytes.startIndex + 21])!.bigEndian
      bank       = Byte2(bytes[bytes.startIndex + 22 ... bytes.startIndex + 23])!.bigEndian
      bagIndex   = Byte2(bytes[bytes.startIndex + 24 ... bytes.startIndex + 25])!.bigEndian
      library    = Byte4(bytes[bytes.startIndex + 26 ... bytes.startIndex + 29])!.bigEndian
      genre      = Byte4(bytes[bytes.startIndex + 30 ... bytes.startIndex + 33])!.bigEndian
      morphology = Byte4(bytes[bytes.startIndex + 34 ... bytes.startIndex + 37])!.bigEndian
      if name == "EOP" || name.isEmpty { return nil }
    }

    var description: String {
      var result = "PresetHeader {\n"
      result += "  name: \(name)\n"
      result += "  preset: \(preset)\n"
      result += "  bank: \(bank)\n"
      result += "  bagIndex: \(bagIndex)\n"
      if library != Byte4(0)    { result += "  library: \(library)\n"       }
      if genre != Byte4(0)      { result += "  genre: \(genre)\n"           }
      if morphology != Byte4(0) { result += "  morphology: \(morphology)\n" }
      result += "}"
      return result
    }

  }

}
