//
//  MIDIClock.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/20/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import CoreMIDI
import AudioToolbox

/// A class capable of keeping time for MIDI events
final class MIDIClock: CustomStringConvertible, Named {

  static var current: MIDIClock { return Transport.current.clock }

  var description: String {
    return "\(type(of: self).self) {\n\t" + "\n\t".join(
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

  fileprivate let dispatchQueue = DispatchQueue(label: "MIDI Clock (Dispatch)", qos: .userInteractive)

  let resolution: UInt64 = 480

  var beatsPerMinute: UInt16 = 120 { didSet { recalculate() } }

  fileprivate(set) var tickInterval:        UInt64 = 0
  fileprivate(set) var nanosecondsPerBeat:  UInt64 = 0
  fileprivate(set) var microsecondsPerBeat: UInt64 = 0
  fileprivate(set) var secondsPerBeat:      Double = 0
  fileprivate(set) var secondsPerTick:      Double = 0

  fileprivate func recalculate() {
    nanosecondsPerBeat = UInt64(60.0e9) / UInt64(beatsPerMinute)
    microsecondsPerBeat = UInt64(60.0e6) / UInt64(beatsPerMinute)
    secondsPerBeat = 60 / Double(beatsPerMinute)
    secondsPerTick = secondsPerBeat / Double(resolution)
    tickInterval = nanosecondsPerBeat / UInt64(resolution)
    timer.interval = .nanoseconds(Int(tickInterval))
  }

  func start() { dispatchQueue.async(execute: _start) }

  fileprivate func _start() {
    guard !timer.running else { return }
    Log.debug("setting ticks to 0, sending start message and starting timer…")
    ticks = 0
    sendStart()
    timer.start()
  }

  var paused: Bool { return !isRunning && ticks > 0 }

  func resume() { dispatchQueue.async(execute: _resume) }

  fileprivate func _resume() {
    guard !timer.running else { return }
    Log.debug("sending continue message and starting timer…")
    sendContinue()
    timer.start()
  }

  func reset() { dispatchQueue.async(execute: _reset) }

  fileprivate func _reset() {
    guard !timer.running else { return }
    Log.debug("setting ticks to 0…")
    ticks = 0
  }

  func stop() { dispatchQueue.async(execute: _stop) }

  fileprivate func _stop() {
    guard timer.running else { return }
    Log.debug("stopping timer and sending stop message…")
    timer.stop()
    sendStop()
  }

  fileprivate var hostInfo: String {
    let currentHostTicks = hostTicks
    let nsPerTick = nanosecondsPerHostTick
    let currentHostTime = currentHostTicks * UInt64(nsPerTick.fraction.numerator/nsPerTick.fraction.denominator)
    return "{ ; }".wrap("; ".join("hostTicks: \(currentHostTicks)",
                                  "nanosecondsPerTick: \(nsPerTick)",
                                  "hostTime: \(currentHostTime)"),
              separator: ";")
  }

  fileprivate let timer = Timer(queue: DispatchQueue(label: "MIDI Clock (Timer)", qos: .userInteractive))

  var isRunning: Bool { return timer.running }

  /// The running number of MIDI clocks that have elapsed
  fileprivate(set) var ticks: MIDITimeStamp = 0

  init(name: String) {
    self.name = name
    recalculate()
    timer.handler = sendClock
    do {
      try MIDIClientCreateWithBlock("Clock" as CFString, &client, nil) ➤ "Failed to create midi client for clock"
      try MIDISourceCreate(client, "Clock" as CFString, &endPoint) ➤ "Failed to create end point for clock"
      MIDIObjectSetStringProperty(endPoint, kMIDIPropertyName, "\(name) clock" as CFString)
    } catch {
      Log.error(error)
      #if !TARGET_INTERFACE_BUILDER
        fatalError("could not create clock as a midi source")
      #endif
    }
  }

  fileprivate var client = MIDIClientRef()
  fileprivate(set) var endPoint = MIDIEndpointRef()

  fileprivate func sendEvent(_ event: Byte) throws {
    var packetList = MIDIPacketList()
    MIDIPacketListAdd(&packetList,
                      MemoryLayout<UInt32>.size + MemoryLayout<MIDIPacket>.size,
                      MIDIPacketListInit(&packetList),
                      ticks,
                      1,
                      [event])
    try withUnsafePointer(to: &packetList) { MIDIReceived(endPoint, $0) } ➤ "Failed to send packets"
  }

  fileprivate func sendClock() { dispatchQueue.async(execute: _sendClock) }

  fileprivate func _sendClock() {

    guard timer.running else { return }
    ticks += 1
    do { try sendEvent(0b1111_1000) } catch { Log.error(error) }
  }

  fileprivate func sendStart() { do { try sendEvent(0b1111_1010) } catch { Log.error(error) } }

  fileprivate func sendContinue() { do { try sendEvent(0b1111_1011) } catch { Log.error(error) } }

  fileprivate func sendStop() { do { try sendEvent(0b1111_1100) } catch { Log.error(error) } }

}
