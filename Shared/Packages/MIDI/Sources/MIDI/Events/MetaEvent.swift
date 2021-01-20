//
//  MetaEvent.swift
//  MIDI
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

/// A structure for representing a meta MIDI event. The signature of a meta MIDI event is
/// as follows:
///
/// \<delta *(4 bytes)*\> **FF** \<type *(1 byte)*\> \<data length *(variable length
/// quantity)*\> \<data *(data length bytes)*\>
///
/// - TODO: Why do we show the delta value in the description when we do not include the
///         corresponding raw bytes in the derived `bytes` value?
public struct MetaEvent: _Event, Hashable
{
  public var time: BarBeatTime
  
  public var delta: UInt64?
  
  /// The data contained by the meta MIDI event.
  public var data: Data
  
  public var bytes: [UInt8]
  {
    // Get the raw bytes for the event's data.
    let dataBytes = data.bytes
    
    // Get the size of `dataBytes` represented as a variable length quantity.
    let dataLength = VariableLengthQuantity(dataBytes.count)
    
    // Create an array for accumulating the event's raw bytes initialized with the byte
    // marking the MIDI event as meta.
    var bytes: [UInt8] = [0xFF]
    
    // Append the byte specifying the meta event's type.
    bytes.append(data.type)
    
    // Append the bytes specifying the length of the event's data.
    bytes.append(contentsOf: dataLength.bytes)
    
    // Append the event's data bytes.
    bytes.append(contentsOf: dataBytes)
    
    // Return the collected bytes.
    return bytes
  }
  
  /// Initializing with data and a bar-beat time.
  ///
  /// - Parameters:
  ///   - data: The meta MIDI event data that will be held by the new `MetaEvent`.
  ///   - time: The tick offset for the new `MetaEvent` expressed as a bar-beat time.
  ///           The default value for this parameter is `zero`.
  public init(data: Data, time: BarBeatTime = .zero)
  {
    // Initialize `data` with the specified data.
    self.data = data
    
    // Initialize `time` with the specified bar-beat time.
    self.time = time
  }
  
  /// Initializing with a tick offset and a slice of data.
  ///
  /// - Parameters:
  ///   - delta: The tick offset for the new `MetaEvent`.
  ///   - data: The slice of raw bytes used to initialize `data` for the new `MetaEvent`.
  ///
  /// - Throws: `MIDIFile.Error.invalidLength` when `data.count < 3` or the byte count
  ///           specified within `data` does not correspond with the actual bytes,
  ///           `MIDIFile.Error.invalidHeader` when the first byte does not equal `0xFF`,
  ///           Any error encountered initializing the `data` property with the specified
  ///           data bytes.
  public init(delta: UInt64, data: Foundation.Data.SubSequence) throws
  {
    // Initialize `delta` with the specified tick offset.
    self.delta = delta
    
    // Check that there are at least 3 raw bytes in `data`.
    guard data.count >= 3
    else
    {
      // Throw an invalid length error.
      throw File.Error.invalidLength("Not enough bytes in the data provided.")
    }
    
    // Check the first byte of data.
    guard data[data.startIndex] == 0xFF
    else
    {
      // Throw an invalid header error.
      throw File.Error.invalidHeader("The first byte of data must equal 0xFF")
    }
    
    // Create a variable to hold the current index, beginning with the second byte.
    var currentIndex = data.startIndex + 1
    
    // Get the byte specifying the meta MIDI event's type.
    let typeByte = data[currentIndex]
    
    // Increment the index past the type byte.
    currentIndex += 1
    
    // Create a variable to hold the index of the final byte of the variable length
    // quantity representing the expected number of bytes in the meta MIDI event's data.
    var last7BitByte = currentIndex
    
    // Iterate through the raw bytes while the iterated byte when interpretted as a 7-bit
    // value followed by a flag bit has the flag bit set.
    while data[last7BitByte] & 0x80 != 0
    {
      // Increment `last7BitByte` to check the next byte for the end of the variable
      // length quantity.
      last7BitByte += 1
    }
    
    // Get the variable length quantity bytes that contain the expected data size.
    let dataLengthBytes = data[currentIndex ... last7BitByte]
    
    // Get the expected length of the meta MIDI event's data by converting a variable
    // length quantity initialized with the determined subrange of bytes.
    let dataLength = Int(VariableLengthQuantity(bytes: dataLengthBytes))
    
    // Set the current index to the location of the next unproccessed byte.
    currentIndex = last7BitByte + 1
    
    // Check that the number of bytes remaining matches the expected data length.
    guard data.endIndex == currentIndex &+ dataLength
    else
    {
      // Throw an invalid length error.
      throw File.Error.invalidLength("Specified length does not match actual")
    }
    
    // Initialize `data` using `typeByte` and the remaining bytes.
    self.data = try Data(type: typeByte, data: data[currentIndex|->])
    
    // Initialize `time` with `zero`.
    time = .zero
  }
  
