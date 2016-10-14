//
//  MIDIEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

enum MIDIEvent {
  case meta    (MetaEvent)
  case channel (ChannelEvent)
  case node    (MIDINodeEvent)

  var event: Any {
    switch self {
    case .meta   (let event): return event
    case .channel(let event): return event
    case .node   (let event): return event
    }
  }

  var time: BarBeatTime {
    get {
      switch self {
      case .meta   (let event): return event.time
      case .channel(let event): return event.time
      case .node   (let event): return event.time
      }

    }
    set {
      switch self {
      case .meta   (var event): event.time = newValue; self = .meta(event)
      case .channel(var event): event.time = newValue; self = .channel(event)
      case .node   (var event): event.time = newValue; self = .node(event)
      }
    }
  }

  var delta: UInt64? {
    get {
      switch self {
      case .meta   (let event): return event.delta
      case .channel(let event): return event.delta
      case .node   (let event): return event.delta
      }
    }
    set {
      switch self {
      case .meta   (var event): event.delta = newValue; self = .meta(event)
      case .channel(var event): event.delta = newValue; self = .channel(event)
      case .node   (var event): event.delta = newValue; self = .node(event)
      }
    }
  }

  var bytes: [Byte] {
    switch self {
    case .meta   (let event): return event.bytes
    case .channel(let event): return event.bytes
    case .node   (let event): return event.bytes
    }
  }
}

extension MIDIEvent: Hashable {

  static func ==(lhs: MIDIEvent, rhs: MIDIEvent) -> Bool {
    switch (lhs, rhs) {
      case let (.meta(event1), .meta(event2)) where event1 == event2:
        return true
      case let (.channel(event1), .channel(event2)) where event1 == event2:
        return true
      case let (.node(event1), .node(event2)) where event1 == event2:
        return true
      default:
        return false
    }
  }

  var hashValue: Int {
    let bytesHash = bytes.segment(8).map({UInt64($0)}).reduce(UInt64(0), { $0 ^ $1 }).hashValue
    let deltaHash = delta?.hashValue ?? 0
    let timeHash = time.totalBeats.hashValue
    return bytesHash ^ deltaHash ^ timeHash
  }

}

extension MIDIEvent: CustomStringConvertible {

  var description: String {

    switch self {
      case .meta   (let event): return event.description
      case .channel(let event): return event.description
      case .node   (let event): return event.description
    }

  }

}

extension MIDIEvent {

  /// Struct to hold data for a meta event where
  /// event = \<delta time\> **FF** \<meta type\> \<length of meta\> \<meta\>
  struct MetaEvent {

    var time: BarBeatTime
    var data: Data
    var delta: UInt64?

    var bytes: [Byte] {
      let dataBytes = data.bytes
      let dataLength = MIDIFile.VariableLengthQuantity(dataBytes.count)
      return [0xFF, data.type] + dataLength.bytes + dataBytes
    }

    ///Initializer that takes the event's data and, optionally, the event's time
    init(data: Data, time: BarBeatTime = BarBeatTime.zero) { self.data = data; self.time = time }

    init(delta: UInt64, data: Foundation.Data.SubSequence) throws {

      self.delta = delta
      guard data.count >= 3 else { throw MIDIFile.Error.invalidLength("Not enough bytes in event") }
      guard data[data.startIndex] == 0xFF else {
        throw MIDIFile.Error.invalidHeader("First byte must be 0xFF")
      }
      var currentIndex = data.startIndex + 1

      let typeByte = data[currentIndex]
      currentIndex += 1

      var i = currentIndex
      while data[i] & 0x80 != 0 { i += 1 }

      let dataLength = Int(MIDIFile.VariableLengthQuantity(bytes: data[currentIndex ... i]))
      currentIndex = i + 1
      i += dataLength + 1

      guard data.endIndex == i else {
        throw MIDIFile.Error.invalidLength("Specified length does not match actual")
      }

      self.data = try Data(type: typeByte, data: data[currentIndex ..< i])
      time = BarBeatTime.zero
    }
    
    /// Initializer that takes a `VariableLengthQuantity` as well as the event's data.
    init(time: BarBeatTime, data: Data) { self.time = time; self.data = data }

  }
}

extension MIDIEvent.MetaEvent: Hashable {

  var hashValue: Int { return time.hashValue ^ data.hashValue ^ (delta?.hashValue ?? 0) }

