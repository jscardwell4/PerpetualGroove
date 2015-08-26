//
//  Track.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import AudioToolbox
import CoreMIDI

extension MIDIObjectType: CustomStringConvertible {
  public var description: String {
    switch self {
      case .Other:               return "Other"
      case .Device:              return "Device"
      case .Entity:              return "Entity"
      case .Source:              return "Source"
      case .Destination:         return "Destination"
      case .ExternalDevice:      return "ExternalDevice"
      case .ExternalEntity:      return "ExternalEntity"
      case .ExternalSource:      return "ExternalSource"
      case .ExternalDestination: return "ExternalDestination"
    }
  }
}

final class Track: Equatable, CustomStringConvertible {

  var description: String {
    return "Track(\(label)) {\n\tbus: \(bus)\n\tcolor: \(color)\n\tevents: {\n\t\t" +
           "\n\t\t".join(events.map({$0.description})) + "\n\t}\n}"
  }

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  // MARK: - Constant properties

  var instrument: Instrument { return bus.instrument }

  let bus: Bus
  let color: Color

  private var nodes: Set<MIDINode> = []
  private var notes: Set<UInt> = []
  private var lastEvent: [UInt:MIDITimeStamp] = [:]
  private var client = MIDIClientRef()
  private var inPort = MIDIPortRef()
  private var outPort = MIDIPortRef()
//  private var musicTrack: MusicTrack
  private let fileQueue: dispatch_queue_t

  // MARK: - Editable properties

  private var _label: String?
  var label: String {
    get {
      guard _label == nil else { return _label! }
      _label = "BUS \(bus.element)"
      return _label!
    } set {
      _label = newValue
    }
  }

  var volume: Float { get { return bus.volume } set { bus.volume = newValue } }
  var pan: Float { get { return bus.pan } set { bus.pan = newValue } }

  enum Error: String, ErrorType, CustomStringConvertible {
    case NodeNotFound = "The specified node was not found among the track's nodes"
  }

  /**
  addNode:

  - parameter node: MIDINode
  */
  func addNode(node: MIDINode) throws {
    nodes.insert(node)
    let identifier = ObjectIdentifier(node).uintValue
    notes.insert(identifier)
    lastEvent[identifier] = 0
    let timestamp = Sequencer.currentTime
    let placement = node.placement
    dispatch_async(fileQueue) {
      [unowned self] in self.events.append(SystemExclusiveEvent.nodePlacementEvent(timestamp, placement: placement))
    }
//    try newUserEvent(Sequencer.barBeatTime.timestamp, bytes)
    logDebug("track (\(label)) added node with source id \(identifier)")
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
  }

  /**
  removeNode:

  - parameter node: MIDINode
  */
  func removeNode(node: MIDINode) throws {
    guard let node = nodes.remove(node) else { throw Error.NodeNotFound }
    let identifier = ObjectIdentifier(node).uintValue
    notes.remove(identifier)
    lastEvent[identifier] = nil
    node.sendNoteOff()
    logDebug("track (\(label)) removed node with source id \(identifier)")
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
  }