  /// Initializing with a bar-beat time and the meta MIDI event's data.
  ///
  /// - Parameters:
  ///   - time: The tick offset represented as a bar-beat time for the new `MetaEvent`.
  ///   - data: The data for the new `MetaEvent`.
  public init(time: BarBeatTime, data: Data)
  {
    // Initialize `time` with the specified bar-beat time.
    self.time = time
    
    // Initialize `data` with the specified data.
    self.data = data
  }
  
  public func hash(into hasher: inout Hasher)
  {
    time.hash(into: &hasher)
    data.hash(into: &hasher)
    delta?.hash(into: &hasher)
  }
  
  /// Returns `true` iff the two events have equal `time`, `delta`, and `data` values.
  public static func == (lhs: MetaEvent, rhs: MetaEvent) -> Bool
  {
    return lhs.time == rhs.time && lhs.delta == rhs.delta && lhs.data == rhs.data
  }
  
  public var description: String { return "\(time) \(data)" }
  
  /// An enumeration encapsulating the data for a meta MIDI event representable by an
  /// instance of `MetaEvent`.
  public enum Data: Hashable, CustomStringConvertible
  {
    /// A string in the general sense.
    case text(text: String)
    
    /// A string intended to serve as a copyright notice.
    case copyrightNotice(notice: String)
    
    /// A string specifying the name of a sequence or track.
    case sequenceTrackName(name: String)
    
    /// A string specifying the name of an instrument.
    case instrumentName(name: String)
    
    /// A string for labeling a particular tick offset.
    case marker(name: String)
    
    /// A string specifying the name of a device.
    case deviceName(name: String)
    
    /// A string specifying the name of a program.
    case programName(name: String)
    
    /// Used to mark the end of a track.
    case endOfTrack
    
    /// A double value containing the number of beats per minute.
    case tempo(bpm: Double)
    
    /// The components needed for expressing the time signature: a `TimeSignature` value
    /// which holds the numerator and denominator of the time signature as it would be
    /// notated, a `UInt8` specifying the number of MIDI clocks per metronome click, and
    /// a `UInt8` specifying the number of thirty-second notes per 24 MIDI clocks.
    case timeSignature(signature: TimeSignature, clocks: UInt8, notes: UInt8)
    
    /// The byte that follows `FF`, when transmitting a meta MIDI event, to specify the
    /// type of event.
    public var type: UInt8
    {
      // Return the byte that corresponds with the data.
      switch self
      {
        case .text: return 0x01
        case .copyrightNotice: return 0x02
        case .sequenceTrackName: return 0x03
        case .instrumentName: return 0x04
        case .marker: return 0x06
        case .programName: return 0x08
        case .deviceName: return 0x09
        case .endOfTrack: return 0x2F
        case .tempo: return 0x51
        case .timeSignature: return 0x58
      }
    }
    
