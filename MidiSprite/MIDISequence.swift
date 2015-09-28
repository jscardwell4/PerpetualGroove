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
  struct Notification: NotificationType {
    enum Name: String, NotificationNameType {
      case DidAddTrack, DidRemoveTrack
    }
    var name: Name
    var object: AnyObject? { return MIDISequence.self }
    var userInfo: [NSObject:AnyObject]?

    enum Key: String { case Track }
    static func DidAddTrack(track: InstrumentTrack) -> Notification {
      return Notification(name: .DidAddTrack, userInfo: [Key.Track.rawValue:track])
    }

    static func DidRemoveTrack(track: InstrumentTrack) -> Notification {
      return Notification(name: .DidRemoveTrack, userInfo: [Key.Track.rawValue:track])
    }
  }

  enum Error: String, ErrorType {
    case NotPermitted = "Action not permitted given the playbackMode value of the sequence"
  }

  var sequenceEnd: CABarBeatTime { return tracks.map({$0.trackEnd}).maxElement() ?? .start }

  let playbackMode: Bool

  /** The instrument tracks are stored in the `tracks` array beginning at index `1` */
  var instrumentTracks: [InstrumentTrack] { return tracks.count > 1 ? tracks[1..<].map({$0 as! InstrumentTrack}) : [] }

  /** The tempo track for the sequence is the first element in the `tracks` array */
  var tempoTrack: TempoTrack { return tracks[0] as! TempoTrack }

  /** Collection of all the tracks in the composition */
  private(set) var tracks: [MIDITrackType] = [TempoTrack()]

  /** Generates a `MIDIFile` from the current sequence state */
  var file: MIDIFile { return MIDIFile(format: .One, division: 480, tracks: tracks) }

  /** init */
  init() { playbackMode = false }

  /**
  initWithFile:

  - parameter file: MIDIFile
  */
  init(file: MIDIFile) {
    playbackMode = true
    var trackChunks = ArraySlice(file.tracks)
    if let trackChunk = trackChunks.first
      where trackChunk.events.count == trackChunk.events.filter({ TempoTrack.isTempoTrackEvent($0) }).count
    {
      tracks[0] = TempoTrack(trackChunk: trackChunk) as MIDITrackType
      trackChunks = trackChunks.dropFirst()
    } else {
      tracks[0] = TempoTrack(playbackMode: true) as MIDITrackType
    }

    tracks.appendContentsOf(trackChunks.flatMap({ try? InstrumentTrack(trackChunk: $0) }) as [MIDITrackType])
  }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  - returns: InstrumentTrack
  */

  func newTrackWithInstrument(instrument: Instrument) throws -> InstrumentTrack {
    guard !playbackMode else { throw Error.NotPermitted }
    let track = try InstrumentTrack(instrument: instrument)
    tracks.append(track)
    Notification.DidAddTrack(track).post()
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
    Notification.DidRemoveTrack(track).post()
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard !playbackMode && Sequencer.recording else { return }
    tempoTrack.insertTempoChange(tempo)
  }

  /**
  writeToFile:

  - parameter file: NSURL
  */
  func writeToFile(file: NSURL, overwrite: Bool = false) throws {
    guard !playbackMode else { throw Error.NotPermitted }
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
    result += "  playbackMode: \(playbackMode)\n"
    result += "\n".join(tracks.map({$0.description.indentedBy(4)}))
    result += "\n}"
    return result
  }
}
