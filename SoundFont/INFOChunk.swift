//
//  INFOChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import MoonKit

/// Parses the info chunk of the file
public struct INFOChunk {
  /// File version.
  public let ifil: SubChunk

  /// Sound engine, less than 257 bytes, missing assume 'EMU8000'.
  public let isng: SubChunk

  /// Bank name, less than 257 bytes, ignore if missing.
  public let inam: SubChunk

  /// ROM, less than 257 bytes, ignore if missing.
  public let irom: SubChunk?

  /// ROM version.
  public let iver: SubChunk?

  /// Creation date, less than 257 bytes, ignore if missing.
  public let icrd: SubChunk?

  /// Sound designers, less than 257 bytes, ignore if missing.
  public let ieng: SubChunk?

  /// Intended product, less than 257 bytes, ignore if missing.
  public let iprd: SubChunk?

  /// Copywrite, less than 257 bytes, ignore if missing.
  public let icop: SubChunk?

  /// Comment, less than 65,537 bytes, ignore if missing.
  public let icmt: SubChunk?

  /// Creation tools, less than 257 bytes, ignore if missing.
  public let isft: SubChunk?

  /// Initializing with data.
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound`
  public init(data: Data.SubSequence) throws {

    // Check that the data begins with info declaration.
    guard data.distance(from: data.startIndex, to: data.endIndex) > 4,
          String(data[data.startIndex +--> 4]).lowercased() == "info"
    else
    {
      throw Error.StructurallyUnsound
    }

    var i = data.startIndex + 4 // The index after 'INFO'

    // Create variable for holding decoded values.
    var ifil: SubChunk?, isng: SubChunk?, inam: SubChunk?,
        irom: SubChunk?, iver: SubChunk?, icrd: SubChunk?,
        ieng: SubChunk?, iprd: SubChunk?, icop: SubChunk?,
        icmt: SubChunk?, isft: SubChunk?

    // Each subchunk begins with an 8-byte preamble containing the type and length
    let preambleSize = 8

    // Iterate while there are at least enough bytes for the preamble.
    while i + preambleSize < data.endIndex {

      let identifier = String(data[i +--> 4]).lowercased()

      // Get the identifier for the subchunk.
      guard let chunkIdentifier = SubChunkIdentifier(rawValue: identifier) else {
        throw Error.StructurallyUnsound
      }

      i += 4 // Move i passed chunk type

      // Get the size of the subchunk.
      let chunkSize = _chunkSize(data[i +--> 4])

      i += 4 // Move i passed chunk size

      // Make sure there are enough remaining bytes for the chunk size
      guard data.distance(from: i, to: data.endIndex) >= chunkSize else {
        throw Error.StructurallyUnsound
      }

      // Get the subchunk's data.
      let chunkData = data[i +--> chunkSize]

      // Try creating a subchunk using the data.
      let chunk = try SubChunk(identifier: chunkIdentifier, data: chunkData)

      // Store the subchunk in the corresponding variable, throwing an error if
      // more than one subchunk with the same identifier have been decoded.
      switch chunk.identifier {
        case .ifil:
          guard ifil == nil else { throw Error.StructurallyUnsound }
          ifil = chunk
        case .isng:
          guard isng == nil else { throw Error.StructurallyUnsound }
          isng = chunk
        case .inam:
          guard inam == nil else { throw Error.StructurallyUnsound }
          inam = chunk
        case .irom:
          guard irom == nil else { throw Error.StructurallyUnsound }
          irom = chunk
        case .iver:
          guard iver == nil else { throw Error.StructurallyUnsound }
          iver = chunk
        case .icrd:
          guard icrd == nil else { throw Error.StructurallyUnsound }
          icrd = chunk
        case .ieng:
          guard ieng == nil else { throw Error.StructurallyUnsound }
          ieng = chunk
        case .iprd:
          guard iprd == nil else { throw Error.StructurallyUnsound }
          iprd = chunk
        case .icop:
          guard icop == nil else { throw Error.StructurallyUnsound }
          icop = chunk
        case .icmt:
          guard icmt == nil else { throw Error.StructurallyUnsound }
          icmt = chunk
        case .isft:
          guard isft == nil else { throw Error.StructurallyUnsound }
          isft = chunk
        default: throw Error.StructurallyUnsound
      }

      i += chunkSize // Move i passed chunk data
    }

    // Make sure the 3 required subchunks are present.
    guard ifil != nil,
          isng != nil,
          inam != nil
    else
    {
      throw Error.StructurallyUnsound
    }

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

}

extension INFOChunk: CustomStringConvertible {
  public var description: String {
    var result = "\n".join("ifil: \(ifil)", "isng: \(isng)", "inam: \(inam)")

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

