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

/// Structure for parsing and storing the data from a sound font file.
public struct File
{
  /// The RIFF chunk identifier.
  public let identifier: CharacterCode
  
  /// The raw bytes of the file's data.
  public let data: Data
  
  /// The sound font file chunk.
  public let sfbk: SFBKChunk
  
  /// An array of presets obtained by decoding the phdr subchunk from the pdta subchunk.
  public var presets: [PresetHeader] { sfbk.pdta.phdr }
  
  /// Initializing with a file url.
  ///
  /// - Parameter url: The `URL` for the file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is detected.
  public init(fileURL url: URL) throws
  {
    try self.init(data: try Data(contentsOf: url,
                                 options: [.uncached, .alwaysMapped]))
  }
  
  /// Initializing with raw data.
  /// - Parameter data: The raw data for the sound font file.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is detected.
  public init(data: Data) throws
  {
    // Parse the identifier.
    let identifier = try CharacterCode(bytes: data)
    try _require(identifier == "riff")
    self.identifier = identifier
    
    // Advance past the four character code.
    var remainingData = _advance(data, by: 4)
    
    // Parse the size.
    let size = try Size(bytes: remainingData)
    
    // Advance past the chunk size.
    remainingData = _advance(remainingData, by: 4)
    
    // Ensure the reported size is accurate.
    try _require(size.value == remainingData.count)
    
    // Parse the sfbk chunk.
    sfbk = try SFBKChunk(data: remainingData)
    
    // Store the slice of raw data.
    self.data = remainingData
  }
  
  /// Returns the collection of preset headers decoded from the data representation
  /// of a sound font file. This method should only be used when one's only interest
  /// in a sound font file is the presets contained within.
  ///
  /// - Parameter data: The raw bytes of the sound font file.
  /// - Returns: The headers parsed from `data`.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public static func presetHeaders(from data: Data) throws -> [PresetHeader]
  {
    // Get the range of the characters within `data` denoting the start of the
    // phdr subchunk.
    guard let range = data.range(of: Data("pdtaphdr".bytes)) else { return [] }
    
    // Get the size of the phdr subchunk.
    let size = Int(try Size(bytes: data.dropFirst(range.upperBound)).value)
    
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
    for index in stride(from: dataʹ.startIndex, to: dataʹ.endIndex, by: 38)
    {
      // Decode the chunk that starts at `index`.
      guard let presetHeader = try PresetHeader(data: dataʹ[index +--> 38])
      else
      {
        continue
      }
      
      // Append the decoded preset header.
      presetHeaders.append(presetHeader)
    }
    
    // Sort the collection of preset headers.
    presetHeaders.sort()
    
    return presetHeaders
  }
}

public extension File
{
  /// Enumeration of the possible errors thrown by `SoundFont` types.
  enum Error: String, Swift.Error, CustomStringConvertible
  {
    case StructurallyUnsound = "Invalid chunk detected"
  }
}
