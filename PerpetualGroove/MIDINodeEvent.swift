//
//  MIDINodeEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// A MIDI meta event that uses the 'Cue Point' message to embed `MIDINode` trajectory 
/// and removal events for a track.
struct MIDINodeEvent: MIDIEvent {

  var time: BarBeatTime = BarBeatTime.zero
  let data: Data
  var delta: MIDIFile.VariableLengthQuantity?

  var bytes: [Byte] { return [0xFF, 0x07] + data.length.bytes + data.bytes }

  var identifier: Identifier {
    switch data {
      case let .add(id, _, _): return id
      case let .remove(id):    return id
    }
  }

  var nodeIdentifier: UUID { return identifier.nodeIdentifier }

  var loopIdentifier: UUID?  { return identifier.loopIdentifier }

  /// Initializer that takes the event's data and, optionally, the event's bar beat time
  init(data: Data, time: BarBeatTime? = nil) {
    self.data = data
    self.time = time ?? BarBeatTime.zero
  }

  init(delta: MIDIFile.VariableLengthQuantity, data: Foundation.Data.SubSequence) throws {
    self.delta = delta
    guard data[data.startIndex +--> 2].elementsEqual([0xFF, 0x07]) else {
      throw MIDIFileError(type: .invalidHeader, reason: "Event must begin with `FF 07`")
    }

    var currentIndex = data.startIndex + 2

    var i = currentIndex
    while data[i] & 0x80 != 0 { i += 1 }

    let dataLength = MIDIFile.VariableLengthQuantity(bytes: data[currentIndex ... i])

    currentIndex = i + 1

    i += dataLength.intValue + 1

    guard data.endIndex == i else {
      throw MIDIFileError(type: .invalidLength, reason: "Specified length does not match actual")
    }

    self.data = try Data(data: data[currentIndex ..< i])
  }
}

extension MIDINodeEvent {

  struct Identifier {
    let loopIdentifier: UUID?
    let nodeIdentifier: UUID

    init(loopIdentifier: UUID? = nil, nodeIdentifier: UUID) {
      self.loopIdentifier = loopIdentifier
      self.nodeIdentifier = nodeIdentifier
    }

    var bytes: [Byte] {

      let nodeIdentifierBytes = {[$0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7,
                                  $0.8, $0.9, $0.10, $0.11, $0.12, $0.13, $0.14, $0.15]}(nodeIdentifier.uuid)

      if let loopIdentifier = loopIdentifier {
        let loopIdentifierBytes = {[$0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7,
                                    $0.8, $0.9, $0.10, $0.11, $0.12, $0.13, $0.14, $0.15]}(loopIdentifier.uuid)

        return Byte4(16).bytes + loopIdentifierBytes + ":".bytes + nodeIdentifierBytes
      } else {
        return Byte4(0).bytes + ":".bytes + nodeIdentifierBytes
      }
    }

    var length: Byte4 { return Byte4(bytes.count) }

    init(data: Foundation.Data.SubSequence) throws {
      guard data.count >= 4 else {
        throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes for node event identifier")
      }

      var currentIndex = data.startIndex

      let loopIDByteCount = Int(Byte4(data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.endIndex - currentIndex >= loopIDByteCount else {
        throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes for node event identifier")
      }

      if loopIDByteCount == 16 {
        loopIdentifier = UUID(
          uuid: data.base.withUnsafeBytes({
            (($0 as UnsafePointer<UInt8>) + currentIndex)
              .withMemoryRebound(to: uuid_t.self, capacity: 1, {$0}).pointee
          })
        )
      } else {
        loopIdentifier = nil
      }

      currentIndex += loopIDByteCount

      guard String(data[currentIndex]) == ":" else {
        throw MIDIFileError(type: .fileStructurallyUnsound, reason: "Missing separator in node event identifier")
      }

      currentIndex += 1

      guard data.endIndex - currentIndex >= 16 else {
        throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes for node event identifier")
      }

      nodeIdentifier = UUID(
          uuid: data.base.withUnsafeBytes({
            (($0 as UnsafePointer<UInt8>) + currentIndex)
              .withMemoryRebound(to: uuid_t.self, capacity: 1, {$0}).pointee
          })
        )
    }

  }
}

extension MIDINodeEvent.Identifier: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return ["nodeIdentifier": nodeIdentifier.uuidString.jsonValue,
            "loopIdentifier": loopIdentifier?.uuidString.jsonValue]
  }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
      let nodeIdentifierString = String(dict["nodeIdentifier"]),
      let nodeIdentifier = UUID(uuidString: nodeIdentifierString) else { return nil }
    self.nodeIdentifier = nodeIdentifier

