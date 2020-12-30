//
//  SF2File.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

/// Returns `data` decoded into an integer.
fileprivate func _chunkSize(_ data: Data.SubSequence) -> Int {
  return Int(UInt64(data).bigEndian)
}

/// Evaluates `condition`.
/// - Throws: `SF2File.Error.StructurallyUnsound` when `condition` evaluates to `false`.
fileprivate func _assert(_ condition: @autoclosure () -> Bool) throws {
  guard condition() else { throw SF2File.Error.StructurallyUnsound }
}

/// Returns a closure for calculating the distance from an integer index to the end of `data`.
fileprivate func _remainingCount(_ data: Data.SubSequence) -> (Int) -> Int {
  return {
    data.distance(from: $0, to: data.endIndex)
  }
}

/// Parses the data from a SoundFont file, which consists of three chunks: info, sdta, and pdta
struct SF2File: CustomStringConvertible {

  /// Stores the data or the data's location for the file.
  private let storage: Storage

  /// The file url or `nil` if the file is stored in memory.
  var url: URL? { if case .url(let url) = storage { return url } else { return nil } }

  /// The range within the file's data corresponding to the info subchunk.
  let infoRange: Range<Int>

  /// The range within the file's data corresponding to the sdta subchunk.
  let sdtaRange: Range<Int>

  /// The range within the file's data corresponding to the pdta subchunk.
  let pdtaRange: Range<Int>

  var description: String { return "SF2File { storage: \(storage) }" }

  /// An array of presets obtained by decoding the phdr subchunk from the pdta subchunk.
  var presets: [PresetHeader] {
    guard let phdr = try? lazyPDTA.phdr.dataChunk(), case let .presets(headers) = phdr.data else { return [] }
    return headers
  }

  /// The decoded info subchunk for the file.
  let info: INFOChunk

  /// The lazy sdta chunk for the file.
  private let lazySDTA: LazySDTAChunk

  /// The lazy pdta chunk for the file.
  private let lazyPDTA: LazyPDTAChunk

  /// Returns the decoded sdta chunk for the file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding the subchunk.
  func sdta() throws -> SDTAChunk {
    return try SDTAChunk(data: try storage.data()[sdtaRange])
  }

  /// Returns the decoded pdta chunk for the file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding the subchunk.
  func pdta() throws -> PDTAChunk {
    return try PDTAChunk(data: try storage.data()[pdtaRange])
  }

  /// Initializing with raw data.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  init(data: Data) throws { try self.init(storage: .memory(data)) }

  /// Initializing with a file url.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  init(fileURL url: URL) throws { try self.init(storage: .url(url)) }

  /// Initializing with raw data or a file url.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  private init(storage: Storage) throws {

    // Store `storage`.
    self.storage = storage

    // Get the data for the file.
    let data = try storage.data()

    // Generate a closure for calculating the remaining byte count.
    let remainingCount = _remainingCount(data[data.startIndex ..< data.endIndex])

    // Check the riff header
    try _assert(   data.count > 8
      && String(data[0..<4]).lowercased() == "riff"
      && remainingCount(_chunkSize(data[4..<8]) + 8) == 0)

    // Check the bytes up to info size and get the info size
    try _assert(String(data[8..<16]) == "sfbkLIST")

    // Get the size of the info chunk.
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

    // Decode the info chunk.
    info = try INFOChunk(data: data[infoRange])

