//
//  ChannelEvent.swift
//  MIDI
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

/// Struct to hold data for a channel event where
/// event = \<delta time\> \<status\> \<data1\> \<data2\>
public struct ChannelEvent: _MIDIEvent, Hashable {

  public var time: BarBeatTime

  public var delta: UInt64?

  /// Structure representing the channel event's status byte.
  public var status: Status

  /// The first byte of data attached to the channel event. All channel events contain at
  /// least one byte of data.
  public var data1: UInt8

  /// The second byte of data attached to the channel event. Some channel events, such
  /// as a channel event specifying a program change, have only one byte of data.
  public var data2: UInt8?

  public var bytes: [UInt8] {

    // Create an array for accumulating bytes intialized with the status byte and the
    // first byte of data.
    var result = [status.value, data1]

    // Check whether there is an additional byte of data.
    if let data2 = data2 {

      // Append the second byte of data.
      result.append(data2)

    }

    // Return the array of bytes.
    return result

  }

  /// Initializing with a tick offset, a bar-beat time, and the raw bytes for a channel
  /// event.
  ///
  /// - Parameters:
  ///   - delta: The tick offset for the new channel event.
  ///   - data: The collection of `UInt8` values for a MIDI transmission of the new
  ///           channel event.
  ///   - time: The event offset expressed as a bar-beat time. The default is `zero`.
  /// - Throws: `MIDIFile.Error.invalidLength` when `data` is empty or there is a mismatch
  ///           between the number of bytes provided in `data` and the number of bytes
  ///           expected for the kind of channel event specified by the status byte
  ///           obtained from `data`, any error encountered intializing a `Status` value
  ///           with the status byte obtained from `data`.
  public init(delta: UInt64,
       data: Foundation.Data.SubSequence,
       time: BarBeatTime = .zero) throws
  {

    // Initialize `delta` with the specified delta value.
    self.delta = delta

    // Get the status byte from `data`.
    guard let statusByte = data.first else {

      // Create an error message.
      let message = "\(#function) requires a non-empty collection of `UInt8` values."

      // Throw an `invalidLength` error.
      throw Error.invalidLength(message)

    }

    // Initialize `status` using the first byte of data.
    status = try Status(statusByte: statusByte)

    // Check the number of raw bytes against the count expected per the kind of event.
    guard data.count == status.kind.byteCount else {

      // Create an error message.
      let message = "The number of bytes provided does not match the number expected."

      // Throw an `invalidLength` error.
      throw Error.invalidLength(message)

    }

    // Initialize `data1` with the second byte of the data provided.
    data1 = data[data.startIndex + 1]

    // Consider the expected number of bytes.
    switch status.kind.byteCount {

      case 3:
        // `data` is expected to contain the status byte and two data bytes.

        // Initialize `data2` with the third byte of the data provided.
        data2 = data[data.startIndex &+ 2]

      default:
        // `data` is only expected to contain the status byte and a data byte.

        // Initialize `data2` with a `nil` value.
        data2 = nil

    }

    // Initialize `time` with the specified bar-beat time.
    self.time = time

  }

  /// Initializing with kind and channel values for a `Status` value, the data bytes, and
  /// a bar-beat time.
  ///
  /// - Parameters:
  ///   - kind: The `Status.Kind` value to use when initializing the new channel event's
  ///            `status` property.
  ///   - channel: The channel value to use when initializing the new channel event's
  ///              `status` property.
  ///   - data1: The first byte of data for the new channel event.
  ///   - data2: The optional second byte of data for the new channel event. The default
  ///            is `nil`.
  ///   - time: The tick offset represented as a bar-beat time. The default is `zero`.
  /// - Throws: `MIDIFile.Error.unsupportedEvent` when the `nil` status of `data2` does
  ///           not match the expected `nil` status as determined by the value of `type`.
  public init(kind: Status.Kind,
              channel: UInt8,
              data1: UInt8,
              data2: UInt8? = nil,
              time: BarBeatTime = BarBeatTime.zero) throws
  {

    // Consider the expected bytes for specified type.
    switch kind.byteCount {

      case 3 where data2 == nil:
        // A second data byte is expected but not provided.

        // Create an error message.
        let message = "\(kind) expects a second data byte but `data2` is `nil`."

        // Throw an `unsupportedEvent` error.
        throw Error.unsupportedEvent(message)

      case 2 where data2 != nil:
        // A second data byte is provided but not expected.

        // Create an error message.
        let message = "\(kind) expects a single data byte but `data2` is not `nil`."

        // Throw an `unsupportedEvent` error.
        throw Error.unsupportedEvent(message)

      default:
        // The expected and provided bytes match.

        break

    }

    // Initialize `status` using the specified kind and channel.
    status = Status(kind: kind, channel: channel)

    // Initialize `data1` with the specified byte.
    self.data1 = data1

    // Initialize `data2` with the specified byte.
    self.data2 = data2

    // Initialize `time` with the specified bar-beat time value.
    self.time = time

  }

