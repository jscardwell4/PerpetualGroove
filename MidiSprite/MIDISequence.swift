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
    get {
      guard let currentTrack = currentTrack else { return nil }
      return instrumentTracks.indexOf(currentTrack)
    }
    set {
      guard let newValue = newValue where instrumentTracks.indices ∋ newValue else { currentTrack = nil; return }
      currentTrack = instrumentTracks[newValue]
    }
  }

  private weak var previousTrack: InstrumentTrack?

  weak var currentTrack: InstrumentTrack? {
    didSet {
      if let oldTrack = oldValue where oldTrack.recording { oldTrack.recording = false }
      guard currentTrack == nil || instrumentTracks ∋ currentTrack else { currentTrack = nil; return }
      previousTrack = oldValue
      currentTrack?.recording = Sequencer.recording
      Notification.DidChangeTrack.post(object: self,
                                       userInfo: [Notification.Key.OldTrack: oldValue as? AnyObject,
                                                  Notification.Key.Track:    currentTrack as? AnyObject])
    }
  }

  /** The tempo track for the sequence is the first element in the `tracks` array */
  private var tempoTrack = TempoTrack()

  var tempo: Double { return tempoTrack.tempo }

  var timeSignature: TimeSignature { return tempoTrack.timeSignature }

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

  /** Conversion to and from the `MIDIFile` type  */
  var file: MIDIFile {
    get { return MIDIFile(format: .One, division: 480, tracks: tracks.map({$0.chunk})) }
    set {
      var trackChunks = ArraySlice(newValue.tracks)
      if let trackChunk = trackChunks.first
        where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
      {
        tempoTrack = TempoTrack(trackChunk: trackChunk)
        trackChunks = trackChunks.dropFirst()
      }

      while let track = instrumentTracks.popLast() { removeTrack(track) }
      for track in trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0) }) {
        addTrack(track)
      }
      previousTrack = nil
      currentTrack = instrumentTracks.first
    }
  }

  let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()

  /** init */
  init() {
    receptionist.observe(Sequencer.Notification.DidToggleRecording, from: Sequencer.self) {
      [weak self] _ in
      let recording = Sequencer.recording
      self?.currentTrack?.recording = recording
      self?.tempoTrack.recording = recording
    }
  }

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  convenience init(file f: MIDIFile) { self.init(); file = f; currentTrack = instrumentTracks.first }

  deinit { logDebug("") }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func newTrackWithInstrument(instrument: Instrument) throws {
    let track = try InstrumentTrack(instrument: instrument)
    addTrack(track)
    if SettingsManager.makeNewTrackCurrent { currentTrack = track }
  }

  /**
  addTrack:

  - parameter track: InstrumentTrack
  */
  private func addTrack(track: InstrumentTrack) {
    guard instrumentTracks ∌ track else { return }
    track.color = TrackColor.allCases[(instrumentTracks.count) % TrackColor.allCases.count]
    instrumentTracks.append(track)
    receptionist.observe(Track.Notification.DidUpdateEvents, from: track) {
      [weak self] _ in
        guard let weakself = self else { return }
        weakself.logDebug("posting 'DidUpdate'")
        Notification.DidUpdate.post(object: weakself)
    }
    logDebug("track added: \(track.name)")
    Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track])

  }

  /**
  removeTrack:

  - parameter track: InstrumentTrack
  */
  func removeTrack(track: InstrumentTrack) {
    guard let idx = instrumentTracks.indexOf(track) else { return }
    removeTrackAtIndex(idx)
  }

  func removeTrackAtIndex(index: Int) {
    let track = instrumentTracks.removeAtIndex(index)
    receptionist.stopObserving(Track.Notification.DidUpdateEvents, from: track)
    logDebug("track removed: \(track.name)")
    Notification.DidRemoveTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    if currentTrack == track { currentTrack = previousTrack }
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) { tempoTrack.tempo = tempo }

  /**
  insertTimeSignature:

  - parameter signature: TimeSignature
  */
  func insertTimeSignature(signature: TimeSignature) { tempoTrack.timeSignature = signature }
}

extension MIDISequence: CustomStringConvertible {
  var description: String {
    return "\ntracks:\n" + "\n\n".join(tracks.map({$0.description.indentedBy(1, useTabs: true)}))
  }
}

extension MIDISequence: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

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