  static func ==(lhs: MIDIEvent.MetaEvent, rhs: MIDIEvent.MetaEvent) -> Bool {
    return lhs.time == rhs.time && lhs.delta == rhs.delta && lhs.data == rhs.data
  }

}

extension MIDIEvent.MetaEvent: CustomStringConvertible {

  var description: String { return "\(time) \(data)" }

}

extension MIDIEvent.MetaEvent {

  /// Enumeration for encapsulating a type of meta event.
  enum Data {
    case text (text: String)
    case copyrightNotice (notice: String)
    case sequenceTrackName (name: String)
    case instrumentName (name: String)
    case marker (name: String)
    case deviceName (name: String)
    case programName (name: String)
    case endOfTrack
    case tempo (bpm: Double)
    case timeSignature (signature: TimeSignature, clocks: Byte, notes: Byte)

    var type: UInt8 {
      switch self {
        case .text:              return 0x01
        case .copyrightNotice:   return 0x02
        case .sequenceTrackName: return 0x03
        case .instrumentName:    return 0x04
        case .marker:            return 0x06
        case .programName:       return 0x08
        case .deviceName:        return 0x09
        case .endOfTrack:        return 0x2F
        case .tempo:             return 0x51
        case .timeSignature:     return 0x58
      }
    }

    var bytes: [Byte] {
      switch self {
        case let .text(text):               return text.bytes
        case let .copyrightNotice(text):    return text.bytes
        case let .sequenceTrackName(text):  return text.bytes
        case let .instrumentName(text):     return text.bytes
        case let .marker(text):             return text.bytes
        case let .programName(text):        return text.bytes
        case let .deviceName(text):         return text.bytes
        case .endOfTrack:                   return []
        case let .tempo(tempo):             return Array(Byte4(60_000_000 / tempo).bytes.dropFirst())
        case let .timeSignature(s, n, m):   return s.bytes + [n, m]
      }
    }

    init(type: UInt8, data: Foundation.Data.SubSequence) throws {
      switch type {
        case 0x01: self = .text(text: String(data))
        case 0x02: self = .copyrightNotice(notice: String(data))
        case 0x03: self = .sequenceTrackName(name: String(data))
        case 0x04: self = .instrumentName(name: String(data))
        case 0x06: self = .marker(name: String(data))
        case 0x08: self = .programName(name: String(data))
        case 0x09: self = .deviceName(name: String(data))
        case 0x2F:
          guard data.count == 0 else {
            throw MIDIFile.Error.invalidLength("EndOfTrack event has no data")
          }
          self = .endOfTrack
        case 0x51:
          guard data.count == 3 else {
            throw MIDIFile.Error.invalidLength("Tempo event data should have a 4 byte length")
          }
          self = .tempo(bpm: Double(60_000_000 / Byte4(data)))
        case 0x58:
          guard data.count == 4 else {
            throw MIDIFile.Error.invalidLength("TimeSignature event data should have a 4 byte length")
          }
          self = .timeSignature(signature: Groove.TimeSignature(data.prefix(2)),
                                clocks: data[data.startIndex + 2],
                                notes: data[data.startIndex + 3])
        default:
          throw MIDIFile.Error.unsupportedEvent("\(String(hexBytes: [type])) is not a supported meta event type")
      }
    }

  }

}

extension MIDIEvent.MetaEvent.Data: CustomStringConvertible {

  var description: String {
    switch self {
      case .text(let text):              return "text '\(text)'"
      case .copyrightNotice(let text):   return "copyright '\(text)'"
      case .sequenceTrackName(let text): return "sequence/track name '\(text)'"
      case .instrumentName(let text):    return "instrument name '\(text)'"
      case .marker(let text):            return "marker '\(text)'"
      case .programName(let text):       return "program name '\(text)'"
      case .deviceName(let text):        return "device name '\(text)'"
      case .endOfTrack:                  return "end of track"
      case .tempo(let bpm):              return "tempo \(bpm)"
      case .timeSignature(let s, _ , _): return "time signature \(s.beatsPerBar)╱\(s.beatUnit)"
    }
  }

}

extension MIDIEvent.MetaEvent.Data: Hashable {

  var hashValue: Int {

    switch self {
      case .text (let text),
           .copyrightNotice (let text),
           .sequenceTrackName (let text),
           .instrumentName (let text),
           .marker (let text),
           .deviceName (let text),
           .programName (let text):
        return type.hashValue ^ text.hashValue
      case .endOfTrack:
        return type.hashValue
      case .tempo (let bpm):
        return type.hashValue ^ bpm.hashValue
      case .timeSignature (let signature, let clocks, let notes):
        return type.hashValue ^ signature.hashValue ^ clocks.hashValue ^ notes.hashValue
    }

  }

