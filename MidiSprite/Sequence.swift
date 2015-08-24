//
//  Sequence.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AudioToolbox
import MoonKit

final class Sequence: CustomStringConvertible {

  var description: String { return "Sequence {\n" + "\n".join(tracks.map({$0.description.indentedBy(4)})) + "\n}" }

  private(set) var musicSequence = MusicSequence()
  private var tempoTrack = MusicTrack()

  /** Collection of all the tracks in the composition */
  private(set) var tracks: [Track] = []

  /** init */
  init() throws {
    try NewMusicSequence(&musicSequence) ➤ "Failed to create music sequence"
    try MusicSequenceGetTempoTrack(musicSequence, &tempoTrack) ➤ "Failed to get tempo track"

  }

  /**
  newTrackOnBus:

  - parameter bus: Bus
  */
  func newTrackOnBus(bus: Bus) throws -> Track {
    var musicTrack = MusicTrack()
    try MusicSequenceNewTrack(musicSequence, &musicTrack) ➤ "Failed to create new music track"
    let track = try Track(bus: bus, track: musicTrack)
    tracks.append(track)
    return track
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) throws {
    try MusicTrackNewExtendedTempoEvent(tempoTrack, Sequencer.barBeatTime.timestamp, tempo)
      ➤ "Failed to add tempo event to tempo track"
  }

}