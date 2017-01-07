//
//  Sequence.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

protocol SequenceDataProvider { var storedData: Sequence.Data { get } }

final class Sequence {

  enum Data { case midi (MIDIFile), groove (GrooveFile) }

  static var current: Sequence? { return Sequencer.sequence }

  // MARK: - Managing tracks
  
  var sequenceEnd: BarBeatTime { return tracks.map({$0.endOfTrack}).max() ?? BarBeatTime.zero }

  fileprivate(set) var instrumentTracks: [InstrumentTrack] = []

  var soloTracks: LazyFilterCollection<[InstrumentTrack]> {
    return instrumentTracks.lazy.filter { $0.solo }
  }

  func exchangeInstrumentTrack(at idx1: Int, with idx2: Int) {
    guard instrumentTracks.indices.contains([idx1, idx2]) else { return }
    swap(&instrumentTracks[idx1], &instrumentTracks[idx2])
    Log.verbose("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self)
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

        case let (oldTrack?, newTrack?) where instrumentTracks.contains(newTrack) && oldTrack != newTrack:
          guard let oldTrackIndex = instrumentTracks.index(of: oldTrack),
                let newTrackIndex = instrumentTracks.index(of: newTrack)
            else
          {
              fatalError("Failed to obtain indexes of old and new tracks.")
          }
          userInfo = [
            "oldTrack": oldTrack,
            "oldTrackIndex": oldTrackIndex,
            "newTrack": newTrack,
            "newTrackIndex": newTrackIndex
          ]
          currentTrackStack.push(Weak(newTrack))
//          newTrack.recording = true

        case let (oldTrack?, nil):
          guard let oldTrackIndex = instrumentTracks.index(of: oldTrack) else {
            fatalError("Failed to obtain indexes of old track.")
          }
          userInfo = [
            "oldTrack": oldTrack,
            "oldTrackIndex": oldTrackIndex,
            "newTrack": NSNull()
          ]
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
    if Transport.current.isPlaying { hasChanges = true }
    else {
      hasChanges = false
      Log.debug("posting 'DidUpdate'")
      postNotification(name: .didUpdate, object: self)
    }
  }

  fileprivate func toggleRecording(_ notification: Foundation.Notification) {
    tempoTrack.recording = Transport.current.isRecording
  }

  fileprivate func sequencerDidReset(_ notification: Foundation.Notification) {
    guard hasChanges else { return }
    hasChanges = false
    Log.verbose("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self)
  }

  fileprivate func observeTrack(_ track: Track) {
    receptionist.observe(name: .didUpdate, from: track,
                         callback: weakMethod(self, Sequence.trackDidUpdate))

    receptionist.observe(name: .soloStatusDidChange, from: track,
                         callback: weakMethod(self, Sequence.trackSoloStatusDidChange))
  }

  fileprivate(set) weak var document: Document!

  // MARK: - Initializing

  init(document: Document) {
    self.document = document
    let transport = Transport.current
    receptionist.observe(name: .didToggleRecording, from: transport,
                callback: weakMethod(self, Sequence.toggleRecording))
    receptionist.observe(name: .didReset, from: transport,
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
      add(track: track)
    }
  }

  convenience init(file: GrooveFile, document: Document) {
    self.init(document: document)
    var tempoEvents: [MIDIEvent] = []
    for (key: rawTime, value: bpmValue) in file.tempoChanges.value {
      guard let time = BarBeatTime(rawValue: rawTime), let bpm = Double(bpmValue) else { continue }
      tempoEvents.append(.meta(MIDIEvent.MetaEvent(data: .tempo(bpm: bpm), time: time)))
    }
    tempoTrack.add(events: tempoEvents)
    for track in file.tracks.flatMap({try? InstrumentTrack(sequence: self, grooveTrack: $0)}) {
      add(track: track)
    }
  }

  convenience init(data: SequenceDataProvider, document: Document) {
    switch data.storedData {
      case .midi  (let file): self.init(file: file, document: document)
      case .groove(let file): self.init(file: file, document: document)
    }
  }

  // MARK: - Adding tracks

  func insertTrack(instrument: Instrument) throws {
    add(track: try InstrumentTrack(sequence: self, instrument: instrument))
    Log.verbose("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self)
  }

  fileprivate func add(track: InstrumentTrack) {
    guard !instrumentTracks.contains(track) else { return }
    instrumentTracks.append(track)
    observeTrack(track)
    Log.debug("track added: \(track.name)")
    postNotification(name: .didAddTrack, object: self,
                     userInfo: ["addedIndex": instrumentTracks.count - 1, "addedTrack": track])
    if currentTrack == nil { currentTrack = track }
  }

  // MARK: - Removing tracks

  func remove(track: InstrumentTrack) {
    guard let idx = track.index , track.sequence === self else { return }
    removeTrack(at: idx)
  }

  func removeTrack(at index: Int) {
    let track = instrumentTracks.remove(at: index)
    track.nodeManager.stopNodes(remove: true)
    receptionist.stopObserving(name: NotificationName.didUpdate.rawValue, from: track)
    Log.debug("track removed: \(track.name)")
    postNotification(name: .didRemoveTrack, object: self,
                     userInfo: ["removedIndex": index, "removedTrack": track])
    if currentTrack == track { currentTrackStack.pop() }
    Log.debug("posting 'DidUpdate'")
    postNotification(name: .didUpdate, object: self)
  }

}

// MARK: - Nameable
extension Sequence: Nameable { var name: String? { return document?.localizedName } }

// MARK: - CustomStringConvertible
extension Sequence: CustomStringConvertible {

  var description: String {
    return "\ntracks:\n" + "\n\n".join(tracks.map({$0.description.indented(by: 1, useTabs: true)}))
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

  var newTrack: InstrumentTrack? { return userInfo?["newTrack"] as? InstrumentTrack }
  var oldTrack: InstrumentTrack? { return userInfo?["oldTrack"] as? InstrumentTrack }

  var newTrackIndex: Int? { return userInfo?["newTrackIndex"] as? Int }
  var oldTrackIndex: Int? { return userInfo?["oldTrackIndex"] as? Int }

  var oldCount: Int? { return userInfo?["oldCount"] as? Int }
  var newCount: Int? { return userInfo?["newCount"] as? Int }

  var removedIndex: Int? { return userInfo?["removedIndex"] as? Int }
  var addedIndex: Int? { return userInfo?["addedIndex"] as? Int }

  var addedTrack: InstrumentTrack? { return userInfo?["addedTrack"] as? InstrumentTrack }
  var removedTrack: InstrumentTrack? { return userInfo?["removedTrack"] as? InstrumentTrack }

}
