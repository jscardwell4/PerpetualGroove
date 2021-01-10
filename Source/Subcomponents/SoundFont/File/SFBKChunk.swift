//
//  SFBKChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 1/1/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

public struct SFBKChunk
{
  /// The identifier for sound font file chunks. This is always "sfbk".
  public let identifier: CharacterCode
  
  /// The raw bytes of data for the sound font chunk.
  public let data: Data
  
  /// The info subchunk.
  public let info: INFOChunk
  
  /// The sdta subchunk.
  public let sdta: SDTAChunk
  
  /// The pdta subchunk.
  public let pdta: PDTAChunk
  
  /// Initializing with the raw bytes of a sound font file.
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if formatting errors are encountered.
  public init(data: Data) throws
  {
    // Parse the identifier.
    let identifier = try CharacterCode(bytes: data)
    try _require(identifier == "sfbk")
    self.identifier = identifier
    
    // Advance past the four character code and store the data.
    var remainingData = _advance(data, by: 4)
    self.data = remainingData
    
    // Parse the list declaration for the supplemental information.
    try _require(try CharacterCode(bytes: remainingData) == "list")
    remainingData = _advance(remainingData, by: 4)
    
    // Get the size of the info chunk.
    var size = try Size(bytes: remainingData)
    remainingData = _advance(remainingData, by: 4)
    try _require(size.value <= remainingData.count)
    
    // Parse the info chunk.
    info = try INFOChunk(data: remainingData[remainingData.startIndex +--> size.value])
    
    // Advance past the info chunk.
    remainingData = _advance(remainingData, by: size.value)
    
    // Parse the list declaration for the samples chunk.
    try _require(try CharacterCode(bytes: remainingData) == "list")
    remainingData = _advance(remainingData, by: 4)
    
    // Get the size of the samples chunk.
    size = try Size(bytes: remainingData)
    remainingData = _advance(remainingData, by: 4)
    try _require(size.value <= remainingData.count)
    
    // Parse the samples chunk.
    sdta = try SDTAChunk(data: data[remainingData.startIndex +--> size.value])
    
    // Advance past the samples chunk.
    remainingData = _advance(remainingData, by: size.value)
    
    // Parse the list declaration for the preset, instrument, and sample header chunk.
    try _require(try CharacterCode(bytes: remainingData.prefix(4)) == "list")
    remainingData = _advance(remainingData, by: 4)
    
    // Get the size of the preset, instrument, and sample header chunk.
    size = try Size(bytes: remainingData)
    remainingData = _advance(remainingData, by: 4)
    try _require(size.value <= remainingData.count)
    
    // Parse the preset, instrument, and sample header chunk.
    pdta = try PDTAChunk(data: data[remainingData.startIndex +--> size.value])
  }
}
