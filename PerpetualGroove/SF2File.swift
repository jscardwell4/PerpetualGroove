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
struct SF2File: CustomStringConvertible {

  let url: URL

  let infoRange: Range<Int>
  let sdtaRange: Range<Int>
  let pdtaRange: Range<Int>


  var description: String { return "\(url.path)" }

  var presets: [Preset] {
    guard let phdr = try? lazyPDTA.phdr.dataChunk(), case let .presets(headers) = phdr.data else { return [] }
    return headers
  }

  let info: INFOChunk

  private let lazySDTA: LazySDTAChunk
  private let lazyPDTA: LazyPDTAChunk


  func sdta() throws -> SDTAChunk {
    let data = try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
    return try SDTAChunk(data: data[sdtaRange])
  }

  func pdta() throws -> PDTAChunk {
    let data = try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
    return try PDTAChunk(data: data[pdtaRange])
  }

  /// Initializer that takes a file url
  init(fileURL url: URL) throws {

    // Grab the url and data
    let data = try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
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
    infoRange = 20 +--> infoSize

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
    sdtaRange = i +--> sdtaSize

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
    pdtaRange = i +--> pdtaSize

    info = try INFOChunk(data: data[infoRange])

    lazySDTA = try LazySDTAChunk(data: data[sdtaRange], url: url)
    lazyPDTA = try LazyPDTAChunk(data: data[pdtaRange], url: url)
  }

  static func presets(from url: URL) throws -> [Preset] {
    let data = try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
    guard let r = data.range(of: Data("pdtaphdr".bytes)) else { return [] }
    let s = _chunkSize(data[r.upperBound +--> 4])
    try _assert(s % 38 == 0)
    let dataʹ = data[(r.upperBound + 4) +--> s]
    return try stride(from: dataʹ.startIndex,
                      to: dataʹ.endIndex, by: 38).flatMap({try Preset(data: dataʹ[$0 +--> 38])}).sorted()
  }

}

// MARK: -

extension SF2File {

  enum Error: String, Swift.Error, CustomStringConvertible {
    case StructurallyUnsound = "Invalid chunk detected"
  }

}

extension SF2File {

  fileprivate struct Index {
    let url: URL
    let range: Range<Int>
    let subchunks: OrderedDictionary<ChunkIdentifier, Range<Int>>

    func data() throws -> Data {
      let data = try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
      return data.subdata(in: range)
    }

    func subchunkData(identifier: ChunkIdentifier) throws -> Data? {
      guard let range = subchunks[identifier] else { return nil }
      let data = try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
      return data.subdata(in: range)
    }

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
      self = Preset(name: name, program: program, bank: bank)
    }

    /// Initialize from a preset header subchunk from a pdta's phdr subchunk.
    init?(data: Data.SubSequence) throws {
      try _assert(data.count == 38)

      let name = String(data[data.startIndex ..< (data.index(of: Byte(0)) ?? data.startIndex + 20)])
      guard !(name == "EOP" || name.isEmpty) else { return nil }

      self.name = name

      program = Byte(Byte2(data[data.startIndex + 20 ... data.startIndex + 21]).bigEndian)
      bank = Byte(Byte2(data[data.startIndex + 22 ... data.startIndex + 23]).bigEndian)
    }


    static func ==(lhs: Preset, rhs: Preset) -> Bool {
      return lhs.bank == rhs.bank && lhs.program == rhs.program
    }

    static func <(lhs: Preset, rhs: Preset) -> Bool {
      return lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program)
    }

  }

}

// MARK: -

extension SF2File {

  /// Parses the info chunk of the file
  struct INFOChunk: CustomStringConvertible {
    let ifil: SubChunk  /// File version
    let isng: SubChunk  /// Sound engine, less than 257 bytes, missing assume 'EMU8000'
    let inam: SubChunk  /// Bank name, less than 257 bytes, ignore if missing
    let irom: SubChunk? /// ROM, less than 257 bytes, ignore if missing
    let iver: SubChunk? /// ROM version
    let icrd: SubChunk? /// Creation date, less than 257 bytes, ignore if missing
    let ieng: SubChunk? /// Sound designers, less than 257 bytes, ignore if missing
    let iprd: SubChunk? /// Intended product, less than 257 bytes, ignore if missing
    let icop: SubChunk? /// Copywrite, less than 257 bytes, ignore if missing
    let icmt: SubChunk? /// Comment, less than 65,537 bytes, ignore if missing
    let isft: SubChunk? /// Creation tools, less than 257 bytes, ignore if missing

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

  struct LazySubChunk: CustomStringConvertible {
    let identifier: ChunkIdentifier
    let url: URL
    let range: Range<Int>

