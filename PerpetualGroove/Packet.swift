//
//  Packet.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import MoonKit

struct Packet: CustomStringConvertible {
  let status: Byte
  let channel: Byte
  let note: Byte
  let velocity: Byte
  let identifier: UInt64

  var packetList: MIDIPacketList {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    let data: [Byte] = [status | channel, note, velocity] + identifier.bytes
    let timeStamp = Sequencer.time.ticks
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, data.count, data)
    return packetList
  }

  /**
  initWithStatus:channel:note:velocity:identifier:

  - parameter status: Byte
  - parameter channel: Byte
  - parameter note: Byte
  - parameter velocity: Byte
  - parameter identifier: Identifier
  */
  init(status: Byte, channel: Byte, note: Byte, velocity: Byte, identifier: UInt64) {
    self.status = status
    self.channel = channel
    self.note = note
    self.velocity = velocity
    self.identifier = identifier
  }

  /**
  initWithPacketList:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  */
  init?(packetList: UnsafePointer<MIDIPacketList>) {
    let packets = packetList.memory
    let packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
    packetPointer.initialize(packets.packet)
    guard packets.numPackets == 1 else { return nil }
    let packet = packetPointer.memory
    guard packet.length == UInt16(sizeof(Identifier.self) + 3) else { return nil }
    var data = packet.data
    status = data.0 >> 4
    channel = data.0 & 0xF
    note = data.1
    velocity = data.2
    identifier = UInt64(withUnsafePointer(&data) {
      UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>($0).advancedBy(3), count: sizeof(Identifier.self))
      })
  }

  var description: String { 
    return "; ".join(
      "{status: \(status)", 
      "channel: \(channel)", 
      "note: \(note)",
      "velocity: \(velocity)", 
      "identifier: \(identifier)}"
      )
  }
}
