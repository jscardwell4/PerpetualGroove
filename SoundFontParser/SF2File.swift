//
//  SF2File.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** Parses the data from a SoundFont file, which consists of three chunks: info, sdta, and pdta */
struct SF2File: CustomStringConvertible {

  enum Error: String, ErrorType {
    case NotAFileURL = "URL provided is not a valid file url"
    case ReadFailure = "Failed to obtain data from the file specified"
    case FileStructurallyUnsound = "The specified file is not structurally sound"
    case FileHeaderInvalid = "The specified file does not contain a valid RIFF header"
    case INFOStructurallyUnsound = "Invalid INFO-list chunk"
    case SDTAStructurallyUnsound = "Invalid SDTA-list chunk"
    case PDTAStructurallyUnsound = "Invalid PDTA-list chunk"
    case PresetHeaderInvalid = "Invalid preset header detected in PDTA chunk"
    case INFOParseError = "Failed to parse INFO-list chunk"
    case SDTAParseError = "Failed to parse SDTA-list chunk"
    case PDTAParseError = "Failed to parse PDTA-list chunk"
  }

  let url: NSURL

  private let info: INFOChunk
  private let sdta: SDTAChunk
  private let pdta: PDTAChunk

  struct Preset: Comparable {
    let name: String
    let program: Int
    let bank: Int
  }

  var presets: [Preset] { return pdta.phdr.map { Preset(name: $0.name, program: Int($0.preset), bank: Int($0.bank))} }

  var description: String {
    var result = "SF2File {\n"
    result += "  url: \(url)\n"
    result += "  info: \(info.description.indentedBy(4, true))\n"
    result += "  sdta: \(sdta.description.indentedBy(4, true))\n"
    result += "  pdta: \(pdta.description.indentedBy(4, true))\n"
    result += "}"
    return result
  }

  /**
  Initializer that takes a file url

  - parameter file: NSURL
  */
  init(file: NSURL) throws {

    // Grab the url and data
    url = file
    guard let fileData = NSData(contentsOfURL: file) else { throw Error.ReadFailure }

    // Check the data length
    let totalBytes = fileData.length
    guard totalBytes > 8 else { throw Error.FileStructurallyUnsound }

    // Get a pointer to the underlying memory buffer
    let bytes = UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>(fileData.bytes), count: totalBytes)

