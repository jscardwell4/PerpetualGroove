//
//  SDTAChunk.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import MoonKit

/// A struct for holding lazy data corresponding to the sdta chunk of a sound font file.
public struct LazySDTAChunk {
  /// Stores a lazy version of the optional smpl subchunk of a sound font file.
  public let smpl: LazySubChunk?

  /// Initializing with data and its origin.
  ///
  /// - Parameters:
  ///   - data: The data with which to initialize.
  ///   - storage: The origin for `data`.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public init(data: Data.SubSequence, storage: Storage) throws {
    // Check that the data begins with 'SDTA'.
    guard data.count >= 4,
          String(data[data.startIndex +--> 4]).lowercased() == "sdta"
    else
    {
      throw Error.StructurallyUnsound
    }

    // Check that the data contains a subchunk.
    guard data.count > 4 else {
      smpl = nil
      return
    }

    // Check that the subchunk begins with 'smpl'.
    guard String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl" else {
      throw Error.StructurallyUnsound
    }

    // Get the size of the subchunk.
    let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

    // Check that data is large enough to contain the subchunk as specified by
    // the decoded size.
    guard data.count >= smplSize + 12 else {
      throw Error.StructurallyUnsound
    }

    // Calculate the range of the subchunk.
    let range = (data.startIndex + 12) +--> smplSize

    // Initialize the lazy smpl subchunk.
    smpl = try LazySubChunk(identifier: .smpl, storage: storage, range: range)
  }

}

extension LazySDTAChunk: CustomStringConvertible {
  public var description: String { "\(smpl?.description ?? "")" }
}


/// A struct for holding data corresponding to the sdta chunk of a sound font file.
public struct SDTAChunk {
  /// Stores the optional smpl subchunk of a sound font file.
  public let smpl: SubChunk?

  /// Initializing from a lazy sdta chunk.
  ///
  /// - Parameter chunk: The lazy chunk with which to initialize.
  /// - Throws: Any error encountered converting the lazy subchunk into a subchunk.
  public init(chunk: LazySDTAChunk) throws { smpl = try chunk.smpl?.dataChunk() }

  /// Intitializing with data.
  ///
  /// - Parameter data: The data with which to initialize.
  /// - Throws: `Error.StructurallyUnsound` if invalid data is encountered while decoding.
  public init(data: Data.SubSequence) throws {
    // Check that the data begins with 'SDTA'.
    guard data.count >= 4,
          String(data[data.startIndex +--> 4]).lowercased() == "sdta"
    else
    {
      throw Error.StructurallyUnsound
    }

    // Check that the data contains a subchunk.
    guard data.count > 4 else {
      smpl = nil
      return
    }

    // Check that the subchunk begins with 'smpl'.
    guard String(data[(data.startIndex + 4) +--> 4]).lowercased() == "smpl" else {
      throw Error.StructurallyUnsound
    }

    // Get the size of the subchunk.
    let smplSize = _chunkSize(data[(data.startIndex + 8) +--> 4])

    // Check that data is large enough to contain the subchunk as specified
    // by the decoded size.
    guard data.count >= smplSize + 12 else {
      throw Error.StructurallyUnsound
    }

    // Calculate the range of the subchunk.
    let range = (data.startIndex + 12) +--> smplSize

    // Initialize the smpl subchunk.
    smpl = try SubChunk(identifier: .smpl, data: data[range])
  }

}

extension SDTAChunk: CustomStringConvertible {
  public var description: String { "\(smpl?.description ?? "")" }
}
