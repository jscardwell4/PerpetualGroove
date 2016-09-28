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
import AudioToolbox
import CoreMIDI
import SpriteKit

extension Sequence {
  /**
   trackSoloStatusDidChange:

   - parameter notification: NSNotification
  */
  func trackSoloStatusDidChange(_ notification: Foundation.Notification) {
    guard let track = notification.object as? InstrumentTrack , instrumentTracks.contains(track) else { return }
    let soloTracks = self.soloTracks
    if soloTracks.count == 0 {
      instrumentTracks.forEach {
        logDebug("clearing force mute for track '\($0.displayName)'")
        $0.forceMute = false
      }
    } else {
      soloTracks.forEach {
        logDebug("clearing forced mute for track '\($0.displayName)'")
        $0.forceMute = false
      }
      Set(instrumentTracks).subtracting(soloTracks).forEach {
        logDebug("force muting track '\($0.displayName)'")
        $0.forceMute = true
      }
    }
  }
}

final class InstrumentTrack: Track, MIDINodeDispatch {

  fileprivate(set) var nodeManager: MIDINodeManager!

  // MARK: - Listening for Sequencer and sequence notifications

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.SequencerContext
    return receptionist
  }()

  /** initializeNotificationReceptionist */
  fileprivate func initializeNotificationReceptionist() {
    guard receptionist.count == 0 else { return }

    receptionist.observe(name: Sequencer.NotificationName.didReset.rawValue,
                         from: Sequencer.self,
                         callback: weakMethod(self, InstrumentTrack.didReset))

    receptionist.observe(name: Sequence.NotificationName.soloCountDidChange.rawValue,
                         from: sequence,
                         callback: weakMethod(self, InstrumentTrack.soloCountDidChange))

    receptionist.observe(name: Sequencer.NotificationName.didBeginJogging.rawValue,
                         from: Sequencer.self,
                         callback: weakMethod(self, InstrumentTrack.didBeginJogging))
    receptionist.observe(name: Sequencer.NotificationName.didEndJogging.rawValue,
                         from: Sequencer.self,
                         callback: weakMethod(self, InstrumentTrack.didEndJogging))
    receptionist.observe(name: Sequencer.NotificationName.didJog.rawValue,
                         from: Sequencer.self,
                         callback: weakMethod(self, InstrumentTrack.didJog))

    receptionist.observe(name: Instrument.NotificationName.presetDidChange.rawValue,
                         from: instrument,
                         callback: weakMethod(self, InstrumentTrack.didChangePreset))
    receptionist.observe(name: Instrument.NotificationName.soundSetDidChange.rawValue,
                         from: instrument,
                         callback: weakMethod(self, InstrumentTrack.didChangePreset))
}

  /**
   didChangePreset:

   - parameter notification: NSNotification
  */
  fileprivate func didChangePreset(_ notification: Foundation.Notification) {
    postNotification(name: .didUpdate, object: self, userInfo: nil)
  }

  /**
  didReset:

  - parameter notification: NSNotification
  */
  fileprivate func didReset(_ notification: Foundation.Notification) { resetNodes() }

  /**
  soloCountDidChange:

  - parameter notification: NSNotification
  */
  fileprivate func soloCountDidChange(_ notification: Foundation.Notification) {
    guard let newCount = notification.newCount else { return }
    forceMute = newCount > 0 && !solo
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  fileprivate func didJog(_ notification: Foundation.Notification) {
    // Toggle track ended flag if we jogged back before the end of the track
    if trackEnded, let jogTime = notification.jogTime , jogTime < endOfTrack {
      trackEnded = false
    }


  }

  /**
   didBeginJogging:

   - parameter notification: NSNotification
  */
  fileprivate func didBeginJogging(_ notification: Foundation.Notification) {

  }

  /**
   didEndJogging:

   - parameter notification: NSNotification
  */
  fileprivate func didEndJogging(_ notification: Foundation.Notification) {

  }

  // MARK: - MIDI file related properties and methods

  /** validateEvents */
  override func validateEvents(_ container: inout MIDIEventContainer) {
    instrumentEvent = MetaEvent(.text(text: "instrument:\(instrument.soundSet.url.lastPathComponent)"))
    programEvent = ChannelEvent(.programChange, instrument.channel, instrument.program)
    super.validateEvents(&container)
  }

  /**
   addEvents:

   - parameter events: [MIDIEvent]
  */
  func addEvents<S:Swift.Sequence>(_ events: S) where S.Iterator.Element == MIDIEvent {
    var filteredEvents: [MIDIEvent] = []
    for event in events {
      switch event {
        case .meta(let metaEvent):
          switch metaEvent.data {
            case .text(let text) where text.hasPrefix("instrument:"): instrumentEvent = metaEvent
            default: filteredEvents.append(event)
          }
        case .channel(let channelEvent) where channelEvent.status.type == .programChange:
          programEvent = channelEvent
        default: filteredEvents.append(event)
      }
    }
    modified = modified || filteredEvents.count > 0
    super.addEvents(filteredEvents)
  }

  fileprivate var instrumentEvent: MetaEvent!
  fileprivate var programEvent: ChannelEvent!

  typealias Identifier = MIDINodeEvent.Identifier
  typealias NodeIdentifier = MIDINode.Identifier
  typealias EventData = MIDINodeEvent.Data

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

  var recording: Bool { return Sequencer.mode == .default && MIDIPlayer.currentDispatch === self }

  var nextNodeName: String { return "\(displayName) \(nodes.count + 1)" }

  override var displayName: String {
    guard name.isEmpty else { return name }
    return instrument?.preset.name ?? ""
  }

  fileprivate(set) var isMuted = false {
    didSet {
      guard isMuted != oldValue else { return }
      swap(&volume, &_volume)
      postNotification(name: .muteStatusDidChange, object: self, userInfo: ["oldValue": oldValue, "newValue": isMuted])
    }
  }

  /** updateIsMuted */
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
      postNotification(name: .forceMuteStatusDidChange, object: self, userInfo: ["oldValue": oldValue, "newValue": forceMute])
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

  /** Empties all node-referencing properties */
  fileprivate func resetNodes() {
    nodes.removeAll()
    logDebug("nodes reset")
    if modified {
      logDebug("posting 'DidUpdate'")
      postNotification(name: .didUpdate, object: self, userInfo: nil)
      modified = false
    }
  }

  fileprivate var connectedEndPoints: Set<MIDIEndpointRef> = []

  /**
   connectNode:

   - parameter node: MIDINode
  */
  func connectNode(_ node: MIDINode) throws {
    guard connectedEndPoints ∌ node.endPoint else { throw MIDINodeDispatchError.NodeAlreadyConnected }
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
    connectedEndPoints.insert(node.endPoint)
  }

  /**
   disconnectNode:

   - parameter node: MIDINode
  */
  func disconnectNode(_ node: MIDINode) throws {
    guard connectedEndPoints ∋ node.endPoint else { throw MIDINodeDispatchError.NodeNotFound }
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    connectedEndPoints.remove(node.endPoint)
  }

  // MARK: - Loops

  /**
   addLoop:

   - parameter loop: Loop
  */
  func addLoop(_ loop: Loop) {
    guard loops[loop.identifier] == nil else { return }
    logDebug("adding loop: \(loop)")
    loops[loop.identifier] = loop
    addEvents(loop)
  }

  fileprivate var loops: [Loop.Identifier:Loop] = [:]

  // MARK: - MIDI events

  fileprivate var client  = MIDIClientRef()
  fileprivate var inPort  = MIDIPortRef()
  fileprivate var outPort = MIDIPortRef()

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafeMutablePointer<Void>
  */
  fileprivate func read(_ packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer?) {

    // Forward the packets to the instrument
    do {
      try MIDISend(outPort, instrument.endPoint, packetList)
        ➤ "Failed to forward packet list to instrument"
    } catch { logError(error) }

    // Check if we are recording, otherwise skip event processing
    guard recording else { return }

    eventQueue.async {
      [weak self, time = Sequencer.time.barBeatTime] in

      guard let packet = Packet(packetList: packetList) else { return }

      let event: MIDIEvent?
      switch packet.status {
        case 9:
          event = .channel(ChannelEvent(.noteOn, packet.channel, packet.note, packet.velocity, time))
        case 8:
          event = .channel(ChannelEvent(.noteOff, packet.channel, packet.note, packet.velocity, time))
        default:
          event = nil
      }
      if event != nil { self?.addEvent(event!) }
    }
  }

  /**
  dispatchEvent:

  - parameter event: MIDIEvent
  */
  override func dispatchEvent(_ event: MIDIEvent) {
      switch event {
        case .node(let nodeEvent):
          switch nodeEvent.data {
            case let .add(identifier, trajectory, generator):
              nodeManager.addNodeWithIdentifier(identifier.nodeIdentifier,
                                     trajectory: trajectory,
                                      generator: generator)
            case let .remove(identifier):
              do { try nodeManager.removeNodeWithIdentifier(identifier.nodeIdentifier) } catch { logError(error) }
          }
        case .meta(let metaEvent) where metaEvent.data == .endOfTrack:
          guard !recording && endOfTrack == metaEvent.time else { break }
          trackEnded = true
        default: break
      }

  }

  /**
  registrationTimesForAddedEvents:

  - parameter events: [MIDIEvent]

  - returns: [BarBeatTime]
  */
  override func registrationTimesForAddedEvents<S:Swift.Sequence>(_ events: S) -> [BarBeatTime]
    where S.Iterator.Element == MIDIEvent
  {
    return events.filter({ if case .node(_) = $0 { return true } else { return false } }).map({$0.time})
      + super.registrationTimesForAddedEvents(events)
  }

  /// The index for the track in the sequence's array of instrument tracks, or nil
  var index: Int? { return sequence.instrumentTracks.index(of: self) }

  // MARK: - Initialization

  /** initializeMIDIClient */
  fileprivate func initializeMIDIClient() throws {
    try MIDIClientCreateWithBlock("track \(instrument.bus)" as CFString, &client, nil)
      ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output" as CFString, &outPort)
      ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, name as CFString, &inPort, weakMethod(self, InstrumentTrack.read))
      ➤ "Failed to create in port"
  }

  /**
  initWithSequence:instrument:

  - parameter sequence: Sequence
  - parameter instrument: Instrument
  */
  init(sequence: Sequence, instrument: Instrument) throws {
    super.init(sequence: sequence)
    nodeManager = MIDINodeManager(owner: self)
    self.instrument = instrument
    instrument.track = self
    instrumentEvent = MetaEvent(.text(text: "instrument:\(instrument.soundSet.url.lastPathComponent)"))
    programEvent = ChannelEvent(.programChange, instrument.channel, instrument.program)
    color = TrackColor.nextColor

    initializeNotificationReceptionist()
    try initializeMIDIClient()
  }


  /**
   initWithSequence:grooveTrack:

   - parameter sequence: Sequence
   - parameter grooveTrack: GrooveTrack
  */
  init(sequence: Sequence, grooveTrack: GrooveTrack) throws {
    super.init(sequence: sequence)
    nodeManager = MIDINodeManager(owner: self)
    guard let instrument = Instrument(grooveTrack.instrument.jsonValue) else {
      throw Error.InstrumentInitializeFailure
    }
    instrument.track = self
    self.instrument = instrument
    color = grooveTrack.color

    name = grooveTrack.name
    var events: [MIDIEvent] = []
    for (_, node) in grooveTrack.nodes {
      events.append(.node(MIDINodeEvent(.add(identifier: node.identifier,
                                             trajectory: node.trajectory,
                                             generator: node.generator), node.addTime)))
      if let time = node.removeTime {
        events.append(.node(MIDINodeEvent(.remove(identifier: node.identifier), time)))
      }
    }
    addEvents(events)

    grooveTrack.loops.values.forEach { addLoop(Loop(grooveLoop: $0, track: self)) }

    initializeNotificationReceptionist()
    try initializeMIDIClient()
  }

  /**
  initWithSequence:trackChunk:

  - parameter sequence: Sequence
  - parameter trackChunk: MIDIFileTrackChunk
  */
  init(sequence: Sequence, trackChunk: MIDIFileTrackChunk) throws {
    super.init(sequence: sequence)
    nodeManager = MIDINodeManager(owner: self)

    addEvents(trackChunk.events)

    // Find the instrument event

    guard let instrumentEvent = instrumentEvent,
      case .text(var instrumentName) = instrumentEvent.data else
    {
      throw MIDIFileError(type: .fileStructurallyUnsound,
                          reason: "Instrument event must be a text event")
    }

    instrumentName = instrumentName[instrumentName.index(instrumentName.startIndex, offsetBy:11)|->]

    guard let url = Bundle.main.url(forResource: instrumentName, withExtension: nil) else {
      throw Error.InvalidSoundSetURL
    }

    let soundSet: SoundFont
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
    guard let programEvent = programEvent else {
      throw MIDIFileError(type: .missingEvent, reason: "Missing program change event")
    }

    let channel = programEvent.status.channel, program = programEvent.data1

    guard let instrument = try? Instrument(track: self,
                                           soundSet: soundSet,
                                           program: program,
                                           channel: channel) else
    {
      throw Error.InstrumentInitializeFailure
    }

    self.instrument = instrument
    color = TrackColor.nextColor

    initializeNotificationReceptionist()
    try initializeMIDIClient()
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
    case InstrumentInitializeFailure = "Failed to create instrument"
  }
}

// MARK: - Hashable
extension InstrumentTrack: Hashable { var hashValue: Int { return ObjectIdentifier(self).hashValue } }

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