  /**
  notify:

  - parameter notification: UnsafePointer<MIDINotification>
  */
  private func notify(notification: UnsafePointer<MIDINotification>) {
    var memory = notification.memory
    switch memory.messageID {
      case .MsgSetupChanged:
        backgroundDispatch{print("received notification that the midi setup has changed")}
      case .MsgObjectAdded:
        // MIDIObjectAddRemoveNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIObjectAddRemoveNotification>.self).memory
          backgroundDispatch {print("received notifcation that an object has been added…\n\t" + "\n\t".join(
            "parent = \(message.parent)",
            "parentType = \(message.parentType)",
            "child = \(message.child)",
            "childType = \(message.childType)"
            ))}
        }
      case .MsgObjectRemoved:
        // MIDIObjectAddRemoveNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIObjectAddRemoveNotification>.self).memory
          backgroundDispatch{print("received notifcation that an object has been removed…\n\t" + "\n\t".join(
            "parent = \(message.parent)",
            "parentType = \(message.parentType)",
            "child = \(message.childType)",
            "childType = \(message.childType)"
            ))}
        }
        break
      case .MsgPropertyChanged:
        // MIDIObjectPropertyChangeNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIObjectPropertyChangeNotification>.self).memory
          backgroundDispatch{print("object: \(message.object); objectType: \(message.objectType); propertyName: \(message.propertyName)")}
        }
      case .MsgThruConnectionsChanged:
        backgroundDispatch{print("received notification that midi thru connections have changed")}
      case .MsgSerialPortOwnerChanged:
        backgroundDispatch{print("received notification that serial port owner has changed")}
      case .MsgIOError:
        // MIDIIOErrorNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIIOErrorNotification>.self).memory
          logError(error(message.errorCode, "received notifcation of io error"))
        }
    }
  }

  /**
  Reconstructs the `uintValue` of an `ObjectIdentifier` using packet data bytes 4 through 11

  - parameter packet: MIDIPacket

  - returns: UInt
  */
  private func nodeIdentifierFromPacket(packet: MIDIPacket) -> UInt {
    guard packet.length == 11 else { return 0 }

    return zip([packet.data.3, packet.data.4, packet.data.5, packet.data.6,
                packet.data.7, packet.data.8, packet.data.9, packet.data.10],
               [0, 8, 16, 24, 32, 40, 48, 56]).reduce(UInt(0)) { $0 | (UInt($1.0) << UInt($1.1)) }

  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafeMutablePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {

    let packets = packetList.memory
    let packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
    packetPointer.initialize(packets.packet)
    guard packets.numPackets == 1 else { fatalError("Packets must be sent to track one at a time") }

    let packet = packetPointer.memory

    if case let n = packet.length where (0b1001_0000 ... 0b1001_1111).contains(packet.data.0) && n == 11 {
      let nodeIdentifier = nodeIdentifierFromPacket(packet)
      let stamp = packet.timeStamp
      guard lastEvent[nodeIdentifier] != stamp else { return }
      let channel = packet.data.0 & 0xFF
      let note = packet.data.1
      let velocity = packet.data.2
      dispatch_async(fileQueue) {
        [unowned self] in
          self.events.append(ChannelEvent.noteOnEvent(stamp, channel: channel, note: note, velocity: velocity))
      }
      lastEvent[nodeIdentifier] = stamp
//      do { try newNoteEvent(stamp, message); lastEvent[nodeIdentifier] = stamp } catch { logError(error) }

    }

/*
      backgroundDispatch{print("packet received (\(nodeIdentifier)) {" + "; ".join(
        "timeStamp: \(packet.timeStamp)",
        "length: \(packet.length)",
        " ".join(String(packet.data.0, radix: 16, uppercase: true),
                 String(packet.data.1, radix: 16, uppercase: true),
                 String(packet.data.2, radix: 16, uppercase: true))) + "}")}

*/
    do { try MIDISend(outPort, bus.instrument.endPoint, packetList) ➤ "Failed to forward packet list to instrument" }
    catch { logError(error) }
  }

  /**
  initWithBus:track:

  - parameter b: Bus
  - parameter track: MusicTrack
  */
  init(bus b: Bus, track: MusicTrack) throws {
    bus = b
    color = Color.allCases[Int(bus.element) % 10]
//    musicTrack = track
    fileQueue = dispatch_queue_create(("BUS \(bus.element)" as NSString).UTF8String, DISPATCH_QUEUE_SERIAL)
    try MIDIClientCreateWithBlock("track \(bus.element)", &client, notify) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, label ?? "BUS \(bus.element)", &inPort, read) ➤ "Failed to create in port"
  }

  // MARK: - Enumeration for specifying the color attached to a `TrackType`
  enum Color: UInt32, EnumerableType, CustomStringConvertible {
    case White      = 0xffffff
    case Portica    = 0xf7ea64
    case MonteCarlo = 0x7ac2a5
    case FlamePea   = 0xda5d3a
    case Crimson    = 0xd6223e
    case HanPurple  = 0x361aee
    case MangoTango = 0xf88242
    case Viking     = 0x6bcbe1
    case Yellow     = 0xfde97e
    case Conifer    = 0x9edc58
    case Apache     = 0xce9f58

    var value: UIColor { return UIColor(RGBHex: rawValue) }
    var description: String {
      switch self {
        case .White:      return "case White"
        case .Portica:    return "case Portica"
        case .MonteCarlo: return "case MonteCarlo"
        case .FlamePea:   return "case FlamePea"
        case .Crimson:    return "case Crimson"
        case .HanPurple:  return "case HanPurple"
        case .MangoTango: return "case MangoTango"
        case .Viking:     return "case Viking"
        case .Yellow:     return "case Yellow"
        case .Conifer:    return "case Conifer"
        case .Apache:     return "case Apache"
      }
    }

    /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
    static let allCases: [Color] = [.Portica, .MonteCarlo, .FlamePea, .Crimson, .HanPurple,
                                    .MangoTango, .Viking, .Yellow, .Conifer, .Apache]
  }


  // MARK: - Wrapping MusicTrack

  /**
  moveEvents:by:

  - parameter interval: HalfOpenInterval<MusicTimeStamp>
  - parameter amount: MusicTimeStamp
  */
