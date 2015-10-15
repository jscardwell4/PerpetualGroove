//
//  InstrumentTrack.swift
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

final class InstrumentTrack: MIDITrackType, Equatable, Hashable {

  typealias Color = TrackColor

  var description: String {
    var result = "Track(\(name)) {\n"
    result += "\tinstrument: \(instrument.description.indentedBy(4, true))\n"
    result += "\tcolor: \(color)\n\tevents: {\n"
    result += ",\n".join(eventContainer.events.map({$0.description.indentedBy(8)}))
    result += "\n\t}\n}"
    return result
  }

  enum Notification: String, NotificationType, NotificationNameType {
    enum Key: String, KeyType { case OldValue, NewValue }
    case MuteStatusDidChange, SoloStatusDidChange, DidAddNode, DidRemoveNode
  }

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  // MARK: - Constant properties

  var instrument: Instrument!
  var color: Color = .White
  
  typealias NodeIdentifier = MIDINodeEvent.Identifier

  private var nodes: Set<MIDINode> = []
  private var notes: Set<NodeIdentifier> = []
  private var fileIDToNodeID: [NodeIdentifier:NodeIdentifier] = [:]
  private var client = MIDIClientRef()
  private var inPort = MIDIPortRef()
  private var outPort = MIDIPortRef()
  private var fileQueue: dispatch_queue_t?
  private var pendingIdentifier: NodeIdentifier?
  private var _trackEnd: CABarBeatTime?


  var hashValue: Int { return ObjectIdentifier(self).hashValue }

  var trackEnd: CABarBeatTime { return _trackEnd ?? time.time }
  
  let time = Sequencer.time

  var recording = false

  private func recordingStatusDidChange(notification: NSNotification) { recording = Sequencer.recording }

  private var receptionist: NotificationReceptionist?

  var eventContainer = MIDITrackEventContainer() {
    didSet {
      MIDITrackNotification.DidUpdateEvents.post(object: self)
    }
  }

  var instrumentNameEvent: MetaEvent? {
    if let event = eventContainer.metaEvents.first, case .Text = event.data { return event } else { return nil }
  }

  var instrumentProgramEvent: ChannelEvent? {
    if let event = eventContainer.channelEvents.first where event.status.type == .ProgramChange { return event }
    else { return nil }
  }

  /** validateInstrumentEvents */
  private func validateInstrumentEvents() {

    let instrumentName = "instrument:\(instrument.soundSet.url.lastPathComponent!)"
    if var event = instrumentNameEvent, case .Text(let t) = event.data where t != instrumentName {
      event.data = .Text(text: instrumentName)
      eventContainer.insert(event, atIndex: 0)
    } else if instrumentNameEvent == nil {
      eventContainer.insert(MetaEvent(.Text(text: instrumentName)), atIndex: 0)
    }

    if var event = instrumentProgramEvent where event.status.channel != instrument.channel || event.data1 != instrument.program {
      event.status.channel = instrument.channel
      event.data1 = instrument.program
      eventContainer.insert(event, atIndex: 1)
    } else if instrumentProgramEvent == nil {
      eventContainer.insert(ChannelEvent(.ProgramChange, instrument.channel, instrument.program), atIndex: 1)
    }
  }

  var chunk: MIDIFileTrackChunk {
    validateFirstAndLastEvents()
    validateInstrumentEvents()
    return MIDIFileTrackChunk(eventContainer: eventContainer)
  }

  // MARK: - Editable properties

  var name: String { return label ?? instrument.preset.name }
  var label: String?

  private var _mute: Bool = false
  var mute: Bool = false {
    didSet {
      guard mute != oldValue else { return }
      if mute { _volume = volume; volume = 0 } else { volume = _volume }
      Notification.MuteStatusDidChange.post(object: self, userInfo: [.OldValue: oldValue, .NewValue: mute])
    }
  }

  var solo: Bool = false {
    didSet {
      guard solo != oldValue else { return }
      if solo { _mute = mute; mute = false }
      Notification.SoloStatusDidChange.post(object: self, userInfo: [.OldValue: oldValue, .NewValue: solo])
    }
  }

  private var _volume: Float = 1
  var volume: Float { get { return instrument.volume } set { instrument.volume = newValue } }
  var pan: Float { get { return instrument.pan } set { instrument.pan = newValue } }

  enum Error: String, ErrorType, CustomStringConvertible {
    case NodeNotFound = "The specified node was not found among the track's nodes"
    case SoundSetInitializeFailure = "Failed to create sound set"
    case InvalidSoundSetURL = "Failed to resolve sound set url"
    case InstrumentInitializeFailure = "Failed to create instrument"
  }

