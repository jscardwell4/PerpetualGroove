//
//  SDTAChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

/// A struct for holding data corresponding to the sdta chunk of a sound font file.
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct SDTAChunk
{
  /// The four character code for this chunk. Always equal to "sdta".
  public let identifier: CharacterCode
  
  /// The raw bytes that hold this chunk's data.
  public let data: Data
  
  /// Stores the optional smpl Subchunk of a sound font file.
  public let smpl: Data?
  
  /// Intitializing with data.
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public init(data: Data) throws
  {
    // Check that the data begins with info declaration.
    identifier = try _require(code: "sdta", data: data)
    
    // Advance and store the data.
    var remainingData = _advance(data, by: 4)
    self.data = remainingData
    
    // Check that the data contains a Subchunk.
    guard !remainingData.isEmpty else { smpl = nil; return }
    
    // Check that the Subchunk begins with 'smpl'.
    try _require(code: "smpl", data: remainingData)
    remainingData = _advance(remainingData, by: 4)
    
    // Get the size of the Subchunk.
    let size = try Size(bytes: remainingData).value
    remainingData = _advance(remainingData, by: 4)
    
    // Check that data is large enough to contain the Subchunk as specified
    // by the decoded size.
    try _require(size <= remainingData.count)
    
    // Initialize the smpl Subchunk.
    smpl = remainingData.prefix(size)
  }
}
