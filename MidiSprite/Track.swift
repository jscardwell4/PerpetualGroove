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
  private let fileQueue: dispatch_queue_t

  private(set) var events: [TrackEvent] = []

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
    logInfo("track (\(label)) added node with source id \(identifier)")
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

  - returns: UInt?
  */
  private func nodeIdentifierFromPacket(packet: MIDIPacket) -> UInt? {
    guard packet.length == 11 else { return nil }

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
    guard let identifier = nodeIdentifierFromPacket(packet) where lastEvent[identifier] != packet.timeStamp else { return }
    let ((status, channel), note, velocity) = ((packet.data.0 >> 4, packet.data.0 & 0xF), packet.data.1, packet.data.2)
    switch status {
      case 9: events.append(ChannelEvent.noteOnEvent(packet.timeStamp, channel: channel, note: note, velocity: velocity))
      case 8: events.append(ChannelEvent.noteOffEvent(packet.timeStamp, channel: channel, note: note, velocity: velocity))
      default: break
    }
    lastEvent[identifier] = packet.timeStamp
    forwardPackets(packetList)
  }

  /**
  forwardPackets:

  - parameter packets: UnsafePointer<MIDIPacketList>
  */
  private func forwardPackets(packets: UnsafePointer<MIDIPacketList>) {
    do { try MIDISend(outPort, bus.instrument.endPoint, packets) ➤ "Failed to forward packet list to instrument" }
    catch { logError(error) }
  }

  /** Generates a MIDI file chunk from current track data */
  var chunk: TrackChunk {
    let nameEvent: TrackEvent = MetaEvent(deltaTime: .Zero, metaEventData: .SequenceTrackName(label))
    let endEvent: TrackEvent  = MetaEvent(deltaTime: VariableLengthQuantity(Sequencer.currentTime), metaEventData: .EndOfTrack)
    return TrackChunk(data: TrackChunkData(events: [nameEvent] + events + [endEvent]))
  }

  /**
  initWithBus:track:

  - parameter b: Bus
  */
  init(bus b: Bus) throws {
    bus = b
    color = Color.allCases[Int(bus.element) % 10]
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

}


func ==(lhs: Track, rhs: Track) -> Bool { return lhs.bus == rhs.bus }

