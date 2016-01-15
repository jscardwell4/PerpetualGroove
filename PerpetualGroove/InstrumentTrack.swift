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

final class InstrumentTrack: Track, MIDINodeDispatch {

  // MARK: - Monitoring state changes

  /// Holds the current state of the node
  private var state: State = [] {
    didSet {
      guard state != oldValue else { return }

      switch state ⊻ oldValue {

        case [.Soloing]:
          Notification.SoloStatusDidChange.post(object: self, userInfo: [.OldValue: !solo, .NewValue: solo])
          if state ⚭ [.ExclusiveMute, .InclusiveMute] {
            Notification.MuteStatusDidChange.post(object: self, userInfo: [.OldValue: !mute, .NewValue: mute])
          }

        case [.ExclusiveMute], [.InclusiveMute]:
          let oldValue = oldValue ⚭ [.ExclusiveMute, .InclusiveMute] && oldValue ∌ .Soloing
          let newValue = state    ⚭ [.ExclusiveMute, .InclusiveMute] && state    ∌ .Soloing
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

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.SequencerContext
    return receptionist
  }()

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard receptionist.count == 0 else { return }

    receptionist.observe(Sequencer.Notification.DidReset,
                    from: Sequencer.self,
                callback: weakMethod(self, InstrumentTrack.didReset))

    receptionist.observe(Sequence.Notification.SoloCountDidChange,
                    from: sequence,
                callback: weakMethod(self, InstrumentTrack.soloCountDidChange))

    receptionist.observe(Sequencer.Notification.DidJog,
                    from: Sequencer.self,
                callback: weakMethod(self, InstrumentTrack.didJog))

    receptionist.observe(Instrument.Notification.PresetDidChange,
                    from: instrument,
                callback: weakMethod(self, InstrumentTrack.didChangePreset))
    receptionist.observe(Instrument.Notification.SoundSetDidChange,
                    from: instrument,
                callback: weakMethod(self, InstrumentTrack.didChangePreset))
}

  /**
   didChangePreset:

   - parameter notification: NSNotification
  */
  private func didChangePreset(notification: NSNotification) {
    Track.Notification.DidUpdate.post(object: self)
  }

  /**
  didReset:

  - parameter notification: NSNotification
  */
  private func didReset(notification: NSNotification) { resetNodes() }

  /**
  soloCountDidChange:

  - parameter notification: NSNotification
  */
  private func soloCountDidChange(notification: NSNotification) {
    guard let newCount = notification.newCount else { return }
         if state !⚭ [.Soloing, .InclusiveMute] && newCount > 0       { state ∪= .InclusiveMute }
    else if state ∌ .Soloing && state ∋ .InclusiveMute && newCount == 0 { state ⊻= .InclusiveMute }
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
    guard state ∋ .TrackEnded, let jogTime = notification.jogTime where jogTime < endOfTrack else { return }
    state ⊻= .TrackEnded
  }

  // MARK: - MIDI file related properties and methods

  /** validateEvents */
  override func validateEvents(inout container: MIDIEventContainer) {
    instrumentEvent = MetaEvent(.Text(text: "instrument:\(instrument.soundSet.url.lastPathComponent!)"))
    programEvent = ChannelEvent(.ProgramChange, instrument.channel, instrument.program)
    super.validateEvents(&container)
  }

  /**
   addEvents:

   - parameter events: [MIDIEvent]
  */
  func addEvents<S:SequenceType where S.Generator.Element == MIDIEvent>(events: S) {
    var filteredEvents: [MIDIEvent] = []
    for event in events {
      switch event {
        case .Meta(let metaEvent):
          switch metaEvent.data {
            case .Text(let text) where text.hasPrefix("instrument:"): instrumentEvent = metaEvent
            default: filteredEvents.append(event)
          }
        case .Channel(let channelEvent) where channelEvent.status.type == .ProgramChange: programEvent = channelEvent
        default: filteredEvents.append(event)
      }
    }
    modified = modified || filteredEvents.count > 0
    super.addEvents(filteredEvents)
  }

  private var instrumentEvent: MetaEvent!
  private var programEvent: ChannelEvent!

  typealias Identifier = MIDINodeEvent.Identifier
  typealias NodeIdentifier = MIDINode.Identifier
  typealias EventData = MIDINodeEvent.Data

  override var headEvents: [MIDIEvent] {
    return super.headEvents + [.Meta(instrumentEvent), .Channel(programEvent)]
  }

  // MARK: - Track properties

  private(set) var instrument: Instrument!
  var color: TrackColor = .White

  var recording: Bool { return Sequencer.mode == .Default && MIDIPlayer.currentDispatch === self }

  var nextNodeName: String { return "\(displayName) \(nodes.count + 1)" }

  override var displayName: String { guard name.isEmpty else { return name }; return instrument?.preset.name ?? "" }

  var mute: Bool {
    get { return state ⚭ [.ExclusiveMute, .InclusiveMute] && state ∌ .Soloing}
    set { guard (state ∋ .ExclusiveMute) != newValue else { return }; state ⊻= .ExclusiveMute }
  }

  var solo: Bool {
    get { return state ∋ .Soloing }
    set { guard solo != newValue else { return }; state ⊻= .Soloing }
  }

  private var _volume: Float = 1
  var volume: Float { get { return instrument.volume } set { instrument.volume = newValue } }

  var pan: Float { get { return instrument.pan } set { instrument.pan = newValue } }

  // MARK: - Managing MIDI nodes

  /// Whether new events have been created and addd to the track
  private var modified = false

  /// The set of `MIDINode` objects that have been added to the track
  var nodes: OrderedSet<MIDINodeRef> = []

  /** Empties all node-referencing properties */
  private func resetNodes() {
    nodes.removeAll()
    logDebug("nodes reset")
    if modified {
      logDebug("posting 'DidUpdate'")
      Track.Notification.DidUpdate.post(object: self)
      modified = false
    }
  }

  private var connectedEndPoints: Set<MIDIEndpointRef> = []

  /**
   connectNode:

   - parameter node: MIDINode
  */
  func connectNode(node: MIDINode) throws {
    guard connectedEndPoints ∌ node.endPoint else { throw MIDINodeDispatchError.NodeAlreadyConnected }
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
    connectedEndPoints.insert(node.endPoint)
  }

  /**
   disconnectNode:

   - parameter node: MIDINode
  */
  func disconnectNode(node: MIDINode) throws {
    guard connectedEndPoints ∋ node.endPoint else { throw MIDINodeDispatchError.NodeNotFound }
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    connectedEndPoints.remove(node.endPoint)
  }

  // MARK: - Loops

  /**
   addLoop:

   - parameter loop: Loop
  */
  func addLoop(loop: Loop) {
    guard loops[loop.identifier] == nil else { return }
    logDebug("adding loop: \(loop)")
    loops[loop.identifier] = loop
    addEvents(loop)
  }

  private var loops: [Loop.Identifier:Loop] = [:]

  // MARK: - MIDI events

  private var client  = MIDIClientRef()
  private var inPort  = MIDIPortRef()
  private var outPort = MIDIPortRef()

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
      [weak self, time = Sequencer.time.barBeatTime] in

      guard let packet = Packet(packetList: packetList) else { return }

      let event: MIDIEvent?
      switch packet.status {
        case 9:  event = .Channel(ChannelEvent(.NoteOn, packet.channel, packet.note, packet.velocity, time))
        case 8:  event = .Channel(ChannelEvent(.NoteOff, packet.channel, packet.note, packet.velocity, time))
        default: event = nil
      }
      if event != nil { self?.addEvent(event!) }
    }
  }

  /**
  dispatchEvent:

  - parameter event: MIDIEvent
  */
  override func dispatchEvent(event: MIDIEvent) {
      switch event {
        case .Node(let nodeEvent):
          switch nodeEvent.data {
            case let .Add(identifier, trajectory, generator):
              addNodeWithIdentifier(identifier.nodeIdentifier, trajectory: trajectory, generator: generator)
            case let .Remove(identifier):
              do { try removeNodeWithIdentifier(identifier.nodeIdentifier) } catch { logError(error) }
          }
        case .Meta(let metaEvent) where metaEvent.data == .EndOfTrack:
          guard !recording && endOfTrack == metaEvent.time else { break }
          state.insert(.TrackEnded)
        default: break
      }

  }

  /**
  registrationTimesForAddedEvents:

  - parameter events: [MIDIEvent]

  - returns: [BarBeatTime]
  */
  override func registrationTimesForAddedEvents<S:SequenceType
    where S.Generator.Element == MIDIEvent>(events: S) -> [BarBeatTime]
  {
    return events.filter({ if case .Node(_) = $0 { return true } else { return false } }).map({$0.time})
      + super.registrationTimesForAddedEvents(events)
  }

  /// The index for the track in the sequence's array of instrument tracks, or nil
  var index: Int? { return sequence.instrumentTracks.indexOf(self) }

  // MARK: - Initialization

  /** initializeMIDIClient */
  private func initializeMIDIClient() throws {
    try MIDIClientCreateWithBlock("track \(instrument.bus)", &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, name, &inPort, weakMethod(self, InstrumentTrack.read))
      ➤ "Failed to create in port"
  }

  /**
  initWithSequence:instrument:

  - parameter sequence: Sequence
  - parameter instrument: Instrument
  */
  init(sequence: Sequence, instrument: Instrument) throws {
    super.init(sequence: sequence)
    self.instrument = instrument
    instrument.track = self
    eventQueue.name = "BUS \(instrument.bus)"
    instrumentEvent = MetaEvent(.Text(text: "instrument:\(instrument.soundSet.url.lastPathComponent!)"))
    programEvent = ChannelEvent(.ProgramChange, instrument.channel, instrument.program)
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
    guard let instrument = Instrument(grooveTrack.instrument.jsonValue) else { throw Error.InstrumentInitializeFailure }
    instrument.track = self
    self.instrument = instrument
    eventQueue.name = "BUS \(instrument.bus)"
    color = grooveTrack.color

    name = grooveTrack.name
    var events: [MIDIEvent] = []
    for (_, node) in grooveTrack.nodes {
      events.append(.Node(MIDINodeEvent(.Add(identifier: node.identifier,
                                             trajectory: node.trajectory,
                                             generator: node.generator), node.addTime)))
      if let time = node.removeTime {
        events.append(.Node(MIDINodeEvent(.Remove(identifier: node.identifier), time)))
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

    addEvents(trackChunk.events)

    // Find the instrument event

    guard let instrumentEvent = instrumentEvent, case .Text(var instrumentName) = instrumentEvent.data else {
      throw MIDIFileError(type: .FileStructurallyUnsound, reason: "Instrument event must be a text event")
    }

    instrumentName = instrumentName[instrumentName.startIndex.advancedBy(11)..<]

    guard let url = NSBundle.mainBundle().URLForResource(instrumentName, withExtension: nil) else {
      throw Error.InvalidSoundSetURL
    }

    let soundSet: SoundSetType
    do {
      soundSet = try EmaxSoundSet(url: url)
    } catch {
      do { soundSet = try SoundSet(url: url) } catch { logError(error); throw Error.SoundSetInitializeFailure }
    }

    // Find the program change event
    guard let programEvent = programEvent else {
      throw MIDIFileError(type: .MissingEvent, reason: "Missing program change event")
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
    eventQueue.name = "BUS \(instrument.bus)"
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
  enum Error: String, ErrorType, CustomStringConvertible {
    case SoundSetInitializeFailure = "Failed to create sound set"
    case InvalidSoundSetURL = "Failed to resolve sound set url"
    case InstrumentInitializeFailure = "Failed to create instrument"
  }
}

// MARK: - Notifications
extension InstrumentTrack {
  enum Notification: String, NotificationType, NotificationNameType {
    enum Key: String, KeyType { case OldValue, NewValue }
    case MuteStatusDidChange, SoloStatusDidChange
  }
}

// MARK: - State
extension InstrumentTrack {
  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Soloing       = State(rawValue: 0b0000_0010)
    static let InclusiveMute = State(rawValue: 0b0000_0100)
    static let ExclusiveMute = State(rawValue: 0b0000_1000)
    static let TrackEnded    = State(rawValue: 0b0001_0000)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if self ∋ .Soloing       { flagStrings.append("Soloing")       }
      if self ∋ .InclusiveMute { flagStrings.append("InclusiveMute") }
      if self ∋ .ExclusiveMute { flagStrings.append("ExclusiveMute") }
      if self ∋ .TrackEnded    { flagStrings.append("TrackEnded")    }
      result += ", ".join(flagStrings)
      result += "]"
      return result
    }
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

