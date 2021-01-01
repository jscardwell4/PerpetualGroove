//
//  PDTAChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import MoonKit

/// A struct for holding lazy data corresponding to the pdta chunk of a sound font file.
public struct LazyPDTAChunk {
  /// Names the presets and points to each of its zones in the `pbag` subchunk.
  public let phdr: LazySubChunk

  /// Points each preset zone to data pointers and values in `pmod` and `pgen`.
  public let pbag: LazySubChunk

  /// Points to preset modulators.
  public let pmod: LazySubChunk

  /// Points to preset generators.
  public let pgen: LazySubChunk

  /// Contains an Instrument, which names the virtual sub-instrument and points to zones
  /// in `ibag`.
  public let inst: LazySubChunk

  /// Points each instrument zone to data pointers and values in `imod` and `igen`.
  public let ibag: LazySubChunk

  /// Points to instrument Modulators.
  public let imod: LazySubChunk

  /// Points to instrument Generators.
  public let igen: LazySubChunk

  /// Contains a sound sample's information and a pointer to the sound sample in the
  /// sdta chunk.
  public let shdr: LazySubChunk

  /// Initializing with data and its origin.
  ///
  /// - Parameters:
  ///   - data: The data with which to initialize.
  ///   - storage: The origin of `data`.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public init(data: Data.SubSequence, storage: Storage) throws {

    // Check that the data begins with 'PDTA'.
    guard data.distance(from: data.startIndex, to: data.endIndex) > 4,
          String(data[data.startIndex +--> 4]).lowercased() == "pdta"
    else
    {
      throw Error.StructurallyUnsound
    }

    var i = data.startIndex + 4 // The index after 'PDTA'

    // Create variables for storing lazy the subchunks.
    var phdr: LazySubChunk?, pbag: LazySubChunk?, pmod: LazySubChunk?,
        pgen: LazySubChunk?, inst: LazySubChunk?, ibag: LazySubChunk?,
        imod: LazySubChunk?, igen: LazySubChunk?, shdr: LazySubChunk?

    // Each subchunk begins with an 8-byte preamble containing the type and length
    let preambleSize = 8

    // Iterate while there is at least a preamble-sized chunk of data to decode.
    while i + preambleSize < data.endIndex {

      let identifier = String(data[i +--> 4]).lowercased()

      // Get the identifier for the next subchunk.
      guard let chunkIdentifier = SubChunkIdentifier(rawValue: identifier) else {
        throw Error.StructurallyUnsound
      }

      i += 4 // Move i passed chunk type

      // Get the expected size of the next subchunk.
      let chunkSize = _chunkSize(data[i +--> 4])

      i += 4 // Move i passed chunk size

      // Make sure there are enough remaining bytes.
      guard data.distance(from: i, to: data.endIndex) >= chunkSize else {
        throw Error.StructurallyUnsound
      }

      // Calculate the range of the next subchunk.
      let range = i +--> chunkSize

      // Create a lazy subchunk with the decoded identifier and calculated range.
      let chunk = try LazySubChunk(identifier: chunkIdentifier,
                                   storage: storage,
                                   range: range)

      // Store the subchunk in the corresponding variable, throwing an error if more
      // than one subchunk with the same identifier have been decoded.
      switch chunk.identifier {
        case .phdr:
          guard phdr == nil else { throw Error.StructurallyUnsound }
          phdr = chunk
        case .pbag:
          guard pbag == nil else { throw Error.StructurallyUnsound }
          pbag = chunk
        case .pmod:
          guard pmod == nil else { throw Error.StructurallyUnsound }
          pmod = chunk
        case .pgen:
          guard pgen == nil else { throw Error.StructurallyUnsound }
          pgen = chunk
        case .inst:
          guard inst == nil else { throw Error.StructurallyUnsound }
          inst = chunk
        case .ibag:
          guard ibag == nil else { throw Error.StructurallyUnsound }
          ibag = chunk
        case .imod:
          guard imod == nil else { throw Error.StructurallyUnsound }
          imod = chunk
        case .igen:
          guard igen == nil else { throw Error.StructurallyUnsound }
          igen = chunk
        case .shdr:
          guard shdr == nil else { throw Error.StructurallyUnsound }
          shdr = chunk
        default: throw Error.StructurallyUnsound
      }

      i += chunkSize // Move i passed chunk data
    }

    // Check that all the subchunks have been decoded.
    guard phdr != nil,
          pbag != nil,
          pmod != nil,
          pgen != nil,
          inst != nil,
          ibag != nil,
          imod != nil,
          igen != nil,
          shdr != nil
    else
    {
      throw Error.StructurallyUnsound
    }

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

}