//  func moveEvents(interval: HalfOpenInterval<MusicTimeStamp>, by amount: MusicTimeStamp) throws {
//    try MusicTrackMoveEvents(musicTrack, interval.start, interval.end, amount) ➤ "Failed to move events \(interval) in music track"
//    _events = nil
//  }

  /**
  clearEvents:

  - parameter interval: HalfOpenInterval<MusicTimeStamp>
  */
//  func clearEvents(interval: HalfOpenInterval<MusicTimeStamp>) throws {
//    try MusicTrackClear(musicTrack, interval.start, interval.end) ➤ "Failed to clear events \(interval) in music track"
//    _events = nil
//  }

  /**
  cutEvents:

  - parameter interval: HalfOpenInterval<MusicTimeStamp>
  */
//  func cutEvents(interval: HalfOpenInterval<MusicTimeStamp>) throws {
//    try MusicTrackCut(musicTrack, interval.start, interval.end) ➤ "Failed to cut events \(interval) in music track"
//    _events = nil
//  }

  /**
  copyEvents:intoTrack:at:

  - parameter interval: HalfOpenInterval<MusicTimeStamp>
  - parameter track: Track
  - parameter insertTime: MusicTimeStamp
  */
//  func copyEvents(interval: HalfOpenInterval<MusicTimeStamp>, intoTrack track: Track, at insertTime: MusicTimeStamp) throws {
//    try MusicTrackCopyInsert(musicTrack, interval.start, interval.end, track.musicTrack, insertTime)
//      ➤ "Failed to copy events \(interval) into track \(track.label) at \(insertTime)"
//    _events = nil
//  }

  /**
  mergeEvents:intoTrack:at:

  - parameter interval: HalfOpenInterval<MusicTimeStamp>
  - parameter track: Track
  - parameter insertTime: MusicTimeStamp
  */
//  func mergeEvents(interval: HalfOpenInterval<MusicTimeStamp>, intoTrack track: Track, at insertTime: MusicTimeStamp) throws {
//    try MusicTrackMerge(musicTrack, interval.start, interval.end, track.musicTrack, insertTime)
//      ➤ "Failed to merge events \(interval) into track \(track.label) at \(insertTime)"
//    _events = nil
//  }


  /**
  newNoteEvent:var:

  - parameter stamp: MIDITimeStamp
  - parameter message: MIDINoteMessage
  */
