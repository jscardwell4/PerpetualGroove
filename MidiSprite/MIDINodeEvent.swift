//
//  MIDINodeEvent.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

/** A MIDI meta event that uses the 'Cue Point' message to embed `MIDINode` placement and removal events for a track */
struct MIDINodeEvent: MIDIEvent {
  var time: CABarBeatTime = .start
  let data: Data
  var delta: VariableLengthQuantity?
  var bytes: [Byte] { return [0xFF, 0x07] + data.length.bytes + data.bytes }

  typealias Identifier = MIDINode.Identifier

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
    guard bytes.endIndex == i else { throw MIDIFileError(type: .InvalidLength, reason: "Specified length does not match actual") }

    data = try Data(data: bytes[currentIndex ..< i])
  }

  enum Data: Equatable {
    case Add(identifier: Identifier, placement: Placement, attributes: NoteAttributes)
    case Remove(identifier: Identifier)

    /**
    initWithData:

    - parameter data: C
    */
    init<C:CollectionType
      where C.Generator.Element == Byte,
            C.Index.Distance == Int,
            C.SubSequence.Generator.Element == Byte,
            C.SubSequence.Index.Distance == Int>(data: C) throws
    {
      let identifierByteCount = sizeof(Identifier.self)
      guard data.count >= identifierByteCount else {
        throw MIDIFileError(type: .InvalidLength,
                            reason: "Data length must be at least as large as the bytes required for identifier")
      }
      var currentIndex = data.startIndex + sizeof(Identifier.self)
      let identifier = Identifier(data[data.startIndex ..< currentIndex])

      guard currentIndex != data.endIndex else { self = .Remove(identifier: identifier); return }

      var i = Int(data[currentIndex]) + ++currentIndex

      guard i ⟷ data.endIndex > 0 else { throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for event") }
      let placement = Placement(data[currentIndex ..< i])

      currentIndex = i
      i += Int(data[currentIndex++]) + 1

      guard i ⟷ data.endIndex == 0 else { throw MIDIFileError(type: .InvalidLength, reason: "Incorrect number of bytes") }

      let attributes = NoteAttributes(data[currentIndex ..< i])
      self = .Add(identifier: identifier, placement: placement, attributes: attributes)
    }

    var bytes: [Byte] {
      switch self {
        case let .Add(identifier, placement, attributes):
          var bytes = identifier.bytes
          let placementBytes = placement.bytes
          bytes.append(Byte(placementBytes.count))
          bytes += placementBytes
          let attributesBytes = attributes.bytes
          bytes.append(Byte(attributesBytes.count))
          bytes += attributesBytes
          return bytes

        case let .Remove(identifier): return identifier.bytes
      }
    }
    
    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
  }
}

extension MIDINodeEvent.Data: CustomStringConvertible {
  var description: String {
    switch self {
      case let .Add(identifier, placement, attributes):
        return "add node '\(identifier)' ( \(placement), \(attributes) )"
      case let .Remove(identifier):
        return "remove node '\(identifier)'"
    }
  }
}

extension MIDINodeEvent.Data: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension MIDINodeEvent: CustomStringConvertible { var description: String { return data.description } }

func ==(lhs: MIDINodeEvent.Data, rhs: MIDINodeEvent.Data) -> Bool { return lhs.bytes.elementsEqual(rhs.bytes) }
