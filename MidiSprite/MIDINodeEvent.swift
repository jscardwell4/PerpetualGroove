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
struct MIDINodeEvent: MIDITrackEvent {
  var time: CABarBeatTime = .start
  let data: Data
  var delta: VariableLengthQuantity?
  var bytes: [Byte] { return [0xFF, 0x07] + data.length.bytes + data.bytes }

  typealias Identifier = MIDINode.Identifier

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "delta: " + (delta?.description ?? "nil"),
      "data: \(data)",
      "time: \(time)"
    )
    result += "\n}"
    return result
  }

  /**
  Initializer that takes the event's data

  - parameter d: MetaEventData
  */
  init(_ d: Data) { data = d }

  init<C:CollectionType where C.Generator.Element == Byte,
    C.Index.Distance == Int, C.SubSequence.Generator.Element == Byte,
    C.SubSequence:CollectionType, C.SubSequence.Index.Distance == Int,
    C.SubSequence.SubSequence == C.SubSequence>(delta: VariableLengthQuantity, bytes: C) throws
  {
    self.delta = delta
    guard bytes[bytes.startIndex ... bytes.startIndex.advancedBy(1)].elementsEqual([0xFF, 0x07]) else {
      throw MIDIFileError(type: .InvalidHeader, reason: "Event must begin with `FF 07`")
    }
    var currentIndex = bytes.startIndex.advancedBy(2)
    var i = currentIndex
    while bytes[i] & 0x80 != 0 { i.increment() }
    let dataLength = VariableLengthQuantity(bytes: bytes[currentIndex ... i])
    i.increment()
    currentIndex = i
    i.advanceBy(dataLength.intValue)
    guard bytes.endIndex == i else {
      throw MIDIFileError(type: .InvalidLength, reason: "Length specified by data does not match actual")
    }

    let dataBytes = bytes[currentIndex ..< i]
    data = try Data(data: dataBytes)
  }


  /**
  Initializer that takes a bar beat time as well as the event's data

  - parameter t: CABarBeatTime
  - parameter d: Data
  */
  init(barBeatTime t: CABarBeatTime, data d: Data) { time = t; data = d }

  enum Data: Equatable {
    case Add(identifier: Identifier, placement: MIDINode.Placement, attributes: NoteAttributes, texture: MIDINode.TextureType)
    case Remove(identifier: Identifier)

    init<C:CollectionType where C.Generator.Element == Byte,
      C.Index.Distance == Int, C.SubSequence.Generator.Element == Byte,
      C.SubSequence.Index.Distance == Int>(data: C) throws
    {
      let identifierByteCount = sizeof(Identifier.self)
      guard data.count >= identifierByteCount else {
        throw MIDIFileError(type: .InvalidLength,
                            reason: "Data length must be at least as large as the bytes required for identifier")
      }
      let identifier = Identifier(data[data.startIndex ..< data.startIndex.advancedBy(sizeof(Identifier.self))])
      var currentIndex = data.startIndex.advancedBy(sizeof(Identifier.self))
      guard currentIndex != data.endIndex else { self = .Remove(identifier: identifier); return }

      let placementSize = Int(data[currentIndex])
      currentIndex.increment()
      var i = currentIndex.advancedBy(placementSize)
      guard i.distanceTo(data.endIndex) > 0 else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for event")
      }
      let placement = MIDINode.Placement(data[currentIndex ..< i])

      currentIndex = i
      let attributesSize = Int(data[currentIndex])
      currentIndex.increment()
      i = currentIndex.advancedBy(attributesSize)
      guard i.distanceTo(data.endIndex) > 0 else {
        throw MIDIFileError(type: .InvalidLength, reason: "Not enough bytes for event")
      }
      let attributes = NoteAttributes(data[currentIndex ..< i])

      currentIndex = i
      guard currentIndex.distanceTo(data.endIndex) == 1 else {
        throw MIDIFileError(type: .InvalidLength, reason: "There should be exactly one byte left for texture index")
      }
      let textureIndex = Int(data[currentIndex])
      guard MIDINode.TextureType.allCases.indices ∋ textureIndex else {
        throw MIDIFileError(type: .FileStructurallyUnsound, reason: "\(textureIndex) is not a valid texture index")
      }
      let texture = MIDINode.TextureType.allCases[textureIndex]

      self = .Add(identifier: identifier, placement: placement, attributes: attributes, texture: texture)
    }

    var bytes: [Byte] {
      switch self {
        case let .Add(identifier, placement, attributes, texture):
          var bytes = identifier.bytes
          let placementBytes = placement.bytes
          bytes.append(Byte(placementBytes.count))
          bytes += placementBytes
          let attributesBytes = attributes.bytes
          bytes.append(Byte(attributesBytes.count))
          bytes += attributesBytes
          bytes.append(Byte(texture.index))
          return bytes

        case let .Remove(identifier): return identifier.bytes
      }
    }
    
    var length: VariableLengthQuantity { return VariableLengthQuantity(bytes.count) }
  }
}

func ==(lhs: MIDINodeEvent.Data, rhs: MIDINodeEvent.Data) -> Bool { return lhs.bytes.elementsEqual(rhs.bytes) }