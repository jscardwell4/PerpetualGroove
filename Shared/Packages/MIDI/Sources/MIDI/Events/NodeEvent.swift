//
//  NodeEvent.swift
//  Groove
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import CoreGraphics
import Foundation
import MoonDev
import struct Common.Trajectory

// MARK: - NodeEvent

/// A MIDI meta event that uses the 'Cue Point' message to embed data for adding and
/// removing `Node` instances to and from the MIDI node player.
public struct NodeEvent: _Event, Hashable
{
  public var time = BarBeatTime.zero

  public var delta: UInt64?

  /// The event's data for adding or removing a MIDI node.
  public let data: Data

  public var bytes: [UInt8]
  {
    // Get the bytes for the event's data.
    let dataBytes = data.bytes

    // Create a variable length quantity for the data's length.
    let length = VariableLengthQuantity(dataBytes.count)

    // Create an array of bytes initialized with the 'FF' specifying a meta event and
    // '7' indicating a 'Cue Point' message.
    var bytes: [UInt8] = [0xFF, 0x07]

    // Append the bytes for the variable length quantity.
    bytes.append(contentsOf: length.bytes)

    // Append the bytes of data.
    bytes.append(contentsOf: dataBytes)

    // Return the array of bytes.
    return bytes
  }

  /// The unique node identifier specified in the event's `data`.
  public var identifier: Identifier
  {
    // Consider the data.
    switch data
    {
      case let .add(id, _, _),
           let .remove(id):
        // Return the data's identifier

        return id
    }
  }

  /// Wrapper for the `nodeIdentifier` property of `identifier`.
  public var nodeIdentifier: UUID { identifier.nodeIdentifier }

  /// Wrapper for the `loopIdentifier` property of `identifier`.
  public var loopIdentifier: UUID? { identifier.loopIdentifier }

  /// Initializing with data and a bar-beat time.
  ///
  /// - Parameters:
  ///   - data: The data for the new MIDI node event.
  ///   - time: The bar-beat time to use when initializing the MIDI node event's `time`
  ///           property. The default is `zero`.
  public init(data: Data, time: BarBeatTime = .zero)
  {
    // Initialize `data` with the specified data.
    self.data = data

    // Initialize `time` with the specified bar-beat time.
    self.time = time
  }

  public init(delta: UInt64, data: Foundation.Data.SubSequence) throws
  {
    self.delta = delta
    guard data[data.startIndex +--> 2].elementsEqual([0xFF, 0x07])
    else
    {
      throw File.Error.invalidHeader("Event must begin with `FF 07`")
    }

    var currentIndex = data.startIndex + 2

    var i = currentIndex
    while data[i] & 0x80 != 0 { i += 1 }

    let dataLength = Int(VariableLengthQuantity(bytes: data[currentIndex ... i]))

    currentIndex = i + 1

    i += dataLength + 1

    guard data.endIndex == i
    else
    {
      throw File.Error.invalidLength("Specified length does not match actual")
    }

    self.data = try Data(data: data[currentIndex ..< i])
  }

  public func hash(into hasher: inout Hasher)
  {
    time.hash(into: &hasher)
    delta?.hash(into: &hasher)
    data.hash(into: &hasher)
  }

  public static func == (lhs: NodeEvent, rhs: NodeEvent) -> Bool
  {
    return lhs.time == rhs.time && lhs.delta == rhs.delta && lhs.data == rhs.data
  }

  public var description: String { return "\(time) \(data)" }
}

extension NodeEvent
{
  /// Type to encode and decode the bytes used to identify a MIDI node.
  public struct Identifier: Hashable, Codable
  {
    public let loopIdentifier: UUID?
    public let nodeIdentifier: UUID

    public init(loopIdentifier: UUID? = nil, nodeIdentifier: UUID)
    {
      self.loopIdentifier = loopIdentifier
      self.nodeIdentifier = nodeIdentifier
    }

    public var bytes: [UInt8]
    {
      let nodeIdentifierBytes = {
        [$0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7,
         $0.8, $0.9, $0.10, $0.11, $0.12, $0.13, $0.14, $0.15]
      }(nodeIdentifier.uuid)

      if let loopIdentifier = loopIdentifier
      {
        let loopIdentifierBytes = {
          [$0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7,
           $0.8, $0.9, $0.10, $0.11, $0.12, $0.13, $0.14, $0.15]
        }(loopIdentifier.uuid)

        return UInt32(16).bytes + loopIdentifierBytes + ":".bytes + nodeIdentifierBytes
      }
      else
      {
        return UInt32(0).bytes + ":".bytes + nodeIdentifierBytes
      }
    }

    public var length: UInt32 { return UInt32(bytes.count) }