    /// The raw bytes of data for use in MIDI packet transmissions.
    public var bytes: [UInt8]
    {
      // Consider the data.
      switch self
      {
        case let .text(text),
             let
              .copyrightNotice(text),
             let
              .sequenceTrackName(text),
             let
              .instrumentName(text),
             let
              .marker(text),
             let
              .programName(text),
             let
              .deviceName(text):
          // The data is composed of a single string of text. Return the string's bytes.
          
          return text.bytes
          
        case .endOfTrack:
          // The data is empty. Return an empty array.
          
          return []
          
        case let .tempo(tempo):
          // The data contains the number of beats per minute. Convert to the number of
          // microseconds per MIDI quarter-note and return the three least significant
          // bytes.
          
          return Array(UInt32(60_000_000 / tempo).bytes.dropFirst())
          
        case let .timeSignature(signature, clocks, notes):
          // The data contains a structure and two bytes. Return the bytes of the
          // structure followed by the other two bytes.
          
          return signature.bytes + [clocks, notes]
      }
    }
    
    /// Initializing with the data's event type and the data's raw bytes.
    ///
    /// - Parameters:
    ///   - type: The byte specifying the type of event for the new `Data` instance.
    ///   - data: The raw byte representation for the new `Data` instance.
    /// - Throws: `MIDIFile.Error.invalidLength` when the number of bytes in `data` is
    ///           inconsistent with the number expected for `type`,
    ///           `MIDIFile.Error.unsupportedEvent` when `type` does not match the type
    ///           value for one of the `Data` enumeration cases.
    public init(type: UInt8, data: Foundation.Data.SubSequence) throws
    {
      // Consider the type-specifying byte.
      switch type
      {
        case 0x01:
          // The type is `text`.
          
          self = .text(text: String(bytes: data))
          
        case 0x02:
          // The type is `copyrightNotice`.
          
          self = .copyrightNotice(notice: String(bytes: data))
          
        case 0x03:
          // The type is `sequenceTrackName`.
          
          self = .sequenceTrackName(name: String(bytes: data))
          
        case 0x04:
          // The type is `instrumentName`.
          
          self = .instrumentName(name: String(bytes: data))
          
        case 0x06:
          // The type is `marker`.
          
          self = .marker(name: String(bytes: data))
          
        case 0x08:
          // The type is `programName`.
          
          self = .programName(name: String(bytes: data))
          
        case 0x09:
          // The type is `deviceName`.
          
          self = .deviceName(name: String(bytes: data))
          
        case 0x2F:
          // The type is `endOfTrack`.
          
          // Check that the specified collection of raw bytes is empty.
          guard data.isEmpty
          else
          {
            // Throw an `invalidLength` error.
            throw File.Error.invalidLength("An end-of-track event has no data.")
          }
          
          self = .endOfTrack
          
        case 0x51:
          // The type is `tempo`.
          
          // Check that there are 3 bytes of data.
          guard data.count == 3
          else
          {
            // Create an error message.
            let message = "Expected 3 bytes of data for tempo event."
            
            // Throw an `invalidLength` error.
            throw File.Error.invalidLength(message)
          }
          
          // Convert the three bytes specifying microseconds per quarter-note into a
          // double specifying the beats per minute.
          let bpm = Double(60_000_000 / UInt32(bytes: data))
          
          self = .tempo(bpm: bpm)
          
        case 0x58:
          // The type is `timeSignature`.
          
          // Check that there are 4 bytes of data.
          guard data.count == 4
          else
          {
            // Create an error message.
            let message = "TimeSignature event data should have a 4 byte length"
            
            // Throw an `invalidLength` error.
            throw File.Error.invalidLength(message)
          }
          
          // Create a time signature with the first two bytes.
          let signature = TimeSignature(bytes: data.prefix(2))
          
          // The third byte holds the number of MIDI clocks per metronome click.
          let clocks = data[data.startIndex &+ 2]
          
          // The fourth byte holds the number of thirty-second notes per 24 MIDI clocks.
          let notes = data[data.startIndex &+ 3]
          
          self = .timeSignature(signature: signature, clocks: clocks, notes: notes)
          
        default:
          // The specified type is not one of the supported meta event types.
          
          // Create an error message.
          let message = "\(String(type, radix: 16)) is not a supported meta event type."
          
          // Throw an `unsupportedEvent` error.
          throw File.Error.unsupportedEvent(message)
      }
    }
    
