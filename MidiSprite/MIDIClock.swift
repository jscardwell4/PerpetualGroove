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

  var beatsPerMinute: Double = 120 { didSet { initTempo() } }
  private static let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

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

  private let timer = Timer(queue:MIDIClock.queue)
  var running: Bool { return timer.running }

  private var nTicks: UInt64 = 0 { didSet { timer.interval = nanosecondsToSeconds(nTicks) } }

  private var ticksPerSecond: UInt64 = 0
  private(set) var clockTimeStamp: MIDITimeStamp = 0

  /** init */
  init() {
    var timebaseInfo = mach_timebase_info()
    mach_timebase_info(&timebaseInfo)
    ticksPerSecond = (UInt64(timebaseInfo.denom) * NSEC_PER_SEC) / UInt64(timebaseInfo.numer)
    initTempo()
    timer.interval = nanosecondsToSeconds(nTicks)
    timer.handler = handler
  }

  /**
  Invoked by timer's dispatch source

  - parameter timer: Timer
  */
  private func handler(timer: Timer) { clockTimeStamp += nTicks }
}

/** `MIDIClock` subclass that serves as a source for MIDI clients to receive clock events */
final class MIDIClockSource: MIDIClock {

  var listSize = 4
  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()


  /** initTempo */
  override private func initTempo() { super.initTempo(); bTicks = nTicks * UInt64(listSize) }

  /** sendClock */
  private func sendClock() {

    let now = mach_absolute_time()
    guard clockTimeStamp <= now || (clockTimeStamp - now) / bTicks <= 0 else { return }

    // setup packetlist
    var clock: UInt8 = 0xF8
    let size = sizeof(UInt32.self) + (listSize * sizeof(MIDIPacket.self))
    var packetList = MIDIPacketList()
    var packet = MIDIPacketListInit(&packetList)

    // Set the time stamps
    for _ in 0 ..< listSize {

      packet = MIDIPacketListAdd(&packetList, size, packet, clockTimeStamp, 1, &clock)
      clockTimeStamp += nTicks
    }
    do { try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Failed to send packets" }
    catch { logError(error) }

  }

  /**
  Invoked by timer's dispatch source

  - parameter timer: Timer
  */
  override private func handler(timer: Timer) { sendClock() }

  /** init */
  override init() {
    super.init()
    do {
      try MIDIClientCreateWithBlock("Clock", &client, nil) ➤ "Failed to create midi client for clock"
      try MIDISourceCreate(client, "Clock", &endPoint) ➤ "Failed to create end point for clock"
    } catch {
      logError(error)
      fatalError("could not create clock as a midi source")
    }

    timer.interval = nanosecondsToSeconds(bTicks)
  }

  private var bTicks: UInt64 = 0 { didSet { timer.interval = nanosecondsToSeconds(bTicks) } }

}