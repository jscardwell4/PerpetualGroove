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

final class Transport {
  var state: State = [] {
    didSet {
      guard state != oldValue else { return }
      Notification.DidChangeState.post(object: self, userInfo: [
        .TransportState: state.rawValue,
        .PreviousTransportState: oldValue.rawValue
        ])
    }
  }
  let name: String
  let clock: MIDIClock
  let time: Time

  var tempo: Double {
    get { return Double(clock.beatsPerMinute) }
    set { clock.beatsPerMinute = UInt16(newValue) }
  }

  /**
   initWithName:

   - parameter name: String
  */
  init(name: String) {
    self.name = name
    let clock = MIDIClock(name: name)
    time = Time(clockSource: clock.endPoint)
    self.clock = clock
  }

  var playing:          Bool { return state ∋ .Playing          }
  var paused:           Bool { return state ∋ .Paused           }
  var jogging:          Bool { return state ∋ .Jogging          }
  var recording:        Bool { return state ∋ .Recording        }

  /** Starts the MIDI clock */
  func play() {
    guard !playing else { logWarning("already playing"); return }
    Notification.DidStart.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: time.barBeatTime.rawValue
      ])
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
      .Time: time.barBeatTime.rawValue
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
        .Time: weakself.time.barBeatTime.rawValue
        ])}
  }

  /** Stops the MIDI clock */
  func stop() {
    guard playing || paused else { logWarning("not playing or paused"); return }
    clock.stop()
    state ∖= [.Playing, .Paused]
    Notification.DidStop.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: time.barBeatTime.rawValue
      ])
  }

  private var jogTime: BarBeatTime = nil

  /**
   beginJog:

   - parameter wheel: ScrollWheel
  */
  func beginJog(wheel: ScrollWheel) {
    guard !jogging else { return }
    if clock.running { clock.stop() }
    jogTime = time.barBeatTime
    state ⊻= [.Jogging]
    Notification.DidBeginJogging.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: time.barBeatTime.rawValue
      ])
  }

  /**
   jog:

   - parameter wheel: ScrollWheel
  */
  func jog(wheel: ScrollWheel) {
    guard jogging && jogTime != nil else { logWarning("not jogging"); return }
    let 𝝙time = BarBeatTime(totalBeats: Double(Sequencer.beatsPerBar) * wheel.𝝙revolutions)
    do { try jogToTime(max(jogTime + 𝝙time, .start1), direction: wheel.direction) } catch { logError(error) }
  }

  /**
   endJog:

   - parameter wheel: ScrollWheel
  */
  func endJog(wheel: ScrollWheel) {
    guard jogging /*&& clock.paused*/ else { logWarning("not jogging"); return }
    state ⊻= [.Jogging]
    time.barBeatTime = jogTime
    jogTime = nil
    Notification.DidEndJogging.post(object: self, userInfo:[
      .Ticks: NSNumber(unsignedLongLong: time.ticks),
      .Time: time.barBeatTime.rawValue
      ])
    guard !paused && clock.paused else { return }
    clock.resume()
  }

  /**
  jogToTime:

  - parameter time: BarBeatTime
  */
  func jogToTime(t: BarBeatTime, direction: ScrollWheel.Direction) throws {
    guard jogging else { throw Error.NotPermitted("state ∌ jogging") }
    guard jogTime != t else { return }
    guard t.isNormal else { throw Error.InvalidBarBeatTime("\(t)") }
    jogTime = t
    Notification.DidJog.post(object: self, userInfo:[
//      .Ticks: NSNumber(unsignedLongLong: time.ticks),
//      .Time: time.barBeatTime.rawValue,
      .JogTime: jogTime.rawValue,
      .JogDirection: direction.rawValue
      ])
  }

}

extension Transport {
  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int

    static let Playing   = State(rawValue: 0b0001)
    static let Recording = State(rawValue: 0b0010)
    static let Paused    = State(rawValue: 0b0100)
    static let Jogging   = State(rawValue: 0b1000)

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
  enum Error: ErrorMessageType {
    case InvalidBarBeatTime (String)
    case NotPermitted (String)

    var name: String {
      switch self {
        case .InvalidBarBeatTime: return "InvalidBarBeatTime"
        case .NotPermitted:       return "NotPermitted"
      }
    }

    var reason: String {
      switch self {
        case .InvalidBarBeatTime(let reason): return reason
        case .NotPermitted(let reason):       return reason
      }
    }
  }
}

extension Transport {
  // MARK: - Notifications
  enum Notification: String, NotificationType, NotificationNameType {
    case DidStart, DidPause, DidStop, DidReset
    case DidToggleRecording
    case DidBeginJogging, DidEndJogging
    case DidJog
    case DidChangeState

    enum Key: String, NotificationKeyType {
      case Time, Ticks, JogTime, JogDirection, TransportState, PreviousTransportState
    }
  }

}

extension NSNotification {
  var jogTime: BarBeatTime? {
    guard let string = userInfo?[Transport.Notification.Key.JogTime.key] as? String else { return nil }
    return BarBeatTime(rawValue: string)
  }
  var jogDirection: ScrollWheel.Direction? {
    guard let raw = userInfo?[Transport.Notification.Key.JogDirection.key] as? Int else {
      return nil
    }
    return ScrollWheel.Direction(rawValue: raw)
  }
  var time: BarBeatTime? {
    guard let string = userInfo?[Transport.Notification.Key.Time.key] as? String else { return nil }
    return BarBeatTime(rawValue: string)
  }
  var ticks: MIDITimeStamp? {
    return (userInfo?[Transport.Notification.Key.Ticks.key] as? NSNumber)?.unsignedLongLongValue
  }
  var transportState: Transport.State? {
    guard let rawState = (userInfo?[Transport.Notification.Key.TransportState.key] as? NSNumber)?.integerValue else {
      return nil
    }
    return Transport.State(rawValue: rawState)
  }
  var previousTransportState: Transport.State? {
    guard let rawState = (userInfo?[Transport.Notification.Key.PreviousTransportState.key] as? NSNumber)?.integerValue else {
      return nil
    }
    return Transport.State(rawValue: rawState)
  }
}