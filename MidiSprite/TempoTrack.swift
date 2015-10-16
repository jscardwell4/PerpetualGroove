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

  let time = Sequencer.time
  var trackEnd: CABarBeatTime { return eventContainer.endOfTrackEvent?.time ?? time.time }

  var eventContainer = MIDITrackEventContainer()

  var hasTimeSignatureEvent: Bool {
    let isTimeSignature: (MIDITrackEvent) -> Bool = {
      if let event = $0 as? MetaEvent, case .TimeSignature = event.data { return true } else { return false }
    }
    return eventContainer.events.filter(isTimeSignature).count != 0
  }

  var hasTempoEvent: Bool {
    let isTempoEvent: (MIDITrackEvent) -> Bool = {
      if let event = $0 as? MetaEvent, case .Tempo = event.data { return true } else { return false }
    }
    return eventContainer.events.filter(isTempoEvent).count != 0
  }

  private var receptionist: NotificationReceptionist?
  private func recordingStatusDidChange(notification: NSNotification) { recording = Sequencer.recording }

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard receptionist == nil else { return }
    typealias Notification = Sequencer.Notification
    let queue = NSOperationQueue.mainQueue()
    let object = Sequencer.self
    let callback: (NSNotification) -> Void = {[weak self] _ in self?.recording = Sequencer.recording}
    receptionist = NotificationReceptionist()
    receptionist?.observe(Notification.DidTurnOnRecording, from: object, queue: queue, callback: callback)
    receptionist?.observe(Notification.DidTurnOffRecording, from: object, queue: queue, callback: callback)
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard recording else { return }
    eventContainer.append(MetaEvent(time.time, .Tempo(microseconds: Byte4(60_000_000 / tempo))))
  }

  let name = "Tempo"
  var recording = false

  /**
  Initializer for non-playback mode tempo track
  
  - parameter s: MIDISequence
  */
  init(sequence s: MIDISequence) {
    sequence = s
    recording = Sequencer.recording
    eventContainer.append(TempoTrack.timeSignatureEvent)
    eventContainer.append(TempoTrack.tempoEvent)
  }


  static private var timeSignatureEvent: MetaEvent {
    return MetaEvent(.TimeSignature(upper: Sequencer.timeSignature.beatsPerBar,
                                    lower: Sequencer.timeSignature.beatUnit,
                                    clocks: 36,
                                    notes: 8))
  }

  static private var tempoEvent: MetaEvent {
    return MetaEvent(.Tempo(microseconds: Byte4(60_000_000 / Sequencer.tempo)))
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
        case let .TimeSignature(upper, lower, _, _): Sequencer.timeSignature = TimeSignature(upper, lower)
        default: break
      }
    }
  }

  private(set) unowned var sequence: MIDISequence

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(trackChunk: MIDIFileTrackChunk, sequence s: MIDISequence) {
    sequence = s
    var events = trackChunk.events.filter { TempoTrack.isTempoTrackEvent($0) }
    if !hasTimeSignatureEvent { events.insert(TempoTrack.timeSignatureEvent, atIndex: 0) }
    if !hasTempoEvent { events.insert(TempoTrack.tempoEvent, atIndex: 1) }

    for event in events {
      let eventTime = event.time
      var eventBag: [MIDITrackEvent] = eventMap[eventTime] ?? []
      eventBag.append(event)
      eventMap[eventTime] = eventBag
      eventContainer.append(event)
    }
    logVerbose("eventMap = \(eventMap)")

    for eventTime in eventMap.keys { time.registerCallback(dispatchEventsForTime, forTime: eventTime) }
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n"
    result += "  events: {\n" + ",\n".join(eventContainer.events.map({$0.description.indentedBy(8)})) + "\n\t}\n"
    result += "}"
    return result
  }

}