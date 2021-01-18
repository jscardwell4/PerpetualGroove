//
//  INFOChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

/// Parses the info chunk of the file
@available(iOS 14.0, *)
@available(OSX 11.0, *)
public struct INFOChunk
{
  /// The four character code for this chunk. Always equal to "info".
  public let identifier: CharacterCode
  
  /// The raw bytes that hold this chunk's data.
  public let data: Data
  
  /// File version.
  public let ifil: Version
  
  /// Sound engine, less than 257 bytes, missing assume 'EMU8000'.
  public let isng: ASCIIString
  
  /// Bank name, less than 257 bytes, ignore if missing.
  public let inam: ASCIIString
  
  /// ROM, less than 257 bytes, ignore if missing.
  public let irom: ASCIIString?
  
  /// ROM version.
  public let iver: Version?
  
  /// Creation date, less than 257 bytes, ignore if missing.
  public let icrd: ASCIIString?
  
  /// Sound designers, less than 257 bytes, ignore if missing.
  public let ieng: ASCIIString?
  
  /// Intended product, less than 257 bytes, ignore if missing.
  public let iprd: ASCIIString?
  
  /// Copywrite, less than 257 bytes, ignore if missing.
  public let icop: ASCIIString?
  
  /// Comment, less than 65,537 bytes, ignore if missing.
  public let icmt: ASCIIString?
  
  /// Creation tools, less than 257 bytes, ignore if missing.
  public let isft: ASCIIString?
  
  /// Initializing with data.
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound`
  public init(data: Data) throws
  {
    // Check that the data begins with info declaration.
    identifier = try _require(code: "info", data: data)
    
    // Advance and store the data.
    var remainingData = _advance(data, by: 4)
    self.data = remainingData
    
    // Create variables for the required properties.
    var ifil: Version?, isng: ASCIIString?, inam: ASCIIString?,
        irom: ASCIIString?, iver: Version?, icrd: ASCIIString?,
        ieng: ASCIIString?, iprd: ASCIIString?, icop: ASCIIString?,
        icmt: ASCIIString?, isft: ASCIIString?
    
    // Iterate while there are at least enough bytes for the preamble.
    Loop: while remainingData.count >= 8
    {
      // Parse the subchunk identifier.
      let identifier = try CharacterCode(bytes: remainingData).value
      
      // Advance past the identifier.
      remainingData = _advance(remainingData, by: 4)
      
      // Get the size of the Subchunk.
      let chunkSize = try Size(bytes: remainingData).value
      
      // Advance past chunk size
      remainingData = _advance(remainingData, by: 4)
      try _require(chunkSize <= remainingData.count)
      
      // Get the Subchunk's data.
      let chunkData = remainingData.prefix(chunkSize)
      remainingData = _advance(remainingData, by: chunkSize)
      
      // Store the Subchunk in the corresponding variable, throwing an error if
      // more than one Subchunk with the same identifier have been decoded.
      switch identifier
      {
        case "ifil": ifil = try Version(bytes: chunkData)
        case "isng": isng = try ASCIIString(bytes: chunkData)
        case "inam": inam = try ASCIIString(bytes: chunkData)
        case "irom": irom = try ASCIIString(bytes: chunkData)
        case "iver": iver = try Version(bytes: chunkData)
        case "icrd": icrd = try ASCIIString(bytes: chunkData)
        case "ieng": ieng = try ASCIIString(bytes: chunkData)
        case "iprd": iprd = try ASCIIString(bytes: chunkData)
        case "icop": icop = try ASCIIString(bytes: chunkData)
        case "icmt": icmt = try ASCIIString(bytes: chunkData)
        case "isft": isft = try ASCIIString(bytes: chunkData)
        default: break Loop
      }
    }
    
    try _require(ifil != nil && isng != nil && inam != nil)
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
