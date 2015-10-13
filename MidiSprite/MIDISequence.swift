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

  static let ExtendedFileAttributeName = "com.MoondeerStudios.MIDISprite.MIDISequence"

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddTrack, DidRemoveTrack, DidChangeTrack, SoloCountDidChange
    enum Key: String, NotificationKeyType { case Track, OldTrack, OldCount, NewCount }
  }

  var sequenceEnd: CABarBeatTime { return tracks.map({$0.trackEnd}).maxElement() ?? .start }

  private(set) var instrumentTracks: [InstrumentTrack] = []
  private var _soloTracks: [WeakObject<InstrumentTrack>] = []
  var soloTracks: [InstrumentTrack] {
    let result = _soloTracks.flatMap {$0.value}
    if result.count < _soloTracks.count { _soloTracks = _soloTracks.filter { $0.value != nil } }
    return result
  }

  var currentTrackIndex: Int? {
    guard let currentTrack = currentTrack else { return nil }
    return instrumentTracks.indexOf(currentTrack)
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
  private(set) lazy var tempoTrack: TempoTrack = TempoTrack(sequence: self)

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
    var tracks = Set(instrumentTracks)
    guard tracks.remove(track) != nil else { return }
    let soloTracks = Set(self.soloTracks)
    let oldCount = soloTracks.count
    let newCount: Int
    tracks ∖= soloTracks
    switch track.solo {
      case true:
        guard let idx = _soloTracks.indexOf({$0.value == track}) else { fatalError("Failed to locate soloing track in array") }
        _soloTracks.removeAtIndex(idx)
        track.solo = false
        newCount = oldCount - 1
        if _soloTracks.isEmpty { tracks.forEach({$0.mute = false}) }
        else { track.mute = true }

      case false:
        track.solo = true
        newCount = oldCount + 1
        _soloTracks.append(WeakObject(track))
//        track.mute = false
        if _soloTracks.count == 1 { tracks.forEach({$0.mute = true}) }
    }
    Notification.SoloCountDidChange.post(object: self, userInfo: [.OldCount: oldCount, .NewCount: newCount])
  }

  /** Conversion to and from the `MIDIFile` type  */
  var file: MIDIFile {
    get { return MIDIFile(format: .One, division: 480, tracks: tracks) }
    set {
      logVerbose("file: \(newValue)")
      var trackChunks = ArraySlice(newValue.tracks)
      if let trackChunk = trackChunks.first
        where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
      {
        tempoTrack = TempoTrack(trackChunk: trackChunk, sequence: self)
        trackChunks = trackChunks.dropFirst()
      }

      instrumentTracks = trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0, sequence: self) })
      zip(InstrumentTrack.Color.allCases, instrumentTracks).forEach { $1.color = $0 }
    }
  }

  /** init */
  init() {}

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  init(file f: MIDIFile) { file = f; currentTrack = instrumentTracks.first }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  */

  func newTrackWithInstrument(instrument: Instrument) throws {
    let track = try InstrumentTrack(instrument: instrument, sequence: self)
    track.color = InstrumentTrack.Color.allCases[(instrumentTracks.count + 1) % InstrumentTrack.Color.allCases.count]
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
    guard Sequencer.recording else { return }
    tempoTrack.insertTempoChange(tempo)
  }

  /**
  writeToFile:

  - parameter file: NSURL
  */
//  func writeToFile(file: NSURL, overwrite: Bool = false) throws {
//    let midiFile = self.file
//    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
//      logVerbose(midiFile.description)
//      let bytes = midiFile.bytes
//      let data = NSData(bytes: bytes, length: bytes.count)
//      do {
//        try data.writeToURL(file, options: overwrite ? [.DataWritingAtomic] : [.DataWritingWithoutOverwriting])
//      } catch {
//        logError(error)
//      }
//    }
//  }

}

extension MIDISequence: CustomStringConvertible {
  var description: String {
    var result = "\(self.dynamicType.self) {\n"
    result += "\n".join(tracks.map({$0.description.indentedBy(4)}))
    result += "\n}"
    return result
  }
}
