//
//  SF2File.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

fileprivate func _chunkSize(_ data: Data.SubSequence) -> Int {
  return Int(Byte4(data).bigEndian)
}

fileprivate func _assert(_ condition: @autoclosure () -> Bool) throws {
  guard condition() else { throw SF2File.Error.StructurallyUnsound }
}

fileprivate func _remainingCount(_ data: Data.SubSequence) -> (Int) -> Int {
  return {
    data.distance(from: $0, to: data.endIndex)
  }
}

/// Parses the data from a SoundFont file, which consists of three chunks: info, sdta, and pdta
struct SF2File {

  let url: URL

  fileprivate let info: INFOChunk
  fileprivate let sdta: SDTAChunk
  fileprivate let pdta: PDTAChunk

  /// Initializer that takes a file url
  init(fileURL url: URL) throws {

    // Grab the url and data
    guard let data = try? Data(contentsOf: url) else { throw Error.ReadFailure }
    self.url = url

    let remainingCount = _remainingCount(data[data.startIndex ..< data.endIndex])

    // Check the riff header
    try _assert(   data.count > 8
                && String(data[0..<4]).lowercased() == "riff"
                && remainingCount(_chunkSize(data[4..<8]) + 8) == 0)

    // Check the bytes up to info size and get the info size
    try _assert(String(data[8..<16]) == "sfbkLIST")

    let infoSize = _chunkSize(data[16..<20])

    // Check that there are enough bytes for the info chunk size
    try _assert(remainingCount(infoSize + 20) >= 0)

    // Note info chunk's range
    let infoRange = 20 +--> infoSize

    var i = infoRange.upperBound

    // Check for sdta list
    try _assert(String(data[i +--> 4]).lowercased() == "list")

    i += 4 // Move i passed 'LIST'

    // Get the sdta chunk size
    let sdtaSize = _chunkSize(data[i +--> 4])

    i += 4 // Move i passed the chunk size

    // Check remaining size
    try _assert(remainingCount(i + sdtaSize) >= 0)


    // Note sdta chunk's range
    let sdtaRange = i +--> sdtaSize

    i = sdtaRange.upperBound // Move i passed th sdta chunk

    // Check for pdta list
    try _assert(String(data[i +--> 4]).lowercased() == "list")

    i += 4 // Move i passed 'LIST'

    // Get the pdta chunk size
    let pdtaSize = _chunkSize(data[i +--> 4])

    i += 4 // Move i passed the chunk size

    // Check remaining size
    try _assert(remainingCount(i + pdtaSize) >= 0)

    // Note pdata chunk's range
    let pdtaRange = i +--> pdtaSize

    // Parse the chunks
    info = try INFOChunk(data: data[infoRange])
    sdta = try SDTAChunk(data: data[sdtaRange])
    pdta = try PDTAChunk(data: data[pdtaRange])
    logVerbose(description)
  }

  var bytes: [Byte] {
    var result: [Byte] = "RIFF".bytes

    let listBytes = "LIST".bytes

    let infoBytes = info.bytes
    result += listBytes
    result += Byte4(infoBytes.count).bytes
    result += infoBytes

    let sdtaBytes = sdta.bytes
    result += listBytes
    result += Byte4(sdtaBytes.count).bytes
    result += sdtaBytes

    let pdtaBytes = pdta.bytes
    result += listBytes
    result += Byte4(pdtaBytes.count).bytes
    result += pdtaBytes

    return result
  }

}

// MARK: -

extension SF2File {

  enum Error: String, Swift.Error, CustomStringConvertible {
    case ReadFailure             = "Failed to obtain data from the file specified"
    case StructurallyUnsound     = "Invalid chunk detected"
    case PresetHeaderInvalid     = "Invalid preset header detected in PDTA chunk"
    case ParseError              = "Failed to parse chunk"
  }

}


// MARK: -

extension SF2File {

  struct Preset: Comparable, CustomStringConvertible, JSONValueConvertible {

    let name: String
    let program: Byte
    let bank: Byte

    var description: String { return "Preset {name: \(name); program: \(program); bank: \(bank)}" }

