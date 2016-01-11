//
//  MIDINodeEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

/** A MIDI meta event that uses the 'Cue Point' message to embed `MIDINode` trajectory and removal events for a track */
struct MIDINodeEvent: MIDIEventType {
  var time: CABarBeatTime = .start
  let data: Data
  var delta: VariableLengthQuantity?
  var bytes: [Byte] { return [0xFF, 0x07] + data.length.bytes + data.bytes }

  var identifier: Identifier {
    switch data {
    case let .Add(id, _, _): return id
    case let .Remove(id): return id
    }
  }

  typealias NodeIdentifier = MIDINode.Identifier
  var nodeIdentifier: NodeIdentifier { return identifier.nodeIdentifier }

  typealias LoopIdentifier = Loop.Identifier
  var loopIdentifier: LoopIdentifier?  { return identifier.loopIdentifier }

  /**
  Initializer that takes the event's data and, optionally, the event's bar beat time

  - parameter d: MetaEventData
  - parameter t: CABarBeatTime? = nil
  */
  init(_ d: Data, _ t: CABarBeatTime? = nil) { data = d; if let t = t { time = t } }

  init<C:CollectionType
    where C.Generator.Element == Byte,
          C.Index.Distance == Int,
          C.SubSequence.Generator.Element == Byte,
          C.SubSequence:CollectionType,
          C.SubSequence.Index.Distance == Int,
          C.SubSequence.SubSequence == C.SubSequence>(delta: VariableLengthQuantity, bytes: C) throws
  {
    self.delta = delta
    guard bytes[bytes.startIndex ... bytes.startIndex + 1].elementsEqual([0xFF, 0x07]) else {
      throw MIDIFileError(type: .InvalidHeader, reason: "Event must begin with `FF 07`")
    }
    var currentIndex = bytes.startIndex + 2
    var i = currentIndex
    while bytes[i] & 0x80 != 0 { i++ }
    let dataLength = VariableLengthQuantity(bytes: bytes[currentIndex ... i++])
    currentIndex = i
    i += dataLength.intValue
    guard bytes.endIndex == i else {
      throw MIDIFileError(type: .InvalidLength, reason: "Specified length does not match actual")
    }

    data = try Data(data: bytes[currentIndex ..< i])
  }
}

extension MIDINodeEvent {

  struct Identifier {
    let loopIdentifier: LoopIdentifier?
    let nodeIdentifier: NodeIdentifier

    typealias NodeIdentifier = MIDINodeEvent.NodeIdentifier
    typealias LoopIdentifier = MIDINodeEvent.LoopIdentifier

    /**
     initWithLoopIdentifier:nodeIdentifier:

     - parameter loopIdentifier: LoopIdentifier = ""
     - parameter nodeIdentifier: NodeIdentifier
    */
    init(loopIdentifier: LoopIdentifier? = nil, nodeIdentifier: NodeIdentifier) {
      self.loopIdentifier = loopIdentifier
      self.nodeIdentifier = nodeIdentifier
    }

    var bytes: [Byte] {
      if let loopIdentifier = loopIdentifier {
        let loopIdentifierBytes = loopIdentifier.bytes
        return Byte4(loopIdentifierBytes.count).bytes + loopIdentifierBytes + ":".bytes + nodeIdentifier.bytes
      } else {
        return Byte4(0).bytes + ":".bytes + nodeIdentifier.bytes
      }
    }

    var length: Byte4 { return Byte4(bytes.count) }

    init<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index.Distance == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index.Distance == Int,
            C.SubSequence.SubSequence == C.SubSequence>(data: C) throws
    {
      var currentIndex = data.startIndex
      guard data.count >= 4 else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for node event identifier")
      }
      let loopIDByteCount = Int(Byte4(data[currentIndex ➞ 4]))
      currentIndex += 4

      guard currentIndex.distanceTo(data.endIndex) >= loopIDByteCount else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for node event identifier")
      }

      if loopIDByteCount > 0 { loopIdentifier = LoopIdentifier(data[currentIndex ➞ loopIDByteCount]) }
      else { loopIdentifier = nil }

      currentIndex += loopIDByteCount

      guard String(data[currentIndex]) == ":" else {
        throw MIDIFileError(type: .FileStructurallyUnsound, reason: "Missing separator in node event identifier")
      }

      currentIndex++

      let nodeIdentifierByteCount = sizeof(NodeIdentifier)