    public var description: String
    {
      // Consider the data.
      switch self
      {
        case let .text(text):
          return "text '\(text)'"
          
        case let .copyrightNotice(text):
          return "copyright '\(text)'"
          
        case let .sequenceTrackName(text):
          return "sequence/track name '\(text)'"
          
        case let .instrumentName(text):
          return "instrument name '\(text)'"
          
        case let .marker(text):
          return "marker '\(text)'"
          
        case let .programName(text):
          return "program name '\(text)'"
          
        case let .deviceName(text):
          return "device name '\(text)'"
          
        case .endOfTrack:
          return "end of track"
          
        case let .tempo(bpm):
          return "tempo \(bpm)"
          
        case let .timeSignature(signature, _, _):
          return "time signature \(signature.beatsPerBar)╱\(signature.beatUnit)"
      }
    }
    
    public func hash(into hasher: inout Hasher)
    {
      type.hash(into: &hasher)
      switch self
      {
        case let .text(text),
             let
              .copyrightNotice(text),
             let
              .sequenceTrackName(text),
             let
              .instrumentName(text),
             let
              .marker(text),
             let
              .deviceName(text),
             let
              .programName(text):
          // The hash value for the data's actual 'data' is the string's hash value.
          
          text.hash(into: &hasher)
          
        case .endOfTrack:
          // The data has no actual 'data' so the hash value is `0`.
          
          break
          
        case let .tempo(bpm):
          // The hash value for the data's actual 'data' is the double's hash value.
          
          bpm.hash(into: &hasher)
          
        case let .timeSignature(signature, clocks, notes):
          // The hash value of the data's actual 'data' is the bitwise XOR of the
          // hash values for the `signature`, `clocks`, and `notes`.
          
          signature.hash(into: &hasher)
          clocks.hash(into: &hasher)
          notes.hash(into: &hasher)
      }
    }
    
    /// Returns `true` iff the two values are the same enumeration case with equal
    /// associated values.
    public static func == (lhs: Data, rhs: Data) -> Bool
    {
      // Consider the two values.
      switch (lhs, rhs)
      {
        case let (.text(text1), .text(text2)),
             let (.copyrightNotice(text1), .copyrightNotice(text2)),
             let (.sequenceTrackName(text1), .sequenceTrackName(text2)),
             let (.instrumentName(text1), .instrumentName(text2)),
             let (.marker(text1), .marker(text2)),
             let (.deviceName(text1), .deviceName(text2)),
             let (.programName(text1), .programName(text2)):
          // The two values are of the same case with an associated string value. Return
          // the result of evaluating the two strings for equality.
          
          return text1 == text2
          
        case (.endOfTrack, .endOfTrack):
          // The two values are both `endOfTrack`. Since there are no associated values
          // to consider, return `true`.
          
          return true
          
        case let (.tempo(bpm1), .tempo(bpm2)):
          // The two values are both `tempo`. Return the result of evaluating the two
          // double values for equality.
          
          return bpm1 == bpm2
          
        case let (.timeSignature(s1, c1, n1), .timeSignature(s2, c2, n2)):
          // The two values are both `timeSignature`. Return the result of evaluating
          // their associated values for equality.
          
          return s1 == s2 && c1 == c2 && n1 == n2
          
        default:
          // The values are not of the same enumeration case, return `false`.
          
          return false
      }
    }
  }
}
