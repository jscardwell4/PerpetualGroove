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

// TODO: Review file

extension MIDIPacketList: Swift.Sequence {

  public func makeIterator() -> AnyIterator<MIDIPacket> {
    var iterator: MIDIPacket?
    var nextIndex: UInt32 = 0

    return AnyIterator {
      if ({let i = nextIndex; nextIndex += 1; return i}()) >= self.numPackets { return nil }
      if iterator == nil { iterator = self.packet }
      else { iterator = withUnsafePointer(to: &iterator!) { MIDIPacketNext($0).pointee } }
      return iterator
    }
  }

}

struct Packet {

  let status: Byte
  let channel: Byte
  let note: Byte
  let velocity: Byte
  let identifier: UInt64

  var packetList: MIDIPacketList {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    let size = MemoryLayout<UInt32>.size + MemoryLayout<MIDIPacket>.size
    let data: [Byte] = [status | channel, note, velocity] + identifier.bytes
    let timeStamp = Time.current.ticks
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, data.count, data)
    return packetList
  }

  init(status: Byte, channel: Byte, note: Byte, velocity: Byte, identifier: UInt64) {
    self.status = status
    self.channel = channel
    self.note = note
    self.velocity = velocity
    self.identifier = identifier
  }

  init?(packetList: UnsafePointer<MIDIPacketList>) {
    let packet = packetList.pointee.packet
    guard packet.length == UInt16(MemoryLayout<Identifier>.size + 3) else { return nil }
    var data = packet.data
    status = data.0 >> 4
    channel = data.0 & 0xF
    note = data.1
    velocity = data.2
    identifier = UInt64(withUnsafePointer(to: &data) {
      $0.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<Identifier>.size) {
        UnsafeBufferPointer<Byte>(start: $0.advanced(by: 3), count: MemoryLayout<Identifier>.size)
      }
    })
  }

}

extension Packet: CustomStringConvertible {

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