    // Lazily decode the sdta and pdta chunks.
    lazySDTA = try LazySDTAChunk(data: data[sdtaRange], storage: storage)
    lazyPDTA = try LazyPDTAChunk(data: data[pdtaRange], storage: storage)

  }

  /// Returns the collection of preset headers decoded from the data representation of a sound font file.
  /// This method should only be used when one's only interest in a sound font file is the presets contained
  /// within.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  static func presetHeaders(from data: Data) throws -> [PresetHeader] {

    // Get the range of the characters within `data` denoting the start of the phdr subchunk.
    guard let range = data.range(of: Data("pdtaphdr".bytes)) else { return [] }

    // Get the size of the phdr subchunk.
    let size = _chunkSize(data[range.upperBound +--> 4])

    // Check that the size consists of zero or more 38 byte chunks.
    try _assert(size % 38 == 0)

    // Get the stream of 38 byte chunks to decode into preset headers.
    let dataʹ = data[(range.upperBound + 4) +--> size]

    // Create a collection to hold the decoded preset headers.
    var presetHeaders: [PresetHeader] = []

    // Iterate the bytes of data in 38 byte chunks.
    for index in stride(from: dataʹ.startIndex, to: dataʹ.endIndex, by: 38) {

      // Decode the chunk that starts at `index`.
      guard let presetHeader = try PresetHeader(data: dataʹ[index +--> 38]) else { continue }

      // Append the decoded preset header.
      presetHeaders.append(presetHeader)

    }

    // Sort the collection of preset headers.
    presetHeaders.sort()

    return presetHeaders

  }

  /// An enumeration for wrapping the source of a sound font file.
  enum Storage: CustomStringConvertible {

    /// The data for the file is located on disk.
    case url (URL)

    /// The data for the file is located in memory.
    case memory (Data)

    /// Returns the wrapped file data.
    /// - Throws: Any error thrown attempting to retrieve the contents of a url.
    func data() throws -> Data {

      switch self {

        case .url(let url):
          return try Data(contentsOf: url, options: [.uncached, .alwaysMapped])

        case .memory(let data):
          return data
        
      }

    }

    var description: String {
      switch self {
        case .url(let url):   return ".url(\(url.path))"
        case .memory(let data): return ".data(\(data.count) bytes)"
      }
    }

  }

  /// Enumeration of the possible errors thrown by `SF2File`.
  enum Error: String, Swift.Error, CustomStringConvertible {

    case StructurallyUnsound = "Invalid chunk detected"

  }

  /// A structure for representing a preset header parsed while decoding a sound font file.
  struct PresetHeader: Comparable, CustomStringConvertible, JSONValueConvertible, JSONValueInitializable {

    /// The name of the preset.
    let name: String

    /// The program assigned to the preset.
    let program: UInt8

    /// The bank assigned to the preset.
    let bank: UInt8

    var description: String { return "PresetHeader {name: \(name); program: \(program); bank: \(bank)}" }

    /// The preset header converted to a JSON object.
    var jsonValue: JSONValue { return ["name": name, "program": program, "bank": bank] }

    /// Initializing with known property values.
    init(name: String, program: UInt8, bank: UInt8) {
      self.name = name
      self.program = program
      self.bank = bank
    }

    /// Initializing from a JSON value. To be successful, `jsonValue` needs to be a JSON object
    /// with keys 'name', 'program', and 'bank' with values convertible to `String`, `UInt8`, and `UInt8`.
    init?(_ jsonValue: JSONValue?) {

      // Retrieve the property values.
      guard let dict = ObjectJSONValue(jsonValue),
            let name = String(dict["name"]),
            let program = UInt8(dict["program"]),
            let bank = UInt8(dict["bank"])
        else
      {
        return nil
      }

      // Initialize using the retrieved property values.
      self = PresetHeader(name: name, program: program, bank: bank)

    }

    /// Initialize from a preset header subchunk from a pdta's phdr subchunk.
    init?(data: Data.SubSequence) throws {

      // Check the size of the data.
      try _assert(data.count == 38)

      // Decode the preset's name.
      name = String(data[data.startIndex ..< (data.index(of: UInt8(0)) ?? data.startIndex + 20)])

      // Decode the program
      program = UInt8(UInt16(data[data.startIndex + 20 ... data.startIndex + 21]).bigEndian)

      // Decode the bank.
      bank = UInt8(UInt16(data[data.startIndex + 22 ... data.startIndex + 23]).bigEndian)

      // Check that the name is valid and that it is not the end marker for a list of presets.
      guard name != "EOP" && !name.isEmpty else { return nil }

    }

    /// Returns `true` iff the two preset headers have equal bank and program values.
    static func ==(lhs: PresetHeader, rhs: PresetHeader) -> Bool {
      return lhs.bank == rhs.bank && lhs.program == rhs.program
    }

    /// Returns `true` iff the bank value of `lhs` is less than that of `rhs` or the bank values are
    /// equal and the program value of `lhs` is less than that of `rhs`.
    static func <(lhs: PresetHeader, rhs: PresetHeader) -> Bool {
      return lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program)
    }

  }

  /// Parses the info chunk of the file
  struct INFOChunk: CustomStringConvertible {

    /// File version.
    let ifil: SubChunk

    /// Sound engine, less than 257 bytes, missing assume 'EMU8000'.
    let isng: SubChunk

    /// Bank name, less than 257 bytes, ignore if missing.
    let inam: SubChunk

    /// ROM, less than 257 bytes, ignore if missing.
    let irom: SubChunk?

    /// ROM version.
    let iver: SubChunk?

    /// Creation date, less than 257 bytes, ignore if missing.
    let icrd: SubChunk?

    /// Sound designers, less than 257 bytes, ignore if missing.
    let ieng: SubChunk?

    /// Intended product, less than 257 bytes, ignore if missing.
    let iprd: SubChunk?

    /// Copywrite, less than 257 bytes, ignore if missing.
    let icop: SubChunk?

    /// Comment, less than 65,537 bytes, ignore if missing.
    let icmt: SubChunk?

    /// Creation tools, less than 257 bytes, ignore if missing.
    let isft: SubChunk?

    /// Initializing with data.
    /// - Throws: `Error.StructurallyUnsound`
    init(data: Data.SubSequence) throws {

      // Generate a function for calculating the remaining byte count.
      let remainingCount = _remainingCount(data)


      // Check that the data begins with info declaration.
      try _assert(   remainingCount(data.startIndex) > 4
                  && String(data[data.startIndex +--> 4]).lowercased() == "info")


      var i = data.startIndex + 4 // The index after 'INFO'

      // Create variable for holding decoded values.
      var ifil: SubChunk?, isng: SubChunk?, inam: SubChunk?, irom: SubChunk?, iver: SubChunk?, icrd: SubChunk?,
          ieng: SubChunk?, iprd: SubChunk?, icop: SubChunk?, icmt: SubChunk?, isft: SubChunk?

      // Each subchunk begins with an 8-byte preamble containing the type and length
      let preambleSize = 8

      // Iterate while there are at least enough bytes for the preamble.
      while i + preambleSize < data.endIndex {

        // Get the identifier for the subchunk.
        guard let chunkIdentifier = ChunkIdentifier(rawValue: String(data[i +--> 4]).lowercased()) else {
          throw Error.StructurallyUnsound
        }

        i += 4 // Move i passed chunk type

        // Get the size of the subchunk.
        let chunkSize = _chunkSize(data[i +--> 4])

        i += 4 // Move i passed chunk size

        // Make sure there are enough remaining bytes for the chunk size
        try _assert(remainingCount(i) >= chunkSize)

        // Get the subchunk's data.
        let chunkData = data[i +--> chunkSize]

        // Try creating a subchunk using the data.
        let chunk = try SubChunk(identifier: chunkIdentifier, data: chunkData)

        // Store the subchunk in the corresponding variable, throwing an error if more than one 
        // subchunk with the same identifier have been decoded.
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
          default:    throw Error.StructurallyUnsound
        }

        i += chunkSize // Move i passed chunk data

     }

      // Make sure the 3 required subchunks are present.
      try _assert(ifil != nil && isng != nil && inam != nil)

      // Store the variables in the corresponding property values.
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

  /// A type for storing a subchunk's location and type without processing the entire chunk of data.
  struct LazySubChunk: CustomStringConvertible {

    /// The unique identifier for the subchunk within a sound font file.
    let identifier: ChunkIdentifier

    /// The data or its location that contains the subchunk.
    let storage: Storage

    /// The location of the subchunk's data within the data of the sound font file.
    let range: Range<Int>

    /// Initializing with known values.
    /// - Throws: `Error.StructurallyUnsound` when the size of a subchunk with `identifier` is statically 
    ///           known and `range` specifies a different size.
    init(identifier: ChunkIdentifier, storage: Storage, range: Range<Int>) throws {

      // Check identifier for known chunk sizes.
      switch identifier {
        case .ifil, .iver: try _assert(range.count == 4)
        case .phdr:        try _assert(range.count % 38 == 0)
        default:           break
      }

      // Set property values.
      self.identifier = identifier
      self.storage = storage
      self.range = range
    }

    /// Returns a fully processed subchunk.
    /// - Throws: Any error encountered while initializing the subchunk.
    func dataChunk() throws -> SubChunk { return try SubChunk(chunk: self) }

    var description: String { return "\(identifier): \(range) \(storage)" }

  }

  /// A subchunk in a sound font file.
  struct SubChunk: CustomStringConvertible {

    /// The unique identifier for the subchunk within a sound font file.
    let identifier: ChunkIdentifier

    /// The subchunk's data.
    let data: ChunkData

    /// Initializing with the identifier and data obtained from a lazy subchunk.
    /// - Throws: Any error encountered retrieving the data from `chunk`.
    /// - Throws: `Error.StructurallyUnsound`.
    init(chunk: LazySubChunk) throws {
      self = try SubChunk(identifier: chunk.identifier, data: try chunk.storage.data()[chunk.range])
    }

    /// Initializing with an identifier and the chunk's data.
    init(identifier: ChunkIdentifier, data: Data.SubSequence) throws {

      // Process the data into an enumerated value that matches the kind expected for `identifier`.
      switch identifier {

        case .ifil, .iver:
          // The data should be the major and minor version.

          // Check the number of bytes.
          try _assert(data.count == 4)

          // Initialize data using the first two bytes for 'major' and the last two bytes for 'minor'.
          self.data = .version(major: UInt16(data.prefix(2)), minor: UInt16(data.suffix(2)))

        case .isng, .inam, .irom, .icrd, .ieng, .iprd, .icop, .icmt, .isft:
          // The data should be null terminated ascii text.

          // Check for null termination.
          try _assert(data.last == 0)

          // Initialize data.
          self.data = .text(String(data))

        case .phdr:
          // The data should be a list of preset headers.

          // Check that the data consists of zero or more 38 byte chunks.
          try _assert(data.count % 38 == 0)

          // Create an array to accumulate headers.
          var headers: [PresetHeader] = []

          var i = data.startIndex // Index after chunk size

          // Iterate through the data appending successfully decoded preset headers to `headers`.
          while i < data.endIndex, let header = try PresetHeader(data: data[i +--> 38]) {
            headers.append(header)
            i += 38
          }

          // Intialize data.
          self.data = .presets(headers)

        default:
          // The data is simply data. Initialize with `data`.

          self.data = .data(Data(data))

      }

      // Set the subchunk's identifier.
      self.identifier = identifier

    }

    var description: String { return "\(identifier): \(data)" }

  }

  /// An enumeration of unique identifiers for subchunks within a sound font file.
  enum ChunkIdentifier: String {

    // Info chunk identifiers

    /// File version.
    case ifil

    /// Sound engine, less than 257 bytes, missing assume 'EMU8000'.
    case isng

    /// Bank name, less than 257 bytes, ignore if missing.
    case inam

    /// ROM, less than 257 bytes, ignore if missing.
    case irom

    /// ROM version.
    case iver

    /// Creation date, less than 257 bytes, ignore if missing.
    case icrd

    /// Sound designers, less than 257 bytes, ignore if missing.
    case ieng

    /// Intended product, less than 257 bytes, ignore if missing.
    case iprd

    /// Copywrite, less than 257 bytes, ignore if missing.
    case icop

    /// Comment, less than 65,537 bytes, ignore if missing.
    case icmt

    /// Creation tools, less than 257 bytes, ignore if missing.
    case isft

    // SDTA chunk identifiers

    /// Sample data.
    case smpl

    // PDTA chunk identifiers

    /// Names the Presets, and points to each of a Preset's Zones (which sub-divide each Preset) 
    /// in the "pbag" sub-chunk.
    case phdr

    /// Points each Preset Zone to data pointers and values in "pmod" and "pgen".
    case pbag

    /// Points to preset Modulators.
    case pmod

    /// Points to preset Generators.
    case pgen

    /// Contains an Instrument, which names the virtual sub-instrument and points to Instrument 
    /// Zones (like Preset Zones) in "ibag".
    case inst

    /// Points each Instrument Zone to data pointers and values in "imod" and "igen".
    case ibag

    /// Points to instrument Modulators.
    case imod

    /// Points to instrument Generators.
    case igen

    /// Contains a sound sample's information and a pointer to the sound sample in "sdta".
    case shdr

  }

  /// Enumeration wrapping the data belonging to a subchunk in a sound font file.
  enum ChunkData: CustomStringConvertible {

    /// Values that represent a major and minor version.
    case version (major: UInt16, minor: UInt16)

    /// Null terminated ascii text.
    case text (String)

    /// Raw data.
    case data (Data)

    /// A collection of preset headers.
    case presets ([PresetHeader])

    var description: String {

      switch self {
        case let .version(major, minor): return "\(major).\(minor)"
        case let .text(string):          return string
        case let .data(data):            return "\(data.count) bytes"
        case let .presets(headers):      return headers.map({$0.description}).joined(separator: "\n")
      }

    }

  }

  /// A struct for holding lazy data corresponding to the sdta chunk of a sound font file.
  struct LazySDTAChunk: CustomStringConvertible {

    /// Stores a lazy version of the optional smpl subchunk of a sound font file.
    let smpl: LazySubChunk?

    /// Initializing with data and its origin.
    /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
    init(data: Data.SubSequence, storage: Storage) throws {

      // Check that the data begins with 'SDTA'.
      try _assert(data.count >= 4 && String(data[data.startIndex +--> 4]).lowercased() == "sdta")

      // Check that the data contains a subchunk.
      guard data.count > 4 else {

        smpl = nil
        return

      }

      // Check that the subchunk begins with 'smpl'.
      try _assert(String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl")

      // Get the size of the subchunk.
      let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

      // Check that data is large enough to contain the subchunk as specified by the decoded size.
      try _assert(data.count >= smplSize + 12)

      // Calculate the range of the subchunk.
      let range = (data.startIndex + 12) +--> smplSize

      // Initialize the lazy smpl subchunk.
      smpl = try LazySubChunk(identifier: .smpl, storage: storage, range: range)

    }

    var description: String { return "\(smpl?.description ?? "")" }
    
  }

  /// A struct for holding data corresponding to the sdta chunk of a sound font file.
  struct SDTAChunk: CustomStringConvertible {

    /// Stores the optional smpl subchunk of a sound font file.
    let smpl: SubChunk?

    /// Initializing from a lazy sdta chunk.
    /// - Throws: Any error encountered converting the lazy subchunk into a subchunk.
    init(chunk: LazySDTAChunk) throws { smpl = try chunk.smpl?.dataChunk() }

    /// Intitializing with data.
    /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
    init(data: Data.SubSequence) throws {

      // Check that the data begins with 'SDTA'.
      try _assert(data.count >= 4 && String(data[data.startIndex +--> 4]).lowercased() == "sdta")

      // Check that the data contains a subchunk.
      guard data.count > 4 else {

        smpl = nil
        return

      }

      // Check that the subchunk begins with 'smpl'.
      try _assert(String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl")

      // Get the size of the subchunk.
      let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

      // Check that data is large enough to contain the subchunk as specified by the decoded size.
      try _assert(data.count >= smplSize + 12)

      // Calculate the range of the subchunk.
      let range = (data.startIndex + 12) +--> smplSize
      
      // Initialize the smpl subchunk.
      smpl = try SubChunk(identifier: .smpl, data: data[range])

    }

    var description: String { return "\(smpl?.description ?? "")" }

  }

  /// A struct for holding lazy data corresponding to the pdta chunk of a sound font file.
  struct LazyPDTAChunk: CustomStringConvertible {

    /// Names the presets and points to each of its zones in the `pbag` subchunk.
    let phdr: LazySubChunk

    /// Points each preset zone to data pointers and values in `pmod` and `pgen`.
    let pbag: LazySubChunk

    /// Points to preset modulators.
    let pmod: LazySubChunk

    /// Points to preset generators.
    let pgen: LazySubChunk

    /// Contains an Instrument, which names the virtual sub-instrument and points to zones in `ibag`.
    let inst: LazySubChunk

    /// Points each instrument zone to data pointers and values in `imod` and `igen`.
    let ibag: LazySubChunk

    /// Points to instrument Modulators.
    let imod: LazySubChunk

    /// Points to instrument Generators.
    let igen: LazySubChunk

    /// Contains a sound sample's information and a pointer to the sound sample in the sdta chunk.
    let shdr: LazySubChunk

    /// Initializing with data and its origin.
    /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
    init(data: Data.SubSequence, storage: Storage) throws {

      // Generate a function for calculating the number of bytes remaining in `data`.
      let remainingCount = _remainingCount(data)

      // Check that the data begins with 'PDTA'.
      try _assert(   remainingCount(data.startIndex) > 4
                  && String(data[data.startIndex +--> 4]).lowercased() == "pdta")

      var i = data.startIndex + 4 // The index after 'PDTA'

      // Create variables for storing lazy the subchunks.
      var phdr: LazySubChunk?, pbag: LazySubChunk?, pmod: LazySubChunk?, pgen: LazySubChunk?,
          inst: LazySubChunk?, ibag: LazySubChunk?, imod: LazySubChunk?, igen: LazySubChunk?,
          shdr: LazySubChunk?

      // Each subchunk begins with an 8-byte preamble containing the type and length
      let preambleSize = 8

      // Iterate while there is at least a preamble-sized chunk of data to decode.
      while i + preambleSize < data.endIndex {

        // Get the identifier for the next subchunk.
        guard let chunkIdentifier = ChunkIdentifier(rawValue: String(data[i +--> 4]).lowercased()) else {
          throw Error.StructurallyUnsound
        }

        i += 4 // Move i passed chunk type

        // Get the expected size of the next subchunk.
        let chunkSize = _chunkSize(data[i +--> 4])

        i += 4 // Move i passed chunk size

        // Make sure there are enough remaining bytes.
        try _assert(remainingCount(i) >= chunkSize)

        // Calculate the range of the next subchunk.
        let range = i +--> chunkSize

        // Create a lazy subchunk with the decoded identifier and calculated range.
        let chunk = try LazySubChunk(identifier: chunkIdentifier, storage: storage, range: range)

        // Store the subchunk in the corresponding variable, throwing an error if more than one
        // subchunk with the same identifier have been decoded.
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
          default:    throw Error.StructurallyUnsound
        }

        i += chunkSize // Move i passed chunk data

      }

      // Check that all the subchunks have been decoded.
      try _assert(   phdr != nil && pbag != nil && pmod != nil && pgen != nil 
                  && inst != nil && ibag != nil && imod != nil && igen != nil 
                  && shdr != nil)

      // Initialize the properties with their corresponding local variable's value.
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
      return [
        "phdr:\n\(phdr.description.indented(by: 1, useTabs: true))",
        "pbag: \(pbag)",
        "pmod: \(pmod)",
        "pgen: \(pgen)",
        "inst: \(inst)",
        "ibag: \(ibag)",
        "imod: \(imod)",
        "igen: \(igen)",
        "shdr: \(shdr)"
      ].joined(separator: "\n")
    }

  }

  /// A struct for holding data corresponding to the pdta chunk of a sound font file.
  struct PDTAChunk: CustomStringConvertible {

    /// Names the presets and points to each of its zones in the `pbag` subchunk.
    let phdr: SubChunk

    /// Points each preset zone to data pointers and values in `pmod` and `pgen`.
    let pbag: SubChunk

    /// Points to preset modulators.
    let pmod: SubChunk

    /// Points to preset generators.
    let pgen: SubChunk

    /// Contains an Instrument, which names the virtual sub-instrument and points to zones in `ibag`.
    let inst: SubChunk

    /// Points each instrument zone to data pointers and values in `imod` and `igen`.
    let ibag: SubChunk

    /// Points to instrument Modulators.
    let imod: SubChunk

    /// Points to instrument Generators.
    let igen: SubChunk

    /// Contains a sound sample's information and a pointer to the sound sample in the sdta chunk.
    let shdr: SubChunk

    /// Initializing from a lazy pdta chunk.
    /// - Throws: Any error encountered converting the lazy subchunks into a subchunks.
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

    /// Initializing with data.
    /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
    init(data: Data.SubSequence) throws {

      // Generate a function for calculating the number of bytes remaining in `data`.
      let remainingCount = _remainingCount(data)

      // Check that the data begins with 'PDTA'.
      try _assert(   remainingCount(data.startIndex) > 4
                  && String(data[data.startIndex +--> 4]).lowercased() == "pdta")

      var i = data.startIndex + 4 // The index after 'PDTA'

      // Create variables for storing lazy the subchunks.
      var phdr: SubChunk?, pbag: SubChunk?, pmod: SubChunk?, pgen: SubChunk?,
          inst: SubChunk?, ibag: SubChunk?, imod: SubChunk?, igen: SubChunk?,
          shdr: SubChunk?

      // Each subchunk begins with an 8-byte preamble containing the type and length
      let preambleSize = 8

      // Iterate while there is at least a preamble-sized chunk of data to decode.
      while i + preambleSize < data.endIndex {

        // Get the identifier for the next subchunk.
        guard let chunkIdentifier = ChunkIdentifier(rawValue: String(data[i +--> 4]).lowercased()) else {
          throw Error.StructurallyUnsound
        }

        i += 4 // Move i passed chunk type

        // Get the expected size of the next subchunk.
        let chunkSize = _chunkSize(data[i +--> 4])

        i += 4 // Move i passed chunk size

        // Make sure there are enough remaining bytes.
        try _assert(remainingCount(i) >= chunkSize)

        // Calculate the range of the next subchunk.
        let range = i +--> chunkSize

        // Create a lazy subchunk with the decoded identifier and calculated range.
        let chunk = try SubChunk(identifier: chunkIdentifier, data: data[range])

        // Store the subchunk in the corresponding variable, throwing an error if more than one
        // subchunk with the same identifier have been decoded.
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
          default:    throw Error.StructurallyUnsound
        }

        i += chunkSize // Move i passed chunk data

      }

      // Check that all the subchunks have been decoded.
      try _assert(   phdr != nil && pbag != nil && pmod != nil && pgen != nil
        && inst != nil && ibag != nil && imod != nil && igen != nil
        && shdr != nil)

      // Initialize the properties with their corresponding local variable's value.
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

      return [
        "phdr:\n\(phdr.description.indented(by: 1, useTabs: true))",
        "pbag: \(pbag)",
        "pmod: \(pmod)",
        "pgen: \(pgen)",
        "inst: \(inst)",
        "ibag: \(ibag)",
        "imod: \(imod)",
        "igen: \(igen)",
        "shdr: \(shdr)"
      ].joined(separator: "\n")

    }

  }

}