    var jsonValue: JSONValue { return ["name": name, "program": program, "bank": bank] }

    init(name: String, program: Byte, bank: Byte) { self.name = name; self.program = program; self.bank = bank }

    init?(_ jsonValue: JSONValue?) {
      guard let dict = ObjectJSONValue(jsonValue),
            let name = String(dict["name"]),
            let program = Byte(dict["program"]),
            let bank = Byte(dict["bank"]) else { return nil }
      self.name = name
      self.program = program
      self.bank = bank
    }

    static func ==(lhs: Preset, rhs: Preset) -> Bool {
      return lhs.bank == rhs.bank && lhs.program == rhs.program
    }

    static func <(lhs: Preset, rhs: Preset) -> Bool {
      return lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program)
    }

  }

  var presets: [Preset] {
    guard case let .presets(headers) = pdta.phdr.data else { return [] }
    return headers.map { Preset(name: $0.name, program: Byte($0.preset), bank: Byte($0.bank))}
  }

}

// MARK: - 

extension SF2File: CustomStringConvertible {

  var description: String {
    return [
      "url: '\(url.path)'",
      "info:\n\(info.description.indentedBy(1, preserveFirst: false, useTabs: true))",
      "sdta:\n\(sdta.description.indentedBy(1, preserveFirst: false, useTabs: true))",
      "pdta:\n\(pdta.description.indentedBy(1, preserveFirst: false, useTabs: true))"
      ].joined(separator: "\n")
  }

}

// MARK: -

extension SF2File {

  /// Parses the info chunk of the file
  struct INFOChunk: CustomStringConvertible {
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

    init(data: Data.SubSequence) throws {

      let remainingCount = _remainingCount(data)

      try _assert(   remainingCount(data.startIndex) > 4
                  && String(data[data.startIndex +--> 4]).lowercased() == "info")

      var i = data.startIndex + 4 // The index after 'INFO'

      var ifil: SubChunk?, isng: SubChunk?, inam: SubChunk?, irom: SubChunk?, iver: SubChunk?, icrd: SubChunk?,
          ieng: SubChunk?, iprd: SubChunk?, icop: SubChunk?, icmt: SubChunk?, isft: SubChunk?

      // Each subchunk begins with an 8-byte preamble containing the type and length
      let preambleSize = 8

      while i + preambleSize < data.endIndex {

        guard let chunkIdentifier = ChunkIdentifier(rawValue: String(data[i +--> 4]).lowercased()) else {
          throw SF2File.Error.StructurallyUnsound
        }

        i += 4 // Move i passed chunk type

        let chunkSize = _chunkSize(data[i +--> 4])

        i += 4 // Move i passed chunk size

        // Make sure there are enough remaining bytes for the chunk size
        try _assert(remainingCount(i) >= chunkSize)

        let chunkData = data[i +--> chunkSize]

        let chunk = try SubChunk(identifier: chunkIdentifier, data: chunkData)

        i += chunkSize // Move i passed chunk data

        switch chunk.identifier {
          case .ifil: try _assert(ifil == nil); ifil = chunk
          case .isng: try _assert(isng == nil); isng = chunk
          case .inam: try _assert(inam == nil); inam = chunk
          case .irom: try _assert(irom == nil); irom = chunk
          case .iver: try _assert(iver == nil); iver = chunk
          case .icrd: try _assert(icrd == nil); icrd = chunk
          case .ieng: try _assert(ieng == nil); ieng = chunk
          case .iprd: try _assert(iprd == nil); iprd = chunk
          case .icop: try _assert(icop == nil); icop = chunk
          case .icmt: try _assert(icmt == nil); icmt = chunk
          case .isft: try _assert(isft == nil); isft = chunk
          default:    throw SF2File.Error.StructurallyUnsound
        }

      }

      // Make sure the 3 required subchunks are present.
      try _assert(ifil != nil && isng != nil && inam != nil)

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

}

// MARK: - 

extension SF2File {

  struct SubChunk: CustomStringConvertible {
    let identifier: ChunkIdentifier
    let data: ChunkData


