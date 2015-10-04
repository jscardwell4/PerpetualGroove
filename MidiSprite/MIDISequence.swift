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
    case DidAddTrack, DidRemoveTrack, DidChangeCurrentTrack
    enum Key: String { case Track, OldTrack }
  }

  var sequenceEnd: CABarBeatTime { return tracks.map({$0.trackEnd}).maxElement() ?? .start }

  /** The instrument tracks are stored in the `tracks` array beginning at index `1` */
  var instrumentTracks: [InstrumentTrack] { return tracks.count > 1 ? tracks[1..<].map({$0 as! InstrumentTrack}) : [] }

  var currentTrack: InstrumentTrack? {
    didSet {
      Notification.DidChangeCurrentTrack.post(from: self,
                                         info: [Notification.Key.OldTrack.rawValue: (oldValue as? AnyObject ?? NSNull()),
                                                Notification.Key.Track.rawValue:    (currentTrack as? AnyObject ?? NSNull())])
    }
  }

  /** The tempo track for the sequence is the first element in the `tracks` array */
  var tempoTrack: TempoTrack { return tracks[0] as! TempoTrack }

  /** Collection of all the tracks in the composition */
  private(set) var tracks: [MIDITrackType] = [TempoTrack()]

  /**
  toggleSoloForTrack:

  - parameter track: InstrumentTrack
  */
  func toggleSoloForTrack(track: InstrumentTrack) {
    guard instrumentTracks ∋ track else { return }
    let otherTracks = instrumentTracks.filter({$0 != track})
    switch track.solo {
      case true: track.solo = false; otherTracks.forEach({$0.mute = false})
      case false: track.solo = true; if track.mute { track.mute = false }; otherTracks.forEach({$0.mute = true})
    }
  }

  /** Generates a `MIDIFile` from the current sequence state */
  var file: MIDIFile {
    get { return MIDIFile(format: .One, division: 480, tracks: tracks) }
    set {
      var trackChunks = ArraySlice(file.tracks)
      if let trackChunk = trackChunks.first
        where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
      {
        tracks[0] = TempoTrack(trackChunk: trackChunk) as MIDITrackType
        trackChunks = trackChunks.dropFirst()
      }

      tracks.appendContentsOf(trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0) }) as [MIDITrackType])
    }
  }

  /** init */
  init() {}

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  init(file f: MIDIFile) { file = f }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  - returns: InstrumentTrack
  */

  func newTrackWithInstrument(instrument: Instrument) throws -> InstrumentTrack {
    let track = try InstrumentTrack(instrument: instrument)
    tracks.append(track)
    Notification.DidAddTrack.post(from: self, info: [Notification.Key.Track.rawValue: track])
    return tracks.last as! InstrumentTrack
  }

  /**
  removeTrack:

  - parameter track: InstrumentTrack
  */
  func removeTrack(track: InstrumentTrack) {
    let instrumentTracks = self.instrumentTracks
    guard let idx = instrumentTracks.indexOf(track) where instrumentTracks.count == tracks.count - 1 else {
      return
    }
    tracks.removeAtIndex(idx + 1)
    Notification.DidRemoveTrack.post(from: self, info: [Notification.Key.Track.rawValue: track])
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
  func writeToFile(file: NSURL, overwrite: Bool = false) throws {
    let midiFile = self.file
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
      logDebug(midiFile.description)
      let bytes = midiFile.bytes
      let data = NSData(bytes: bytes, length: bytes.count)
      do {
        try data.writeToURL(file, options: overwrite ? [.DataWritingAtomic] : [.DataWritingWithoutOverwriting])
      } catch {
        logError(error)
      }
    }
  }

}

extension MIDISequence: CustomStringConvertible {
  var description: String {
    var result = "\(self.dynamicType.self) {\n"
    result += "\n".join(tracks.map({$0.description.indentedBy(4)}))
    result += "\n}"
    return result
  }
}
