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

  var playing:          Bool { return state ∋ .Playing   }
  var paused:           Bool { return state ∋ .Paused    }
  var jogging:          Bool { return state ∋ .Jogging   }
  var recording:        Bool { return state ∋ .Recording }

  /** Starts the MIDI clock */
  func play() {
    guard !playing else { logWarning("already playing"); return }
    Notification.DidStart.post(object: self, userInfo:[
      .Time: time.barBeatTime.rawValue
      ])
    if paused { clock.resume(); state.formSymmetricDifference([.Paused, .Playing]) }
    else { clock.start(); state.formSymmetricDifference([.Playing]) }
  }

  /** toggleRecord */
  func toggleRecord() { state.formSymmetricDifference(.Recording); Notification.DidToggleRecording.post() }

  /** pause */
  func pause() {
    guard playing else { return }
    clock.stop()
    state.formSymmetricDifference([.Paused, .Playing])
    Notification.DidPause.post(object: self, userInfo:[
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
        .Time: weakself.time.barBeatTime.rawValue
        ])}
  }

  /** Stops the MIDI clock */
  func stop() {
    guard playing || paused else { logWarning("not playing or paused"); return }
    clock.stop()
    state ∖= [.Playing, .Paused]
    Notification.DidStop.post(object: self, userInfo:[
      .Time: time.barBeatTime.rawValue
      ])
  }

  fileprivate var jogTime: BarBeatTime = nil

  /**
   beginJog:

   - parameter wheel: ScrollWheel
  */
  func beginJog(_ wheel: ScrollWheel) {
    guard !jogging else { return }
    if clock.running { clock.stop() }
    jogTime = time.barBeatTime
    state.formSymmetricDifference([.Jogging])
    Notification.DidBeginJogging.post(object: self, userInfo:[
      .Time: time.barBeatTime.rawValue
      ])
  }

  /**
   jog:

   - parameter wheel: ScrollWheel
  */
  func jog(_ wheel: ScrollWheel) {
    guard jogging && jogTime != nil else { logWarning("not jogging"); return }
    let 𝝙time = BarBeatTime(totalBeats: Double(Sequencer.beatsPerBar) * wheel.𝝙revolutions)
    do { try jogToTime(max(jogTime + 𝝙time, .start1), direction: wheel.direction) }
    catch { logError(error) }
  }

  /**
   endJog:

   - parameter wheel: ScrollWheel
  */
  func endJog(_ wheel: ScrollWheel) {
    guard jogging /*&& clock.paused*/ else { logWarning("not jogging"); return }
    state.formSymmetricDifference([.Jogging])
    time.barBeatTime = jogTime
    jogTime = nil
    Notification.DidEndJogging.post(object: self, userInfo:[
      .Time: time.barBeatTime.rawValue
      ])
    guard !paused && clock.paused else { return }
    clock.resume()
  }

  /**
  jogToTime:

  - parameter time: BarBeatTime
  */
  func jogToTime(_ t: BarBeatTime, direction: ScrollWheel.Direction) throws {
    guard jogging else { throw Error.notPermitted("state ∌ jogging") }
    guard jogTime != t else { return }
    guard t.isNormal else { throw Error.invalidBarBeatTime("\(t)") }
    jogTime = t
    Notification.DidJog.post(object: self, userInfo:[
      .Time: time.barBeatTime.rawValue,
      .JogTime: jogTime.rawValue,
      .JogDirection: direction.rawValue
      ])
  }

  /**
   automateJogToTime:

   - parameter tʹ: BarBeatTime
  */
  func automateJogToTime(_ tʹ: BarBeatTime) throws {
    let t = time.barBeatTime
    guard t != tʹ else { return }
    guard tʹ.isNormal else { throw Error.invalidBarBeatTime("\(tʹ)") }
    let direction: ScrollWheel.Direction = tʹ < time.barBeatTime ? .counterClockwise : .clockwise
    if clock.running { clock.stop() }
    time.barBeatTime = tʹ
    Notification.DidJog.post(object: self, userInfo:[
      .Time: t.rawValue,
      .JogTime: tʹ.rawValue,
      .JogDirection: direction.rawValue
      ])
    guard !paused && clock.paused else { return }
    clock.resume()
  }

}

extension Transport {
  struct State: OptionSet, CustomStringConvertible {
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
    case invalidBarBeatTime (String)
    case notPermitted (String)

    var name: String {
      switch self {
        case .invalidBarBeatTime: return "InvalidBarBeatTime"
        case .notPermitted:       return "NotPermitted"
      }
    }

    var reason: String {
      switch self {
        case .invalidBarBeatTime(let reason): return reason
        case .notPermitted(let reason):       return reason
      }
    }
  }
}

extension Transport: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didStart, didPause, didStop, didReset
    case didToggleRecording
    case didBeginJogging, didEndJogging
    case didJog
    case didChangeState
  }

}

extension Notification {

  var jogTime: BarBeatTime? {
    guard let string = userInfo?["jogTime"] as? String else { return nil }
    return BarBeatTime(rawValue: string)
  }

  var jogDirection: ScrollWheel.Direction? {
    guard let raw = userInfo?["jogDirection"] as? Int else {
      return nil
    }
    return ScrollWheel.Direction(rawValue: raw)
  }

  var time: BarBeatTime? {
    guard let string = userInfo?["time"] as? String else { return nil }
    return BarBeatTime(rawValue: string)
  }

  var transportState: Transport.State? {
    guard let rawState = userInfo?["transportState"] as? NSNumber else {
      return nil
    }
    return Transport.State(rawValue: rawState.intValue)
  }

  var previousTransportState: Transport.State? {
    guard let rawState = userInfo?["previousTransportState"] as? NSNumber else {
      return nil
    }
    return Transport.State(rawValue: rawState.intValue)
  }
}