  /**
  addNode:

  - parameter node: MIDINode
  */
  func addNode(node: MIDINode) throws {
    nodes.insert(node)
    let identifier = NodeIdentifier(ObjectIdentifier(node).uintValue)
    notes.insert(identifier)
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
    Notification.DidAddNode.post(object: self)
    guard recording else {
      if let pendingIdentifier = pendingIdentifier {
        fileIDToNodeID[pendingIdentifier] = identifier
        self.pendingIdentifier = nil
      }
      return
    }
    dispatch_async(fileQueue!) {
      [time = time.time, placement = node.initialSnapshot.placement, note = node.note, weak self] in
      let event = MIDINodeEvent(.Add(identifier: identifier, placement: placement, attributes: note), time)
      self?.eventContainer.append(event)
    }
  }

  /**
  addNodeWithIdentifier:placement:attributes:texture:

  - parameter identifier: NodeIdentifier
  - parameter placement: Placement
  - parameter attributes: NoteAttributes
  - parameter texture: MIDINode.TextureType
  */
  private func addNodeWithIdentifier(identifier: NodeIdentifier,
                           placement: Placement,
                          attributes: NoteAttributes)
  {
    guard pendingIdentifier == nil else { fatalError("already have an identifier pending: \(pendingIdentifier!)") }
    guard let midiPlayer = MIDIPlayerNode.currentPlayer else { fatalError("trying to add node without a midi player") }
    pendingIdentifier = identifier
    midiPlayer.placeNew(placement, targetTrack: self, attributes: attributes)
  }

  /**
  removeNodeWithIdentifier:

  - parameter identifier: NodeIdentifier
  */
  private func removeNodeWithIdentifier(identifier: NodeIdentifier) {
    guard let mappedIdentifier = fileIDToNodeID[identifier] else {
      fatalError("trying to remove node for unmapped identifier \(identifier)")
    }
    guard let idx = nodes.indexOf({$0.sourceID == mappedIdentifier}) else {
      fatalError("failed to find node with mapped identifier \(mappedIdentifier)")
    }
    let node = nodes[idx]
    do {
      try removeNode(node)
      node.removeFromParent()
      fileIDToNodeID[identifier] = nil
    } catch {
      logError(error)
    }
  }

  /**
  removeNode:

  - parameter node: MIDINode
  */
  func removeNode(node: MIDINode) throws {
    guard let node = nodes.remove(node) else { throw Error.NodeNotFound }
    let identifier = NodeIdentifier(ObjectIdentifier(node).uintValue)
    notes.remove(identifier)
    node.sendNoteOff()
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    Notification.DidRemoveNode.post(object: self)
    guard recording else { return }
    dispatch_async(fileQueue!) {
      [time = time.time, weak self] in
      self?.eventContainer.append(MIDINodeEvent(.Remove(identifier: identifier), time))
    }
  }

  /**
  Reconstructs the `uintValue` of an `ObjectIdentifier` using packet data bytes 4 through 11

  - parameter packet: MIDIPacket

  - returns: UInt?
  */
  private func nodeIdentifierFromPacket(var packet: MIDIPacket) -> NodeIdentifier? {
    guard packet.length == UInt16(sizeof(NodeIdentifier.self) + 3) else { return nil }
    return NodeIdentifier(withUnsafePointer(&packet.data) {
      UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>($0).advancedBy(3), count: sizeof(NodeIdentifier.self))
    })
  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafeMutablePointer<Void>
  */
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {

    // Forward the packets to the instrument
    do { try MIDISend(outPort, instrument.endPoint, packetList) ➤ "Failed to forward packet list to instrument" }
    catch { logError(error) }

    // Check if we are recording, otherwise skip event processing
    guard recording else { return }
    
    dispatch_async(fileQueue!) {
      [weak self, time = time.time] in

      let packets = packetList.memory
      let packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
      packetPointer.initialize(packets.packet)
      guard packets.numPackets == 1 else { fatalError("Packets must be sent to track one at a time") }

      let packet = packetPointer.memory
      let ((status, channel), note, velocity) = ((packet.data.0 >> 4, packet.data.0 & 0xF), packet.data.1, packet.data.2)
      let event: MIDITrackEvent?
      switch status {
        case 9:  event = ChannelEvent(.NoteOn, channel, note, velocity, time)
        case 8:  event = ChannelEvent(.NoteOff, channel, note, velocity, time)
        default: event = nil
      }
      if event != nil { self?.eventContainer.append(event!) }
    }
  }

