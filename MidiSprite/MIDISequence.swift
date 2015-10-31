//
//  MIDISequence.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

final class MIDISequence {


  // MARK: - Managing tracks
  
  var sequenceEnd: CABarBeatTime { return tracks.map({$0.endOfTrack}).maxElement() ?? .start }

  private(set) var instrumentTracks: [InstrumentTrack] = []
  private var _soloTracks: [Weak<InstrumentTrack>] = []
  var soloTracks: [InstrumentTrack] {
    let result = _soloTracks.flatMap {$0.reference}
    if result.count < _soloTracks.count { _soloTracks = _soloTracks.filter { $0.reference != nil } }
    return result
  }

  /**
  exchangeInstrumentTrackAtIndex:withTrackAtIndex:

  - parameter idx1: Int
  - parameter idx2: Int
  */
  func exchangeInstrumentTrackAtIndex(idx1: Int, withTrackAtIndex idx2: Int) {
    guard instrumentTracks.indices ⊇ [idx1, idx2] else { return }
    swap(&instrumentTracks[idx1], &instrumentTracks[idx2])
  }

  var currentTrackIndex: Int? {
    get { return currentTrack?.index }
    set {
      guard let newValue = newValue where instrumentTracks.indices ∋ newValue else { currentTrack = nil; return }
      currentTrack = instrumentTracks[newValue]
    }
  }

  private var currentTrackStack: Stack<Weak<InstrumentTrack>> = []

  weak var currentTrack: InstrumentTrack? {
    get { return currentTrackStack.peek?.reference }
    set {
      let userInfo: [Notification.Key:AnyObject?]?

      switch (currentTrackStack.peek?.reference, newValue) {

        case let (oldTrack, newTrack?) where instrumentTracks ∋ newTrack && oldTrack != newTrack:
          userInfo = [Notification.Key.OldTrack: oldTrack, Notification.Key.Track: newTrack]
          currentTrackStack.push(Weak(newTrack))
          newTrack.recording = Sequencer.recording

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
  private var tempoTrack: TempoTrack!

  var tempo: Double { get { return tempoTrack.tempo } set { tempoTrack.tempo = newValue } }

  var timeSignature: TimeSignature { get { return tempoTrack.timeSignature } set { tempoTrack.timeSignature = newValue } }

  /** Collection of all the tracks in the composition */
  var tracks: [Track] { return [tempoTrack] + instrumentTracks }

  /**
  toggleSoloForTrack:

  - parameter track: InstrumentTrack
  */
  func toggleSoloForTrack(track: InstrumentTrack) {
    guard instrumentTracks ∋ track else { logWarning("Request to toggle track not owned by sequence"); return }

    if let idx = soloTracks.indexOf(track), track = _soloTracks.removeAtIndex(idx).reference {
      guard track.solo else { fatalError("Internal inconsistency, track should have solo set to true to be in _soloTracks") }
      track.solo = false
      Notification.SoloCountDidChange.post(object: self,
                                           userInfo: [.OldCount: _soloTracks.count + 1, .NewCount: _soloTracks.count])
    } else {
      track.solo = true
      _soloTracks.append(Weak(track))
      Notification.SoloCountDidChange.post(object: self,
                                           userInfo: [.OldCount: _soloTracks.count - 1, .NewCount: _soloTracks.count])
    }
  }

  /** Conversion to the `MIDIFile` type  */
  var file: MIDIFile { return MIDIFile(format: .One, division: 480, tracks: tracks.map({$0.chunk})) }

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
    let recording = Sequencer.recording
    currentTrack?.recording = recording
    tempoTrack.recording = recording
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

  private(set) weak var document: MIDIDocument?

  // MARK: - Initializing

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  init(file: MIDIFile, document: MIDIDocument) {
    self.document = document
    receptionist.observe(Sequencer.Notification.DidToggleRecording,
                    from: Sequencer.self,
                callback: weakMethod(self, method: MIDISequence.toggleRecording))
    receptionist.observe(Sequencer.Notification.DidReset,
                    from: Sequencer.self,
                callback: weakMethod(self, method: MIDISequence.sequencerDidReset))

    var trackChunks = ArraySlice(file.tracks)
    if let trackChunk = trackChunks.first
      where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
    {
      tempoTrack = TempoTrack(sequence: self, trackChunk: trackChunk)
      trackChunks = trackChunks.dropFirst()
    } else {
      tempoTrack = TempoTrack(sequence: self)
    }

    while let track = instrumentTracks.popLast() { removeTrack(track) }
    for track in trackChunks.flatMap({ try? InstrumentTrack(sequence: self, trackChunk: $0) }) {
      addTrack(track)
    }
  }

  deinit { logDebug("") }

  // MARK: - Adding tracks

  /**
  addTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func addTrackWithInstrument(instrument: Instrument) throws { addTrack(try InstrumentTrack(sequence: self, instrument: instrument)) }

  /**
  addTrack:

  - parameter track: InstrumentTrack
  */
  private func addTrack(track: InstrumentTrack) {
    guard instrumentTracks ∌ track else { return }
    track.color = TrackColor.allCases[(instrumentTracks.count) % TrackColor.allCases.count]
    instrumentTracks.append(track)
    receptionist.observe(Track.Notification.DidUpdateEvents,
                    from: track,
                callback: weakMethod(self, method: MIDISequence.trackDidUpdate))

    logDebug("track added: \(track.name)")
    Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track])
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

  func removeTrackAtIndex(index: Int) {
    let track = instrumentTracks.removeAtIndex(index)
    receptionist.stopObserving(Track.Notification.DidUpdateEvents, from: track)
    logDebug("track removed: \(track.name)")
    Notification.DidRemoveTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    if currentTrack == track { currentTrackStack.pop(); currentTrack?.recording = Sequencer.recording }
  }

}

// MARK: - Nameable
extension MIDISequence: Nameable { var name: String? { return document?.localizedName } }

// MARK: - CustomStringConvertible
extension MIDISequence: CustomStringConvertible {
  var description: String {
    return "\ntracks:\n" + "\n\n".join(tracks.map({$0.description.indentedBy(1, useTabs: true)}))
  }
}

// MARK: - CustomDebugStringConvertible
extension MIDISequence: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Notification

extension MIDISequence {
  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddTrack, DidRemoveTrack, DidChangeTrack, SoloCountDidChange, DidUpdate
    enum Key: String, NotificationKeyType { case Track, OldTrack, OldCount, NewCount }
  }
}

extension NSNotification {

  var track: InstrumentTrack?    { return userInfo?[MIDISequence.Notification.Key.Track.key] as? InstrumentTrack }
  var oldTrack: InstrumentTrack? { return userInfo?[MIDISequence.Notification.Key.OldTrack.key] as? InstrumentTrack }

  var oldCount: Int? { return (userInfo?[MIDISequence.Notification.Key.OldCount.key] as? NSNumber)?.integerValue }
  var newCount: Int? { return (userInfo?[MIDISequence.Notification.Key.NewCount.key] as? NSNumber)?.integerValue }

}