    init(identifier: ChunkIdentifier, url: URL, range: Range<Int>) throws {
      switch identifier {
        case .ifil, .iver: try _assert(range.count == 4)
        case .phdr:        try _assert(range.count % 38 == 0)
        default:           break
      }
      self.identifier = identifier
      self.url = url
      self.range = range
    }

    func dataChunk() throws -> SubChunk { return try SubChunk(chunk: self) }

    var description: String { return "\(identifier): \(range) '\(url)'" }

  }
  
}

// MARK: -

extension SF2File {

  struct SubChunk: CustomStringConvertible {
    let identifier: ChunkIdentifier
    let data: ChunkData

    fileprivate init(chunk: LazySubChunk) throws {
      let data = try Data(contentsOf: chunk.url, options: [.uncached, .alwaysMapped])
      self = try SubChunk(identifier: chunk.identifier, data: data[chunk.range])
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
          var headers: [Preset] = []
          var i = data.startIndex // Index after chunk size
          while i < data.endIndex, let header = try Preset(data: data[i +--> 38]) {
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
  }


}

// MARK: - 

extension SF2File {

  enum ChunkData: CustomStringConvertible {
    case version (major: Byte2, minor: Byte2)
    case text (String)
    case data (Data)
    case presets ([Preset])

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
  struct LazySDTAChunk: CustomStringConvertible {

    let smpl: LazySubChunk?

    init(data: Data.SubSequence, url: URL) throws {
      try _assert(data.count >= 4 && String(data[data.startIndex +--> 4]).lowercased() == "sdta")

      guard data.count > 4 else { smpl = nil; return }

      try _assert(String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl")

      let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

      try _assert(data.count >= smplSize + 12)

      smpl = try LazySubChunk(identifier: .smpl, url: url, range: (data.startIndex + 12) +--> smplSize)
    }

    var description: String { return "\(smpl?.description ?? "")" }
    
  }

  /// Parses the sdta chunk of the file
  struct SDTAChunk: CustomStringConvertible {

    let smpl: SubChunk?

    init(chunk: LazySDTAChunk) throws { smpl = try chunk.smpl?.dataChunk() }

    init(data: Data.SubSequence) throws {
      try _assert(data.count >= 4 && String(data[data.startIndex +--> 4]).lowercased() == "sdta")

      guard data.count > 4 else { smpl = nil; return }

      try _assert(String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl")

      let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

      try _assert(data.count >= smplSize + 12)

      smpl = try SubChunk(identifier: .smpl, data: data[(data.startIndex + 12) +--> smplSize])
    }

    var description: String { return "\(smpl?.description ?? "")" }

  }
}

// MARK: -

extension SF2File {

  /// Parses the pdta chunk of the file
  struct LazyPDTAChunk: CustomStringConvertible {

    let phdr: LazySubChunk /// Names the Presets, and points to each of a Preset's Zones (which
                           /// sub-divide each Preset) in the "pbag" sub-chunk.
    let pbag: LazySubChunk /// Points each Preset Zone to data pointers and values in "pmod" and "pgen".
    let pmod: LazySubChunk /// Points to preset Modulators
    let pgen: LazySubChunk /// Points to preset Generators
    let inst: LazySubChunk /// Contains an Instrument, which names the virtual sub-
                           /// instrument and points to Instrument Zones (like Preset Zones) in "ibag".
    let ibag: LazySubChunk /// Points each Instrument Zone to data pointers and values in "imod" and "igen"
    let imod: LazySubChunk /// Points to instrument Modulators
    let igen: LazySubChunk /// Points to instrument Generators
    let shdr: LazySubChunk /// Contains a sound sample's information and a pointer to the sound sample in "sdta".

    init(data: Data.SubSequence, url: URL) throws {

      let remainingCount = _remainingCount(data)

      try _assert(   remainingCount(data.startIndex) > 4
                  && String(data[data.startIndex +--> 4]).lowercased() == "pdta")

      var i = data.startIndex + 4 // The index after 'PDTA'

      var phdr: LazySubChunk?, pbag: LazySubChunk?, pmod: LazySubChunk?, pgen: LazySubChunk?,
          inst: LazySubChunk?, ibag: LazySubChunk?, imod: LazySubChunk?, igen: LazySubChunk?,
          shdr: LazySubChunk?

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

        let chunk = try LazySubChunk(identifier: chunkIdentifier, url: url, range: i +--> chunkSize)

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

    init(chunk: LazyPDTAChunk) throws {
      phdr = try chunk.phdr.dataChunk()
      pbag = try chunk.pbag.dataChunk()
      pmod = try chunk.pmod.dataChunk()
      pgen = try chunk.pgen.dataChunk()
      inst = try chunk.inst.dataChunk()
      ibag = try chunk.ibag.dataChunk()
      imod = try chunk.imod.dataChunk()
      igen = try chunk.igen.dataChunk()
      shdr = try chunk.shdr.dataChunk()
    }

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
