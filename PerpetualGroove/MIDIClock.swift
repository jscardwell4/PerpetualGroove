//
//  MIDIClock.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI
import AudioToolbox

/** A class capable of keeping time for MIDI events */
final class MIDIClock: CustomStringConvertible, Named {

  var description: String {
    return "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "name: \(name)",
      "beatsPerMinute: \(beatsPerMinute)",
      "resolution: \(resolution)",
      "ticks: \(ticks)",
      "tickInterval: \(tickInterval)",
      "nanosecondsPerBeat: \(nanosecondsPerBeat)",
      "microsecondsPerBeat: \(microsecondsPerBeat)",
      "secondsPerBeat: \(secondsPerBeat)",
      "secondsPerTick: \(secondsPerTick)",
      "hostInfo: \(hostInfo)"
    ) + "\n}"
  }

  let name: String

  private static let queue = concurrentQueueWithLabel("MIDI Clock", qualityOfService: QOS_CLASS_USER_INTERACTIVE)

  let resolution: UInt64 = 480

  var beatsPerMinute: UInt16 = 120 { didSet { recalculate() } }

  private(set) var tickInterval:        UInt64 = 0
  private(set) var nanosecondsPerBeat:  UInt64 = 0
  private(set) var microsecondsPerBeat: UInt64 = 0
  private(set) var secondsPerBeat:      Double = 0
  private(set) var secondsPerTick:      Double = 0

  /** recalculate */
  private func recalculate() {
    nanosecondsPerBeat = UInt64(60.0e9) / UInt64(beatsPerMinute)
    microsecondsPerBeat = UInt64(60.0e6) / UInt64(beatsPerMinute)
    secondsPerBeat = 60 / Double(beatsPerMinute)
    secondsPerTick = secondsPerBeat / Double(resolution)// * 4)
    tickInterval = nanosecondsPerBeat / UInt64(resolution)// * 4 // ???: Still don't know why I need to multiply by 4
    timer.interval = tickInterval
  }

  /** start */
  func start() {
    guard !timer.running else { return }
    logDebug("setting ticks to 0, sending start message and starting timer…")
    ticks = 0
    sendStart()
    timer.start()
  }

  var paused: Bool { return !running && ticks > 0 }

  /** resume */
  func resume() {
    guard !timer.running else { return }
    logDebug("sending continue message and starting timer…")
    sendContinue()
    timer.start()
  }

  /** reset */
  func reset() {
    guard !timer.running else { return }
    logDebug("setting ticks to 0…")
    ticks = 0
  }

  /** stop */
  func stop() {
    guard timer.running else { return }
    logDebug("stopping timer and sending stop message…")
    timer.stop()
    sendStop()
  }

  private var hostInfo: String {
    let currentHostTicks = hostTicks
    let nsPerTick = nanosecondsPerHostTick
    let currentHostTime = currentHostTicks * UInt64(nsPerTick.value)
    return "{ hostTicks: \(currentHostTicks); nanosecondsPerTick: \(nsPerTick); hostTime: \(currentHostTime)}"
  }

  private let timer = Timer(queue:MIDIClock.queue)
  var running: Bool { return timer.running }

  /// The running number of MIDI clocks that have elapsed
  private(set) var ticks: MIDITimeStamp = 0

  /** init */
  init(name: String) {
    self.name = name
    recalculate()
    timer.handler = sendClock
    do {
      try MIDIClientCreateWithBlock("Clock", &client, nil) ➤ "Failed to create midi client for clock"
      try MIDISourceCreate(client, "Clock", &endPoint) ➤ "Failed to create end point for clock"
      MIDIObjectSetStringProperty(endPoint, kMIDIPropertyName, "\(name) clock")
    } catch {
      logError(error)
      #if !TARGET_INTERFACE_BUILDER
        fatalError("could not create clock as a midi source")
      #endif
    }
  }

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  /**
  sendEvent:

  - parameter event: Byte
  */
  private func sendEvent(event: Byte) throws {
    var packetList = MIDIPacketList()
    MIDIPacketListAdd(&packetList,
                      sizeof(UInt32.self) + sizeof(MIDIPacket.self),
                      MIDIPacketListInit(&packetList),
                      ticks,
                      1,
                      [event])
    try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Failed to send packets"
  }

  /** sendClock */
  private func sendClock() {
    guard timer.running else { return }
    ticks++
    do { try sendEvent(0b1111_1000) } catch { logError(error) }
  }

  /** sendStart */
  private func sendStart() { do { try sendEvent(0b1111_1010) } catch { logError(error) } }

  /** sendContinue */
  private func sendContinue() { do { try sendEvent(0b1111_1011) } catch { logError(error) } }

  /** sendStop */
  private func sendStop() { do { try sendEvent(0b1111_1100) } catch { logError(error) } }

}