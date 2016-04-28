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

  enum Data { case MIDI (MIDIFile), Groove (GrooveFile) }


  // MARK: - Managing tracks
  
  var sequenceEnd: BarBeatTime { return tracks.map({$0.endOfTrack}).maxElement() ?? .start1 }

  private(set) var instrumentTracks: [InstrumentTrack] = []

  var soloTracks: LazyFilterCollection<[InstrumentTrack]> {
    return instrumentTracks.lazy.filter { $0.solo }
//    return LazyFilterCollection<[InstrumentTrack]>(instrumentTracks, whereElementsSatisfy: {$0.solo})
  }

  /**
  exchangeInstrumentTrackAtIndex:withTrackAtIndex:

  - parameter idx1: Int
  - parameter idx2: Int
  */
  func exchangeInstrumentTrackAtIndex(idx1: Int, withTrackAtIndex idx2: Int) {
    guard instrumentTracks.indices.contains([idx1, idx2]) else { return }
    swap(&instrumentTracks[idx1], &instrumentTracks[idx2])
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
  }

  var currentTrackIndex: Int? {
    get { return currentTrack?.index }
    set {
      guard let newValue = newValue where instrumentTracks.indices.contains(newValue) else {
        currentTrack = nil
        return
      }
      currentTrack = instrumentTracks[newValue]
    }
  }

  private var currentTrackStack: Stack<Weak<InstrumentTrack>> = []

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
  private(set) var tempoTrack: TempoTrack!

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

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  private var hasChanges = false

  /**
  trackDidUpdate:

  - parameter notification: NSNotification
  */
  private func trackDidUpdate(notification: NSNotification) {
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
  private func toggleRecording(notification: NSNotification) {
    tempoTrack.recording = Sequencer.recording
  }

  /**
  sequencerDidReset:

  - parameter notification: NSNotification
  */
  private func sequencerDidReset(notification: NSNotification) {
    guard hasChanges else { return }
    hasChanges = false
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
  }

  /**
   observeTrack:

   - parameter track: Track
  */
  private func observeTrack(track: Track) {
    receptionist.observe(notification: .DidUpdate,
                    from: track,
                callback: weakMethod(self, Sequence.trackDidUpdate))

    receptionist.observe(notification: .SoloStatusDidChange,
                    from: track,
                callback: weakMethod(self, Sequence.trackSoloStatusDidChange))
  }

  private(set) weak var document: Document!

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
      where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
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
    for (_, rawTime, bpmValue) in file.tempoChanges.value {
      guard let time = BarBeatTime(rawValue: rawTime), bpm = Double(bpmValue) else { continue }
      tempoEvents.append(.Meta(MetaEvent(.Tempo(bpm: bpm), time)))
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
      case .MIDI(let file): self.init(file: file, document: document)
      case .Groove(let file): self.init(file: file, document: document)
    }
  }

  // MARK: - Adding tracks

  /**
  insertTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func insertTrackWithInstrument(instrument: Instrument) throws {
    addTrack(try InstrumentTrack(sequence: self, instrument: instrument))
    logDebug("posting 'DidUpdate'")
    Notification.DidUpdate.post(object: self)
  }

  /**
  addTrack:

  - parameter track: InstrumentTrack
  */
  private func addTrack(track: InstrumentTrack) {
    guard !instrumentTracks.contains(track) else { return }
    instrumentTracks.append(track)
    observeTrack(track)
    logDebug("track added: \(track.name)")
    Notification.DidAddTrack.post(
      object: self,
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
  func removeTrack(track: InstrumentTrack) {
    guard let idx = track.index where track.sequence === self else { return }
    removeTrackAtIndex(idx)
  }

  /**
   removeTrackAtIndex:

   - parameter index: Int
  */
  func removeTrackAtIndex(index: Int) {
    let track = instrumentTracks.removeAtIndex(index)
    track.nodeManager.stopNodes(remove: true)
    receptionist.stopObserving(notification: .DidUpdate, from: track)
    logDebug("track removed: \(track.name)")
    Notification.DidRemoveTrack.post(
      object: self,
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
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Notification

extension Sequence: NotificationDispatchType {
  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddTrack, DidRemoveTrack, DidChangeTrack, SoloCountDidChange, DidUpdate
    enum Key: String, NotificationKeyType {
      case Track, OldTrack, OldCount, RemovedIndex, AddedIndex, NewCount, AddedTrack, RemovedTrack
    }
  }
}

extension NSNotification {

  var track: InstrumentTrack?    { return userInfo?[Sequence.Notification.Key.Track.key] as? InstrumentTrack }
  var oldTrack: InstrumentTrack? { return userInfo?[Sequence.Notification.Key.OldTrack.key] as? InstrumentTrack }

  var oldCount: Int? { return (userInfo?[Sequence.Notification.Key.OldCount.key] as? NSNumber)?.integerValue }
  var newCount: Int? { return (userInfo?[Sequence.Notification.Key.NewCount.key] as? NSNumber)?.integerValue }

  var removedIndex: Int? {
    return (userInfo?[Sequence.Notification.Key.RemovedIndex.key] as? NSNumber)?.integerValue
  }
  var addedIndex: Int? {
    return (userInfo?[Sequence.Notification.Key.AddedIndex.key] as? NSNumber)?.integerValue
  }

  var addedTrack: InstrumentTrack? {
    return userInfo?[Sequence.Notification.Key.AddedTrack.key] as? InstrumentTrack
  }
  var removedTrack: InstrumentTrack? {
    return userInfo?[Sequence.Notification.Key.RemovedTrack.key] as? InstrumentTrack
  }

}
