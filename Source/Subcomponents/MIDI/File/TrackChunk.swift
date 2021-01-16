//
//  TrackChunk
//  MIDI
//
//  Created by Jason Cardwell on 01/02/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev

// MARK: - TrackChunk

/// Struct to hold a track chunk for a MIDI file.
public struct TrackChunk
{
  // MARK: Stored Properties
  
  /// The four character ascii string identifying the chunk as a track chunk.
  public let type = UInt32(bytes: "MTrk".utf8)
  
  /// The collection of MIDI events for the track.
  public var events: [Event] = []
  
  // MARK: Initializing
  
  /// Initializing an empty track chunk.
  public init() {}
  
  /// Initializing with an array of MIDI events.
  ///
  /// - Parameter events: The MIDI events for the track.
  public init(events: [Event]) { self.events = events }
  
  /// Initializing with an event container.
  ///
  /// - Parameter eventContainer: The MIDI events for the track.
  public init(eventContainer: EventContainer) { events = Array(eventContainer) }
  
  /// Initializing with raw bytes.
  ///
  /// - Parameter data: The raw bytes composing the track chunk.
  /// - Throws: `Error.invalidLength`, `Error.invalidHeader`, `Error.invalidLength`.
  public init(data: Data) throws
  {
    // Check that there are at least enough bytes for the preamble.
    guard data.count > 8
    else
    {
      throw File.Error.invalidLength("Not enough bytes in chunk")
    }
    
    // Check that the `data` specifies a track chunk
    guard String(bytes: data[data.startIndex +--> 4]) == "MTrk"
    else
    {
      throw File.Error.invalidHeader("Track chunk header must be of type 'MTrk'")
    }
    
    // Get the size of the chunk's data.
    let chunkLength = UInt32(bytes: data[(data.startIndex + 4) +--> 4])
    
    // Check that the size specified in the preamble and the size of the data
    // provided are a match.
    guard data.count == Int(chunkLength) + 8
    else
    {
      throw File.Error.invalidLength("Specified length missmatch.")
    }
    
    // Start with the index just past the chunk's preamble.
    var currentIndex = data.startIndex + 8
    
    // Create an array for accumulating decoded MIDI events.
    var events: [Event] = []
    
    // Iterate through the remaining bytes of `data`.
    while currentIndex < data.endIndex
    {
      // Create an additional index set to the current index.
      var i = currentIndex
      
      // Iterate through the bytes until reaching the end of the variable length quantity.
      while data[i] & 0x80 != 0 { i += 1 }
      
      // Get the delta value for the event.
      let delta = UInt64(VariableLengthQuantity(bytes: data[currentIndex ... i]))
      
      // Move current index to just past the bytes of the delta.
      currentIndex = i + 1
      
      // Store the first index of the bytes containing the event data.
      let eventStart = currentIndex
      
      // Handle according to the first byte of the data.
      switch data[currentIndex]
      {
        case 0xFF:
          // The event is a meta event. Create and append either a node or meta event.
          
          // Get the event type.
          let type = data[currentIndex &+ 1]
          
          // Move the current index past the first two bytes of the event's data.
          currentIndex = currentIndex &+ 2
          
          // Update `i` to the current index.
          i = currentIndex
          
          // Iterate through the bytes until reaching the end of the variable length quantity.
          while data[i] & 0x80 != 0 { i += 1 }
          
          // Get the size of the event's data.
          let dataLength = Int(VariableLengthQuantity(bytes: data[currentIndex ... i]))
          
          // Move the current index to the last byte of the event's data.
          currentIndex = i &+ dataLength
          
          // Get the event's data.
          let eventData = data[eventStart ... currentIndex]
          
          // Create and append an event of the decoded type.
          if type == 0x07
          {
            events.append(.node(try NodeEvent(delta: delta, data: eventData)))
          }
          else
          {
            events.append(.meta(try MetaEvent(delta: delta, data: eventData)))
          }
          
          // Move the current index past the decoded event.
          currentIndex = currentIndex &+ 1
          
        default:
          // Decode a channel event or throw an error.
          
          // Get the kind of channel event
          guard let type = ChannelEvent.Status.Kind(rawValue: data[currentIndex] >> 4)
          else
          {
            throw File.Error.unsupportedEvent("Unsupported channel event")
          }
          
          // Get the event's data.
          let eventData = data[currentIndex +--> type.byteCount]
          
          // Create and append a new channel event using `eventData`.
          events.append(.channel(try ChannelEvent(delta: delta, data: eventData)))
          
          // Move the current index past the event's data.
          currentIndex = currentIndex &+ type.byteCount
      }
    }
    
    // Intialize `events` with the decoded events.
    self.events = events
  }
}

// MARK: CustomStringConvertible

extension TrackChunk: CustomStringConvertible
{
  public var description: String
  {
    "MTrk\n\("\n".join(events.map { $0.description.indented(by: 1, useTabs: true) }))"
  }
}
