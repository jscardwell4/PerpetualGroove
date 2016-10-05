//
//  Sequence.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

protocol SequenceDataProvider { var storedData: Sequence.Data { get } }

final class Sequence {

  enum Data { case midi (MIDIFile), groove (GrooveFile) }


  // MARK: - Managing tracks
  
  var sequenceEnd: BarBeatTime { return tracks.map({$0.endOfTrack}).max() ?? BarBeatTime.zero }

  fileprivate(set) var instrumentTracks: [InstrumentTrack] = []

  var soloTracks: LazyFilterCollection<[InstrumentTrack]> {
    return instrumentTracks.lazy.filter { $0.solo }
  }

  func exchangeInstrumentTrackAtIndex(_ idx1: Int, withTrackAtIndex idx2: Int) {
    guard instrumentTracks.indices.contains([idx1, idx2]) else { return }
    swap(&instrumentTracks[idx1], &instrumentTracks[idx2])
    logDebug("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self, userInfo: nil)
  }

  var currentTrackIndex: Int? {
    get { return currentTrack?.index }
    set {
      guard let newValue = newValue, instrumentTracks.indices.contains(newValue) else {
        currentTrack = nil
        return
      }
      currentTrack = instrumentTracks[newValue]
    }
  }

  fileprivate var currentTrackStack: Stack<Weak<InstrumentTrack>> = []

  weak var currentTrack: InstrumentTrack? {
    get { return currentTrackStack.peek?.reference }
    set {
      let userInfo: [AnyHashable:Any]?

      switch (currentTrackStack.peek?.reference, newValue) {

        case let (oldTrack, newTrack?) where instrumentTracks.contains(newTrack) && oldTrack != newTrack:
          userInfo = ["oldTrack": oldTrack, "newTrack": newTrack]
          currentTrackStack.push(Weak(newTrack))
//          newTrack.recording = true

        case let (oldTrack?, nil):
          userInfo = ["oldTrack": oldTrack, "newTrack": NSNull()]
          currentTrackStack.pop()

        case (nil, nil):
          fallthrough

        default:
          userInfo = nil

      }
      guard userInfo != nil else { return }
      postNotification(name: .didChangeTrack, object: self, userInfo: userInfo)
    }
  }

  /// The tempo track for the sequence is the first element in the `tracks` array
  fileprivate(set) var tempoTrack: TempoTrack!

  var tempo: Double { get { return tempoTrack.tempo } set { tempoTrack.tempo = newValue } }

  var timeSignature: TimeSignature {
    get { return tempoTrack.timeSignature }
    set { tempoTrack.timeSignature = newValue }
  }

  /// Collection of all the tracks in the composition
  var tracks: [Track] {
    guard tempoTrack != nil else { return instrumentTracks }
    return [tempoTrack] + instrumentTracks
  }

  // MARK: - Receiving track and sequencer notifications

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  fileprivate var hasChanges = false

  fileprivate func trackDidUpdate(_ notification: Foundation.Notification) {
    if Sequencer.playing { hasChanges = true }
    else {
      hasChanges = false
      logDebug("posting 'DidUpdate'")
      postNotification(name: .didUpdate, object: self, userInfo: nil)
    }
  }

  fileprivate func toggleRecording(_ notification: Foundation.Notification) {
    tempoTrack.recording = Sequencer.recording
  }

  fileprivate func sequencerDidReset(_ notification: Foundation.Notification) {
    guard hasChanges else { return }
    hasChanges = false
    logDebug("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self, userInfo: nil)
  }

  fileprivate func observeTrack(_ track: Track) {
    receptionist.observe(name: Track.NotificationName.didUpdate.rawValue,
                         from: track,
                         callback: weakMethod(self, Sequence.trackDidUpdate))

    receptionist.observe(name: Track.NotificationName.soloStatusDidChange.rawValue,
                         from: track,
                         callback: weakMethod(self, Sequence.trackSoloStatusDidChange))
  }

  fileprivate(set) weak var document: Document!

  // MARK: - Initializing

  init(document: Document) {
    self.document = document
    receptionist.observe(name: Sequencer.NotificationName.didToggleRecording.rawValue,
                    from: Sequencer.self,
                callback: weakMethod(self, Sequence.toggleRecording))
    receptionist.observe(name: Sequencer.NotificationName.didReset.rawValue,
                    from: Sequencer.self,
                callback: weakMethod(self, Sequence.sequencerDidReset))
    tempoTrack = TempoTrack(sequence: self)
  }

  convenience init(file: MIDIFile, document: Document) {
    self.init(document: document)

    var trackChunks = ArraySlice(file.tracks)
    if let trackChunk = trackChunks.first,
      trackChunk.events.count == trackChunk.events.filter(TempoTrack.isTempoTrackEvent).count
    {
      tempoTrack = TempoTrack(sequence: self, trackChunk: trackChunk)
      trackChunks = trackChunks.dropFirst()
    } else {
      tempoTrack = TempoTrack(sequence: self)
    }

    for track in trackChunks.flatMap({ try? InstrumentTrack(sequence: self, trackChunk: $0) }) {
      addTrack(track)
    }
  }

  convenience init(file: GrooveFile, document: Document) {
    self.init(document: document)
    var tempoEvents: [MIDIEvent] = []
    for (key: rawTime, value: bpmValue) in file.tempoChanges.value {
      guard let time = BarBeatTime(rawValue: rawTime), let bpm = Double(bpmValue) else { continue }
      tempoEvents.append(.meta(MetaEvent(.tempo(bpm: bpm), time)))
    }
    tempoTrack.addEvents(tempoEvents)
    for track in file.tracks.flatMap({try? InstrumentTrack(sequence: self, grooveTrack: $0)}) {
      addTrack(track)
    }
  }

  convenience init(data: SequenceDataProvider, document: Document) {
    switch data.storedData {
      case .midi(let file): self.init(file: file, document: document)
      case .groove(let file): self.init(file: file, document: document)
    }
  }

  // MARK: - Adding tracks

  func insertTrack(instrument: Instrument) throws {
    addTrack(try InstrumentTrack(sequence: self, instrument: instrument))
    logDebug("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self, userInfo: nil)
  }

  fileprivate func addTrack(_ track: InstrumentTrack) {
    guard !instrumentTracks.contains(track) else { return }
    instrumentTracks.append(track)
    observeTrack(track)
    logDebug("track added: \(track.name)")
    postNotification(name: .didAddTrack,
                     object: self,
                     userInfo: ["addedIndex": instrumentTracks.count - 1, "addedTrack": track])
    if currentTrack == nil { currentTrack = track }
  }

  // MARK: - Removing tracks

  func removeTrack(_ track: InstrumentTrack) {
    guard let idx = track.index , track.sequence === self else { return }
    removeTrackAtIndex(idx)
  }

  func removeTrackAtIndex(_ index: Int) {
    let track = instrumentTracks.remove(at: index)
    track.nodeManager.stopNodes(remove: true)
    receptionist.stopObserving(name: NotificationName.didUpdate.rawValue, from: track)
    logDebug("track removed: \(track.name)")
    postNotification(name: .didRemoveTrack,
                     object: self,
                     userInfo: ["removedIndex": index, "removedTrack": track])
    if currentTrack == track { currentTrackStack.pop() }
    logDebug("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self, userInfo: nil)
  }

}

// MARK: - Nameable
extension Sequence: Nameable { var name: String? { return document?.localizedName } }

// MARK: - CustomStringConvertible
extension Sequence: CustomStringConvertible {
  var description: String {
    return "\ntracks:\n" + "\n\n".join(tracks.map({$0.description.indentedBy(1, useTabs: true)}))
  }
}

// MARK: - Notification

extension Sequence: NotificationDispatching {
  enum NotificationName: String, LosslessStringConvertible {
    case didAddTrack, didRemoveTrack, didChangeTrack, soloCountDidChange, didUpdate

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }
}

extension Notification {

  var track: InstrumentTrack?    { return userInfo?["track"] as? InstrumentTrack }
  var oldTrack: InstrumentTrack? { return userInfo?["oldTrack"] as? InstrumentTrack }

  var oldCount: Int? { return (userInfo?["oldCount"] as? NSNumber)?.intValue }
  var newCount: Int? { return (userInfo?["newCount"] as? NSNumber)?.intValue }

  var removedIndex: Int? { return (userInfo?["removedIndex"] as? NSNumber)?.intValue }
  var addedIndex: Int? { return (userInfo?["addedIndex"] as? NSNumber)?.intValue }

  var addedTrack: InstrumentTrack? { return userInfo?["addedTrack"] as? InstrumentTrack }
  var removedTrack: InstrumentTrack? { return userInfo?["removedTrack"] as? InstrumentTrack }

}