    guard String(bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(4)]).lowercaseString == "riff" else {
      throw Error.FileHeaderInvalid
    }

    // Get the size specified by the file and make sure it is long enough to get to the first chunk size
    let riffSize = Int(Byte4(bytes[bytes.startIndex.advancedBy(4) ..< bytes.startIndex.advancedBy(8)]).bigEndian)
    guard riffSize + 8 == totalBytes && riffSize > 20 else {
      throw Error.FileStructurallyUnsound
    }

    // Check the bytes up to info size and get the info size
    guard String(Array(bytes[bytes.startIndex.advancedBy(8) ..< bytes.startIndex.advancedBy(16)])) == "sfbkLIST" else {
      throw Error.FileStructurallyUnsound
    }

    let infoSize = Int(Byte4(bytes[bytes.startIndex.advancedBy(16) ..< bytes.startIndex.advancedBy(20)]).bigEndian)

    // Check that there are enough bytes for the info chunk size
    guard totalBytes >= bytes.startIndex.advancedBy(infoSize + 20) else {
      throw Error.INFOStructurallyUnsound
    }

    // Create a reference slice of the info chunk
    let infoBytes = bytes[bytes.startIndex.advancedBy(20) ..< bytes.startIndex.advancedBy(infoSize + 20)]


    // Check for sdta list
    guard bytes[infoBytes.endIndex ..< infoBytes.endIndex.advancedBy(4)].elementsEqual("LIST".utf8) else {
      throw Error.SDTAStructurallyUnsound
    }

    // Get the sdta chunk size
    let sdtaSize = Int(Byte4(bytes[infoBytes.endIndex.advancedBy(4) ..< infoBytes.endIndex.advancedBy(8)]).bigEndian)

    // Check size against total bytes
    guard totalBytes >= infoBytes.endIndex.advancedBy(sdtaSize + 8) else {
      throw Error.SDTAStructurallyUnsound
    }

    // Create a reference slice of the sdta chunk
    let sdtaBytes = bytes[infoBytes.endIndex.advancedBy(8) ..< infoBytes.endIndex.advancedBy(sdtaSize + 8)]

    // Check for pdta list
    guard bytes[sdtaBytes.endIndex ..< sdtaBytes.endIndex.advancedBy(4)].elementsEqual("LIST".utf8) else {
      throw Error.PDTAStructurallyUnsound
    }

    // Get the sdta chunk size
    let pdtaSize = Int(Byte4(bytes[sdtaBytes.endIndex.advancedBy(4) ..< sdtaBytes.endIndex.advancedBy(8)]).bigEndian)

    // Check size against total bytes
    guard totalBytes >= sdtaBytes.endIndex.advancedBy(pdtaSize + 8) else {
      throw Error.PDTAStructurallyUnsound
    }

    // Create a reference slice of the sdta chunk
    let pdtaBytes = bytes[sdtaBytes.endIndex.advancedBy(8) ..< sdtaBytes.endIndex.advancedBy(pdtaSize + 8)]

    // Parse the chunks
    info = try INFOChunk(bytes: infoBytes)
    sdta = try SDTAChunk(bytes: sdtaBytes)
    pdta = try PDTAChunk(bytes: pdtaBytes)
  }

  /** Parses the info chunk of the file */
  private struct INFOChunk: CustomStringConvertible {
    let ifil: (major: Byte2, minor: Byte2)  // file version
    let isng: String                        // sound engine, less than 257 bytes, missing assume 'EMU8000'
    let inam: String                        // bank name, less than 257 bytes, ignore if missing
    let irom: String?                       // ROM, less than 257 bytes, ignore if missing
    let iver: (major: Byte2, minor: Byte2)? // ROM version
    let icrd: String?                       // creation date, less than 257 bytes, ignore if missing
    let ieng: String?                       // sound designers, less than 257 bytes, ignore if missing
    let iprd: String?                       // intended product, less than 257 bytes, ignore if missing
    let icop: String?                       // copywrite, less than 257 bytes, ignore if missing
    let icmt: String?                       // comment, less than 65,537 bytes, ignore if missing
    let isft: String?                       // creation tools, less than 257 bytes, ignore if missing

    var description: String {
      var result = "INFOChunk {\n"
      result += "  ifil: \(ifil.major).\(ifil.minor)\n"
      result += "  isng: \(isng)\n"
      result += "  inam: \(inam)\n"
      if let irom = irom { result += "  irom: \(irom)\n" }
      if let iver = iver { result += "  iver: \(iver.major).\(iver.minor)\n" }
      if let icrd = icrd { result += "  icrd: \(icrd)\n" }
      if let ieng = ieng { result += "  ieng: \(ieng)\n" }
      if let iprd = iprd { result += "  iprd: \(iprd)\n" }
      if let icop = icop { result += "  icop: \(icop)\n" }
      if let icmt = icmt { result += "  icmt: \(icmt)\n" }
      if let isft = isft { result += "  isft: \(isft)\n" }
      result += "}"
      return result
    }

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
      guard byteCount > 4 else { throw Error.INFOStructurallyUnsound }
      guard String(bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(4)]).lowercaseString == "info" else {
        throw Error.INFOStructurallyUnsound
      }
      var i = bytes.startIndex.advancedBy(4)
      var ifil: (major: Byte2, minor: Byte2)?
      var isng: String?
      var inam: String?
      var irom: String?
      var iver: (major: Byte2, minor: Byte2)?
      var icrd: String?
      var ieng: String?
      var iprd: String?
      var icop: String?
      var icmt: String?
      var isft: String?
      while i.advancedBy(8) < byteCount {
        let chunkType = String(Array(bytes[i ..< i.advancedBy(4)]))
        let chunkSize = Int(Byte4(bytes[i.advancedBy(4) ..< i.advancedBy(8)]).bigEndian)
        guard i.advancedBy(8 + chunkSize) <= bytes.endIndex else { throw Error.INFOStructurallyUnsound }
        let chunkData = bytes[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)]
        switch chunkType.lowercaseString {
          case "ifil":
            guard ifil == nil else { throw Error.INFOStructurallyUnsound }
            guard chunkSize == 4 else { throw Error.INFOStructurallyUnsound }
            ifil = (major: Byte2(chunkData[i.advancedBy(8) ... i.advancedBy(9)]), 
                    minor: Byte2(chunkData[i.advancedBy(10) ... i.advancedBy(11)]))
          case "isng":
            guard isng == nil else { throw Error.INFOStructurallyUnsound }
            isng = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
          case "inam":
            guard inam == nil else { throw Error.INFOStructurallyUnsound }
            inam = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
          case "irom":
            guard irom == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { irom = string }
          case "iver":
            guard iver == nil else { throw Error.INFOStructurallyUnsound }
            guard chunkSize == 4 else { throw Error.INFOStructurallyUnsound }
            iver = (major: Byte2(chunkData[i.advancedBy(8) ... i.advancedBy(9)]), 
                    minor: Byte2(chunkData[i.advancedBy(10) ... i.advancedBy(11)]))
          case "icrd":
            guard icrd == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { icrd = string }
          case "ieng":
            guard ieng == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { ieng = string }
          case "iprd":
            guard iprd == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { iprd = string }
          case "icop":
            guard icop == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { icop = string }
          case "icmt":
            guard icmt == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { icmt = string }
          case "isft":
            guard isft == nil else { throw Error.INFOStructurallyUnsound }
            let string = String(chunkData[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)])
            if !string.isEmpty { isft = string }
          default: continue
        }
        i.advanceBy(8 + chunkSize)
      }
      guard ifil != nil && isng != nil && inam != nil else { throw Error.INFOStructurallyUnsound }
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

  }

  /** Parses the sdta chunk of the file */
  private struct SDTAChunk: CustomStringConvertible {

    let smpl: Range<Int>?

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
      guard byteCount >= 4 && String(bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(4)]).lowercaseString == "sdta" else {
        throw Error.SDTAStructurallyUnsound
      }

      if byteCount > 8 {
        guard String(bytes[bytes.startIndex.advancedBy(4) ..< bytes.startIndex.advancedBy(8)]).lowercaseString == "smpl" else {
          throw Error.SDTAStructurallyUnsound
        }
        let smplSize = Int(Byte4(bytes[bytes.startIndex.advancedBy(8) ..< bytes.startIndex.advancedBy(12)]).bigEndian)
        guard byteCount >= smplSize + 12 else {
          throw Error.SDTAStructurallyUnsound
        }
        smpl = bytes.startIndex.advancedBy(12) ..< bytes.startIndex.advancedBy(smplSize + 12)
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

  /** Parses the pdta chunk of the file */
  private struct PDTAChunk: CustomStringConvertible {

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
      init?<C:CollectionType where C.Generator.Element == Byte,
                                   C.Index == Int, C.SubSequence.Generator.Element == Byte,
                                   C.SubSequence:CollectionType, C.SubSequence.Index == Int,
                                   C.SubSequence.SubSequence == C.SubSequence>(bytes: C) throws
      {
        guard bytes.count == 38 else { throw Error.PresetHeaderInvalid }
        name       = String(bytes[bytes.startIndex ..< (bytes.indexOf(Byte(0)) ?? bytes.startIndex.advancedBy(20))])
        preset     = Byte2(bytes[bytes.startIndex.advancedBy(20) ... bytes.startIndex.advancedBy(21)]).bigEndian
        bank       = Byte2(bytes[bytes.startIndex.advancedBy(22) ... bytes.startIndex.advancedBy(23)]).bigEndian
        bagIndex   = Byte2(bytes[bytes.startIndex.advancedBy(24) ... bytes.startIndex.advancedBy(25)]).bigEndian
        library    = Byte4(bytes[bytes.startIndex.advancedBy(26) ... bytes.startIndex.advancedBy(29)]).bigEndian
        genre      = Byte4(bytes[bytes.startIndex.advancedBy(30) ... bytes.startIndex.advancedBy(33)]).bigEndian
        morphology = Byte4(bytes[bytes.startIndex.advancedBy(34) ... bytes.startIndex.advancedBy(37)]).bigEndian
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
    init<C:CollectionType where C.Generator.Element == Byte,
                                C.Index == Int, C.SubSequence.Generator.Element == Byte,
                                C.SubSequence:CollectionType, C.SubSequence.Index == Int,
                                C.SubSequence.SubSequence == C.SubSequence>(bytes: C) throws
    {
      let byteCount = bytes.count
      guard byteCount > 4 else { throw Error.PDTAStructurallyUnsound }
      guard String(bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(4)]).lowercaseString == "pdta" else {
        throw Error.PDTAStructurallyUnsound
      }
      var i = bytes.startIndex.advancedBy(4)
      var phdr: [PresetHeader]?
      var pbag: Range<Int>?
      var pmod: Range<Int>?
      var pgen: Range<Int>?
      var inst: Range<Int>?
      var ibag: Range<Int>?
      var imod: Range<Int>?
      var igen: Range<Int>?
      var shdr: Range<Int>?
      while i.advancedBy(8) < bytes.endIndex {
        let chunkType = String(bytes[i ..< i.advancedBy(4)])
        let chunkSize = Int(Byte4(bytes[i.advancedBy(4) ..< i.advancedBy(8)]).bigEndian)
        guard byteCount >= i.advancedBy(8 + chunkSize) - bytes.startIndex else { throw Error.PDTAStructurallyUnsound }
        let chunkData = bytes[i.advancedBy(8) ..< i.advancedBy(8 + chunkSize)]
        func uniqueAssign(inout value: Range<Int>?) {
          guard case .None = value else { return }
          value = chunkData.indices
        }
        switch chunkType.lowercaseString {
          case "phdr":
            guard phdr == nil && chunkSize % 38 == 0 else { throw Error.PDTAStructurallyUnsound }
            var j = chunkData.startIndex
            var presetHeaders: [PresetHeader] = []
            while j < chunkData.endIndex, let presetHeader = try PresetHeader(bytes: chunkData[j ..< j.advancedBy(38)]) {
              presetHeaders.append(presetHeader)
              j.advanceBy(38)
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
        i.advanceBy(8 + chunkSize)
      }
      guard phdr != nil && pbag != nil && pmod != nil && pgen != nil && inst != nil 
         && ibag != nil && imod != nil && igen != nil && shdr != nil else {  throw Error.PDTAStructurallyUnsound }
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

}

func ==(lhs: SF2File.Preset, rhs: SF2File.Preset) -> Bool { return lhs.bank == rhs.bank && lhs.program == rhs.program }
func <(lhs: SF2File.Preset, rhs: SF2File.Preset) -> Bool {
  return lhs.bank < rhs.bank || lhs.bank == rhs.bank && lhs.program < rhs.program
}