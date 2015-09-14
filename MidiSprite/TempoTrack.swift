//
//  TempoTrack.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import MoonKit
import struct AudioToolbox.CABarBeatTime


final class TempoTrack: MIDITrackType {

  let time = BarBeatTime(clockSource: Sequencer.clockSource)

  let playbackMode: Bool

  private(set) var events: [MIDITrackEvent] = [
    MetaEvent(.TimeSignature(upper: 4, lower: 4, clocks: 36, notes: 8)),
    MetaEvent(.Tempo(microseconds: Byte4(60_000_000 / Sequencer.tempo)))
  ]

  private var notificationReceptionist: NotificationReceptionist?
  private func recordingStatusDidChange(notification: NSNotification) { recording = Sequencer.recording }

  /**
  reset:

  - parameter notification: NSNotification
  */
  private func reset(notification: NSNotification) { time.reset() }

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard notificationReceptionist == nil else { return }
    typealias Callback = NotificationReceptionist.Callback
    let recordingCallback: Callback = (Sequencer.self, NSOperationQueue.mainQueue(), recordingStatusDidChange)
    let resetCallback: Callback = (Sequencer.self, NSOperationQueue.mainQueue(), reset)
    notificationReceptionist = NotificationReceptionist(callbacks: [
      Sequencer.Notification.DidTurnOnRecording.name.value : recordingCallback,
      Sequencer.Notification.DidTurnOffRecording.name.value : recordingCallback,
      Sequencer.Notification.DidReset.name.value : resetCallback
      ])
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard !playbackMode && recording else { return }
    events.append(MetaEvent(time.time, .Tempo(microseconds: Byte4(60_000_000 / tempo))))
  }

  let name = "Tempo"
  var recording = false

  /**
  Initializer for non-playback mode tempo track
  */
  init(playbackMode: Bool = false) {
    recording = Sequencer.recording
    self.playbackMode = playbackMode
  }


  /**
  isTempoTrackEvent:

  - parameter trackEvent: MIDITrackEvent

  - returns: Bool
  */
  static func isTempoTrackEvent(trackEvent: MIDITrackEvent) -> Bool {
    guard let metaEvent = trackEvent as? MetaEvent else { return false }
    switch metaEvent.data {
      case .Tempo, .TimeSignature, .EndOfTrack: return true
      case .SequenceTrackName(let name) where name.lowercaseString == "tempo": return true
      default: return false
    }
  }

  private var eventMap: [CABarBeatTime:[MIDITrackEvent]] = [:]

  /**
  dispatchEventsForTime:

  - parameter time: CABarBeatTime
  */
  private func dispatchEventsForTime(time: CABarBeatTime) {
    guard let events = eventMap[time] else { return }
    for event in events where event is MetaEvent {
      switch (event as! MetaEvent).data {
        case let .Tempo(microseconds): Sequencer.tempo = Double(60_000_000 / microseconds)
        case let .TimeSignature(upper, lower, _, _): Sequencer.timeSignature = SimpleTimeSignature(upper: upper, lower: lower)
        default: break
      }
    }
  }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  */
  init(trackChunk: MIDIFileTrackChunk) {
    playbackMode = true
    events = trackChunk.events.filter { TempoTrack.isTempoTrackEvent($0) }
    for event in events {
      let eventTime = event.time
      var eventBag: [MIDITrackEvent] = eventMap[eventTime] ?? []
      eventBag.append(event)
      eventMap[eventTime] = eventBag
    }
    for eventTime in eventMap.keys { time.registerCallback(dispatchEventsForTime, forTime: eventTime) }
    logDebug("eventMap = \(eventMap)")
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n"
    result += "  playbackMode: \(playbackMode)\n"
    result += "  events: {\n" + ",\n".join(events.map({$0.description.indentedBy(8)})) + "\n\t}\n"
    result += "}"
    return result
  }

}