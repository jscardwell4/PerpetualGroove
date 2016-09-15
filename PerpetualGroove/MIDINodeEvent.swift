//
//  MIDINodeEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/** A MIDI meta event that uses the 'Cue Point' message to embed `MIDINode` trajectory and removal events for a track */
struct MIDINodeEvent: MIDIEventType {
  var time: BarBeatTime = .start1
  let data: Data
  var delta: VariableLengthQuantity?
  var bytes: [Byte] { return [0xFF, 0x07] + data.length.bytes + data.bytes }

  var identifier: Identifier {
    switch data {
    case let .add(id, _, _): return id
    case let .remove(id): return id
    }
  }

  typealias NodeIdentifier = MIDINode.Identifier
  var nodeIdentifier: NodeIdentifier { return identifier.nodeIdentifier }

  typealias LoopIdentifier = Loop.Identifier
  var loopIdentifier: LoopIdentifier?  { return identifier.loopIdentifier }

  /**
  Initializer that takes the event's data and, optionally, the event's bar beat time

  - parameter d: MetaEventData
  - parameter t: BarBeatTime? = nil
  */
  init(_ d: Data, _ t: BarBeatTime? = nil) { data = d; if let t = t { time = t } }

  init<C:Collection>(delta: VariableLengthQuantity, bytes: C) throws
    where C.Iterator.Element == Byte,
          C.IndexDistance == Int,
          C.SubSequence.Iterator.Element == Byte,
          C.SubSequence:Collection,
          C.SubSequence.IndexDistance == Int,
          C.SubSequence.SubSequence == C.SubSequence
  {
    self.delta = delta
    guard bytes[bytes.startIndex ... bytes.index(after: bytes.startIndex)].elementsEqual([0xFF, 0x07]) else {
      throw MIDIFileError(type: .InvalidHeader, reason: "Event must begin with `FF 07`")
    }
    var currentIndex = bytes.index(bytes.startIndex, offsetBy: 2)
    var i = currentIndex
    while bytes[i] & 0x80 != 0 { bytes.formIndex(after: &i) }
    let dataLength = VariableLengthQuantity(bytes: bytes[currentIndex ... i])
    bytes.formIndex(after: &i)
    currentIndex = i
    bytes.formIndex(&i, offsetBy: dataLength.intValue)
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
      let nodeIdentifierBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
      (nodeIdentifier as NSUUID).getBytes(nodeIdentifierBytes)
      let nodeIdentifierBytesBuffer = UnsafeBufferPointer(start: nodeIdentifierBytes, count: 16)
      if let loopIdentifier = loopIdentifier {
        let loopIdentifierBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        (loopIdentifier as NSUUID).getBytes(loopIdentifierBytes)
        let loopIdentifierBytesBuffer = UnsafeBufferPointer(start: loopIdentifierBytes, count: 16)

        return Byte4(16).bytes + loopIdentifierBytesBuffer + ":".bytes + nodeIdentifierBytesBuffer
      } else {
        return Byte4(0).bytes + ":".bytes + nodeIdentifierBytesBuffer
      }
    }

    var length: Byte4 { return Byte4(bytes.count) }

    init<C:Collection>(data: C) throws
      where C.Iterator.Element == Byte,
            C.IndexDistance == Int,
            C.SubSequence.Iterator.Element == Byte,
            C.SubSequence:Collection,
            C.SubSequence.IndexDistance == Int,
            C.SubSequence.SubSequence == C.SubSequence
    {
      var currentIndex = data.startIndex
      guard data.count >= 4 else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for node event identifier")
      }
      let loopIDByteCount = Int(Byte4(data[currentIndex..<data.index(currentIndex, offsetBy: 4)]))
      currentIndex = data.index(currentIndex, offsetBy: 4)

