//
//  File.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import typealias CoreMIDI.MIDITimeStamp
import Foundation
import MoonKit

// MARK: - File

/// Struct that holds the data for a complete MIDI file.
public struct File
{
  // MARK: Stored Properties

  /// The collection of track chunks that make up the file's contents.
  public let tracks: [TrackChunk]

  /// The file's header.
  public let header: HeaderChunk

  // MARK: Initializing

  /// Initializing with a file url.
  /// - Throws: Any error encountered initializing via `init(data:)`.
  public init(file: URL) throws { try self.init(data: try Data(contentsOf: file)) }

  /// Initializing with existing chunks.
  ///
  /// - Parameters:
  ///   - tracks: The track chunks for the file.
  ///   - header: The header chunk for the file.
  public init(tracks: [TrackChunk], header: HeaderChunk)
  {
    self.tracks = tracks
    self.header = header
  }

  /// Initializing with raw data.
  /// - Throws: `Error.fileStructurallyUnsound`, `Error.invalidHeader`.
  public init(data: Data, beatsPerMinute: UInt = 120) throws
  {
    // The file's header should be a total of fourteen bytes.
    let headerSize = 14

    // Check that there are enough bytes for the file's header.
    guard data.count > headerSize
    else
    {
      throw Error.fileStructurallyUnsound("Not enough bytes in file")
    }

    // Initialize `header` with the first fourteen bytes in `data`.
    header = try HeaderChunk(data: data.prefix(headerSize))

    // Create a variable for tracking the number of decoded tracks.
    var tracksRemaining = header.numberOfTracks

    // Create an array for holding track chunks decoded but not yet processed.
    var unprocessedTracks: [TrackChunk] = []

    // Start with the index just past the decoded header.
    var currentIndex = headerSize

    // Iterate while the number of tracks decoded is less than the the total specified
    // in the file's header.
    while tracksRemaining > 0
    {
      // Check that there are at least enough bytes remaining for a track's preamble.
      guard data.endIndex - currentIndex > 8
      else
      {
        throw Error.fileStructurallyUnsound("Not enough bytes for track count.")
      }

      // Check that chunk begins with 'MTrk'.
      guard String(bytes: data[currentIndex +--> 4]) == "MTrk"
      else
      {
        throw Error.invalidHeader("Expected chunk header with type 'MTrk'")
      }

      currentIndex += 4 // Move past 'MTrk'

      // Get the byte count for the chunk's data.
      let chunkLength = Int(UInt32(bytes: data[currentIndex +--> 4]))

      currentIndex += 4 // Move past the chunk size.

      // Check that there are at least enough bytes remaining for the decoded chunk size.
      guard currentIndex + chunkLength <= data.endIndex
      else
      {
        throw Error.fileStructurallyUnsound("Not enough bytes in track chunk")
      }

      // Calculate the range for the chunk's data.
      let range = currentIndex +--> chunkLength

      // Get the chunk's data.
      let chunkData = data[range]

      // Create a new `TrackChunk` instance using the chunk's data.
      let chunk = try TrackChunk(data: chunkData)

      // Append the decoded chunk to the collection of unprocessed tracks.
      unprocessedTracks.append(chunk)

      currentIndex += chunkLength // Move past the decoded chunk.

      tracksRemaining -= 1 // Decrement the number of tracks that remain.
    }

    // TODO: We need to track signature changes to do this properly

    // Create an array for accumulating track chunks as they are processed.
    var processedTracks: [TrackChunk] = []

    // Iterate the decoded track chunks.
    for trackChunk in unprocessedTracks
    {
      // Create a variable for holding the tick offset.
      var ticks: UInt64 = 0

      // Create an array for accumulating the track's events as they are processed.
      var processedEvents: [Event] = []

      // Iterate the track chunk's events.
      for var trackEvent in trackChunk.events
      {
        // Retrieve the event's delta value.
        guard let delta = trackEvent.delta
        else
        {
          throw Error.fileStructurallyUnsound("Track event missing delta value")
        }

        // Advance `ticks` by the event's delta value.
        ticks += delta

        // Modify the event's time using the current tick offset.
        trackEvent.time = BarBeatTime(tickValue: ticks,
                                      beatsPerBar: 4,
                                      beatsPerMinute: beatsPerMinute,
                                      subbeatDivisor: UInt(header.division))

        // Append the modified event.
        processedEvents.append(trackEvent)
      }

      // Create a new track chunk composed of the processed events.
      let processedTrack = TrackChunk(events: processedEvents)

      // Append the processed track chunk.
      processedTracks.append(processedTrack)
    }

    // Intialize `tracks` with the processed track chunks.
    tracks = processedTracks
  }
}

// MARK: ByteArrayConvertible

extension File: ByteArrayConvertible
{
  /// The collection of raw bytes consisting of the header's bytes followed by each
  /// of the track's bytes.
  public var bytes: [UInt8]
  {
    // Create an array for accumulating the file's bytes, initializing the array
    // with header's bytes.
    var bytes = header.bytes

    // Create an array for holding the arrays of bytes generated by the tracks.
    var trackData: [[UInt8]] = []

    // Iterate the track chunks.
    for track in tracks
    {
      // Create a variable for holding the time of the most recently encoded track event.
      var previousTime: MIDITimeStamp = 0

      // Create an array for holding the encoded track chunk.
      var trackBytes: [UInt8] = []

      // Iterate the events in the track chunk.
      for event in track.events
      {
        // Get the event's tick offset, using the previous time if the event's time
        // is less than the previous time so that the delta calculation results in
        // a value of `0`.
        let eventTime = max(event.time.ticks, previousTime)

        // Calculate the delta for `event`.
        let delta = VariableLengthQuantity(eventTime - previousTime)

        // Append the bytes for the event's delta value.
        trackBytes.append(contentsOf: delta.bytes)

        // Append the bytes for the event.
        trackBytes.append(contentsOf: event.bytes)

        // Update the previous time to the event's time.
        previousTime = eventTime
      }

      // Append the track's bytes.
      trackData.append(trackBytes)
    }

    // Iterate the arrays of the track's bytes to append each track's bytes to `bytes`.
    for trackBytes in trackData
    {
      // Append 'MTrk' to mark the beginning of a track chunk.
      bytes.append(contentsOf: Array("MTrk".utf8))

      // Append the size of `trackBytes`.
      bytes.append(contentsOf: UInt64(trackBytes.count).bytes)

      // Append the track's data.
      bytes.append(contentsOf: trackBytes)
    }

    return bytes
  }
}

// MARK: CustomStringConvertible

extension File: CustomStringConvertible
{
  public var description: String { "\(header)\n\("\n".join(tracks.map(\.description)))" }
}

extension File {
  /// An enumeration of the possible errors thrown by `MIDIFile`.
  public enum Error: LocalizedError {
    case fileStructurallyUnsound (String)
    case invalidHeader (String)
    case invalidLength (String)
    case unsupportedEvent (String)
    case unsupportedFormat (String)

    public var errorDescription: String? {
      switch self {
        case .fileStructurallyUnsound: return "File structurally unsound"
        case .invalidHeader:           return "Invalid header"
        case .invalidLength:           return "Invalid length"
        case .unsupportedEvent:        return "Unsupported event"
        case .unsupportedFormat:       return "Unsupported format"
      }
    }

    public var failureReason: String? {
      switch self {
        case .fileStructurallyUnsound(let reason),
             .invalidHeader(let reason),
             .invalidLength(let reason),
             .unsupportedEvent(let reason),
             .unsupportedFormat(let reason):
          return reason
      }
    }
  }
}