      guard currentIndex.distanceTo(data.endIndex) >= nodeIdentifierByteCount else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for node event identifier")
      }

      nodeIdentifier = NodeIdentifier(data[currentIndex ➞ nodeIdentifierByteCount])
    }

  }
}

extension MIDINodeEvent.Identifier: JSONValueConvertible {
  var jsonValue: JSONValue {
    return ["nodeIdentifier": nodeIdentifier, "loopIdentifier": loopIdentifier]
  }
}

extension MIDINodeEvent.Identifier: JSONValueInitializable {
  /**
   init:

   - parameter jsonValue: JSONValue?
   */
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
      nodeIdentifier = NodeIdentifier(dict["nodeIdentifier"]) else { return nil }
    self.nodeIdentifier = nodeIdentifier
    loopIdentifier = LoopIdentifier(dict["loopIdentifier"])
  }
}

extension MIDINodeEvent.Identifier: StringValueConvertible {
  var stringValue: String { return "\(loopIdentifier):\(nodeIdentifier)" }
}

extension MIDINodeEvent.Identifier: Hashable {
  var hashValue: Int { return stringValue.hashValue }
}

func ==(lhs: MIDINodeEvent.Identifier, rhs: MIDINodeEvent.Identifier) -> Bool {
  return lhs.stringValue == rhs.stringValue
}

extension MIDINodeEvent {

  enum Data: Equatable {
    case Add(identifier: Identifier, trajectory: Trajectory, generator: MIDINodeGenerator)
    case Remove(identifier: Identifier)

    /**
    initWithData:

    - parameter data: C
    */
    init<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index.Distance == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence:CollectionType,
            C.SubSequence.Index.Distance == Int,
            C.SubSequence.SubSequence == C.SubSequence>(data: C) throws
    {
      var currentIndex = data.startIndex
      let identifierByteCount = Int(Byte4(data[data.startIndex ➞ 4])) //sizeof(NodeIdentifier.self)
      guard data.count >= identifierByteCount else {
        throw MIDIFileError(type: .InvalidLength,
                            reason: "Data length must be at least as large as the bytes required for identifier")
      }

      let identifier = try Identifier(data: data[currentIndex ➞ identifierByteCount])
      currentIndex += identifierByteCount

      guard currentIndex != data.endIndex else { self = .Remove(identifier: identifier); return }

      var i = Int(data[currentIndex]) + ++currentIndex

      guard i ⟷ data.endIndex > 0 else { throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for event") }

      let trajectory = Trajectory(data[currentIndex ..< i])
      guard trajectory != .null else { throw MIDIFileError(type: .ReadFailure, reason: "Null trajectory produced") }

      currentIndex = i
      i += Int(data[currentIndex++]) + 1

      guard i ⟷ data.endIndex == 0 else { throw MIDIFileError(type: .InvalidLength, reason: "Incorrect number of bytes") }

      let generator = NoteGenerator(data[currentIndex ..< i])
      self = .Add(identifier: identifier, trajectory: trajectory, generator: generator)
    }

    var bytes: [Byte] {
      switch self {
        case let .Add(identifier, trajectory, generator):
          var bytes = identifier.length.bytes + identifier.bytes
          let trajectoryBytes = trajectory.bytes
          bytes.append(Byte(trajectoryBytes.count))
          bytes += trajectoryBytes
          if let noteAttributes = generator as? NoteGenerator {
            let generatorBytes = noteAttributes.bytes
            bytes.append(Byte(generatorBytes.count))
            bytes += generatorBytes
          }
          return bytes

        case let .Remove(identifier): return identifier.bytes
      }
    }
    
    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
  }
}

extension MIDINodeEvent: Equatable {}

func ==(lhs: MIDINodeEvent, rhs: MIDINodeEvent) -> Bool { return lhs.bytes == rhs.bytes }

extension MIDINodeEvent.Data: CustomStringConvertible {
  var description: String {
    switch self {
      case let .Add(identifier, trajectory, generator):
        return "add node '\(identifier)' (\(trajectory), \(generator))"
      case let .Remove(identifier):
        return "remove node '\(identifier)'"
    }
  }
}

extension MIDINodeEvent.Data: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension MIDINodeEvent: CustomStringConvertible { var description: String { return "\(time) \(data)" } }

func ==(lhs: MIDINodeEvent.Data, rhs: MIDINodeEvent.Data) -> Bool { return lhs.bytes.elementsEqual(rhs.bytes) }
