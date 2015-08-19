//
//  Track.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import AudioToolbox

final class InstrumentTrack: Equatable {

  // MARK: - Constant properties

  let instrument: Instrument
  let musicTrack: MusicTrack

  let bus: Mixer.Bus
  let color: Color

  // MARK: - Enumeration for specifying the color attached to a `TrackType`
  enum Color: UInt32, EnumerableType {
    case White      = 0xffffff
    case Portica    = 0xf7ea64
    case MonteCarlo = 0x7ac2a5
    case FlamePea   = 0xda5d3a
    case Crimson    = 0xd6223e
    case HanPurple  = 0x361aee
    case MangoTango = 0xf88242
    case Viking     = 0x6bcbe1
    case Yellow     = 0xfde97e
    case Conifer    = 0x9edc58
    case Apache     = 0xce9f58

    var value: UIColor { return UIColor(RGBHex: rawValue) }

    /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
    static let allCases: [Color] = [.Portica, .MonteCarlo, .FlamePea, .Crimson, .HanPurple,
                                    .MangoTango, .Viking, .Yellow, .Conifer, .Apache]
  }

  // MARK: - Editable properties

  lazy var label: String = {"bus \(self.bus)"}()

  var volume: Mixer.ParameterValue = 1  {
    didSet {
      volume = ClosedInterval<Mixer.ParameterValue>(0, 1).clampValue(volume)
      do { try Mixer.setVolume(volume, onBus: bus) } catch { logError(error) }
    }
  }
  var pan: Mixer.ParameterValue = 0 {
    didSet {
      pan = ClosedInterval<Mixer.ParameterValue>(-1, 1).clampValue(pan)
      do { try Mixer.setPan(pan, onBus: bus) } catch { logError(error) }
    }
  }

  /**
  init:bus:

  - parameter i: Instrument
  - parameter b: AudioUnitElement
  */
  init(instrument i: Instrument, bus b: Mixer.Bus, track: MusicTrack) {
    instrument = i
    bus = b
    musicTrack = track
    color = Color.allCases[Int(bus) % 10]
    do {
      let currentVolume = try Mixer.volumeOnBus(bus)
      let currentPan = try Mixer.panOnBus(bus)
      volume = currentVolume
      pan = currentPan
    } catch { logError(error) }
  }

  /**
  addNoteForNode:

  - parameter node: MIDINode
  */
  func addNoteForNode(node: MIDINode) throws {
    var playing = DarwinBoolean(false)
    try checkStatus(MusicPlayerIsPlaying(AudioManager.musicPlayer, &playing), "Failed to check playing status of music player")
    var timestamp = MusicTimeStamp(0)
    if playing { try checkStatus(MusicPlayerGetTime(AudioManager.musicPlayer, &timestamp), "Failed to get time from player") }
    try checkStatus(MusicTrackNewMIDINoteEvent(musicTrack, timestamp, &node.note), "Failed to add new note event")
    if !playing { try checkStatus(MusicPlayerStart(AudioManager.musicPlayer), "Failed to start playing music player") }
  }

}


func ==(lhs: InstrumentTrack, rhs: InstrumentTrack) -> Bool { return lhs.bus == rhs.bus }
