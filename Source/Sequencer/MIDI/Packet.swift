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

/// To make iterating the packets in a packet list a little easier, `MIDIPacketList` is 
/// extended to conform with `Swift.Sequence`.
extension MIDIPacketList: Swift.Sequence {

  /// Returns an iterator over the packets contained by the packet list.
  public func makeIterator() -> AnyIterator<MIDIPacket> {

    // Create a variable for holding iterated packets.
    var iterator: MIDIPacket?

    // Create a variable for holding the position of the next iteration.
    var nextIndex: UInt32 = 0

    return AnyIterator {

      // Check that the next iteration does not surpass the total number of packets.
      guard nextIndex + 1 <= self.numPackets else { return nil }

      defer {

        // Advance the postion.
        nextIndex = nextIndex &+ 1

      }

      // Check whether this is the first iteration.
      if iterator == nil {

        // Update `iterator` with the first packet in the list.
        iterator = self.packet

      } else {

        // Update `iterator` with the next packet in the list.
        iterator = MIDIPacketNext(&iterator!).pointee

      }

      return iterator

    }

  }

}

/// A simple data structure for MIDI packet that contains a MIDI note event. For interfacing
/// with the `CoreMIDI` API, `Packet` converts to and from a `MIDIPacketList`.
struct Packet: CustomStringConvertible {

  /// The four most significant bits of the packet's first byte of data shifted right by 
  /// `4`. This value represents a MIDI status.
  let status: UInt8

  /// The four least significant bits of the packet's first byte of data. This value
  /// represents a MIDI channel value.
  let channel: UInt8

  /// The packet's second byte of data. This value represents a MIDI note value.
  let note: UInt8

  /// The packet's third byte of data. This value represents a MIDI velocity value.
  let velocity: UInt8

  /// The packet's last four bytes of data. This value represents an identifier.
  let identifier: UInt64

  /// A new `MIDIPacketList` containing a single `MIDIPacket` composed of the packet's 
  /// properties with following order: (`status`, `channel`), `note`, `velocity`,
  /// `identifier`. The `MIDIPacket` is timestamped using the total elapsed ticks of the
  /// current instance of `Time`. Therefore, to be of much use, this property is meant to be
  /// accessed with a transport running as a means of capturing a MIDI event in the form of
  /// a `MIDIPacketList`.
  var packetList: MIDIPacketList {

    // Create the list.
    var packetList = MIDIPacketList()

    // Initialize the list, receiving a pointer to the first packet in the list.
    let packet = MIDIPacketListInit(&packetList)

    // How was this determined to be the calculated size for the packet list?
    let size = MemoryLayout<UInt32>.size + MemoryLayout<MIDIPacket>.size

    // Get the data for the packet as an array of bytes.
    let data: [UInt8] = [status | channel, note, velocity] + identifier.bytes

    // Get the time for the event.
    let timeStamp = Time.current.ticks

    // Add a packet using `timeStamp` and `data`.
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, data.count, data)

    // Return the packet list with the single packet.
    return packetList

  }

  /// Initializing with values for each property.
  init(status: UInt8, channel: UInt8, note: UInt8, velocity: UInt8, identifier: UInt64) {

    // Assign parameter values to the corresponding property values.
    self.status = status
    self.channel = channel
    self.note = note
    self.velocity = velocity
    self.identifier = identifier

  }

  /// Initializing with a pointer to a packet list.
  init?(packetList: UnsafePointer<MIDIPacketList>) {

    // Get the first packet in the list.
    let packet = packetList.pointee.packet

    // Check that the packet holds correct number of bytes for an instance of `Packet`.
    guard packet.length == UInt16(MemoryLayout<UInt64>.size + 3) else { return nil }

    // Shift the first byte of data right by four to initialize `status`.
    status = packet.data.0 >> 4

    // Mask the least significant four bits of the first byte of data to initialize 
    // `channel`.
    channel = packet.data.0 & 0xF

    // Initialize `note` using the second byte of data.
    note = packet.data.1

    // Initialize `velocity` using the third byte of data.
    velocity = packet.data.2

    // Initialize `identifier` using the fourth, fifth, sixth, and seventh bytes of data.
    identifier = UInt64(bytes: [packet.data.3, packet.data.4, packet.data.5, packet.data.6])

  }

  var description: String { 

    // Return a list of property values separated with '; ' and wrapped by curly brackets.
    return [
      "{status: \(status)",
      "channel: \(channel)",
      "note: \(note)",
      "velocity: \(velocity)",
      "identifier: \(identifier)}"
      ].joined(separator: "; ")

  }

}
