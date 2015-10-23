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
import SpriteKit

final class InstrumentTrack: MIDITrackType {


  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Recording     = State(rawValue: 0b0000_0001)
    static let Soloing       = State(rawValue: 0b0000_0010)
    static let InclusiveMute = State(rawValue: 0b0000_0100)
    static let ExclusiveMute = State(rawValue: 0b0000_1000)
    static let TrackEnded    = State(rawValue: 0b0001_0000)

    var description: String {
      var result = "InstrumentTrack.State { "
      var flagStrings: [String] = []
      if self ∋ .Recording     { flagStrings.append("Recording")     }
      if self ∋ .Soloing       { flagStrings.append("Soloing")       }
      if self ∋ .InclusiveMute { flagStrings.append("InclusiveMute") }
      if self ∋ .ExclusiveMute { flagStrings.append("ExclusiveMute") }
      if self ∋ .TrackEnded    { flagStrings.append("TrackEnded")    }
      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }

  /// Holds the current state of the node
  private var state: State = [] {
    didSet {
      guard state != oldValue else { return }

      switch state ⊻ oldValue {

        case [.Soloing]:
          Notification.SoloStatusDidChange.post(object: self, userInfo: [.OldValue: !solo, .NewValue: solo])
          if state ~∩ [.ExclusiveMute, .InclusiveMute] {
            Notification.MuteStatusDidChange.post(object: self, userInfo: [.OldValue: !mute, .NewValue: mute])
          }

        case [.ExclusiveMute], [.InclusiveMute]:
          let oldValue = oldValue ~∩ [.ExclusiveMute, .InclusiveMute] && oldValue ∌ .Soloing
          let newValue = state    ~∩ [.ExclusiveMute, .InclusiveMute] && state    ∌ .Soloing
          guard oldValue != newValue else { break }
          if newValue { _volume = volume; volume = 0 } else { volume = _volume }
          Notification.MuteStatusDidChange.post(object: self, userInfo: [.OldValue: oldValue, .NewValue: newValue])

        case [.TrackEnded]:
          if state ∋ .TrackEnded { stopNodes() } else { startNodes() }

        default:
          break
      }

    }
  }

  // MARK: - Listening for Sequencer and sequence notifications

  private let receptionist = NotificationReceptionist()

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard receptionist.count == 0 else { return }

    receptionist.observe(Sequencer.Notification.DidToggleRecording, from: Sequencer.self, queue: NSOperationQueue.mainQueue()) {
      [weak self] _ in self?.recording = Sequencer.recording
    }

    receptionist.observe(Sequencer.Notification.DidReset, from: Sequencer.self, queue: NSOperationQueue.mainQueue()) {
      [weak self] _ in self?.resetNodes()
    }

    receptionist.observe(MIDISequence.Notification.SoloCountDidChange, from: sequence, queue: NSOperationQueue.mainQueue()) {
      [weak self] in

      guard let state = self?.state,
        newCount = ($0.userInfo?[MIDISequence.Notification.Key.NewCount.rawValue] as? NSNumber)?.integerValue else {
          return
      }

           if state !~∩ [.Soloing, .InclusiveMute] && newCount > 0         { self?.state ∪= .InclusiveMute }
      else if state ∌ .Soloing && state ∋ .InclusiveMute && newCount == 0 { self?.state ⊻= .InclusiveMute }
    }

