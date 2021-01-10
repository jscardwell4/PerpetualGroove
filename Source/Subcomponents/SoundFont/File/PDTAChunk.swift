//
//  PDTAChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import MoonKit

// MARK: - PDTAChunk

/// A struct for holding data corresponding to the pdta chunk of a sound font file.
public struct PDTAChunk
{
  /// The four character code for this chunk. Always equal to "pdta".
  public let identifier: CharacterCode
  
  /// The raw bytes that hold this chunk's data.
  public let data: Data
  
  /// Names the presets and points to each of its zones in the `pbag` Subchunk.
  public let phdr: [PresetHeader]
  
  /// Points each preset zone to data pointers and values in `pmod` and `pgen`.
  public let pbag: Data
  
  /// Points to preset modulators.
  public let pmod: Data
  
  /// Points to preset generators.
  public let pgen: Data
  
  /// Contains an Instrument, which names the virtual sub-instrument and points to
  /// zones in `ibag`.
  public let inst: Data
  
  /// Points each instrument zone to data pointers and values in `imod` and `igen`.
  public let ibag: Data
  
  /// Points to instrument Modulators.
  public let imod: Data
  
  /// Points to instrument Generators.
  public let igen: Data
  
  /// Contains a sound sample's information and a pointer to the sound sample in the
  /// sdta chunk.
  public let shdr: Data
  
  /// Initializing with data.
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public init(data: Data.SubSequence) throws
  {
    // Check that the data begins with info declaration.
    identifier = try _require(code: "pdta", data: data)
    
    // Advance and store the data.
    var remainingData = _advance(data, by: 4)
    self.data = remainingData
    
    // Create variables for storing lazy the Subchunks.
    var phdr: [PresetHeader]?, pbag: Data?, pmod: Data?,
        pgen: Data?, inst: Data?, ibag: Data?,
        imod: Data?, igen: Data?, shdr: Data?
    
    // Iterate while there is at least a preamble-sized chunk of data to decode.
    Loop: while remainingData.count >= 8
    {
      let identifier = try CharacterCode(bytes: remainingData).value
      remainingData = _advance(remainingData, by: 4)
      
      // Get the expected size of the next Subchunk.
      let size = try Size(bytes: remainingData).value
      remainingData = _advance(remainingData, by: 4)
      try _require(size <= remainingData.count)
      
      var chunkData = remainingData.prefix(size)
      remainingData = _advance(remainingData, by: size)
      
      // Store the Subchunk in the corresponding variable, throwing an error if
      // more than one Subchunk with the same identifier have been decoded.
      switch identifier
      {
        case "pbag": pbag = chunkData
        case "pmod": pmod = chunkData
        case "pgen": pgen = chunkData
        case "inst": inst = chunkData
        case "ibag": ibag = chunkData
        case "imod": imod = chunkData
        case "igen": igen = chunkData
        case "shdr": shdr = chunkData
        case "phdr":
          // Check that the data consists of zero or more 38 byte chunks.
          try _require(chunkData.count % 38 == 0)
          
          // Create an array to accumulate headers.
          var headers: [PresetHeader] = []
          
          while chunkData.count >= 38
          {
            let headerData = chunkData.prefix(38)
            chunkData = _advance(chunkData, by: 38)
            guard let header = try PresetHeader(data: headerData) else { break }
            headers.append(header)
          }
          
          phdr = headers
          
        default: break Loop
      }
    }
    
    // Check that all the Subchunks have been decoded.
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
      throw File.Error.StructurallyUnsound
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

// MARK: CustomStringConvertible

extension PDTAChunk: CustomStringConvertible
{
  public var description: String
  {
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
