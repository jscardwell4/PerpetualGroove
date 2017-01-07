//
//  InstrumentTrack.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

// TODO: Review file
import AudioToolbox
import CoreMIDI
import SpriteKit

extension Sequence {

  func trackSoloStatusDidChange(_ notification: Foundation.Notification) {
    guard let track = notification.object as? InstrumentTrack, instrumentTracks.contains(track) else { return }

    let soloTracks = self.soloTracks

    if soloTracks.count == 0 {
      instrumentTracks.forEach { $0.forceMute = false }
    } else {
      soloTracks.forEach { $0.forceMute = false }
      Set(instrumentTracks).subtracting(soloTracks).forEach { $0.forceMute = true }
    }
  }

}

final class InstrumentTrack: Track, MIDINodeDispatch {

  static var current: InstrumentTrack? { return Sequence.current?.currentTrack }

  fileprivate(set) var nodeManager: MIDINodeManager!

  // MARK: - Listening for Sequencer and sequence notifications

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.SequencerContext
    return receptionist
  }()

  fileprivate func initializeNotificationReceptionist() {
    guard receptionist.count == 0 else { return }

    let transport = Transport.current

    receptionist.observe(name: .didReset, from: transport,
                         callback: weakMethod(self, InstrumentTrack.didReset))

    receptionist.observe(name: .soloCountDidChange, from: sequence,
                         callback: weakMethod(self, InstrumentTrack.soloCountDidChange))

    receptionist.observe(name: .didBeginJogging, from: transport,
                         callback: weakMethod(self, InstrumentTrack.didBeginJogging))
    receptionist.observe(name: .didEndJogging, from: transport,
                         callback: weakMethod(self, InstrumentTrack.didEndJogging))
    receptionist.observe(name: .didJog, from: transport,
                         callback: weakMethod(self, InstrumentTrack.didJog))

    receptionist.observe(name: .programDidChange, from: instrument,
                         callback: weakMethod(self, InstrumentTrack.didChangePreset))
    receptionist.observe(name: .soundFontDidChange, from: instrument,
                         callback: weakMethod(self, InstrumentTrack.didChangePreset))
}

  fileprivate func didChangePreset(_ notification: Foundation.Notification) {
    postNotification(name: .didUpdate, object: self)
  }

  fileprivate func didReset(_ notification: Foundation.Notification) { resetNodes() }

  fileprivate func soloCountDidChange(_ notification: Foundation.Notification) {
    guard let newCount = notification.newCount else { return }
    forceMute = newCount > 0 && !solo
  }

  fileprivate func didJog(_ notification: Foundation.Notification) {
    // Toggle track ended flag if we jogged back before the end of the track
    if trackEnded, let jogTime = notification.jogTime, jogTime < endOfTrack {
      trackEnded = false
    }
  }

  fileprivate func didBeginJogging(_ notification: Foundation.Notification) {}

  fileprivate func didEndJogging(_ notification: Foundation.Notification) {}

  // MARK: - MIDI file related properties and methods

  override func validate(events container: inout MIDIEventContainer) {
    instrumentEvent = MIDIEvent.MetaEvent(data: .text(text: "instrument:\(instrument.soundFont.url.lastPathComponent)"))
    programEvent = MIDIEvent.ChannelEvent(type: .programChange, channel: instrument.channel, data1: instrument.program)
    super.validate(events: &container)
  }

  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == MIDIEvent {

    var filteredEvents: [MIDIEvent] = []

    for event in events {

      switch event {

        case .meta(let metaEvent):
          switch metaEvent.data {
            case .text(let text) where text.hasPrefix("instrument:"): instrumentEvent = metaEvent
            default: filteredEvents.append(event)
          }

        case .channel(let channelEvent) where channelEvent.status.kind == .programChange:
          programEvent = channelEvent

        default:
          filteredEvents.append(event)

      }

    }

    modified = modified || filteredEvents.count > 0
    
    super.add(events: filteredEvents)
  }

  fileprivate var instrumentEvent: MIDIEvent.MetaEvent!
  fileprivate var programEvent: MIDIEvent.ChannelEvent!

  typealias Identifier = MIDIEvent.MIDINodeEvent.Identifier
  typealias NodeIdentifier = UUID
  typealias EventData = MIDIEvent.MIDINodeEvent.Data

  override var headEvents: [MIDIEvent] {
    return super.headEvents + [.meta(instrumentEvent), .channel(programEvent)]
  }

  fileprivate(set) var trackEnded = false {
    didSet {
      guard trackEnded != oldValue else { return }
      if trackEnded { nodeManager.stopNodes() } else { nodeManager.startNodes() }
    }
  }

  // MARK: - Track properties

  fileprivate(set) var instrument: Instrument!
  var color: TrackColor = .muddyWaters

  var recording: Bool { return Sequencer.mode == .default && MIDINodePlayer.currentDispatch === self }

  var nextNodeName: String { return "\(displayName) \(nodes.count + 1)" }

  override var displayName: String {
    guard name.isEmpty else { return name }
    return instrument?.preset.programName ?? ""
  }

  fileprivate(set) var isMuted = false {
    didSet {
      guard isMuted != oldValue else { return }
      swap(&volume, &_volume)
      postNotification(name: .muteStatusDidChange,
                       object: self,
                       userInfo: ["oldValue": oldValue, "newValue": isMuted])
    }
  }

  fileprivate func updateIsMuted() {
    switch (forceMute, mute, solo) {
      case (true,   true,  true): fallthrough
      case (true,  false,  true): fallthrough
      case (false,  true,  true): fallthrough
      case (false, false,  true): fallthrough
      case (false, false, false): isMuted = false
      case (true,   true, false): fallthrough
      case (true,  false, false): fallthrough
      case (false,  true, false): isMuted = true
    }
  }

  fileprivate(set) var forceMute = false {
    didSet {
      guard forceMute != oldValue else { return }
      postNotification(name: .forceMuteStatusDidChange,
                       object: self,
                       userInfo: ["oldValue": oldValue, "newValue": forceMute])
      updateIsMuted()
    }
  }

  var mute = false { didSet { guard mute != oldValue else { return }; updateIsMuted() } }

  var solo = false {
    didSet {
      guard solo != oldValue else { return }
      postNotification(name: .soloStatusDidChange, object: self, userInfo: ["oldValue": !solo, "newValue": solo])
      updateIsMuted()
    }
  }

  fileprivate var _volume: Float = 0
  var volume: Float { get { return instrument.volume } set { instrument.volume = newValue } }

  var pan: Float { get { return instrument.pan } set { instrument.pan = newValue } }

  // MARK: - Managing MIDI nodes

  /// Whether new events have been created and addd to the track
  fileprivate var modified = false

  /// The set of `MIDINode` objects that have been added to the track
  var nodes: OrderedSet<HashableTuple<BarBeatTime, MIDINodeRef>> = []

  /// Empties all node-referencing properties
  fileprivate func resetNodes() {
    nodes.removeAll()
    Log.debug("nodes reset")
    if modified {
      Log.debug("posting 'DidUpdate'")
      postNotification(name: .didUpdate, object: self)
      modified = false
    }
  }

  fileprivate var connectedEndPoints: Set<MIDIEndpointRef> = []

  func connect(node: MIDINode) throws {
    guard connectedEndPoints ∌ node.endPoint else { throw MIDINodeDispatchError.NodeAlreadyConnected }
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
    connectedEndPoints.insert(node.endPoint)
  }

  func disconnect(node: MIDINode) throws {
    guard connectedEndPoints ∋ node.endPoint else { throw MIDINodeDispatchError.NodeNotFound }
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    connectedEndPoints.remove(node.endPoint)
  }

  // MARK: - Loops

  func add(loop: Loop) {
    guard loops[loop.identifier] == nil else { return }
    Log.debug("adding loop: \(loop)")
    loops[loop.identifier] = loop
    add(events: loop)
  }

  fileprivate var loops: [UUID:Loop] = [:]

  // MARK: - MIDI events

  fileprivate var client  = MIDIClientRef()
  fileprivate var inPort  = MIDIPortRef()
  fileprivate var outPort = MIDIPortRef()

  fileprivate func read(_ packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer?) {

    // Forward the packets to the instrument
    do {
      try MIDISend(outPort, instrument.endPoint, packetList)
        ➤ "Failed to forward packet list to instrument"
    } catch { Log.error(error) }

    // Check if we are recording, otherwise skip event processing
    guard recording else { return }

    eventQueue.async {
      [weak self, time = Time.current.barBeatTime] in

      guard let packet = Packet(packetList: packetList) else { return }

      let event: MIDIEvent?
      switch packet.status {
        case 9:
          event = .channel(MIDIEvent.ChannelEvent(type: .noteOn,
                                        channel: packet.channel,
                                        data1: packet.note,
                                        data2: packet.velocity,
                                        time: time))
        case 8:
          event = .channel(MIDIEvent.ChannelEvent(type: .noteOff,
                                        channel: packet.channel,
                                        data1: packet.note,
                                        data2: packet.velocity,
                                        time: time))
        default:
          event = nil
      }
      if event != nil { self?.add(event: event!) }
    }
  }

  override func dispatch(event: MIDIEvent) {
      switch event {
        case .node(let nodeEvent):
          switch nodeEvent.data {
            case let .add(identifier, trajectory, generator):
              nodeManager.addNode(identifier: identifier.nodeIdentifier,
                                  trajectory: trajectory,
                                  generator: generator)
            case let .remove(identifier):
              do { try nodeManager.removeNode(identifier: identifier.nodeIdentifier) } catch { Log.error(error) }
          }
        case .meta(let metaEvent) where metaEvent.data == .endOfTrack:
          guard !recording && endOfTrack == metaEvent.time else { break }
          trackEnded = true
        default: break
      }

  }

  override func registrationTimes<S:Swift.Sequence>(forAdding events: S) -> [BarBeatTime]
    where S.Iterator.Element == MIDIEvent
  {
    return events.filter({ if case .node(_) = $0 { return true } else { return false } }).map({$0.time})
      + super.registrationTimes(forAdding: events)
  }

  /// The index for the track in the sequence's array of instrument tracks, or nil
  var index: Int? { return sequence.instrumentTracks.index(of: self) }

  // MARK: - Initialization

  fileprivate func initializeMIDIClient() throws {
    try MIDIClientCreateWithBlock("track \(instrument.bus)" as CFString, &client, nil)
      ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output" as CFString, &outPort)
      ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, name as CFString, &inPort, weakMethod(self, InstrumentTrack.read))
      ➤ "Failed to create in port"
  }

  init(sequence: Sequence, instrument: Instrument) throws {
    super.init(sequence: sequence)
    nodeManager = MIDINodeManager(owner: self)
    self.instrument = instrument
    instrument.track = self
    instrumentEvent = MIDIEvent.MetaEvent(data: .text(text: "instrument:\(instrument.soundFont.url.lastPathComponent)"))
    programEvent = MIDIEvent.ChannelEvent(type: .programChange, channel: instrument.channel, data1: instrument.program)
    color = TrackColor.nextColor

    initializeNotificationReceptionist()
    try initializeMIDIClient()
  }

  init(sequence: Sequence, grooveTrack: GrooveFile.Track) throws {

    super.init(sequence: sequence)

    nodeManager = MIDINodeManager(owner: self)

    guard let preset = Instrument.Preset(grooveTrack.instrument.jsonValue) else {
      throw Error.InstrumentInitializeFailure
    }
    
    instrument = try Instrument(track: self, preset: preset)
    instrument.track = self
    color = grooveTrack.color

    name = grooveTrack.name
    var events: [MIDIEvent] = []
    for (_, node) in grooveTrack.nodes {
      events.append(.node(MIDIEvent.MIDINodeEvent(data: .add(identifier: node.identifier,
                                                   trajectory: node.trajectory,
                                                   generator: node.generator),
                                        time: node.addTime)))
      if let time = node.removeTime {
        events.append(.node(MIDIEvent.MIDINodeEvent(data: .remove(identifier: node.identifier), time: time)))
      }
    }
    add(events: events)

    grooveTrack.loops.values.forEach { add(loop: Loop(grooveLoop: $0, track: self)) }

    initializeNotificationReceptionist()
    try initializeMIDIClient()
  }

  init(sequence: Sequence, trackChunk: MIDIFile.TrackChunk) throws {
    super.init(sequence: sequence)
    nodeManager = MIDINodeManager(owner: self)

    add(events: trackChunk.events)

    // Find the instrument event

    guard let instrumentEvent = instrumentEvent,
      case .text(var instrumentName) = instrumentEvent.data else
    {
      throw Error.MissingInstrument
    }

    instrumentName = instrumentName[instrumentName.index(instrumentName.startIndex, offsetBy:11)|->]

    guard let url = Bundle.main.url(forResource: instrumentName, withExtension: nil) else {
      throw Error.InvalidSoundSetURL
    }

    guard let soundSet: SoundFont = (try? EmaxSoundSet(url: url)) ?? (try? SoundSet(url: url)) else {
      throw Error.SoundSetInitializeFailure
    }

    // Find the program change event
    guard let programEvent = programEvent else {
      throw Error.MissingProgram
    }

    let channel = programEvent.status.channel, program = programEvent.data1

    guard let presetHeader = soundSet[program: program, bank: 0] else {
      throw Error.InvalidProgram
    }

    let preset = Instrument.Preset(soundFont: soundSet, presetHeader: presetHeader, channel: channel)

    guard let instrument = try? Instrument(track: self, preset: preset) else {
      throw Error.InstrumentInitializeFailure
    }

    self.instrument = instrument
    color = TrackColor.nextColor

    initializeNotificationReceptionist()
    try initializeMIDIClient()

    fatalError("need to also extract bank")
  }

  override var description: String {
    return "\n".join( "instrument: \(instrument)", "color: \(color)", super.description )
  }
}

// MARK: - Errors
extension InstrumentTrack {

  enum Error: String, Swift.Error, CustomStringConvertible {
    case SoundSetInitializeFailure = "Failed to create sound set"
    case InvalidSoundSetURL = "Failed to resolve sound set url"
    case MissingProgram = "Missing program change event"
    case InvalidProgram = "Specified sound set does not have the specified program"
    case MissingInstrument = "Missing instrument event"
    case InstrumentInitializeFailure = "Failed to create instrument"
  }

}

// MARK: - Hashable
extension InstrumentTrack: Hashable {

  var hashValue: Int { return ObjectIdentifier(self).hashValue }

}

// MARK: - Equatable
extension InstrumentTrack: Equatable {

  static func ==(lhs: InstrumentTrack, rhs: InstrumentTrack) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }

}