    receptionist.observe(Sequencer.Notification.DidJog, from: Sequencer.self, queue: NSOperationQueue.mainQueue()) {
      [weak self] in

      guard let state = self?.state where state ∋ .TrackEnded else { return }

      guard let jogTime = ($0.userInfo?[Sequencer.Notification.Key.JogTime.rawValue] as? NSValue)?.barBeatTimeValue else {
        self?.logError("notication does not contain jog tick value")
        return
      }

      guard let trackEnd = self?._trackEnd where jogTime < trackEnd else { return }

      self?.state.remove(.TrackEnded)
    }

  }

  // MARK: - MIDI file related properties and methods

  var eventContainer = MIDIEventContainer() { didSet { MIDITrackNotification.DidUpdateEvents.post(object: self) } }

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

  // MARK: - Track properties

  var instrument: Instrument!

  var color: TrackColor = .White

  var name: String { return label ?? instrument.preset.name }
  var label: String?

  var mute: Bool {
    get { return state ~∩ [.ExclusiveMute, .InclusiveMute] && state ∌ .Soloing}
    set { guard (state ∋ .ExclusiveMute) != newValue else { return }; state ⊻= .ExclusiveMute }
  }

  var recording: Bool {
    get { return state ∋ .Recording }
    set { if newValue { state.insert(.Recording) } else { state.remove(.Recording) } }
  }

  var solo: Bool {
    get { return state ∋ .Soloing }
    set { guard solo != newValue else { return }; state ⊻= .Soloing }
  }

  private var _volume: Float = 1
  var volume: Float { get { return instrument.volume } set { instrument.volume = newValue } }
  var pan: Float { get { return instrument.pan } set { instrument.pan = newValue } }

  // MARK: - Managing MIDI nodes

  typealias NodeIdentifier = MIDINodeEvent.Identifier

  /// The identifier parsed from a file awaiting the identifier of its generated node
  private var pendingIdentifier: NodeIdentifier?

  /// The set of `MIDINode` objects that have been added to the track
  private var nodes: Set<MIDINode> = []

  /// Index that maps the identifiers parsed from a file to the identifiers assigned to the generated nodes
  private var fileIDToNodeID: [NodeIdentifier:NodeIdentifier] = [:]

  /** Empties all node-referencing properties */
  private func resetNodes() { pendingIdentifier = nil; nodes.removeAll(); fileIDToNodeID.removeAll() }

  /**
  addNode:

  - parameter node: MIDINode
  */
  func addNode(node: MIDINode) throws {
    nodes.insert(node)
    let identifier = NodeIdentifier(ObjectIdentifier(node).uintValue)
    logVerbose("identifier = \(identifier)")
    notes.insert(identifier)
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
    Notification.DidAddNode.post(object: self)
    if let pendingIdentifier = pendingIdentifier {
      fileIDToNodeID[pendingIdentifier] = identifier
      self.pendingIdentifier = nil
    }
    guard recording else { return }
    eventQueue.addOperationWithBlock {
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
    logVerbose("identifier = \(identifier)")
    guard fileIDToNodeID[identifier] == nil else { return }
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
    logVerbose("identifier = \(identifier)")
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
    logVerbose("identifier = \(identifier)")
    notes.remove(identifier)
    node.sendNoteOff()
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    Notification.DidRemoveNode.post(object: self)
    guard recording else { return }
    eventQueue.addOperationWithBlock {
      [time = time.time, weak self] in
      self?.eventContainer.append(MIDINodeEvent(.Remove(identifier: identifier), time))
    }
  }

  /** stopNodes */
  private func stopNodes() { nodes.forEach {$0.fadeOut()} }

  /** startNodes */
  private func startNodes() { nodes.forEach {$0.fadeIn()} }

  // MARK: - MIDI events

  /// Queue used generating `MIDIFile` track events
  private let eventQueue: NSOperationQueue = {
    let q = NSOperationQueue()
    q.maxConcurrentOperationCount = 1
    return q
    }()

  /// The end of the track as parsed when initializing from a `MIDIFileTrackChunk`
  private var _trackEnd: CABarBeatTime?

  /// The end of the track as parsed from a chunk or the current time
  var trackEnd: CABarBeatTime { return _trackEnd ?? time.time }

  /// A reference to the bar beat time object owned by the sequencer
  let time = Sequencer.time

  private var notes: Set<NodeIdentifier> = []

  private var client  = MIDIClientRef()
  private var inPort  = MIDIPortRef()
  private var outPort = MIDIPortRef()

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
    
    eventQueue.addOperationWithBlock {
      [weak self, time = time.time] in

      let packets = packetList.memory
      let packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
      packetPointer.initialize(packets.packet)
      guard packets.numPackets == 1 else { fatalError("Packets must be sent to track one at a time") }

      let packet = packetPointer.memory
      let ((status, channel), note, velocity) = ((packet.data.0 >> 4, packet.data.0 & 0xF), packet.data.1, packet.data.2)
      self?.logVerbose("status: \(status); channel: \(channel); note: \(note); velocity: \(velocity)")
      let event: MIDIEvent?
      switch status {
        case 9:  event = ChannelEvent(.NoteOn, channel, note, velocity, time)
        case 8:  event = ChannelEvent(.NoteOff, channel, note, velocity, time)
        default: event = nil
      }
      if event != nil { self?.logVerbose("event: \(event!)"); self?.eventContainer.append(event!) }
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

  /// Holds events parsed from a `MIDIFile` keyed by their bar beat time
  private(set) var eventMap = MIDIEventMap()

  /**
  dispatchEventsForTime:

  - parameter time: CABarBeatTime
  */
  private func dispatchEventsForTime(time: CABarBeatTime) {
    guard let events = eventMap.eventsForTime(time) where Sequencer.playing else { return }
    for event in events {
      switch event {
        case let nodeEvent as MIDINodeEvent:
          switch nodeEvent.data {
            case let .Add(i, p, a):       addNodeWithIdentifier(i, placement: p, attributes: a)
            case let .Remove(identifier): removeNodeWithIdentifier(identifier)
          }
        case let metaEvent as MetaEvent where metaEvent.data == .EndOfTrack:
          guard _trackEnd == time else { break }
          state.insert(.TrackEnded)
        default: break
      }

    }
  }

  /// The track's owning sequence
  private(set) unowned var sequence: MIDISequence

  /// The index for the track in the sequence's array of instrument tracks, or nil
  var index: Int? { return sequence.instrumentTracks.indexOf(self) }

  // MARK: - Initialization

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
    eventQueue.name = "BUS \(instrument.bus)"
    recording = Sequencer.recording

    initializeNotificationReceptionist()
    try initializeMIDIClient()
  }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(trackChunk: MIDIFileTrackChunk, sequence s: MIDISequence) throws {
    sequence = s
    eventContainer = MIDIEventContainer(events: trackChunk.events)

    // Find the end of track event
    guard let endOfTrackEvent = self.endOfTrackEvent else {
      throw MIDIFileError(type: .MissingEvent, reason: "Missing end of track event")
    }
    _trackEnd = endOfTrackEvent.time

    if let trackNameEvent = self.trackNameEvent, case .SequenceTrackName(let n) = trackNameEvent.data { label = n }

    // Find the instrument event
    guard let instrumentName = self.instrumentNameEvent, case .Text(var instr) = instrumentName.data else {
      throw MIDIFileError(type: .FileStructurallyUnsound, reason: "Instrument event must be a text event")
    }

    instr = instr[instr.startIndex.advancedBy(11)..<]

    guard let url = NSBundle.mainBundle().URLForResource(instr, withExtension: nil) else { throw Error.InvalidSoundSetURL }

    let soundSet: SoundSetType
    do {
      soundSet = try EmaxSoundSet(url: url)
    } catch {
      do {
        soundSet = try SoundSet(url: url)
      } catch {
        logError(error)
        throw Error.SoundSetInitializeFailure
      }
    }

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
    eventQueue.name = "BUS \(instrument.bus)"
    recording = Sequencer.recording

    eventMap.insert(typecast(eventContainer.nodeEvents) ?? [])

    if let event = eventContainer.endOfTrackEvent { eventMap.insert([event]) }

    time.registerCallback(dispatchEventsForTime, forTimes: eventMap.times, forObject: self)

    initializeNotificationReceptionist()
    try initializeMIDIClient()
  }

}

