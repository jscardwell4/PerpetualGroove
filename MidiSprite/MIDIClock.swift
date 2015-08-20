//
//  MIDIClock.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

/** A class capable of keeping time for MIDI events */
class MIDIClock {

  var beatsPerMinute: Double { didSet { initTempo() } }
  static let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)

  /** initTempo */
  private func initTempo() {
    // Number of ticks between clock's. Round the nTicks to avoid 'jitter' in the sound
    nTicks = UInt64(Double(ticksPerSecond) / (beatsPerMinute * 24 / 60)) & ~0xF
  }

  /** start */
  func start() {
    guard !timer.running else { return }
    clockTimeStamp = mach_absolute_time()
    timer.start()
  }

  /** stop */
  func stop() {
    guard timer.running else { return }
    timer.stop()
  }

  private let timer: Timer

  private var nTicks: UInt64 = 0 { didSet { timer.interval = nanosecondsToSeconds(nTicks) } }

  private var ticksPerSecond: UInt64 = 0
  private var clockTimeStamp: MIDITimeStamp = 0

  init(beatsPerMinute bpm: Double) {
    beatsPerMinute = bpm
    timer = Timer(queue:MIDIClock.queue)

    var timebaseInfo = mach_timebase_info()
    mach_timebase_info(&timebaseInfo)
    ticksPerSecond = (UInt64(timebaseInfo.denom) * NSEC_PER_SEC) / UInt64(timebaseInfo.numer)
    initTempo()
    timer.interval = nanosecondsToSeconds(nTicks)
    timer.handler = {
      [unowned self] _ in

      // avoid to much blocks send in the future to avoid latency in tempo changes
      // just skip on block when the clockTimeStamp is ahead of the mach_absolute_time()
      guard self.clockTimeStamp - mach_absolute_time() <= 0 else { return }
      self.clockTimeStamp += self.nTicks
    }
  }

}

/** `MIDIClock` subclass that serves as a source for MIDI clients to receive clock events */
final class MIDIClockSource: MIDIClock {

  var listSize = 4
  let destination: MIDIEndpointRef
  let outPort: MIDIPortRef

  /** initTempo */
  override private func initTempo() {
    // Number of ticks between clock's. Round the nTicks to avoid 'jitter' in the sound
    nTicks = UInt64(Double(ticksPerSecond) / (beatsPerMinute * 24 / 60)) & ~0xF
    bTicks = nTicks * UInt64(listSize)
  }

  /**
  init:outPort:destination:

  - parameter bpm: Float
  - parameter out: MIDIPortRef
  - parameter dest: MIDIEndpointRef
  */
  init(beatsPerMinute bpm: Double, outPort out: MIDIPortRef, destination dest: MIDIEndpointRef) {
    outPort = out; destination = dest
    super.init(beatsPerMinute: bpm)

    timer.interval = nanosecondsToSeconds(bTicks)
    timer.handler = {
      [unowned self] _ in

      // avoid to much blocks send in the future to avoid latency in tempo changes
      // just skip on block when the clockTimeStamp is ahead of the mach_absolute_time()
      guard (self.clockTimeStamp - mach_absolute_time()) / self.bTicks <= 0 else { return }

      // setup packetlist
      var clock: UInt8 = 0xF8
      let size = sizeof(UInt32.self) + (self.listSize * sizeof(MIDIPacket.self))
      var packetList = MIDIPacketList()
      var packet = MIDIPacketListInit(&packetList)

      // Set the time stamps
      for _ in 0 ..< self.listSize {

        packet = MIDIPacketListAdd( &packetList, size, packet, self.clockTimeStamp, 1, &clock )
        self.clockTimeStamp += self.nTicks
      }
      do { try withUnsafePointer(&packetList) { MIDISend(self.outPort, self.destination, $0) } ➤ "Failed to send packets" }
      catch { logError(error) }
    }
  }

  private var bTicks: UInt64 = 0 { didSet { timer.interval = nanosecondsToSeconds(bTicks) } }

}