  public var description: String {

    // Create a string with the event's time and status values.
    var result = "\(time) \(status) "

    // Consider the kind of channel event.
    switch status.kind {

      case .noteOn, .noteOff:
        // The channel event is a 'note-on' or 'note-off' event.

        // Append the `MIDINote` and `Velocity` values created with the event's data.
        result += "\(MIDINote(midi: data1)) \(Velocity(midi: data2!))"

      default:
        // The channel event is not a 'note-on' or 'note-off' event.

        // Append the first byte of data.
        result += "\(data1)"

        // Check if there is a second byte of data.
        if let data2 = data2 {

          // Append the second byte of data.
          result += " \(data2)"
        }

    }

    return result

  }

  public func hash(into hasher: inout Hasher) {
    time.hash(into: &hasher)
    delta?.hash(into: &hasher)
    status.hash(into: &hasher)
    data1.hash(into: &hasher)
    data2?.hash(into: &hasher)
  }

  /// Returns `true` iff all property values of the two channel events are equal.
  public static func ==(lhs: ChannelEvent, rhs: ChannelEvent) -> Bool {

    // Return the result of evaluating the properties of the two values for equality.
    lhs.status == rhs.status
      && lhs.data1 == rhs.data1
      && lhs.time == rhs.time
      && lhs.data2 == rhs.data2
      && lhs.delta == rhs.delta

  }

  /// A structure representing a channel event's status byte.
  public struct Status: Hashable, CustomStringConvertible {

    /// The kind of channel event specified by the status.
    public var kind: Kind

    /// The MIDI channel specified by the status.
    public var channel: UInt8

    /// The status byte for a MIDI transmission of a channel event with the status.
    public var value: UInt8 {

      // Return a `UInt8` value whose four most significant bits are obtained from the
      // raw value for `kind` and whose four least significant bits are obtained from
      // the value of `channel`.
      (kind.rawValue << 4) | channel

    }

    public var description: String { return "\(kind) (\(channel))" }

    public func hash(into hasher: inout Hasher) {
      kind.hash(into: &hasher)
      channel.hash(into: &hasher)
    }

    /// Initializing with the status byte of a channel event.
    ///
    /// - Parameter statusByte: The `UInt8` value containing the status byte of a
    ///                         channel event MIDI transmission.
    /// - Throws: `MIDIFile.Error.unsupportedEvent` when the kind specified by
    ///           `statusByte` does not match the raw value for one of the cases in the
    ///           `Kind` enumeration.
    public init(statusByte: UInt8) throws {

      // Initialize a `Kind` value using the four most significant bits shifted into the
      // four least significant bits.
      guard let kind = Status.Kind(rawValue: statusByte >> 4) else {

        // Create an error message.
        let message = "\(statusByte >> 4) is not a supported channel event."

        // Throw an `unsupportedEvent` error.
        throw Error.unsupportedEvent(message)

      }

      // Initialize `kind` with the value initialized using `statusByte`.
      self.kind = kind

      // Initialize `channel` by masking `statusByte` to be within the range `0...15`.
      channel = statusByte & 0xF

    }

    /// Initializing with kind and channel values.
    ///
    /// - Parameters:
    ///   - kind: The kind of channel event indicated by the new status value.
    ///   - channel: The channel value for the new status value.
    public init(kind: Kind, channel: UInt8) {

      // Initialize `kind` with the specified value.
      self.kind = kind

      // Initialize `channel` with the specified value.
      self.channel = channel

    }

    /// Returns `true` iff the `value` values of the two status values are equal.
    public static func ==(lhs: Status, rhs: Status) -> Bool { lhs.value == rhs.value }

    /// An enumeration of the seven MIDI channel voice messages where the raw value of a
    /// case is equal to the four bit number stored in the four most significant bits of
    /// a channel event's status byte.
    public enum Kind: UInt8 {

      /// Specifies a channel event containing a MIDI note to stop playing and a release
      /// velocity.
      case noteOff = 0x8

      /// Specifies a channel event containing a MIDI note to start playing and a
      /// velocity.
      case noteOn = 0x9

      /// Specifies a channel event containing a MIDI note for polyphonic aftertouch and
      /// a pressure value.
      case polyphonicKeyPressure = 0xA

      /// Specifies a channel event containing a MIDI control and a value to apply.
      case controlChange = 0xB

      /// Specifies a channel event containing a MIDI program value.
      case programChange = 0xC

      /// Specifies a channel event containing a pressure value for channel aftertouch.
      case channelPressure = 0xD

      /// Specifies a channel event containing 'LSB' and 'MSB' pitch wheel values.
      case pitchBendChange = 0xE

      /// The total number of bytes in a channel event whose status byte's four most
      /// significant bits are equal to the kind's raw value. The value of this property
      /// will be `3` when a second data byte is expected and `2` otherwise.
      public var byteCount: Int {

        // Consider the kind.
        switch self {

        case .controlChange, .programChange, .channelPressure:
          // The kind specifies a channel event expecting only one byte of data.

          return 2

        default:
          // The kind specifies a channel event expecting two bytes of data.

          return 3

        }

      }

    }

  }

}