extension LazyPDTAChunk: CustomStringConvertible {
  public var description: String {
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
public struct PDTAChunk {
  /// Names the presets and points to each of its zones in the `pbag` subchunk.
  public let phdr: SubChunk

  /// Points each preset zone to data pointers and values in `pmod` and `pgen`.
  public let pbag: SubChunk

  /// Points to preset modulators.
  public let pmod: SubChunk

  /// Points to preset generators.
  public let pgen: SubChunk

  /// Contains an Instrument, which names the virtual sub-instrument and points to
  /// zones in `ibag`.
  public let inst: SubChunk

  /// Points each instrument zone to data pointers and values in `imod` and `igen`.
  public let ibag: SubChunk

  /// Points to instrument Modulators.
  public let imod: SubChunk

  /// Points to instrument Generators.
  public let igen: SubChunk

  /// Contains a sound sample's information and a pointer to the sound sample in the
  /// sdta chunk.
  public let shdr: SubChunk

  /// Initializing from a lazy pdta chunk.
  ///
  /// - Parameter chunk: The lazy chunk with which to initialize.
  /// - Throws: Any error encountered converting the lazy subchunks into a subchunks.
  public init(chunk: LazyPDTAChunk) throws {
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
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public init(data: Data.SubSequence) throws {

    // Check that the data begins with 'PDTA'.
    guard data.distance(from: data.startIndex, to: data.endIndex) > 4,
          String(data[data.startIndex +--> 4]).lowercased() == "pdta"
    else
    {
      throw Error.StructurallyUnsound
    }

    var i = data.startIndex + 4 // The index after 'PDTA'

    // Create variables for storing lazy the subchunks.
    var phdr: SubChunk?, pbag: SubChunk?, pmod: SubChunk?,
        pgen: SubChunk?, inst: SubChunk?, ibag: SubChunk?,
        imod: SubChunk?, igen: SubChunk?, shdr: SubChunk?

    // Each subchunk begins with an 8-byte preamble containing the type and length
    let preambleSize = 8

    // Iterate while there is at least a preamble-sized chunk of data to decode.
    while i + preambleSize < data.endIndex {

      let identifier = String(data[i +--> 4]).lowercased()

      // Get the identifier for the next subchunk.
      guard let chunkIdentifier = SubChunkIdentifier(rawValue: identifier) else {
        throw Error.StructurallyUnsound
      }

      i += 4 // Move i passed chunk type

      // Get the expected size of the next subchunk.
      let chunkSize = _chunkSize(data[i +--> 4])

      i += 4 // Move i passed chunk size

      // Make sure there are enough remaining bytes.
      guard data.distance(from: i, to: data.endIndex) >= chunkSize else {
        throw Error.StructurallyUnsound
      }

      // Calculate the range of the next subchunk.
      let range = i +--> chunkSize

      // Create a lazy subchunk with the decoded identifier and calculated range.
      let chunk = try SubChunk(identifier: chunkIdentifier, data: data[range])

      // Store the subchunk in the corresponding variable, throwing an error if
      // more than one subchunk with the same identifier have been decoded.
      switch chunk.identifier {
        case .phdr:
          guard phdr == nil else { throw Error.StructurallyUnsound }
          phdr = chunk
        case .pbag:
          guard pbag == nil else { throw Error.StructurallyUnsound }
          pbag = chunk
        case .pmod:
          guard pmod == nil else { throw Error.StructurallyUnsound }
          pmod = chunk
        case .pgen:
          guard pgen == nil else { throw Error.StructurallyUnsound }
          pgen = chunk
        case .inst:
          guard inst == nil else { throw Error.StructurallyUnsound }
          inst = chunk
        case .ibag:
          guard ibag == nil else { throw Error.StructurallyUnsound }
          ibag = chunk
        case .imod:
          guard imod == nil else { throw Error.StructurallyUnsound }
          imod = chunk
        case .igen:
          guard igen == nil else { throw Error.StructurallyUnsound }
          igen = chunk
        case .shdr:
          guard shdr == nil else { throw Error.StructurallyUnsound }
          shdr = chunk
        default: throw Error.StructurallyUnsound
      }

      i += chunkSize // Move i passed chunk data
    }

    // Check that all the subchunks have been decoded.
    guard phdr != nil,
          pbag != nil,
          pmod != nil,
          pgen != nil,
          inst != nil,
          ibag != nil,
          imod != nil,
          igen != nil,
          shdr != nil
    else
    {
      throw Error.StructurallyUnsound
    }

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

}

extension PDTAChunk: CustomStringConvertible {
  public var description: String {
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