//  func newNoteEvent(stamp: MIDITimeStamp, _ message: MIDINoteMessage) throws {
//    dispatch_async(fileQueue) { [unowned self] in self.events.append(ChannelEvent.noteOnEvent(stamp, message: message)) }
//    try MusicTrackNewMIDINoteEvent(musicTrack, stamp, &message) ➤ "Failed to add note event"
//    _events = nil
//  }

  /**
  newChannelEvent:status:data1:data2:

  - parameter stamp: MusicTimeStamp
  - parameter status: UInt8
  - parameter data1: UInt8
  - parameter data2: UInt8
  */
//  func newChannelEvent(stamp: MusicTimeStamp, status: UInt8, _ data1: UInt8, _ data2: UInt8) throws {
//    var message = MIDIChannelMessage(status: status, data1: data1, data2: data2, reserved: 0)
//    try MusicTrackNewMIDIChannelEvent(musicTrack, stamp, &message) ➤ "Failed to add channel event to music track"
//    _events = nil
//  }

  /**
  newRawDataEvent:length:data:

  - parameter stamp: MusicTimeStamp
  - parameter data: [Byte]
  */
//  func newRawDataEvent(stamp: MusicTimeStamp, var _ data: [Byte]) throws {
//    let eventSize = sizeof(MIDIRawData) - 1
//    let size =  eventSize + data.count
//    var dataMemory = UnsafeMutablePointer<Byte>.alloc(size)
//    dataMemory = dataMemory.advancedBy(eventSize)
//    dataMemory.assignFrom(&data, count: data.count)
//    dataMemory = dataMemory.advancedBy(-eventSize)
//    let eventPointer = UnsafeMutablePointer<MIDIRawData>(dataMemory)
//    eventPointer.memory.length = UInt32(data.count)
//    try MusicTrackNewMIDIRawDataEvent(musicTrack, stamp, eventPointer) ➤ "Failed to add raw data event to music track"
//    _events = nil
//  }

  /**
  newExtendedNoteEvent:instrumentID:groupID:duration:pitch:velocity:controlValues:

  - parameter stamp: MusicTimeStamp
  - parameter instrumentID: MusicDeviceInstrumentID
  - parameter groupID: MusicDeviceGroupID
  - parameter duration: Float
  - parameter pitch: Float
  - parameter velocity: Float
  - parameter controlValues: [NoteParamsControlValue]
  */
//  func newExtendedNoteEvent(stamp: MusicTimeStamp,
//                         _ instrumentID: MusicDeviceInstrumentID,
//                         _ groupID: MusicDeviceGroupID,
//                         _ duration: Float,
//                         _ pitch: Float,
//                         _ velocity: Float,
//                         _ controlValues: [NoteParamsControlValue]) throws
//  {
//    let cv = controlValues.withUnsafeBufferPointer {
//      (ptr: UnsafeBufferPointer<NoteParamsControlValue>) -> (NoteParamsControlValue) in
//      return ptr.baseAddress.memory
//    }
//    let noteParams = MusicDeviceNoteParams(
//      argCount: UInt32(2 + controlValues.count),
//      mPitch: pitch,
//      mVelocity: velocity,
//      mControls: cv
//    )
//    var noteOnEvent = ExtendedNoteOnEvent(
//      instrumentID: instrumentID,
//      groupID: groupID,
//      duration: duration,
//      extendedParams: noteParams
//    )
//    try MusicTrackNewExtendedNoteEvent(musicTrack, stamp, &noteOnEvent) ➤ "Failed to add extened note event to music track"
//    _events = nil
//  }

  /**
  newParameterEvent:parameterID:scope:element:value:

  - parameter stamp: MusicTimeStamp
  - parameter parameterID: AudioUnitParameterID
  - parameter scope: AudioUnitScope
  - parameter element: AudioUnitElement
  - parameter value: AudioUnitParameterValue
  */
