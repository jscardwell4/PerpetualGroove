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
final class MIDIClockSource {

  private static let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
  private static let MIDIClocksPerBeat = Double(96)
  var beatsPerMinute: Double = 120 { didSet { initTempo() } }

  /** initTempo */
  private func initTempo() {
    let ticksPerSecond = CAHostTimeBase.frequency
    let ticksPerMinute = 60 * ticksPerSecond
    let ticksPerBeat = ticksPerMinute / beatsPerMinute
    ticksPerMIDIClock = UInt64(ticksPerBeat / MIDIClockSource.MIDIClocksPerBeat)
  }

  /** start */
  func start() {
    guard !timer.running else { return }
    clockTimeStamp = 0
    timer.start()
  }

  /** reset */
  func reset() {
    guard !timer.running else { return }
    clockTimeStamp = 0
  }

  /** stop */
  func stop() {
    guard timer.running else { return }
    timer.stop()
  }

  private let timer = Timer(queue:MIDIClockSource.queue)
  var running: Bool { return timer.running }

  private var ticksPerMIDIClock: UInt64 = 0 { didSet { timer.interval = nanosecondsToSeconds(ticksPerMIDIClock) } }
  private(set) var clockTimeStamp: MIDITimeStamp = 0

  /** init */
  init() {
    initTempo()
    timer.interval = nanosecondsToSeconds(ticksPerMIDIClock)
    timer.handler = handler
    do {
      try MIDIClientCreateWithBlock("Clock", &client, nil) ➤ "Failed to create midi client for clock"
      try MIDISourceCreate(client, "Clock", &endPoint) ➤ "Failed to create end point for clock"
    } catch {
      logError(error)
      fatalError("could not create clock as a midi source")
    }
  }

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  /** sendClock */
  private func sendClock() {

    // setup packetlist
    var clock: UInt8 = 0xF8
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    var packetList = MIDIPacketList()
    MIDIPacketListAdd(&packetList, size, MIDIPacketListInit(&packetList), clockTimeStamp, 1, &clock)
    clockTimeStamp += ticksPerMIDIClock

    do { try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Failed to send packets" }
    catch { logError(error) }

  }

  /**
  Invoked by timer's dispatch source

  - parameter timer: Timer
  */
  private func handler(timer: Timer) { sendClock() }

}