    if let loopIdentifierString = String(dict["loopIdentifier"]),
       let loopIdentifier = UUID(uuidString: loopIdentifierString)
    {
      self.loopIdentifier = loopIdentifier
    } else {
      loopIdentifier = nil
    }

  }

}

extension MIDINodeEvent.Identifier: StringValueConvertible {

  var stringValue: String { return "\(loopIdentifier):\(nodeIdentifier)" }

}

extension MIDINodeEvent.Identifier: Hashable {

  var hashValue: Int { return stringValue.hashValue }

  static func ==(lhs: MIDINodeEvent.Identifier, rhs: MIDINodeEvent.Identifier) -> Bool {
    return lhs.stringValue == rhs.stringValue
  }

}

extension MIDINodeEvent {

  enum Data {
    case add(identifier: Identifier, trajectory: Trajectory, generator: AnyMIDIGenerator)
    case remove(identifier: Identifier)

    init(data: Foundation.Data.SubSequence) throws {
      var currentIndex = data.startIndex

      let identifierByteCount = Int(Byte4(data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.count >= identifierByteCount else {
        throw MIDIFileError(type: .invalidLength,
                            reason: "Data length must be at least as large as the bytes required for identifier")
      }

      let identifier = try Identifier(data: data[currentIndex +--> identifierByteCount])

      currentIndex += identifierByteCount

      guard currentIndex != data.endIndex else {
        self = .remove(identifier: identifier)
        return
      }

      var i = currentIndex + Int(data[currentIndex]) + 1

      currentIndex += 1

      guard data.endIndex - i > 0 else {
        throw MIDIFileError(type: .invalidLength, reason: "Not enough bytes for event")
      }

      let trajectory = Trajectory(data[currentIndex ..< i])
      guard trajectory != .null else {
        throw MIDIFileError(type: .readFailure, reason: "Null trajectory produced")
      }

      currentIndex = i + 1
      i += Int(data[i]) + 1

      guard data.endIndex - i == 0 else {
        throw MIDIFileError(type: .invalidLength, reason: "Incorrect number of bytes")
      }

      self = .add(identifier: identifier,
                  trajectory: trajectory,
                  generator: AnyMIDIGenerator(NoteGenerator(data[currentIndex ..< i])))
    }

    var bytes: [Byte] {
      switch self {
        case let .add(identifier, trajectory, generator):
          var bytes = identifier.length.bytes + identifier.bytes
          let trajectoryBytes = trajectory.bytes
          bytes.append(Byte(trajectoryBytes.count))
          bytes += trajectoryBytes
          if case .note(let noteGenerator) = generator {
            let generatorBytes = noteGenerator.bytes
            bytes.append(Byte(generatorBytes.count))
            bytes += generatorBytes
          }
          return bytes

        case let .remove(identifier): return identifier.bytes
      }
    }
    
    var length: MIDIFile.VariableLengthQuantity { return MIDIFile.VariableLengthQuantity(bytes.count) }
  }
}

extension MIDINodeEvent: Equatable {

  static func ==(lhs: MIDINodeEvent, rhs: MIDINodeEvent) -> Bool {
    return lhs.bytes == rhs.bytes
  }

}

extension MIDINodeEvent.Data: CustomStringConvertible {

  var description: String {
    switch self {
      case let .add(identifier, trajectory, generator):
        return "add node '\(identifier)' (\(trajectory), \(generator))"
      case let .remove(identifier):
        return "remove node '\(identifier)'"
    }
  }

}

extension MIDINodeEvent: CustomStringConvertible {

  var description: String { return "\(time) \(data)" }

}

extension MIDINodeEvent.Data: Equatable {

  static func ==(lhs: MIDINodeEvent.Data, rhs: MIDINodeEvent.Data) -> Bool {
    return lhs.bytes == rhs.bytes
  }

}