    var bytes: [Byte] {
      let chunkBytes = data.bytes
      let sizeBytes = Byte4(chunkBytes.count).bytes
      return identifier.bytes + sizeBytes + chunkBytes
    }

    fileprivate init(identifier: ChunkIdentifier, data: Data.SubSequence) throws {

      switch identifier {
        case .ifil, .iver:
          try _assert(data.count == 4)
          self.data = .version(major: Byte2(data.prefix(2)), minor: Byte2(data.suffix(2)))
        case .isng, .inam, .irom, .icrd, .ieng, .iprd, .icop, .icmt, .isft:
          try _assert(data.last == 0)
          self.data = .text(String(data))
        case .phdr:
          try _assert(data.count % 38 == 0)
//          let chunkSize = _chunkSize(data[data.startIndex +--> 4])
//          try _assert(chunkSize + 4 <= data.count && chunkSize % 38 == 0)
          var headers: [PresetHeader] = []
          var i = data.startIndex // Index after chunk size
          while i < data.endIndex, let header = try PresetHeader(data: data[i +--> 38]) {
            headers.append(header)
            i += 38
          }
          self.data = .presets(headers)

        default:
          self.data = .data(Data(data))
      }

      self.identifier = identifier

    }

    var description: String { return "\(identifier): \(data)" }

  }

}

// MARK: - 

extension SF2File {

  enum ChunkIdentifier: String {
    /// Info chunk identifiers
    case ifil, isng, inam, irom, iver, icrd, ieng, iprd, icop, icmt, isft

    /// SDTA chunk identifiers
    case smpl

    /// PDTA chunk identifiers
    case phdr, pbag, pmod, pgen, inst, ibag, imod, igen, shdr

    var bytes: [Byte] { return rawValue.lowercased().bytes }
  }


}

// MARK: - 

extension SF2File {

  enum ChunkData: CustomStringConvertible {
    case version (major: Byte2, minor: Byte2)
    case text (String)
    case data (Data)
    case presets ([PresetHeader])

    var bytes: [Byte] {
      switch self {
        case let .version(major, minor): return major.bytes + minor.bytes
        case let .text(string):          return string.bytes
        case let .data(data):            return Array(data)
        case let .presets(headers):      return headers.flatMap({$0.bytes}) + PresetHeader.EOP.bytes
      }
    }

    var description: String {
      switch self {
        case let .version(major, minor): return "\(major).\(minor)"
        case let .text(string):          return string
        case let .data(data):            return "\(data.count) bytes"
        case let .presets(headers):      return headers.map({$0.description}).joined(separator: "\n")
      }
    }

  }

}

// MARK: -

extension SF2File {

  /// Parses the sdta chunk of the file
  struct SDTAChunk: CustomStringConvertible {

    let smpl: SubChunk?

    init(data: Data.SubSequence) throws {
      try _assert(data.count >= 4 && String(data[data.startIndex +--> 4]).lowercased() == "sdta")

      guard data.count > 4 else { smpl = nil; return }

      try _assert(String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl")

      let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

      try _assert(data.count >= smplSize + 12)
      
      smpl = try SubChunk(identifier: .smpl, data: data[(data.startIndex + 12) +--> smplSize])
    }

    var bytes: [Byte] {
      guard let smpl = smpl else { return "sdta".bytes }
      return "sdta".bytes + smpl.bytes
    }

    var description: String { return "\(smpl?.description ?? "")" }

  }
}

// MARK: -

extension SF2File {

  /// Parses the pdta chunk of the file
  struct PDTAChunk: CustomStringConvertible {

    let phdr: SubChunk /// Names the Presets, and points to each of a Preset's Zones (which sub-divide each
                       /// Preset) in the "pbag" sub-chunk.
    let pbag: SubChunk /// Points each Preset Zone to data pointers and values in "pmod" and "pgen".
    let pmod: SubChunk /// Points to preset Modulators
    let pgen: SubChunk /// Points to preset Generators
    let inst: SubChunk /// Contains an Instrument, which names the virtual sub-instrument
                       /// and points to Instrument Zones (like Preset Zones) in "ibag".
    let ibag: SubChunk /// Points each Instrument Zone to data pointers and values in "imod" and "igen"
    let imod: SubChunk /// Points to instrument Modulators
    let igen: SubChunk /// Points to instrument Generators
    let shdr: SubChunk /// Contains a sound sample's information and a pointer to the sound sample in "sdta".

