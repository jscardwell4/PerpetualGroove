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
  
  var sequenceEnd: BarBeatTime { return tracks.map({$0.endOfTrack}).max() ?? .start1 }

  fileprivate(set) var instrumentTracks: [InstrumentTrack] = []

  var soloTracks: LazyFilterCollection<[InstrumentTrack]> {
    return instrumentTracks.lazy.filter { $0.solo }
//    return LazyFilterCollection<[InstrumentTrack]>(instrumentTracks, whereElementsSatisfy: {$0.solo})
  }

  /**
  exchangeInstrumentTrackAtIndex:withTrackAtIndex:

  - parameter idx1: Int
  - parameter idx2: Int
  */
  func exchangeInstrumentTrackAtIndex(_ idx1: Int, withTrackAtIndex idx2: Int) {
    guard instrumentTracks.indices.contains([idx1, idx2]) else { return }
    swap(&instrumentTracks[idx1], &instrumentTracks[idx2])
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
  }

  var currentTrackIndex: Int? {
    get { return currentTrack?.index }
    set {
      guard let newValue = newValue , instrumentTracks.indices.contains(newValue) else {
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
      let userInfo: [Notification.Key:AnyObject?]?

      switch (currentTrackStack.peek?.reference, newValue) {

        case let (oldTrack, newTrack?) where instrumentTracks.contains(newTrack) && oldTrack != newTrack:
          userInfo = [Notification.Key.OldTrack: oldTrack, Notification.Key.Track: newTrack]
          currentTrackStack.push(Weak(newTrack))
//          newTrack.recording = true

        case let (oldTrack?, nil):
          userInfo = [Notification.Key.OldTrack: oldTrack, Notification.Key.Track: nil]
          currentTrackStack.pop()

        case (nil, nil):
          fallthrough

        default:
          userInfo = nil

      }
      guard userInfo != nil else { return }
      Notification.DidChangeTrack.post(object: self, userInfo: userInfo)
    }
  }

  /** The tempo track for the sequence is the first element in the `tracks` array */
  fileprivate(set) var tempoTrack: TempoTrack!

  var tempo: Double { get { return tempoTrack.tempo } set { tempoTrack.tempo = newValue } }

  var timeSignature: TimeSignature {
    get { return tempoTrack.timeSignature }
    set { tempoTrack.timeSignature = newValue }
  }

  /** Collection of all the tracks in the composition */
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

  /**
  trackDidUpdate:

  - parameter notification: NSNotification
  */
  fileprivate func trackDidUpdate(_ notification: Foundation.Notification) {
    if Sequencer.playing { hasChanges = true }
    else {
      hasChanges = false
      logDebug("posting 'DidUpdate'")
      Notification.DidUpdate.post(object: self)
    }
  }

  /**
  toggleRecording:

  - parameter notification: NSNotification
  */
  fileprivate func toggleRecording(_ notification: Foundation.Notification) {
    tempoTrack.recording = Sequencer.recording
  }

  /**
  sequencerDidReset:

  - parameter notification: NSNotification
  */
  fileprivate func sequencerDidReset(_ notification: Foundation.Notification) {
    guard hasChanges else { return }
    hasChanges = false
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
  }

  /**
   observeTrack:

   - parameter track: Track
  */
  fileprivate func observeTrack(_ track: Track) {
    receptionist.observe(notification: .DidUpdate,
                    from: track,
                callback: weakMethod(self, Sequence.trackDidUpdate))

    receptionist.observe(notification: .SoloStatusDidChange,
                    from: track,
                callback: weakMethod(self, Sequence.trackSoloStatusDidChange))
  }

  fileprivate(set) weak var document: Document!

  // MARK: - Initializing

  /**
   initWithDocument:

   - parameter document: Document
  */
  init(document: Document) {
    self.document = document
    receptionist.observe(notification: Sequencer.Notification.DidToggleRecording,
                    from: Sequencer.self,
                callback: weakMethod(self, Sequence.toggleRecording))
    receptionist.observe(notification: Sequencer.Notification.DidReset,
                    from: Sequencer.self,
                callback: weakMethod(self, Sequence.sequencerDidReset))
    tempoTrack = TempoTrack(sequence: self)
  }

  /**
   initWithFile:document:

   - parameter file: MIDIFile
   - parameter document: Document
  */
  convenience init(file: MIDIFile, document: Document) {
    self.init(document: document)

    var trackChunks = ArraySlice(file.tracks)
    if let trackChunk = trackChunks.first
      , trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
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

  /**
   initWithFile:document:

   - parameter file: GrooveFile
   - parameter document: Document
  */
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

  /**
   initWithData:document:

   - parameter data: SequenceDataProvider
   - parameter document: Document
  */
  convenience init(data: SequenceDataProvider, document: Document) {
    switch data.storedData {
      case .midi(let file): self.init(file: file, document: document)
      case .groove(let file): self.init(file: file, document: document)
    }
  }

  // MARK: - Adding tracks

  /**
  insertTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func insertTrackWithInstrument(_ instrument: Instrument) throws {
    addTrack(try InstrumentTrack(sequence: self, instrument: instrument))
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
  }

  /**
  addTrack:

  - parameter track: InstrumentTrack
  */
  fileprivate func addTrack(_ track: InstrumentTrack) {
    guard !instrumentTracks.contains(track) else { return }
    instrumentTracks.append(track)
    observeTrack(track)
    logDebug("track added: \(track.name)")
    Notification.DidAddTrack.post(
      object: self as AnyObject,
      userInfo: [
        Notification.Key.AddedIndex: instrumentTracks.count - 1,
        Notification.Key.AddedTrack: track
      ]
    )
    if currentTrack == nil { currentTrack = track }
  }

  // MARK: - Removing tracks

  /**
  removeTrack:

  - parameter track: InstrumentTrack
  */
  func removeTrack(_ track: InstrumentTrack) {
    guard let idx = track.index , track.sequence === self else { return }
    removeTrackAtIndex(idx)
  }

  /**
   removeTrackAtIndex:

   - parameter index: Int
  */
  func removeTrackAtIndex(_ index: Int) {
    let track = instrumentTracks.remove(at: index)
    track.nodeManager.stopNodes(remove: true)
    receptionist.stopObserving(notification: .DidUpdate, from: track)
    logDebug("track removed: \(track.name)")
    Notification.DidRemoveTrack.post(
      object: self as AnyObject,
      userInfo: [
        Notification.Key.RemovedIndex: index,
        Notification.Key.RemovedTrack: track
      ]
    )
    if currentTrack == track { currentTrackStack.pop() }
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
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

// MARK: - CustomDebugStringConvertible
extension Sequence: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

// MARK: - Notification

extension Sequence: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didAddTrack, didRemoveTrack, didChangeTrack, soloCountDidChange, didUpdate
  }
}

extension Notification {

  var track: InstrumentTrack?    { return userInfo?["track"] as? InstrumentTrack }
  var oldTrack: InstrumentTrack? { return userInfo?["oldTrack"] as? InstrumentTrack }

  var oldCount: Int? { return (userInfo?["oldCount"] as? NSNumber)?.intValue }
  var newCount: Int? { return (userInfo?["newCount"] as? NSNumber)?.intValue }

  var removedIndex: Int? {
    return (userInfo?["removedIndex"] as? NSNumber)?.intValue
  }
  var addedIndex: Int? {
    return (userInfo?["addedIndex"] as? NSNumber)?.intValue
  }

  var addedTrack: InstrumentTrack? {
    return userInfo?["addedTrack"] as? InstrumentTrack
  }
  var removedTrack: InstrumentTrack? {
    return userInfo?["removedTrack"] as? InstrumentTrack
  }

}