  static func ==(lhs: MIDIEvent.MetaEvent.Data, rhs: MIDIEvent.MetaEvent.Data) -> Bool {
    switch (lhs, rhs) {
      case let (.text(text1), .text(text2)) where text1 == text2: return true
      case let (.copyrightNotice(notice1), .copyrightNotice(notice2)) where notice1 == notice2: return true
      case let (.sequenceTrackName(name1), .sequenceTrackName(name2)) where name1 == name2: return true
      case let (.instrumentName(name1), .instrumentName(name2)) where name1 == name2: return true
      case (.endOfTrack, .endOfTrack): return true
      case let (.tempo(microseconds1), .tempo(microseconds2)) where microseconds1 == microseconds2: return true
      case let (.timeSignature(signature1, clocks1, notes1), .timeSignature(signature2, clocks2, notes2))
        where signature1.beatsPerBar == signature2.beatsPerBar
           && signature1.beatUnit == signature2.beatUnit
           && clocks1 == clocks2
           && notes1 == notes2: return true
      default: return false
    }
  }

}

extension MIDIEvent {

  /// Struct to hold data for a channel event where
  /// event = \<delta time\> \<status\> \<data1\> \<data2\>
  struct ChannelEvent {

    var time: BarBeatTime
    var delta: UInt64?
    var status: Status
    var data1: Byte
    var data2: Byte?

    var bytes: [Byte] { return [status.value, data1] + (data2 != nil ? [data2!] : []) }

    init(delta: UInt64,
         data: Foundation.Data.SubSequence,
         time: BarBeatTime = BarBeatTime.zero) throws
    {

      self.delta = delta

      guard let kind = Kind(rawValue: data[data.startIndex] >> 4) else {
        throw MIDIFile.Error.unsupportedEvent("\(data[data.startIndex] >> 4) is not a supported channel event")
      }

      guard data.count == kind.byteCount else {
        throw MIDIFile.Error.invalidLength("\(kind) events expect a total byte count of \(kind.byteCount)")
      }

      status = Status(kind: kind, channel: data[data.startIndex] & 0xF)

      data1 = data[data.startIndex + 1]
      data2 =  kind.byteCount == 3 ? data[data.startIndex + 2] : nil

      self.time = time

    }

    init(type: Kind, channel: Byte, data1: Byte, data2: Byte? = nil, time: BarBeatTime = BarBeatTime.zero) {

      status = Status(kind: type, channel: channel)
      self.data1 = data1
      self.data2 = data2
      self.time = time

    }

  }

}

extension MIDIEvent.ChannelEvent: CustomStringConvertible {

  var description: String {
    var result = "\(time) \(status) "
    switch status.kind {
      case .noteOn, .noteOff:
        result += "\(NoteGenerator.Tone(midi: data1)) \(Velocity(midi: data2!))"
      default:
        result += "\(data1)"
    }
    return result
  }

}

extension MIDIEvent.ChannelEvent: Hashable {

  var hashValue: Int {
    return time.hashValue ^ (delta?.hashValue ?? 0) ^ status.hashValue ^ data1.hashValue ^ (data2?.hashValue ?? 0)
  }

  static func ==(lhs: MIDIEvent.ChannelEvent, rhs: MIDIEvent.ChannelEvent) -> Bool {
    return lhs.status == rhs.status
        && lhs.data1 == rhs.data1
        && lhs.time == rhs.time
        && lhs.data2 == rhs.data2
        && lhs.delta == rhs.delta
  }

}

extension MIDIEvent.ChannelEvent {

  enum Kind: UInt8 {
    case noteOff               = 0x8
    case noteOn                = 0x9
    case polyphonicKeyPressure = 0xA
    case controlChange         = 0xB
    case programChange         = 0xC
    case channelPressure       = 0xD
    case pitchBendChange       = 0xE

    var byteCount: Int {
      switch self {
        case .controlChange, .programChange, .channelPressure: return 2
        default:                                               return 3
      }
    }

  }

}

extension MIDIEvent.ChannelEvent.Kind: CustomStringConvertible {

  var description: String {
    switch self {
      case .noteOff:               return "note off"
      case .noteOn:                return "note on"
      case .polyphonicKeyPressure: return "polyphonic key pressure"
      case .controlChange:         return "control change"
      case .programChange:         return "program change"
      case .channelPressure:       return "channel pressure"
      case .pitchBendChange:       return "pitch bend change"
    }
  }

}