//  func newParameterEvent(stamp: MusicTimeStamp,
//                       _ parameterID: AudioUnitParameterID,
//                       _ scope: AudioUnitScope,
//                       _ element: AudioUnitElement,
//                       _ value: AudioUnitParameterValue) throws
//  {
//    var event = ParameterEvent(parameterID: parameterID, scope: scope, element: element, value: value)
//    try MusicTrackNewParameterEvent(musicTrack, stamp, &event) ➤ "Failed to add new parameter event to music track"
//    _events = nil
//  }

  /**
  newTempoEvent:beatsPerMinute:

  - parameter stamp: MusicTimeStamp
  - parameter beatsPerMinute: Double
  */
//  func newTempoEvent(stamp: MusicTimeStamp, _ beatsPerMinute: Double) throws {
//    try MusicTrackNewExtendedTempoEvent(musicTrack, stamp, beatsPerMinute) ➤ "Failed to add tempo event to music track"
//    _events = nil
//  }

  /**
  newMetaEvent:type:length:data:

  - parameter stamp: MusicTimeStamp
  - parameter type: UInt8
  - parameter data: [Byte]
  */
//  func newMetaEvent(stamp: MusicTimeStamp, _ type: UInt8, var _ data: [Byte]) throws {
//    let eventSize = sizeof(MIDIMetaEvent) - 1
//    let size =  eventSize + data.count
//    var dataMemory = UnsafeMutablePointer<Byte>.alloc(size)
//    dataMemory = dataMemory.advancedBy(eventSize)
//    dataMemory.assignFrom(&data, count: data.count)
//    dataMemory = dataMemory.advancedBy(-eventSize)
//    let eventPointer = UnsafeMutablePointer<MIDIMetaEvent>(dataMemory)
//    eventPointer.memory.dataLength = UInt32(data.count)
//    eventPointer.memory.metaEventType = type
//    try MusicTrackNewMetaEvent(musicTrack, stamp, eventPointer) ➤ "Failed to add new meta event to music track"
//    _events = nil
//  }

  /**
  newUserEvent:length:data:

  - parameter stamp: MusicTimeStamp
  - parameter data: [Byte]
  */
//  func newUserEvent(stamp: MusicTimeStamp, var _ data: [Byte]) throws {
//    let eventSize = sizeof(MusicEventUserData) - 1
//    let size =  eventSize + data.count
//    var dataMemory = UnsafeMutablePointer<Byte>.alloc(size)
//    dataMemory = dataMemory.advancedBy(eventSize)
//    dataMemory.assignFrom(&data, count: data.count)
//    dataMemory = dataMemory.advancedBy(-eventSize)
//    let eventPointer = UnsafeMutablePointer<MusicEventUserData>(dataMemory)
//    eventPointer.memory.length = UInt32(data.count)
//    try MusicTrackNewUserEvent(musicTrack, stamp, eventPointer) ➤ "Failed to add new user event to music track"
//    _events = nil
//  }

  /**
  newAUPresetEvent:scope:element:preset:

  - parameter stamp: MusicTimeStamp
  - parameter scope: AudioUnitScope
  - parameter element: AudioUnitElement
  - parameter preset: Unmanaged<CFPropertyListRef>
  */
//  func newAUPresetEvent(stamp: MusicTimeStamp,
//                      _ scope: AudioUnitScope,
//                      _ element: AudioUnitElement,
//                      _ preset: Unmanaged<CFPropertyListRef>) throws
//  {
//    var event = AUPresetEvent(scope: scope, element: element, preset: preset)
//    try MusicTrackNewAUPresetEvent(musicTrack, stamp, &event) ➤ "Failed to add new au preset event to music track"
//    _events = nil
//  }

  private(set) var events: [TrackEvent] = []
