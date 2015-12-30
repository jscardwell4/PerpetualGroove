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

final class InstrumentTrack: Track {

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
}

  /**
   didChangePreset:

   - parameter notification: NSNotification
  */
  private func didChangePreset(notification: NSNotification) {
    guard let oldPresetName = notification.oldPresetName, newPresetName = notification.newPresetName
      where oldPresetName == super.name && oldPresetName != newPresetName else { return }
    super.name = newPresetName
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
  override func addEvents(events: [MIDIEvent]) {
    var filteredEvents: [MIDIEvent] = []
    for event in events {
      if let event = event as? MetaEvent, case .Text(let text) = event.data where text.hasPrefix("instrument:") {
        instrumentEvent = event
      } else if let event = event as? ChannelEvent where event.status.type == .ProgramChange {
        programEvent = event
      } else { filteredEvents.append(event) }
    }
    super.addEvents(filteredEvents)
  }

  private var instrumentEvent: MetaEvent!
  private var programEvent: ChannelEvent!

  override var headEvents: [MIDIEvent] {
    return super.headEvents + [instrumentEvent as MIDIEvent, programEvent as MIDIEvent]
  }

  // MARK: - Track properties

  private(set) var instrument: Instrument!
  var color: TrackColor = .White

  override var name: String {
    get {
      if super.name.isEmpty, let instrument = instrument { return instrument.preset.name }
      return super.name
    }
    set { super.name = newValue }
  }

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

  typealias Identifier = MIDINode.Identifier

  /// Whether new events have been created and addd to the track
  private var modified = false

  /// The identifier parsed from a file awaiting the identifier of its generated node
  private var pendingID: Identifier?

  /// The set of `MIDINode` objects that have been added to the track
  private(set) var nodes: OrderedSet<Weak<MIDINode>> = []

  /// Index that maps the identifiers parsed from a file to the identifiers assigned to the generated nodes
  private var fileIDToNodeID: [Identifier:Identifier] = [:]

  /** Empties all node-referencing properties */
  private func resetNodes() {
    pendingID = nil
    nodes.removeAll()
    fileIDToNodeID.removeAll()
    logDebug("nodes reset")
    if modified {
      logDebug("posting 'DidUpdateEvents'")
      Track.Notification.DidUpdateEvents.post(object: self)
      modified = false
    }
  }

  /**
  addNode:

  - parameter node: MIDINode
  */
  func addNode(node: MIDINode) throws {

    // Insert the node into our set
    nodes.append(Weak(node))
    logDebug("adding node \(node.name!) (\(node.identifier))")

    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"

    Notification.DidAddNode.post(object: self)

    if let pendingIdentifier = pendingID {
      fileIDToNodeID[pendingIdentifier] = node.identifier
      self.pendingID = nil
    } else {

      guard recording else { logDebug("not recording…skipping event creation"); return }

      eventQueue.addOperationWithBlock {
        [time = Sequencer.time.time, unowned node, weak self] in
        let event = MIDINodeEvent(.Add(identifier: node.identifier,
                                       trajectory: node.initialSnapshot.trajectory,
                                       attributes: node.noteGenerator),
                                  time)
        self?.addEvent(event)
        self?.modified = true
      }
    }
  }

  /**
  addNodeWithIdentifier:trajectory:attributes:texture:

  - parameter identifier: NodeIdentifier
  - parameter trajectory: Trajectory
  - parameter generator: MIDINoteGenerator
  - parameter texture: MIDINode.TextureType
  */
  private func addNodeWithIdentifier(identifier: Identifier,
                           trajectory: Trajectory,
                          generator: MIDINoteGenerator)
  {
    logDebug("placing node with identifier \(identifier), trajectory \(trajectory), attributes \(generator)")

    // Make sure a node hasn't already been place for this identifier
    guard fileIDToNodeID[identifier] == nil else { return }

    // Make sure there is not already a pending trajectory
    guard pendingID == nil else { fatalError("already have an identifier pending: \(pendingID!)") }

    // Store the identifier
    pendingID = identifier

    // Place a node
    MIDIPlayer.placeNew(trajectory, targetTrack: self, generator: generator)
  }

  /**
  removeNodeWithIdentifier:

  - parameter identifier: NodeIdentifier
  */
  private func removeNodeWithIdentifier(identifier: Identifier) {
    logDebug("removing node with identifier \(identifier)")
    guard let mappedIdentifier = fileIDToNodeID[identifier] else {
      fatalError("trying to remove node for unmapped identifier \(identifier)")
    }
    guard let idx = nodes.indexOf({$0.reference?.identifier == mappedIdentifier}), node = nodes[idx].reference else {
      fatalError("failed to find node with mapped identifier \(mappedIdentifier)")
    }

    do {
      try removeNode(node)
      MIDIPlayer.removeNode(node)
      fileIDToNodeID[identifier] = nil
    } catch {
      logError(error)
    }
  }

  /**
  removeNode:

  - parameter node: MIDINode
  */
  func removeNode(node: MIDINode) throws { try _removeNode(node, delete: false) }

  func deleteNode(node: MIDINode) throws { try _removeNode(node, delete: true) }

  /**
   _removeNode:delete:

   - parameter node: MIDINode
   - parameter delete: Bool
  */
  private func _removeNode(node: MIDINode, delete: Bool) throws {
    guard let idx = nodes.indexOf({$0.reference == node}),
      node = nodes.removeAtIndex(idx).reference else { throw Error.NodeNotFound }
    
    let identifier = Identifier(ObjectIdentifier(node).uintValue)
    logDebug("removing node \(node.name!) \(identifier)")

    node.sendNoteOff()
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    Notification.DidRemoveNode.post(object: self)

    switch delete {
      case true:
        eventContainer.removeEventsMatching { ($0 as? MIDINodeEvent)?.identifier == identifier }
      case false:
        guard recording else { logDebug("not recording…skipping event creation"); return }
        eventQueue.addOperationWithBlock {
          [time = Sequencer.time.time, weak self] in
          self?.addEvent(MIDINodeEvent(.Remove(identifier: identifier), time))
        }
    }
  }

  /** stopNodes */
  private func stopNodes() { nodes.forEach {$0.reference?.fadeOut()}; logDebug("nodes stopped") }

  /** startNodes */
  private func startNodes() { nodes.forEach {$0.reference?.fadeIn()}; logDebug("nodes started") }

  // MARK: - Loops

  /**
   insertLoop:

   - parameter loop: Loop
  */
  func insertLoop(loop: Loop) { addEvents(Array(loop)) }

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
      [weak self, time = Sequencer.time.time] in

      guard let packet = Packet(packetList: packetList) else { return }

      let event: MIDIEvent?
      switch packet.status {
        case 9:  event = ChannelEvent(.NoteOn, packet.channel, packet.note, packet.velocity, time)
        case 8:  event = ChannelEvent(.NoteOff, packet.channel, packet.note, packet.velocity, time)
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
        case let nodeEvent as MIDINodeEvent:
          switch nodeEvent.data {
            case let .Add(i, p, a):       addNodeWithIdentifier(i, trajectory: p, generator: a)
            case let .Remove(identifier): removeNodeWithIdentifier(identifier)
          }
        case let metaEvent as MetaEvent where metaEvent.data == .EndOfTrack:
          guard !recording && endOfTrack == metaEvent.time else { break }
          state.insert(.TrackEnded)
        default: break
      }

  }

  /**
  registrationTimesForAddedEvents:

  - parameter events: [MIDIEvent]

  - returns: [CABarBeatTime]
  */
  override func registrationTimesForAddedEvents(events: [MIDIEvent]) -> [CABarBeatTime] {
    return events.filter({$0 is MIDINodeEvent}).map({$0.time}) + super.registrationTimesForAddedEvents(events)
  }

  /// The index for the track in the sequence's array of instrument tracks, or nil
  var index: Int? { return sequence.instrumentTracks.indexOf(self) }

  // MARK: - Initialization

  /** initializeMIDIClient */
  private func initializeMIDIClient() throws {
    try MIDIClientCreateWithBlock("track \(instrument.bus)", &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, name, &inPort, weakMethod(self, InstrumentTrack.read)) ➤ "Failed to create in port"
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

    guard let instrumentMaybe = try? Instrument(track: self,
                                                soundSet: soundSet,
                                                program: program,
                                                channel: channel) else
    {
      throw Error.InstrumentInitializeFailure
    }

    instrument = instrumentMaybe
    eventQueue.name = "BUS \(instrument.bus)"

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