  /**
  dispatchChannelEvent:

  - parameter channelEvent: ChannelEvent
  */
  private func dispatchChannelEvent(channelEvent: ChannelEvent) {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    var data: [Byte] = [channelEvent.status.value, channelEvent.data1]
    if let data2 = channelEvent.data2 { data.append(data2) }
    let timeStamp = time.ticks
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, 3, data)
    withUnsafePointer(&packetList) {
      do { try MIDISend(outPort, instrument.endPoint, $0) ➤ "Failed to dispatch packet list to instrument" }
      catch { logError(error) }
    }
  }

  /**
  didStart:

  - parameter notification: NSNotification
  */
  private func didStart(notification: NSNotification) { logVerbose("time = \(time)") }

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard receptionist == nil else { return }
    typealias Notification = Sequencer.Notification
    let queue = NSOperationQueue.mainQueue()
    let object = Sequencer.self
    let callback: (NSNotification) -> Void = {[weak self] _ in self?.recording = Sequencer.recording}
    receptionist = NotificationReceptionist()
    receptionist?.observe(Notification.DidTurnOnRecording, from: object, queue: queue, callback: callback)
    receptionist?.observe(Notification.DidTurnOffRecording, from: object, queue: queue, callback: callback)
    receptionist?.observe(Notification.DidStart, from: object, queue: queue, callback: didStart)
  }

  /** initializeMIDIClient */
  private func initializeMIDIClient() throws {
    try MIDIClientCreateWithBlock("track \(instrument.bus)", &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, name, &inPort, read) ➤ "Failed to create in port"
  }

  /**
  initWithBus:track:

  - parameter b: Bus
  - parameter s: MIDISequence
  */
  init(instrument i: Instrument, sequence s: MIDISequence) throws {
    sequence = s
    instrument = i
    fileQueue = serialQueueWithLabel("BUS \(instrument.bus)", qualityOfService: QOS_CLASS_BACKGROUND)
    recording = Sequencer.recording

    initializeNotificationReceptionist()

    try initializeMIDIClient()
  }

  private var eventMap: [CABarBeatTime:[MIDITrackEvent]] = [:]

  /**
  dispatchEventsForTime:

  - parameter time: CABarBeatTime
  */
  private func dispatchEventsForTime(time: CABarBeatTime) {
    guard let events = eventMap[time] else { return }
    for event in events {
      switch event {
        case let nodeEvent as MIDINodeEvent:
          switch nodeEvent.data {
            case let .Add(i, p, a):    addNodeWithIdentifier(i, placement: p, attributes: a)
            case let .Remove(identifier): removeNodeWithIdentifier(identifier)
          }
        default: break
      }

    }
  }

  private(set) weak var sequence: MIDISequence?
  var index: Int? { return sequence?.instrumentTracks.indexOf(self) }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(trackChunk: MIDIFileTrackChunk, sequence s: MIDISequence) throws {
    sequence = s
    eventContainer = MIDITrackEventContainer(events: trackChunk.events)
//    let events = trackChunk.events

    // Find the end of track event
    guard let endOfTrackEvent = self.endOfTrackEvent else {
      throw MIDIFileError(type: .MissingEvent, reason: "Missing end of track event")
    }
    _trackEnd = endOfTrackEvent.time

    if let trackNameEvent = self.trackNameEvent, case .SequenceTrackName(let n) = trackNameEvent.data { label = n }

    // Find the instrument event
    guard let instrumentNameEvent = self.instrumentNameEvent, case .Text(var instr) = instrumentNameEvent.data else {
      throw MIDIFileError(type: .FileStructurallyUnsound, reason: "Instrument event must be a text event")
    }

    instr = instr[instr.startIndex.advancedBy(11)..<]

    guard let url = NSBundle.mainBundle().URLForResource(instr, withExtension: nil) else { throw Error.InvalidSoundSetURL }

    guard let soundSet = try? SoundSet(url: url) else { throw Error.SoundSetInitializeFailure }

    // Find the program change event
    guard let programEvent = self.instrumentProgramEvent else {
      throw MIDIFileError(type: .MissingEvent, reason: "Missing program change event")
    }

    let program = programEvent.data1
    let channel = programEvent.status.channel

    guard let instrumentMaybe = try? Instrument(soundSet: soundSet, program: program, channel: channel) else {
      throw Error.InstrumentInitializeFailure
    }

    instrument = instrumentMaybe
    fileQueue = serialQueueWithLabel("BUS \(instrument.bus)", qualityOfService: QOS_CLASS_BACKGROUND)
    recording = Sequencer.recording

    for event in eventContainer.events {
      let eventTime = event.time
      var eventBag: [MIDITrackEvent] = eventMap[eventTime] ?? []
      eventBag.append(event)
      eventMap[eventTime] = eventBag
    }
    
    for eventTime in eventMap.keys { time.registerCallback(dispatchEventsForTime, forTime: eventTime) }

    initializeNotificationReceptionist()

    try initializeMIDIClient()
  }


}


/**
Equatable conformance

- parameter lhs: InstrumentTrack
- parameter rhs: InstrumentTrack

- returns: Bool
*/
func ==(lhs: InstrumentTrack, rhs: InstrumentTrack) -> Bool {
  return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}