//  private var _events: TrackEvents?
//  var events: TrackEvents {
//    guard _events == nil else { return _events! }
//    do { _events = try TrackEvents(self) }
//    catch { logError(error); _events = TrackEvents() }
//    return _events!
//  }

  func dumpTrackEvents() {
    let events = self.events
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { print(events) }
  }

  // MARK: - An enumeration to simplify getting and setting MusicTrack properties
//  enum TrackProperty: UInt32, CustomStringConvertible {
//    case LoopInfo, OffsetTime, MuteStatus, SoloStatus, AutomatedParameters, TrackLength, TimeResolution
//    var description: String {
//      switch self {
//        case .LoopInfo:            return "Loop Info"
//        case .OffsetTime:          return "Offset Time"
//        case .MuteStatus:          return "Mute Status"
//        case .SoloStatus:          return "Solo Status"
//        case .AutomatedParameters: return "Automated Parameters"
//        case .TrackLength:         return "Track Length"
//        case .TimeResolution:      return "Time Resolution"
//      }
//    }
//
//    enum DataType {
//      case LoopInfo (MusicTrackLoopInfo)
//      case TimeStamp (MusicTimeStamp)
//      case Boolean (DarwinBoolean)
//      case UnsignedInteger (UInt32)
//      case Integer (Int16)
//
//      var size: UInt32 {
//        switch self {
//          case .LoopInfo: return UInt32(sizeof(MusicTrackLoopInfo.self))
//          case .TimeStamp: return UInt32(sizeof(MusicTimeStamp.self))
//          case .Boolean: return UInt32(sizeof(DarwinBoolean.self))
//          case .UnsignedInteger: return UInt32(sizeof(UInt32.self))
//          case .Integer: return UInt32(sizeof(Int16.self))
//        }
//      }
//
//      var pointer: UnsafeMutablePointer<Void> {
//        switch self {
//          case .LoopInfo(var data):        return withUnsafeMutablePointer(&data) { UnsafeMutablePointer<Void>($0) }
//          case .TimeStamp(var data):       return withUnsafeMutablePointer(&data) { UnsafeMutablePointer<Void>($0) }
//          case .Boolean(var data):         return withUnsafeMutablePointer(&data) { UnsafeMutablePointer<Void>($0) }
//          case .UnsignedInteger(var data): return withUnsafeMutablePointer(&data) { UnsafeMutablePointer<Void>($0) }
//          case .Integer(var data):         return withUnsafeMutablePointer(&data) { UnsafeMutablePointer<Void>($0) }
//        }
//      }
//    }
//
//    var dataType: DataType {
//      switch self {
//        case .LoopInfo:                 return .LoopInfo(MusicTrackLoopInfo())
//        case .OffsetTime, .TrackLength: return .TimeStamp(MusicTimeStamp())
//        case .MuteStatus, .SoloStatus:  return .Boolean(DarwinBoolean(false))
//        case .AutomatedParameters:      return .UnsignedInteger(UInt32())
//        case .TimeResolution:           return .Integer(Int16())
//      }
//    }
//
//    /**
//    valueForTrack:
//
//    - parameter track: MusicTrack
//    - returns: DataType
//    */
//    func valueForTrack(track: MusicTrack) throws -> DataType {
//      var data = dataType
//      let result = data.pointer
//      var size = data.size
//      try MusicTrackGetProperty(track, rawValue, result, &size) ➤ "Failed to retrieve '\(description)' from track"
//      return data
//    }
//
//    /**
//    setValue:forTrack:
//
//    - parameter value: DataType
//    - parameter track: MusicTrack
//    */
//    func setValue(value: DataType, forTrack track: MusicTrack) throws {
//      try MusicTrackSetProperty(track, rawValue, value.pointer, value.size) ➤ "Failed to set '\(description)' for track"
//    }
//  }
}


func ==(lhs: Track, rhs: Track) -> Bool { return lhs.bus == rhs.bus }