    public init(data: Foundation.Data.SubSequence) throws
    {
      guard data.count >= 4
      else
      {
        throw File.Error.invalidLength("Not enough bytes for node event identifier")
      }

      var currentIndex = data.startIndex

      let loopIDByteCount = Int(UInt32(bytes: data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.endIndex - currentIndex >= loopIDByteCount
      else
      {
        throw File.Error.invalidLength("Not enough bytes for node event identifier")
      }

      if loopIDByteCount == 16
      {
        loopIdentifier = UUID(
          uuid: data.withUnsafeBytes
          { (pointer: UnsafeRawBufferPointer) -> uuid_t in
            (pointer.baseAddress! + currentIndex).assumingMemoryBound(to: uuid_t.self)
              .pointee
          }
        )
      }
      else
      {
        loopIdentifier = nil
      }

      currentIndex += loopIDByteCount

      guard String(data[currentIndex]) == ":"
      else
      {
        throw File.Error
        .fileStructurallyUnsound("Missing separator in node event identifier")
      }

      currentIndex += 1

      guard data.endIndex - currentIndex >= 16
      else
      {
        throw File.Error.invalidLength("Not enough bytes for node event identifier")
      }

      nodeIdentifier = UUID(
        uuid: data.withUnsafeBytes
        { (pointer: UnsafeRawBufferPointer) -> uuid_t in
          (pointer.baseAddress! + currentIndex).assumingMemoryBound(to: uuid_t.self)
            .pointee
        }
      )
    }

    private enum CodingKeys: String, CodingKey
    {
      case nodeIdentifier, loopIdentifier
    }

    public func encode(to encoder: Encoder) throws
    {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(nodeIdentifier, forKey: .nodeIdentifier)
      if let loopIdentifier = loopIdentifier
      {
        try container.encode(loopIdentifier, forKey: .loopIdentifier)
      }
      else
      {
        try container.encodeNil(forKey: .loopIdentifier)
      }
    }

    public init(from decoder: Decoder) throws
    {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      nodeIdentifier = try container.decode(UUID.self, forKey: .nodeIdentifier)
      loopIdentifier = try container.decodeIfPresent(UUID.self, forKey: .loopIdentifier)
    }

    public func hash(into hasher: inout Hasher)
    {
      nodeIdentifier.hash(into: &hasher)
      loopIdentifier?.hash(into: &hasher)
    }

    public static func == (lhs: Identifier, rhs: Identifier) -> Bool
    {
      return lhs.nodeIdentifier == rhs.nodeIdentifier && lhs.loopIdentifier == rhs
        .loopIdentifier
    }
  }
}

extension NodeEvent
{
  public enum Data: Hashable, CustomStringConvertible
  {
    case add(identifier: Identifier, trajectory: Trajectory, generator: AnyGenerator)
    case remove(identifier: Identifier)

    public init(data: Foundation.Data.SubSequence) throws
    {
      var currentIndex = data.startIndex

      let identifierByteCount = Int(UInt32(bytes: data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.count >= identifierByteCount
      else
      {
        throw File.Error
        .invalidLength("Data length must at least cover length of identifier")
      }

      let identifier = try Identifier(data: data[currentIndex +--> identifierByteCount])

      currentIndex += identifierByteCount

      guard currentIndex != data.endIndex
      else
      {
        self = .remove(identifier: identifier)
        return
      }

      var i = currentIndex + Int(data[currentIndex]) + 1

      currentIndex += 1

      guard data.endIndex - i > 0
      else
      {
        throw File.Error.invalidLength("Not enough bytes for event")
      }

      let trajectory = Trajectory(bytes: data[currentIndex ..< i])
      guard trajectory != .null
      else
      {
        throw File.Error.fileStructurallyUnsound("Invalid trajectory data")
      }

      currentIndex = i + 1
      i += Int(data[i]) + 1

      guard data.endIndex - i == 0
      else
      {
        throw File.Error.invalidLength("Incorrect number of bytes")
      }

      self = .add(identifier: identifier,
                  trajectory: trajectory,
                  generator: .note(NoteGenerator(bytes: data[currentIndex ..< i])))
    }

    public var bytes: [UInt8]
    {
      switch self
      {
        case let .add(identifier, trajectory, generator):
          var bytes = identifier.length.bytes + identifier.bytes
          let trajectoryBytes = trajectory.bytes
          bytes.append(UInt8(trajectoryBytes.count))
          bytes += trajectoryBytes
          if case let .note(noteGenerator) = generator
          {
            let generatorBytes = noteGenerator.bytes
            bytes.append(UInt8(generatorBytes.count))
            bytes += generatorBytes
          }
          return bytes

        case let .remove(identifier): return identifier.bytes
      }
    }

    public var description: String
    {
      switch self
      {
        case let .add(identifier, trajectory, generator):
          return "add node '\(identifier)' (\(trajectory), \(generator))"
        case let .remove(identifier):
          return "remove node '\(identifier)'"
      }
    }

    public func hash(into hasher: inout Hasher)
    {
      switch self
      {
        case let .add(identifier, trajectory, generator):
          identifier.hash(into: &hasher)
          trajectory.hash(into: &hasher)
          generator.hash(into: &hasher)

        case let .remove(identifier):
          identifier.hash(into: &hasher)
      }
    }

    public static func == (lhs: Data, rhs: Data) -> Bool
    {
      switch (lhs, rhs)
      {
        case let (.add(identifier1, trajectory1, generator1),
                  .add(identifier2, trajectory2, generator2))
              where identifier1 == identifier2
              && trajectory1 == trajectory2
              && generator1 == generator2:
          return true
        case let (.remove(identifier1), .remove(identifier2))
              where identifier1 == identifier2:
          return true
        default:
          return false
      }
    }
  }
}
