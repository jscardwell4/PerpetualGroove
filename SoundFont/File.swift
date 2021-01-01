//
//  File.swift
//  SoundFont
//
//  Created by Jason Cardwell on 9/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

// MARK: - File

/// Parses the data from a SoundFont file, which consists of three chunks: info, sdta, and pdta
public struct File {
  /// Stores the data or the data's location for the file.
  public let storage: Storage

  /// The file url or `nil` if the file is stored in memory.
  public var url: URL? { if case let .url(url) = storage { return url } else { return nil } }

  /// The range within the file's data corresponding to the info subchunk.
  public let infoRange: Range<Int>

  /// The range within the file's data corresponding to the sdta subchunk.
  public let sdtaRange: Range<Int>

  /// The range within the file's data corresponding to the pdta subchunk.
  public let pdtaRange: Range<Int>

  /// An array of presets obtained by decoding the phdr subchunk from the pdta subchunk.
  public var presets: [PresetHeader] {
    guard let phdr = try? lazyPDTA.phdr.dataChunk(),
          case let .presets(headers) = phdr.data else { return [] }
    return headers
  }

  /// The decoded info subchunk for the file.
  public let info: INFOChunk

  /// The lazy sdta chunk for the file.
  public let lazySDTA: LazySDTAChunk

  /// The lazy pdta chunk for the file.
  public let lazyPDTA: LazyPDTAChunk

  /// Returns the decoded sdta chunk for the file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered.
  public func sdta() throws -> SDTAChunk {
    return try SDTAChunk(data: try storage.data()[sdtaRange])
  }

  /// Returns the decoded pdta chunk for the file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered.
  public func pdta() throws -> PDTAChunk {
    return try PDTAChunk(data: try storage.data()[pdtaRange])
  }

  /// Initializing with raw data.
  ///
  /// - Parameter data: The raw file data.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is detected.
  public init(data: Data) throws { try self.init(storage: .memory(data)) }

  /// Initializing with a file url.
  ///
  /// - Parameter url: The `URL` for the file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is detected.
  public init(fileURL url: URL) throws { try self.init(storage: .url(url)) }

  /// Initializing with raw data or a file url.
  /// - Parameter storage: The file's data or url.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is detected.
  public init(storage: Storage) throws {
    // Store `storage`.
    self.storage = storage

    // Get the data for the file.
    let data = try storage.data()

    // Check the riff code.
    try _require(try CharacterCode(bytes: data.prefix(4)) == "RIFF")

    var remainingData = data.dropFirst(4)

    var size = try Size(bytes: remainingData)
    remainingData = remainingData.dropFirst(4)
    try _require(size.value == remainingData.count)

    // Check the riff chunk header.
    try _require(try CharacterCode(bytes: remainingData.prefix(4)) == "sfbk")
    remainingData = remainingData.dropFirst(4)

    // Check the info chunk header.
    try _require(try CharacterCode(bytes: remainingData.prefix(4)) == "LIST")
    remainingData = remainingData.dropFirst(4)

    // Get the size of the info chunk.
    size = try Size(bytes: remainingData)
    remainingData = remainingData.dropFirst(4)
    try _require(size.value <= remainingData.count)

    // Note info chunk's range
    infoRange = remainingData.startIndex +--> size.value

    // Advance past the info chunk.
    remainingData = remainingData.dropFirst(size.value)

    // Check for sdta list
    try _require(try CharacterCode(bytes: remainingData.prefix(4)) == "LIST")
    remainingData = remainingData.dropFirst(4)

    // Get the sdta chunk size
    size = try Size(bytes: remainingData)
    remainingData = remainingData.dropFirst(4)
    try _require(size.value <= remainingData.count)

    // Note sdta chunk's range
    sdtaRange = remainingData.startIndex +--> size.value

    // Advance past the sdta chunk.
    remainingData = remainingData.dropFirst(size.value)

    // Check for pdta list
    try _require(try CharacterCode(bytes: remainingData.prefix(4)) == "LIST")
    remainingData = remainingData.dropFirst(4)

    // Get the pdta chunk size
    size = try Size(bytes: remainingData)
    remainingData = remainingData.dropFirst(4)
    try _require(size.value <= remainingData.count)

    // Note pdata chunk's range
    pdtaRange = remainingData.startIndex +--> size.value

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
  public static func presetHeaders(from data: Data) throws -> [PresetHeader] {
    // Get the range of the characters within `data` denoting the start of the phdr subchunk.
    guard let range = data.range(of: Data("pdtaphdr".bytes)) else { return [] }

    // Get the size of the phdr subchunk.
    let size = try Size(bytes: data.dropFirst(range.upperBound)).value

    // Check that the size consists of zero or more 38 byte chunks.
    try _require(size % 38 == 0)

    let lower = range.upperBound + 4
    let upper = lower + size

    assert(data.endIndex >= upper)

    // Get the stream of 38 byte chunks to decode into preset headers.
    let dataʹ = data[lower ..< upper]

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

}

extension File: CustomStringConvertible {
  public var description: String { "File (storage: \(storage))" }
}
