//
//  NodeCapturingMIDISequence.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class NodeCapturingMIDISequence {

  static let ExtendedFileAttributeName = "com.MoondeerStudios.MIDISprite.NodeCapturingMIDISequence"

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case TrackAdded, TrackRemoved
    var object: AnyObject? { return NodeCapturingMIDISequence.self }
  }

  var recording = false { didSet { instrumentTracks.forEach { $0.recording = recording } } }

  /** The instrument tracks are stored in the `tracks` array beginning at index `1` */
  var instrumentTracks: [InstrumentTrack] { return tracks.count > 1 ? tracks[1..<].map({$0 as! InstrumentTrack}) : [] }

  /** The tempo track for the sequence is the first element in the `tracks` array */
  var tempoTrack: TempoTrack { return tracks[0] as! TempoTrack }

  private let time = BarBeatTime(clockSource: Sequencer.clockSource)

  /** Collection of all the tracks in the composition */
  private(set) var tracks: [MIDITrackType] = [TempoTrack()]

  /** Generates a `MIDIFile` from the current sequence state */
  var file: MIDIFile { return MIDIFile(format: .One, division: 480, tracks: tracks) }

  /**
  newTrackWithInstrument:

  - parameter instrument: Instrument
  - returns: InstrumentTrack
  */

  func newTrackWithInstrument(instrument: Instrument) throws -> InstrumentTrack {
    tracks.append(try InstrumentTrack(instrument: instrument, recording: recording))
    Notification.TrackAdded.post()
    return tracks.last as! InstrumentTrack
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) { tempoTrack.insertTempoChange(tempo) }

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
//        file.absoluteString.withCString({
//          filePtr in
//          NodeCapturingMIDISequence.ExtendedFileAttributeName.withCString({
//            namePtr in
//            var value: UInt8 = 1
//            setxattr(filePtr, namePtr, &value, 1, 0, 0)
//          })
//        })
      } catch {
        logError(error)
      }
    }
  }

}

extension NodeCapturingMIDISequence: CustomStringConvertible {
  var description: String {
    return "\(self.dynamicType.self) {\n" + "\n".join(tracks.map({$0.description.indentedBy(4)})) + "\n}"
  }
}