extension MIDIEvent.ChannelEvent {

  struct Status {

    var kind: Kind
    var channel: Byte

    var value: Byte { return (kind.rawValue << 4) | channel }

  }

}

extension MIDIEvent.ChannelEvent.Status: Hashable {

  var hashValue: Int { return kind.rawValue.hashValue ^ channel.hashValue }

  static func ==(lhs: MIDIEvent.ChannelEvent.Status, rhs: MIDIEvent.ChannelEvent.Status) -> Bool {
    return lhs.kind == rhs.kind && lhs.channel == rhs.channel
  }

}

extension MIDIEvent.ChannelEvent.Status: CustomStringConvertible {

  var description: String { return "\(kind) (\(channel))" }

}

extension MIDIEvent {

  /// A MIDI meta event that uses the 'Cue Point' message to embed `MIDINode` trajectory
  /// and removal events for a track.
  struct MIDINodeEvent {

    var time: BarBeatTime = BarBeatTime.zero
    let data: Data
    var delta: UInt64?

    var bytes: [Byte] {
      let dataBytes = data.bytes
      let length = MIDIFile.VariableLengthQuantity(dataBytes.count)
      return [0xFF, 0x07] + length.bytes + dataBytes
    }

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

    init(delta: UInt64, data: Foundation.Data.SubSequence) throws {

      self.delta = delta
      guard data[data.startIndex +--> 2].elementsEqual([0xFF, 0x07]) else {
        throw MIDIFile.Error.invalidHeader("Event must begin with `FF 07`")
      }

      var currentIndex = data.startIndex + 2

      var i = currentIndex
      while data[i] & 0x80 != 0 { i += 1 }

      let dataLength = Int(MIDIFile.VariableLengthQuantity(bytes: data[currentIndex ... i]))

      currentIndex = i + 1

      i += dataLength + 1

      guard data.endIndex == i else {
        throw MIDIFile.Error.invalidLength("Specified length does not match actual")
      }

      self.data = try Data(data: data[currentIndex ..< i])
    }
  }
}

