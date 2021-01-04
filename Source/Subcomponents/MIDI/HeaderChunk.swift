//
//  HeaderChunk.swift
//  MIDI
//
//  Created by Jason Cardwell on 01/02/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonKit

/// Struct to hold the header chunk of a MIDI file.
public struct HeaderChunk: CustomStringConvertible {

  /// The total number of bytes for a valid header chunk.
  public static let byteCount = 14

  /// The four character ascii string identifying the chunk as a header chunk.
  public let type = UInt64(bytes: "MThd".utf8)

  /// The MIDI file format.
  public static let format: UInt16 = 1

  /// The number of bytes in the header's data.
  public static let dataSize: UInt64 = 6

  /// The number of tracks specified by the header.
  public let numberOfTracks: UInt16

  /// The subbeat division specified by the header.
  public let division: UInt16 = 480

  /// The collection of raw bytes for the header.
  public var bytes: [UInt8] {

    // Initialize an array with the bytes of `type`.
    var result = type.bytes

    // Append the size of the chunk's data.
    result.append(contentsOf: HeaderChunk.dataSize.bytes)

    // Append the bytes of `format`.
    result.append(contentsOf: HeaderChunk.format.bytes)

    // Append the bytes of `numberOfTracks`.
    result.append(contentsOf: numberOfTracks.bytes)

    // Append the bytes of `division`.
    result.append(contentsOf: division.bytes)

    return result

  }

  /// Initialize with the number of tracks.
  public init(numberOfTracks: UInt16) { self.numberOfTracks = numberOfTracks }

  /// Initialize with raw bytes.
  /// - Throws:
  ///   `Error.invalidLength` when `data.count != HeaderChunk.byteCount` or `data` specifies a size other
  ///   than `HeaderChunk.dataSize`.
  ///
  ///   `Error.invalidHeader` when data does not begin with 'MThd'
  ///
  ///   `Error.unsupportedFormat` when `data` specifies a file format other than `HeaderChunk.format`.
  public init(data: Data.SubSequence) throws {

    // Check that `data` contains the required number of bytes.
    guard data.count == HeaderChunk.byteCount else {
      throw Error.invalidLength("Header chunk must be 14 bytes")
    }

    // Check that `data` begins with 'MThd'.
    guard String(bytes: data[data.startIndex +--> 4]) == "MThd" else {
      throw Error.invalidHeader("Expected chunk header with type 'MThd'")
    }

    // Check that the data's preamble specifies six bytes of data.
    guard HeaderChunk.dataSize == UInt64(bytes: data[(data.startIndex + 4) +--> 4]) else {
      throw Error.invalidLength("Header must specify length of 6")
    }

    // Check that the data specifies the correct file format.
    guard HeaderChunk.format == UInt16(bytes: data[(data.startIndex + 8) +--> 2]) else {
      throw Error.unsupportedFormat("Format must be 00 00 00 00, 00 00 00 01, 00 00 00 02")
    }

    // Intialize `numberOfTracks` with a value decoded from the remaining bytes in data.
    numberOfTracks = UInt16(bytes: data[(data.startIndex + 10) +--> 2])

  }

  public var description: String {
    return [
      "MThd",
      "format: \(HeaderChunk.format)",
      "number of tracks: \(numberOfTracks)",
      "division: \(division)"
      ].joined(separator: "\n\t")
  }

}