//struct TrackEvents: CollectionType, CustomStringConvertible {
//  private let iterator: MusicEventIterator
//  typealias Index = Int
//  var startIndex: Int { return events.startIndex }
//  var endIndex: Int { return events.endIndex }
//  var count: Int { return events.count }
//  let events: [TrackEvent]
//
//  init() { events = []; iterator = MusicEventIterator() }
//  init(_ track: Track) throws {
//    var iterator = MusicEventIterator()
//    try NewMusicEventIterator(track.musicTrack, &iterator) ➤ "Failed to create iterator for track '\(track.label)'"
//    self.iterator = iterator
//    var events: [TrackEvent] = []
//    var hasEvent = DarwinBoolean(false)
//    try MusicEventIteratorHasCurrentEvent(iterator, &hasEvent) ➤ "Failed to check whether iterator has current event"
//
//    guard hasEvent else { self.events = events; return }
//    try MusicEventIteratorHasNextEvent(iterator, &hasEvent) ➤ "Failed to check whether iterator has next event"
//
//    while hasEvent {
//      try MusicEventIteratorNextEvent(iterator) ➤ "Failed to move iterator to next event"
//      var time = MusicTimeStamp()
//      try MusicEventIteratorGetEventInfo(iterator, &time, nil, nil, nil) ➤ "Failed to get event info"
//      let event = try TrackEvent(iterator: iterator, timestamp: time)
//      events.append(event)
//      try MusicEventIteratorHasNextEvent(iterator, &hasEvent) ➤ "Failed to check whether iterator has next event"
//    }
//    self.events = events
//  }
//
//  subscript(i: Int) -> TrackEvent {
//    guard indices.contains(i) else { fatalError("Index out of bounds") }
//    return events[i]
//  }
//
//  func generate() -> AnyGenerator<TrackEvent> {
//    var i = 0, events = self
//    return anyGenerator { () -> TrackEvent? in return events.count > i ? events[i++] : nil }
//  }
//
//  var description: String {
//    return "{\n\tNumber of events: \(count)\n\t" + "\n\t".join(events.map {$0.description}) + "\n}"
//  }
//
//  enum TrackEvent: CustomStringConvertible {
//    case None
//    case ExtendedNote (MusicTimeStamp, ExtendedNoteOnEvent)
//    case ExtendedTempo (MusicTimeStamp, ExtendedTempoEvent)
//    case User (MusicTimeStamp, MusicEventUserData)
//    case Meta (MusicTimeStamp, MIDIMetaEvent)
//    case Note (MusicTimeStamp, MIDINoteMessage)
//    case Channel (MusicTimeStamp, MIDIChannelMessage)
//    case RawData (MusicTimeStamp, MIDIRawData)
//    case Parameter (MusicTimeStamp, ParameterEvent)
//    case AUPreset (MusicTimeStamp, AUPresetEvent)
//
//    var description: String {
//      switch self {
//        case .None:
//          return "Non-event"
//        case let .ExtendedNote(stamp, event):
//          return "[\(stamp)] " + "; ".join(
//            "instrumentID: \(event.instrumentID)",
//            "groupID: \(event.groupID)",
//            "duration: \(event.duration)",
//            "pitch: \(event.extendedParams.mPitch)",
//            "velocity: \(event.extendedParams.mVelocity)",
//            "controls: \(event.extendedParams.mControls)"
//          )
//        case let .ExtendedTempo(stamp, event):
//          return "[\(stamp)] " + "bpm: \(event.bpm)"
//        case let .User(stamp, event):
//          return "[\(stamp)] " + "; ".join("length: \(event.length)", "data: \(event.data)")
//        case let .Meta(stamp, event):
//          return "[\(stamp)] " + "; ".join(
//            "type: \(event.metaEventType)",
//            "dataLength: \(event.dataLength)",
//            "data: \(event.data)"
//          )
//        case let .Note(stamp, event):
//          return "[\(stamp)] " + "; ".join(
//            "channel: \(event.channel)",
//            "note: \(event.note)",
//            "velocity: \(event.velocity)",
//            "duration: \(event.duration)"
//          )
//        case let .Channel(stamp, event):
//          return "[\(stamp)] " + "; ".join(
//            "status: \(String(event.status, radix: 16, uppercase: true))",
//            "data1: \(String(event.data1, radix: 16, uppercase: true))",
//            "data2: \(String(event.data2, radix: 16, uppercase: true))"
//          )
//        case let .RawData(stamp, event):
//          return "[\(stamp)] " + "; ".join("length: \(event.length)", "data: \(event.data)")
//        case let .Parameter(stamp, event):
//          return "[\(stamp)] " + "; ".join(
//            "parameterID: \(event.parameterID)",
//            "scope: \(event.scope)",
//            "element: \(event.element)",
//            "value: \(event.value)"
//          )
//        case let .AUPreset(stamp, event):
//          return "[\(stamp)] " + "; ".join("scope: \(event.scope)", "element: \(event.element)", "preset: \(event.preset)")
//      }
//    }
//
//    /**
//    initWithIterator:timestamp:
//
//    - parameter iterator: MusicEventIterator
//    - parameter timestamp: MusicTimeStamp
//    */
//    init(iterator: MusicEventIterator, timestamp: MusicTimeStamp) throws {
//      try MusicEventIteratorSeek(iterator, timestamp) ➤ "Failed to seek iterator to \(timestamp)"
//      var hasEvent = DarwinBoolean(false)
//      try MusicEventIteratorHasCurrentEvent(iterator, &hasEvent) ➤ "Failed to check whether iterator has current event"
//      guard hasEvent else { self = .None; return }
//      var eventType = MusicEventType()
//      try MusicEventIteratorGetEventInfo(iterator, nil, &eventType, nil, nil) ➤ "Failed to get event type for current event"
//      switch eventType {
//        case kMusicEventType_ExtendedNote:
//          var data = ExtendedNoteOnEvent()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<ExtendedNoteOnEvent>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .ExtendedNote(timestamp, data)
//        case kMusicEventType_ExtendedTempo:
//          var data = ExtendedTempoEvent()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<ExtendedTempoEvent>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .ExtendedTempo(timestamp, data)
//        case kMusicEventType_User:
//          var data = MusicEventUserData()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<MusicEventUserData>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .User(timestamp, data)
//        case kMusicEventType_Meta:
//          var data = MIDIMetaEvent()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<MIDIMetaEvent>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .Meta(timestamp, data)
//        case kMusicEventType_MIDINoteMessage:
//          var data = MIDINoteMessage()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<MIDINoteMessage>(dataPointer)
//            data = retrievedData.memory
//            return status
//          } ➤ "Failed to get data for current event"
//          self = .Note(timestamp, data)
//        case kMusicEventType_MIDIChannelMessage:
//          var data = MIDIChannelMessage()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<MIDIChannelMessage>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .Channel(timestamp, data)
//        case kMusicEventType_MIDIRawData:
//          var data = MIDIRawData()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<MIDIRawData>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .RawData(timestamp, data)
//        case kMusicEventType_Parameter:
//          var data = ParameterEvent()
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<ParameterEvent>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .Parameter(timestamp, data)
//        case kMusicEventType_AUPreset:
//          var data = UnsafeMutablePointer<AUPresetEvent>.alloc(1).memory
//          try withUnsafePointer(&data) {
//            var dataPointer = UnsafePointer<Void>($0)
//            let status = MusicEventIteratorGetEventInfo(iterator, nil, nil, &dataPointer, nil)
//            let retrievedData = UnsafePointer<AUPresetEvent>(dataPointer)
//            data = retrievedData.memory
//            return status
//            } ➤ "Failed to get data for current event"
//          self = .AUPreset(timestamp, data)
//        default: self = .None
//      }
//    }
//  }
//
//}
