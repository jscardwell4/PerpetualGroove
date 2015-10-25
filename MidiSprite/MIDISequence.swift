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
      guard currentTrack == nil || instrumentTracks ∋ currentTrack else { currentTrack = nil; return }
      previousTrack = oldValue
      Notification.DidChangeTrack.post(object: self,
                                       userInfo: [Notification.Key.OldTrack: oldValue as? AnyObject,
                                                  Notification.Key.Track:    currentTrack as? AnyObject])
    }
  }

  /** The tempo track for the sequence is the first element in the `tracks` array */
  private(set) var tempoTrack = TempoTrack()

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
    get {
      let file = MIDIFile(format: .One, division: 480, tracks: tracks.map({$0.chunk}))
      logDebug("<out> file: \(file)")
      return file
    }
    set {
      logDebug("<in> file: \(newValue)")
      var trackChunks = ArraySlice(newValue.tracks)
      if let trackChunk = trackChunks.first
        where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
      {
        tempoTrack = TempoTrack(trackChunk: trackChunk)
        trackChunks = trackChunks.dropFirst()
      }

      instrumentTracks = trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0) })
      for track in instrumentTracks {
        Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track])
      }
      zip(TrackColor.allCases, instrumentTracks).forEach { $1.color = $0 }
      currentTrack = instrumentTracks.first
    }
  }

  let receptionist = NotificationReceptionist()

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard receptionist.count == 0 else { return }
    receptionist.logContext = LogManager.MIDIFileContext
  }

  /** init */
  init() {}

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  init(file f: MIDIFile) { file = f; currentTrack = instrumentTracks.first }

  deinit {
    instrumentTracks.removeAll()
    MoonKit.logDebug("deinit")
  }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func newTrackWithInstrument(instrument: Instrument) throws {
    let track = try InstrumentTrack(instrument: instrument/*, sequence: self*/)
    track.color = TrackColor.allCases[(instrumentTracks.count + 1) % TrackColor.allCases.count]
    instrumentTracks.append(track)
    receptionist.observe(Track.Notification.DidUpdateEvents, from: track) {
      [weak self] _ in
      guard let weakself = self else { return }
      Notification.DidUpdate.post(object: weakself)
    }
    Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    if SettingsManager.makeNewTrackCurrent { currentTrack = track }
  }

  /**
  removeTrack:

  - parameter track: InstrumentTrack
  */
  func removeTrack(track: InstrumentTrack) {
    guard let idx = instrumentTracks.indexOf(track) else { return }
    receptionist.stopObserving(Track.Notification.DidUpdateEvents, from: track)
    instrumentTracks.removeAtIndex(idx)
    Notification.DidRemoveTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    if currentTrack == track { currentTrack = previousTrack }
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard Sequencer.recording else { return }
    tempoTrack.insertTempoChange(tempo)
    Notification.DidUpdate.post(object: self)
  }

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