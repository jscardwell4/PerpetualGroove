//
//  Transport.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import typealias AudioToolbox.MIDITimeStamp
import struct AudioToolbox.CABarBeatTime

final class Transport {
  var state: State = []
  let name: String
  let clock: MIDIClock
  let time: BarBeatTime

  var tempo: Double { get { return Double(clock.beatsPerMinute) } set { clock.beatsPerMinute = UInt16(newValue) } }

  init(name: String) {
    self.name = name
    let clock = MIDIClock(name: name)
    time = BarBeatTime(clockSource: clock.endPoint)
    self.clock = clock
  }

  var playing:          Bool { return state ∋ .Playing          }
  var paused:           Bool { return state ∋ .Paused           }
  var jogging:          Bool { return state ∋ .Jogging          }
  var recording:        Bool { return state ∋ .Recording        }

  /** Starts the MIDI clock */
  func play() {
    guard !playing else { logWarning("already playing"); return }
    Notification.DidStart.post()
    if paused { clock.resume(); state ⊻= [.Paused, .Playing] }
    else { clock.start(); state ⊻= [.Playing] }
  }

  /** toggleRecord */
  func toggleRecord() { state ⊻= .Recording; Notification.DidToggleRecording.post() }

  /** pause */
  func pause() {
    guard playing else { return }
    clock.stop()
    state ⊻= [.Paused, .Playing]
    Notification.DidPause.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: NSValue(barBeatTime: time.time)
      ])
  }

  /** Moves the time back to 0 */
  func reset() {
    if playing || paused { stop() }
    clock.reset()
    time.reset {[weak self] in
      guard let weakself = self else { return }
      Notification.DidReset.post(object: weakself, userInfo:[
        .Ticks: NSNumber(unsignedLongLong: weakself.time.ticks),
        .Time: NSValue(barBeatTime: weakself.time.time)
        ])}
  }

  /** Stops the MIDI clock */
  func stop() {
    guard playing || paused else { logWarning("not playing or paused"); return }
    clock.stop()
    state ∖= [.Playing, .Paused]
    Notification.DidStop.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: NSValue(barBeatTime: time.time)
      ])
  }

  private var jogStartTimeTicks: UInt64 = 0
  private var maxTicks: MIDITimeStamp = 0
  private var jogTime: CABarBeatTime = .start
  private var ticksPerRevolution: MIDITimeStamp = 0

  /** beginJog */
  func beginJog() {
    guard !jogging, let sequence = MIDIDocumentManager.currentDocument?.sequence else { return }
    clock.stop()
    jogTime = time.time
    maxTicks = max(jogTime.ticks, sequence.sequenceEnd.ticks)
    ticksPerRevolution = MIDITimeStamp(Sequencer.timeSignature.beatsPerBar) * MIDITimeStamp(time.partsPerQuarter)
    state ⊻= [.Jogging]
    Notification.DidBeginJogging.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: NSValue(barBeatTime: time.time)
      ])
  }

  /**
  jog:

  - parameter revolutions: Float
  */
  func jog(revolutions: Float) {
    guard jogging else { logWarning("not jogging"); return }

    let 𝝙ticks = MIDITimeStamp(Double(abs(revolutions)) * Double(ticksPerRevolution))

    let ticks: MIDITimeStamp

    switch revolutions.isSignMinus {
      case true where time.ticks < 𝝙ticks:             	ticks = 0
      case true:                                        ticks = time.ticks - 𝝙ticks
      case false where time.ticks + 𝝙ticks > maxTicks: 	ticks = maxTicks
      default:                                          ticks = time.ticks + 𝝙ticks
    }

    do { try jogToTime(CABarBeatTime(tickValue: ticks)) } catch { logError(error) }
  }

  /** endJog */
  func endJog() {
    guard jogging && clock.paused else { logWarning("not jogging"); return }
    state ⊻= [.Jogging]
    time.time = jogTime
    maxTicks = 0
    Notification.DidEndJogging.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: NSValue(barBeatTime: time.time)
      ])
    guard !paused else { return }
    clock.resume()
  }

  /**
  jogToTime:

  - parameter time: CABarBeatTime
  */
  func jogToTime(t: CABarBeatTime) throws {
    guard jogTime != t else { return }
    guard jogging else { throw Error.NotPermitted }
    guard time.isValidTime(t) else { throw Error.InvalidBarBeatTime }
    jogTime = t
    Notification.DidJog.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: NSValue(barBeatTime: time.time),
      .JogTime: NSValue(barBeatTime: jogTime)
      ])
  }

}

extension Transport {
  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int

    static let Playing   = State(rawValue: 0b0000_0010)
    static let Recording = State(rawValue: 0b0000_0100)
    static let Paused    = State(rawValue: 0b0001_0000)
    static let Jogging   = State(rawValue: 0b0010_0000)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if contains(.Playing)            { flagStrings.append("Playing")   }
      if contains(.Recording)          { flagStrings.append("Recording") }
      if contains(.Paused)             { flagStrings.append("Paused")    }
      if contains(.Jogging)            { flagStrings.append("Jogging")   }
      result += ", ".join(flagStrings)
      result += " ]"
      return result
    }
  }
}

extension Transport {
  enum Error: String, ErrorType {
    case InvalidBarBeatTime
    case NotPermitted
  }
}

extension Transport {
  // MARK: - Notifications
  enum Notification: String, NotificationType, NotificationNameType {
    case DidStart, DidPause, DidStop, DidReset
    case DidToggleRecording
    case DidBeginJogging, DidEndJogging
    case DidJog

    enum Key: String, NotificationKeyType {
      case Time, Ticks, JogTime
    }
  }

}

extension NSNotification {
  var jogTime: CABarBeatTime? {
    return (userInfo?[Transport.Notification.Key.JogTime.key] as? NSValue)?.barBeatTimeValue
  }
  var time: CABarBeatTime? {
    return (userInfo?[Transport.Notification.Key.Time.key] as? NSValue)?.barBeatTimeValue
  }
  var ticks: MIDITimeStamp? {
    return (userInfo?[Transport.Notification.Key.Ticks.key] as? NSNumber)?.unsignedLongLongValue
  }
}