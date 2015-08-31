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
import AudioToolbox

/** A class capable of keeping time for MIDI events */
final class MIDIClock: CustomStringConvertible {

  var description: String {
    return "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "beatsPerMinute: \(beatsPerMinute)",
      "resolution: \(resolution)",
      "ticks: \(ticks)",
      "tickInterval: \(tickInterval)",
      "nanosecondsPerBeat: \(nanosecondsPerBeat)",
      "hostInfo: \(hostInfo)"
    )
  }

  private static let queue = concurrentQueueWithLabel("MIDI Clock", qualityOfService: QOS_CLASS_USER_INTERACTIVE)

  var resolution: UInt64 { didSet { timer.interval = tickInterval } }
  var beatsPerMinute: UInt16 = 120 { didSet { timer.interval = tickInterval } }
  var tickInterval: UInt64 {
    return nanosecondsPerBeat / UInt64(resolution) * 4 // ???: Still don't know why I need to multiply by
                                                       // four to get the right intervals
  }
  var nanosecondsPerBeat: UInt64 { return UInt64(60.0e9) / UInt64(beatsPerMinute) }
  var microsecondsPerBeat: UInt64 { return UInt64(60.0e6) / UInt64(beatsPerMinute) }
  var secondsPerBeat: Double { return 60 / Double(beatsPerMinute) }

  /** start */
  func start() {
    guard !timer.running else { return }
    ticks = 0
    timer.start()
  }

  /** reset */
  func reset() { guard !timer.running else { return }; ticks = 0 }

  /** stop */
  func stop() {
    guard timer.running else { return }
    timer.stop()
  }

  private var hostInfo: String {
    let currentHostTicks = hostTicks
    let nsPerTick = nanosecondsPerHostTick
    let currentHostTime = UInt64(Float80(currentHostTicks) * nsPerTick)
    return "{ hostTicks: \(currentHostTicks); nanosecondsPerTick: \(nsPerTick); hostTime: \(currentHostTime)}"
  }

  private let timer = Timer(queue:MIDIClock.queue)
  var running: Bool { return timer.running }

  /// The running number of MIDI clocks that have elapsed
  private(set) var ticks: MIDITimeStamp = 0

  private var graph: AUGraph?

  /** init */
  init(resolution: UInt64) {
    self.resolution = resolution
    timer.interval = tickInterval
    timer.handler = { [unowned self] _ in self.sendClock() }
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
    var clock: Byte = 0xF8
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    var packetList = MIDIPacketList()
    MIDIPacketListAdd(&packetList, size, MIDIPacketListInit(&packetList), ++ticks, 1, &clock)
    do {
      try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Failed to send packets"
    }
    catch { logError(error) }
  }

}