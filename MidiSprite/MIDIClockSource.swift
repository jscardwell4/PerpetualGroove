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
  var resolution = 480.0 { didSet { initializeTempo() } }
  var beatsPerMinute = 120.0 { didSet { initializeTempo() } }

  /** initiliazeTempo */
  private func initializeTempo() {
    var timeInfo = mach_timebase_info()
    mach_timebase_info(&timeInfo)
    let hostFrequency = Float80(timeInfo.numer) / Float80(timeInfo.denom) * Float80(1_000_000_000)
    hostTicksPerMIDIClock = UInt64(hostFrequency / Float80(beatsPerMinute) * 60 / Float80(resolution))
  }

  /** start */
  func start() {
    guard !timer.running else { return }
    ticks = 0
    timer.start()
  }

  /** reset */
  func reset() {
    guard !timer.running else { return }
    ticks = 0
  }

  /** stop */
  func stop() {
    guard timer.running else { return }
    timer.stop()
  }

  private let timer = Timer(queue:MIDIClockSource.queue)
  var running: Bool { return timer.running }

  private(set) var hostTicksPerMIDIClock: UInt64 = 0 {
    didSet { timer.interval = nanosecondsToSeconds(hostTicksPerMIDIClock) }
  }
  private(set) var ticks: MIDITimeStamp = 0

  /** init */
  init() {
    initializeTempo()
    timer.interval = nanosecondsToSeconds(hostTicksPerMIDIClock)
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
    print("tick")
    // setup packetlist
    var clock: Byte = 0xF8
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    var packetList = MIDIPacketList()
    MIDIPacketListAdd(&packetList, size, MIDIPacketListInit(&packetList), ticks, 1, &clock)
    ticks += hostTicksPerMIDIClock

    do { try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Failed to send packets" }
    catch { logError(error) }

  }

  /**
  Invoked by timer's dispatch source

  - parameter timer: Timer
  */
  private func handler(timer: Timer) { sendClock() }

}