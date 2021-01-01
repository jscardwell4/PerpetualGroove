//
//  SubChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import MoonKit

// MARK: - LazySubChunk

/// A type for storing a subchunk's location and type without processing the entire
/// chunk of data.
public struct LazySubChunk {
  /// The unique identifier for the subchunk within a sound font file.
  public let identifier: SubChunkIdentifier

  /// The data or its location that contains the subchunk.
  public let storage: Storage

  /// The location of the subchunk's data within the data of the sound font file.
  public let range: Range<Int>

  /// Initializing with known values.
  /// - Throws: `Error.StructurallyUnsound` when the size of a subchunk with `identifier`
  ///           is statically known and `range` specifies a different size.
  public init(identifier: SubChunkIdentifier, storage: Storage, range: Range<Int>) throws {
    // Check identifier for known chunk sizes.
    switch identifier {
      case .ifil, .iver: guard range.count == 4 else { throw Error.StructurallyUnsound }
      case .phdr: guard range.count % 38 == 0 else { throw Error.StructurallyUnsound }
      default: break
    }

    // Set property values.
    self.identifier = identifier
    self.storage = storage
    self.range = range
  }

  /// Returns a fully processed subchunk.
  /// - Throws: Any error encountered while initializing the subchunk.
  public func dataChunk() throws -> SubChunk { return try SubChunk(chunk: self) }
}

// MARK: CustomStringConvertible

extension LazySubChunk: CustomStringConvertible {
  public var description: String { return "\(identifier): \(range) \(storage)" }
}

// MARK: - SubChunk

/// A subchunk in a sound font file.
public struct SubChunk {
  /// The unique identifier for the subchunk within a sound font file.
  public let identifier: SubChunkIdentifier

  /// The subchunk's data.
  public let data: SubChunkData

  /// Initializing with the identifier and data obtained from a lazy subchunk.
  /// - Throws: Any error encountered retrieving the data from `chunk`.
  /// - Throws: `Error.StructurallyUnsound`.
  public init(chunk: LazySubChunk) throws {
    self = try SubChunk(identifier: chunk.identifier,
                        data: try chunk.storage.data()[chunk.range])
  }

  /// Initializing with an identifier and the chunk's data.
  public init(identifier: SubChunkIdentifier, data: Data.SubSequence) throws {
    // Process the data into an enumerated value that matches the kind expected
    // for `identifier`.
    switch identifier {
      case .ifil, .iver:
        // The data should be the major and minor version.

        // Check the number of bytes.
        guard data.count == 4 else { throw Error.StructurallyUnsound }

        // Initialize data using the first two bytes for 'major' and the last two
        // bytes for 'minor'.
        self.data = .version(major: UInt16(data.prefix(2)),
                             minor: UInt16(data.suffix(2)))

      case .isng, .inam, .irom, .icrd, .ieng, .iprd, .icop, .icmt, .isft:
        // The data should be null terminated ascii text.

        // Check for null termination.
        guard data.last == 0 else { throw Error.StructurallyUnsound }

        // Initialize data.
        self.data = .text(String(data))

      case .phdr:
        // The data should be a list of preset headers.

        // Check that the data consists of zero or more 38 byte chunks.
        guard data.count % 38 == 0 else { throw Error.StructurallyUnsound }

        // Create an array to accumulate headers.
        var headers: [PresetHeader] = []

        var i = data.startIndex // Index after chunk size

        // Iterate through the data appending successfully decoded preset
        // headers to `headers`.
        while i < data.endIndex,
              let header = try PresetHeader(data: data[i +--> 38])
        {
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
}

// MARK: CustomStringConvertible

extension SubChunk: CustomStringConvertible {
  public var description: String { "\(identifier): \(data)" }
}

// MARK: - ChunkIdentifier

/// An enumeration of unique identifiers for subchunks within a sound font file.
public enum SubChunkIdentifier: String {
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

// MARK: - ChunkData

/// Enumeration wrapping the data belonging to a subchunk in a sound font file.
public enum SubChunkData {
  /// Values that represent a major and minor version.
  case version(major: UInt16, minor: UInt16)

  /// Null terminated ascii text.
  case text(String)

  /// Raw data.
  case data(Data)

  /// A collection of preset headers.
  case presets([PresetHeader])
}

// MARK: CustomStringConvertible

extension SubChunkData: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .version(major, minor):
        return "\(major).\(minor)"
      case let .text(string):
        return string
      case let .data(data):
        return "\(data.count) bytes"
      case let .presets(headers):
        return headers.map(\PresetHeader.description).joined(separator: "\n")
    }
  }
}
