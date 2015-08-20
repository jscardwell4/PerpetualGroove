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

final class Track: Equatable {

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  // MARK: - Constant properties

  var instrument: Instrument { return bus.instrument }

  let bus: Bus
  let color: Color

  private var client = MIDIClientRef()
  private(set) var inPort = MIDIEndpointRef()
  private var outPort = MIDIPortRef()

  // MARK: - Editable properties

  lazy var label: String = {"bus \(self.bus.element)"}()

  var volume: Float { get { return bus.volume } set { bus.volume = newValue } }
  var pan: Float { get { return bus.pan } set { bus.pan = newValue } }

  /**
  notify:

  - parameter notification: UnsafePointer<MIDINotification>
  */
  private func notify(notification: UnsafePointer<MIDINotification>) {
    var memory = notification.memory
    switch memory.messageID {
      case .MsgSetupChanged:
        MSLogDebug("received notification that the midi setup has changed")
      case .MsgObjectAdded:
        // MIDIObjectAddRemoveNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIObjectAddRemoveNotification>.self).memory
          MSLogDebug("received notifcation that an object has been added…\n\t" + "\n\t".join(
            "parent = \(message.parent)",
            "parentType = \(message.parentType)",
            "child = \(message.childType)",
            "childType = \(message.childType)"
          ))
        }
      case .MsgObjectRemoved:
        // MIDIObjectAddRemoveNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIObjectAddRemoveNotification>.self).memory
          MSLogDebug("received notifcation that an object has been removed…\n\t" + "\n\t".join(
            "parent = \(message.parent)",
            "parentType = \(message.parentType)",
            "child = \(message.childType)",
            "childType = \(message.childType)"
            ))
        }
        break
      case .MsgPropertyChanged:
        // MIDIObjectPropertyChangeNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIObjectPropertyChangeNotification>.self).memory
          MSLogDebug("object: \(message.object); objectType: \(message.objectType); propertyName: \(message.propertyName)")
        }
      case .MsgThruConnectionsChanged:
        MSLogDebug("received notification that midi thru connections have changed")
      case .MsgSerialPortOwnerChanged:
        MSLogDebug("received notification that serial port owner has changed")
      case .MsgIOError:
        // MIDIIOErrorNotification
        withUnsafePointer(&memory) {
          let message = unsafeBitCast($0, UnsafePointer<MIDIIOErrorNotification>.self).memory
          logError(error(message.errorCode, "received notifcation of io error"))
        }
    }
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
      let (status, data1, data2) = (packet.data.0, packet.data.1, packet.data.2)
      let rawStatus = status & 0xF0 // without channel
      let channel = status & 0x0F

      let message: String
      switch rawStatus {
        case 0x80: message = "Note off. Channel \(channel) note \(data1) velocity \(data2)"
        case 0x90: message = "Note on. Channel \(channel) note \(data1) velocity \(data2)"
        case 0xA0: message = "Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(data1) pressure \(data2)"
        case 0xB0: message = "Control Change. Channel \(channel) controller \(data1) value \(data2)"
        case 0xC0: message = "Program Change. Channel \(channel) program \(data1)"
        case 0xD0: message = "Channel Pressure (Aftertouch). Channel \(channel) pressure \(data1)"
        case 0xE0: message = "Pitch Bend Change. Channel \(channel) lsb \(data1) msb \(data2)"
        default:   message = "Unhandled message \(status)"
      }

      MSLogDebug("packet received { timeStamp: \(packet.timeStamp); length: \(packet.length); "
                 + String(format: "0x%X 0x%X 0x%X;", packet.data.0, packet.data.1, packet.data.2) + " \(message)}")

      packetPointer = MIDIPacketNext(packetPointer)
    }

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
    try MIDIDestinationCreateWithBlock(client, label, &inPort, read) ➤ "Failed to create in port"
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
