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
    case DidAddTrack, DidRemoveTrack, DidChangeTrack
    enum Key: String, NotificationKeyType { case Track, OldTrack }
  }

  var sequenceEnd: CABarBeatTime { return tracks.map({$0.trackEnd}).maxElement() ?? .start }

  /** The instrument tracks are stored in the `tracks` array beginning at index `1` */
  private(set) var instrumentTracks: [InstrumentTrack] = []// { return tracks.count > 1 ? tracks[1..<].map({$0 as! InstrumentTrack}) : [] }

  var currentTrack: InstrumentTrack? {
    didSet {
      guard instrumentTracks ∋ currentTrack else { if currentTrack != nil { currentTrack = nil }; return }
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
    guard instrumentTracks ∋ track else { return }
    let otherTracks = instrumentTracks.filter({$0 != track})
    switch track.solo {
      case true: track.solo = false; otherTracks.forEach({$0.mute = false})
      case false: track.solo = true; if track.mute { track.mute = false }; otherTracks.forEach({$0.mute = true})
    }
  }

  /** Conversion to and from the `MIDIFile` type  */
  var file: MIDIFile {
    get { return MIDIFile(format: .One, division: 480, tracks: tracks) }
    set {
      logDebug("file: \(newValue)")
      var trackChunks = ArraySlice(newValue.tracks)
      if let trackChunk = trackChunks.first
        where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
      {
        tempoTrack = TempoTrack(trackChunk: trackChunk)
        trackChunks = trackChunks.dropFirst()
      }

      instrumentTracks = trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0) })
      zip(InstrumentTrack.Color.allCases, instrumentTracks).forEach { $1.color = $0 }
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
    track.color = InstrumentTrack.Color.allCases[(instrumentTracks.count + 1) % InstrumentTrack.Color.allCases.count]
    instrumentTracks.append(track)
    Notification.DidAddTrack.post(object: self, userInfo: [Notification.Key.Track: track])
    return track
  }

  /**
  removeTrack:

  - parameter track: InstrumentTrack
  */
  func removeTrack(track: InstrumentTrack) {
    guard let idx = instrumentTracks.indexOf(track) else { return }
    instrumentTracks.removeAtIndex(idx)
    Notification.DidRemoveTrack.post(object: self, userInfo: [Notification.Key.Track: track])
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
//      logDebug(midiFile.description)
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