      guard data.distance(from: currentIndex, to: data.endIndex) >= loopIDByteCount else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for node event identifier")
      }

      if loopIDByteCount > 0 {
        let loopIdentifierBytes = Array(data[currentIndex..<data.index(currentIndex, offsetBy: loopIDByteCount)])
        loopIdentifier = NSUUID(uuidBytes: loopIdentifierBytes) as LoopIdentifier
      }
      else { loopIdentifier = nil }

      data.formIndex(&currentIndex, offsetBy: loopIDByteCount)

      guard String(data[currentIndex]) == ":" else {
        throw MIDIFileError(type: .FileStructurallyUnsound, reason: "Missing separator in node event identifier")
      }

      data.formIndex(&currentIndex, offsetBy: 1)

      let nodeIdentifierByteCount = MemoryLayout<NodeIdentifier>.size

      guard data.distance(from: currentIndex, to: data.endIndex) >= nodeIdentifierByteCount else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for node event identifier")
      }

      let nodeIdentifierBytes = Array(data[currentIndex..<data.index(currentIndex, offsetBy: nodeIdentifierByteCount)])
      nodeIdentifier = NSUUID(uuidBytes: nodeIdentifierBytes) as NodeIdentifier
    }

  }
}

extension MIDINodeEvent.Identifier: JSONValueConvertible {
  var jsonValue: JSONValue {
    return ["nodeIdentifier": nodeIdentifier as! JSONValueConvertible, "loopIdentifier": loopIdentifier]
  }
}

extension MIDINodeEvent.Identifier: JSONValueInitializable {
  /**
   init:

   - parameter jsonValue: JSONValue?
   */
  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
      let nodeIdentifierJSON = dict["nodeIdentifier"],
      let nodeIdentifierString = String(nodeIdentifierJSON),
      let nodeIdentifier = NodeIdentifier(uuidString: nodeIdentifierString) else { return nil }
    self.nodeIdentifier = nodeIdentifier
    if let loopIdentifierJSON = dict["loopIdentifier"],
      let loopIdentifierString = String(loopIdentifierJSON),
      let loopIdentifier = LoopIdentifier(uuidString: loopIdentifierString)
    {
      self.loopIdentifier = loopIdentifier
    }
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
    case add(identifier: Identifier, trajectory: Trajectory, generator: MIDIGenerator)
    case remove(identifier: Identifier)

    /**
    initWithData:

    - parameter data: C
    */
    init<C:Collection>(data: C) throws
      where C.Iterator.Element == Byte,
            C.IndexDistance == Int,
            C.SubSequence.Iterator.Element == Byte,
            C.SubSequence:Collection,
            C.SubSequence.IndexDistance == Int,
            C.SubSequence.SubSequence == C.SubSequence
    {
      var currentIndex = data.startIndex
      let identifierByteCount = Int(Byte4(data[currentIndex..<data.index(currentIndex, offsetBy: 4)]))
      data.formIndex(&currentIndex, offsetBy: 4)
      guard data.count >= identifierByteCount else {
        throw MIDIFileError(type: .InvalidLength,
                            reason: "Data length must be at least as large as the bytes required for identifier")
      }

      let identifier = try Identifier(data: data[currentIndex..<data.index(currentIndex, offsetBy: identifierByteCount)])
      data.formIndex(&currentIndex, offsetBy: identifierByteCount)

      guard currentIndex != data.endIndex else { self = .remove(identifier: identifier); return }

      var i = data.index(currentIndex, offsetBy: Int(data[currentIndex]) + 1)

      data.formIndex(&currentIndex, offsetBy: 1)

      guard data.distance(from: i, to: data.endIndex) > 0 else { throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for event") }

      let trajectory = Trajectory(data[currentIndex ..< i])
      guard trajectory != .null else { throw MIDIFileError(type: .ReadFailure, reason: "Null trajectory produced") }

      currentIndex = i
      data.formIndex(&i, offsetBy: Int(data[currentIndex]) + 1)
      data.formIndex(&currentIndex, offsetBy: 1)

      guard data.distance(from: i, to: data.endIndex) == 0 else { throw MIDIFileError(type: .InvalidLength, reason: "Incorrect number of bytes") }

      let generator = MIDIGenerator(NoteGenerator(data[currentIndex ..< i]))
      self = .add(identifier: identifier, trajectory: trajectory, generator: generator)
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
    
    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
  }
}

extension MIDINodeEvent: Equatable {}

func ==(lhs: MIDINodeEvent, rhs: MIDINodeEvent) -> Bool { return lhs.bytes == rhs.bytes }

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

extension MIDINodeEvent.Data: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

extension MIDINodeEvent: CustomStringConvertible { var description: String { return "\(time) \(data)" } }

func ==(lhs: MIDINodeEvent.Data, rhs: MIDINodeEvent.Data) -> Bool { return lhs.bytes.elementsEqual(rhs.bytes) }
