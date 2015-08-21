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

final class Track: Equatable {

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  // MARK: - Constant properties

  var instrument: Instrument { return bus.instrument }

  let bus: Bus
  let color: Color

  private var nodes: Set<MIDINode> = []
  private var client = MIDIClientRef()
  private var inPort = MIDIPortRef()
  private var outPort = MIDIPortRef()

  // MARK: - Editable properties

  lazy var label: String = {"bus \(self.bus.element)"}()

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
    MSLogDebug("track (\(label)) added node with source id \(ObjectIdentifier(node).uintValue)")
    try MIDIPortConnectSource(inPort, node.endPoint, nil) ➤ "Failed to connect to node \(node.name!)"
  }

  /**
  removeNode:

  - parameter node: MIDINode
  */
  func removeNode(node: MIDINode) throws {
    guard let node = nodes.remove(node) else { throw Error.NodeNotFound }
    MSLogDebug("track (\(label)) removed node with source id \(ObjectIdentifier(node).uintValue)")
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
    var packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
    packetPointer.initialize(packets.packet)

    for _ in 0 ..< packets.numPackets {

      let packet = packetPointer.memory

      let nodeIdentifier = nodeIdentifierFromPacket(packet)

      let message: String
      switch packet.length {
        case 1 where packet.data.0 == 0b1111_1000:
          message = "Timing Clock"
        case 11 where (0b1000_0000 ... 0b1000_1111).contains(packet.data.0):
          message = "Note off (ch: \(packet.data.0 & 0x0F); note: \(packet.data.1); velocity: \(packet.data.2))"
        case 11 where (0b1001_0000 ... 0b1001_1111).contains(packet.data.0):
          message = "Note on (ch: \(packet.data.0 & 0x0F); note: \(packet.data.1); velocity: \(packet.data.2))"
        default:
          message = "Unhandled message (status: \(String(packet.data.0, radix: 2)))"
      }

      backgroundDispatch{print("packet received (\(nodeIdentifier)) {" + "; ".join(
        "timeStamp: \(packet.timeStamp)",
        "length: \(packet.length)",
        " ".join(String(packet.data.0, radix: 16, uppercase: true),
                 String(packet.data.1, radix: 16, uppercase: true),
                 String(packet.data.2, radix: 16, uppercase: true)),
        message) + "}")}

      packetPointer = MIDIPacketNext(packetPointer)
    }
    
    do { try MIDISend(outPort, bus.instrument.endPoint, packetList) ➤ "Failed to forward packet list to instrument" }
    catch { logError(error) }
  }

  /**
  init:bus:

  - parameter i: Instrument
  - parameter b: AudioUnitElement
  */
  init(bus b: Bus) throws {
    bus = b
    color = Color.allCases[Int(bus.element) % 10]

    try MIDIClientCreateWithBlock("track \(bus.element)", &client, notify) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    try MIDIInputPortCreateWithBlock(client, label, &inPort, read) ➤ "Failed to create in port"
  }

  // MARK: - Enumeration for specifying the color attached to a `TrackType`
  enum Color: UInt32, EnumerableType {
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

    /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
    static let allCases: [Color] = [.Portica, .MonteCarlo, .FlamePea, .Crimson, .HanPurple,
                                    .MangoTango, .Viking, .Yellow, .Conifer, .Apache]
  }

}


func ==(lhs: Track, rhs: Track) -> Bool { return lhs.bus == rhs.bus }