// MARK: - Errors
extension InstrumentTrack {
  enum Error: String, ErrorType, CustomStringConvertible {
    case NodeNotFound = "The specified node was not found among the track's nodes"
    case SoundSetInitializeFailure = "Failed to create sound set"
    case InvalidSoundSetURL = "Failed to resolve sound set url"
    case InstrumentInitializeFailure = "Failed to create instrument"
  }
}

// MARK: - Notifications
extension InstrumentTrack {
  enum Notification: String, NotificationType, NotificationNameType {
    enum Key: String, KeyType { case OldValue, NewValue }
    case MuteStatusDidChange, SoloStatusDidChange, DidAddNode, DidRemoveNode
  }
}

// MARK: - CustomStringConvertible
extension InstrumentTrack: CustomStringConvertible {
  var description: String {
    return "\n".join(
      "name: \(name)",
      "instrument: \(instrument)",
      "color: \(color)",
      "events:\n\(eventContainer.description.indentedBy(1, useTabs: true))",
      "map:\n\(eventMap.description.indentedBy(1, useTabs: true))"
    )
  }
}

// MARK: - CustomStringConvertible
extension InstrumentTrack: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Hashable
extension InstrumentTrack: Hashable {
  var hashValue: Int { return ObjectIdentifier(self).hashValue }
}

// MARK: - Equatable
extension InstrumentTrack: Equatable {}

/**
Equatable conformance

- parameter lhs: InstrumentTrack
- parameter rhs: InstrumentTrack

- returns: Bool
*/
func ==(lhs: InstrumentTrack, rhs: InstrumentTrack) -> Bool {
  return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}