    init(data: Data.SubSequence) throws {

      let remainingCount = _remainingCount(data)

      try _assert(   remainingCount(data.startIndex) > 4
                  && String(data[data.startIndex +--> 4]).lowercased() == "pdta")

      var i = data.startIndex + 4 // The index after 'PDTA'

      var phdr: SubChunk?, pbag: SubChunk?, pmod: SubChunk?, pgen: SubChunk?, inst: SubChunk?,
          ibag: SubChunk?, imod: SubChunk?, igen: SubChunk?, shdr: SubChunk?

      // Each subchunk begins with an 8-byte preamble containing the type and length
      let preambleSize = 8

      while i + preambleSize < data.endIndex {

        guard let chunkIdentifier = ChunkIdentifier(rawValue: String(data[i +--> 4]).lowercased()) else {
          throw SF2File.Error.StructurallyUnsound
        }

        i += 4 // Move i passed chunk type

        let chunkSize = _chunkSize(data[i +--> 4])

        i += 4 // Move i passed chunk size

        // Make sure there are enough remaining bytes for the chunk size
        try _assert(remainingCount(i) >= chunkSize)

        let chunkData = data[i +--> chunkSize]

        let chunk = try SubChunk(identifier: chunkIdentifier, data: chunkData)

        i += chunkSize // Move i passed chunk data

        switch chunk.identifier {
          case .phdr: try _assert(phdr == nil); phdr = chunk
          case .pbag: try _assert(pbag == nil); pbag = chunk
          case .pmod: try _assert(pmod == nil); pmod = chunk
          case .pgen: try _assert(pgen == nil); pgen = chunk
          case .inst: try _assert(inst == nil); inst = chunk
          case .ibag: try _assert(ibag == nil); ibag = chunk
          case .imod: try _assert(imod == nil); imod = chunk
          case .igen: try _assert(igen == nil); igen = chunk
          case .shdr: try _assert(shdr == nil); shdr = chunk
          default:    throw SF2File.Error.StructurallyUnsound
        }

      }

      try _assert(   phdr != nil && pbag != nil && pmod != nil && pgen != nil 
                  && inst != nil && ibag != nil && imod != nil && igen != nil 
                  && shdr != nil)

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

}

// MARK: -
extension SF2File {

  struct PresetHeader: CustomStringConvertible {

    let name: String
    let preset: Byte2
    let bank: Byte2
    let bagIndex: Byte2
    let library: Byte4
    let genre: Byte4
    let morphology: Byte4

    static var EOP: PresetHeader { return PresetHeader(name: "EOP") }

    init(name: String,
         preset: Byte2 = 0,
         bank: Byte2 = 0,
         bagIndex: Byte2 = 0,
         library: Byte4 = 0,
         genre: Byte4 = 0,
         morphology: Byte4 = 0)
    {
      self.name = name
      self.preset = preset
      self.bank = bank
      self.bagIndex = bagIndex
      self.library = library
      self.genre = genre
      self.morphology = morphology
    }

    init?(data: Data.SubSequence) throws {
      try _assert(data.count == 38)

      let name = String(data[data.startIndex ..< (data.index(of: Byte(0)) ?? data.startIndex + 20)])
      guard !(name == "EOP" || name.isEmpty) else { return nil }

      self.name = name
      
      preset     = Byte2(data[data.startIndex + 20 ... data.startIndex + 21]).bigEndian
      bank       = Byte2(data[data.startIndex + 22 ... data.startIndex + 23]).bigEndian
      bagIndex   = Byte2(data[data.startIndex + 24 ... data.startIndex + 25]).bigEndian
      library    = Byte4(data[data.startIndex + 26 ... data.startIndex + 29]).bigEndian
      genre      = Byte4(data[data.startIndex + 30 ... data.startIndex + 33]).bigEndian
      morphology = Byte4(data[data.startIndex + 34 ... data.startIndex + 37]).bigEndian
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

