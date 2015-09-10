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

final class Track: TrackType, Equatable {

  var description: String {
    var result = "Track(\(label)) {\n"
    result += "\tinstrument: \(instrument.description.indentedBy(4, true))\n"
    result += "\tcolor: \(color)\n\tevents: {\n"
    result += ",\n".join(events.map({$0.description.indentedBy(8)}))
    result += "\n\t}\n}"
    return result
  }

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  // MARK: - Constant properties

  let instrument: Instrument
  let color: Color

  private var nodes: Set<MIDINode> = []
  private var notes: Set<UInt> = []
  private var lastEvent: [UInt:MIDITimeStamp] = [:]
  private var client = MIDIClientRef()
  private var inPort = MIDIPortRef()
  private var outPort = MIDIPortRef()
  private let fileQueue: dispatch_queue_t
  let time = BarBeatTime(clockSource: Sequencer.clockSource)

  var recording = false

  private func appendEvent(var event: TrackEvent) {
    guard recording else { return }
    event.time = time.time
    events.append(event)
  }
  private(set) var events: [TrackEvent] = []

  var chunk: TrackChunk {
    var trackEvents = events
    trackEvents.insert(MetaEvent(.SequenceTrackName(name: label)), atIndex: 0)
    trackEvents.insert(instrument.event, atIndex: 1)
    trackEvents.insert(ChannelEvent(.ProgramChange, 0, instrument.program), atIndex: 2)
    trackEvents.append(MetaEvent(.EndOfTrack))
    return TrackChunk(events: trackEvents)
  }

  // MARK: - Editable properties

  private var _label: String?
  var label: String {
    get {
      guard _label == nil else { return _label! }
      _label = "BUS \(instrument.bus)"
      return _label!
    } set {
      _label = newValue
    }
  }

  var volume: Float { get { return instrument.node.volume } set { instrument.node.volume = (0 ... 1).clampValue(newValue) } }
  var pan: Float { get { return instrument.node.pan } set { instrument.node.pan = (-1 ... 1).clampValue(newValue) } }

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
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
    guard recording else { return }
    dispatch_async(fileQueue) {
      [unowned self, placement = node.placement] in
        self.appendEvent(MIDINodeEvent(.Add(identifier: identifier, placement: placement))
      )
    }
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
    try MIDIPortDisconnectSource(inPort, node.endPoint) ➤ "Failed to disconnect to node \(node.name!)"
    guard recording else { return }
    dispatch_async(fileQueue) {
      [unowned self] in self.appendEvent(MIDINodeEvent(.Remove(identifier: identifier)))
    }
  }

  /**
  Reconstructs the `uintValue` of an `ObjectIdentifier` using packet data bytes 4 through 11

  - parameter packet: MIDIPacket

  - returns: UInt?
  */
  private func nodeIdentifierFromPacket(var packet: MIDIPacket) -> UInt? {
    guard packet.length == 11 else { return nil }
    return UInt(withUnsafePointer(&packet.data) {
      Array(UnsafeMutableBufferPointer<Byte>(start: UnsafeMutablePointer<Byte>($0), count: 11)[3 ..< 11])
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
    
    dispatch_async(fileQueue) {
      [unowned self] in
      let packets = packetList.memory
      let packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
      packetPointer.initialize(packets.packet)
      guard packets.numPackets == 1 else { fatalError("Packets must be sent to track one at a time") }

      let packet = packetPointer.memory
      guard let identifier = self.nodeIdentifierFromPacket(packet) else { return }
      self.lastEvent[identifier] = packet.timeStamp
      let ((status, channel), note, velocity) = ((packet.data.0 >> 4, packet.data.0 & 0xF), packet.data.1, packet.data.2)
      let event: TrackEvent?
      switch status {
        case 9:  event = ChannelEvent(.NoteOn, channel, note, velocity)
        case 8:  event = ChannelEvent(.NoteOff, channel, note, velocity)
        default: event = nil
      }
      if event != nil { self.appendEvent(event!) }
    }
  }

  /**
  initWithBus:track:

  - parameter b: Bus
  */
  init(instrument i: Instrument) throws {
    instrument = i
    color = Color.allCases[Sequencer.sequence.tracks.count % 10]
    fileQueue = serialQueueWithLabel("BUS \(instrument.bus)", qualityOfService: QOS_CLASS_BACKGROUND)
    try MIDIClientCreateWithBlock("track \(instrument.bus)", &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    let label = self.label ?? "BUS \(instrument.bus)"
    try MIDIInputPortCreateWithBlock(client, label, &inPort, read) ➤ "Failed to create in port"
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
        case .White:      return "White"
        case .Portica:    return "Portica"
        case .MonteCarlo: return "MonteCarlo"
        case .FlamePea:   return "FlamePea"
        case .Crimson:    return "Crimson"
        case .HanPurple:  return "HanPurple"
        case .MangoTango: return "MangoTango"
        case .Viking:     return "Viking"
        case .Yellow:     return "Yellow"
        case .Conifer:    return "Conifer"
        case .Apache:     return "Apache"
      }
    }

    /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
    static let allCases: [Color] = [.Portica, .MonteCarlo, .FlamePea, .Crimson, .HanPurple,
                                    .MangoTango, .Viking, .Yellow, .Conifer, .Apache]
  }

}


func ==(lhs: Track, rhs: Track) -> Bool { return lhs.instrument == rhs.instrument }