extension MIDIEvent.MIDINodeEvent {

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
        throw MIDIFile.Error.invalidLength("Not enough bytes for node event identifier")
      }

      var currentIndex = data.startIndex

      let loopIDByteCount = Int(Byte4(data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.endIndex - currentIndex >= loopIDByteCount else {
        throw MIDIFile.Error.invalidLength("Not enough bytes for node event identifier")
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
        throw MIDIFile.Error.fileStructurallyUnsound("Missing separator in node event identifier")
      }

      currentIndex += 1

      guard data.endIndex - currentIndex >= 16 else {
        throw MIDIFile.Error.invalidLength("Not enough bytes for node event identifier")
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

extension MIDIEvent.MIDINodeEvent.Identifier: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return ["nodeIdentifier": nodeIdentifier.uuidString.jsonValue,
            "loopIdentifier": loopIdentifier?.uuidString.jsonValue]
  }

  init?(_ jsonValue: JSONValue?) {
    guard
      let dict = ObjectJSONValue(jsonValue),
      let nodeIdentifierString = String(dict["nodeIdentifier"]),
      let nodeIdentifier = UUID(uuidString: nodeIdentifierString)
      else
    {
      return nil
    }

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

extension MIDIEvent.MIDINodeEvent.Identifier: Hashable {

  var hashValue: Int { return nodeIdentifier.hashValue ^ (loopIdentifier?.hashValue ?? 0) }

  static func ==(lhs: MIDIEvent.MIDINodeEvent.Identifier, rhs: MIDIEvent.MIDINodeEvent.Identifier) -> Bool {
    return lhs.nodeIdentifier == rhs.nodeIdentifier && lhs.loopIdentifier == rhs.loopIdentifier
  }

}

extension MIDIEvent.MIDINodeEvent {

  enum Data {
    case add(identifier: Identifier, trajectory: Trajectory, generator: AnyMIDIGenerator)
    case remove(identifier: Identifier)

    init(data: Foundation.Data.SubSequence) throws {
      var currentIndex = data.startIndex

      let identifierByteCount = Int(Byte4(data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.count >= identifierByteCount else {
        throw MIDIFile.Error.invalidLength("Data length must be at least as large as the bytes required for identifier")
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
        throw MIDIFile.Error.invalidLength("Not enough bytes for event")
      }

      let trajectory = Trajectory(data[currentIndex ..< i])
      guard trajectory != .null else {
        throw MIDIFile.Error.fileStructurallyUnsound("Invalid trajectory data")
      }

      currentIndex = i + 1
      i += Int(data[i]) + 1

      guard data.endIndex - i == 0 else {
        throw MIDIFile.Error.invalidLength("Incorrect number of bytes")
      }

      self = .add(identifier: identifier,
                  trajectory: trajectory,
                  generator: .note(NoteGenerator(data[currentIndex ..< i])))
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
    
  }
  
}

extension MIDIEvent.MIDINodeEvent: Hashable {

  var hashValue: Int { return time.hashValue ^ (delta?.hashValue ?? 0) ^ data.hashValue }

  static func ==(lhs: MIDIEvent.MIDINodeEvent, rhs: MIDIEvent.MIDINodeEvent) -> Bool {
    return lhs.time == rhs.time && lhs.delta == rhs.delta && lhs.data == rhs.data
  }

}

extension MIDIEvent.MIDINodeEvent.Data: CustomStringConvertible {

  var description: String {
    switch self {
      case let .add(identifier, trajectory, generator):
        return "add node '\(identifier)' (\(trajectory), \(generator))"
      case let .remove(identifier):
        return "remove node '\(identifier)'"
    }
  }

}

extension MIDIEvent.MIDINodeEvent: CustomStringConvertible {

  var description: String { return "\(time) \(data)" }

}

extension MIDIEvent.MIDINodeEvent.Data: Hashable {

  var hashValue: Int {
    switch self {
      case let .add(identifier, trajectory, generator):
        return identifier.hashValue ^ trajectory.hashValue ^ generator.hashValue
      case let .remove(identifier):
        return identifier.hashValue
    }
  }

  static func ==(lhs: MIDIEvent.MIDINodeEvent.Data, rhs: MIDIEvent.MIDINodeEvent.Data) -> Bool {
    switch (lhs, rhs) {
      case let (.add(identifier1, trajectory1, generator1), .add(identifier2, trajectory2, generator2))
        where identifier1 == identifier2 && trajectory1 == trajectory2 && generator1 == generator2:
      return true
      case let (.remove(identifier1), .remove(identifier2)) where identifier1 == identifier2:
        return true
      default:
        return false
    }
  }

}


protocol MIDIEventDispatch: class, Loggable {

  func add(event: MIDIEvent)
  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == MIDIEvent

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>? 

  func filterEvents(_ isIncluded: (MIDIEvent) -> Bool) -> [MIDIEvent]

  func dispatchEvents(for time: BarBeatTime)
  func dispatch(event: MIDIEvent)

  func registrationTimes<S:Swift.Sequence>(forAdding events: S) -> [BarBeatTime]
    where S.Iterator.Element == MIDIEvent

  var eventContainer: MIDIEventContainer { get set }
  var metaEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { get }
  var channelEvents: AnyBidirectionalCollection<MIDIEvent.ChannelEvent> { get }
  var nodeEvents: AnyBidirectionalCollection<MIDIEvent.MIDINodeEvent> { get }
  var timeEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { get }
  var tempoEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent> { get }

  var eventQueue: DispatchQueue { get }

}

extension MIDIEventDispatch {

  func add(event: MIDIEvent) { add(events: [event]) }

  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == MIDIEvent {
    eventContainer.append(contentsOf: events)
    Sequencer.time.register(callback: weakMethod(self, type(of: self).dispatchEvents),
                            forTimes: registrationTimes(forAdding: events),
                            identifier: UUID())
  }

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>?  { return eventContainer[time] }

  func filterEvents(_ isIncluded: (MIDIEvent) -> Bool) -> [MIDIEvent] { return eventContainer.filter(isIncluded) }

  func dispatchEvents(for time: BarBeatTime) { events(for: time)?.forEach(dispatch) }

  var metaEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent>       { return eventContainer.metaEvents    }
  var channelEvents: AnyBidirectionalCollection<MIDIEvent.ChannelEvent> { return eventContainer.channelEvents }
  var nodeEvents: AnyBidirectionalCollection<MIDIEvent.MIDINodeEvent>   { return eventContainer.nodeEvents    }
  var timeEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent>       { return eventContainer.timeEvents    }
  var tempoEvents: AnyBidirectionalCollection<MIDIEvent.MetaEvent>      { return eventContainer.tempoEvents    }

}

