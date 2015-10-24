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

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddTrack, DidRemoveTrack, DidChangeTrack, SoloCountDidChange
    enum Key: String, NotificationKeyType { case Track, OldTrack, OldCount, NewCount }
  }

  var sequenceEnd: CABarBeatTime { return tracks.map({$0.trackEnd}).maxElement() ?? .start }

  private(set) var instrumentTracks: [InstrumentTrack] = []
  private var _soloTracks: [WeakObject<InstrumentTrack>] = []
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

  private var previousTrack: InstrumentTrack?

  var currentTrack: InstrumentTrack? {
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
  var tracks: [MIDITrackType] {
    let tempo = [tempoTrack as MIDITrackType]
    let instruments = instrumentTracks.map({$0 as MIDITrackType})
    return tempo + instruments
  }

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
      _soloTracks.append(WeakObject(track))
      Notification.SoloCountDidChange.post(object: self,
                                           userInfo: [.OldCount: _soloTracks.count - 1, .NewCount: _soloTracks.count])
    }
  }

  /** Conversion to and from the `MIDIFile` type  */
  var file: MIDIFile {
    get {
      let file = MIDIFile(format: .One, division: 480, tracks: tracks)
      logVerbose("<out> file: \(file.debugDescription)")
      return file
    }
    set {
      logVerbose("<in> file: \(newValue.debugDescription)")
      var trackChunks = ArraySlice(newValue.tracks)
      if let trackChunk = trackChunks.first
        where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
      {
        tempoTrack = TempoTrack(trackChunk: trackChunk/*, sequence: self*/)
        trackChunks = trackChunks.dropFirst()
      }

      instrumentTracks = trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0/*, sequence: self*/) })
      for track in instrumentTracks { Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track]) }
      zip(TrackColor.allCases, instrumentTracks).forEach { $1.color = $0 }
      currentTrack = instrumentTracks.first
    }
  }

  /** init */
  init() {}

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  init(file f: MIDIFile) { file = f; currentTrack = instrumentTracks.first }

  deinit {
    logDebug("")
  }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func newTrackWithInstrument(instrument: Instrument) throws {
    let track = try InstrumentTrack(instrument: instrument/*, sequence: self*/)
    track.color = TrackColor.allCases[(instrumentTracks.count + 1) % TrackColor.allCases.count]
    instrumentTracks.append(track)
    Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    if SettingsManager.makeNewTrackCurrent { currentTrack = track }
  }

  /**
  removeTrack:

  - parameter track: InstrumentTrack
  */
  func removeTrack(track: InstrumentTrack) {
    guard let idx = instrumentTracks.indexOf(track) else { return }
    instrumentTracks.removeAtIndex(idx)
    Notification.DidRemoveTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    if currentTrack == track { currentTrack = previousTrack }
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard Sequencer.recording else { return }; tempoTrack.insertTempoChange(tempo)
  }

}

extension MIDISequence: CustomStringConvertible {
  var description: String { return "\ntracks:\n" + "\n\n".join(tracks.map({$0.description.indentedBy(1, useTabs: true)})) }
}

extension MIDISequence: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}
