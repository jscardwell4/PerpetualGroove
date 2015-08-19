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

final class Track: Equatable {

  typealias Program = Instrument.Program
  typealias Channel = Instrument.Channel

  // MARK: - Constant properties

  let musicTrack: MusicTrack

  var instrument: Instrument { return bus.instrument }
  let bus: Bus
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

  lazy var label: String = {"bus \(self.bus.element)"}()

  var volume: Float { get { return bus.volume } set { bus.volume = newValue } }
  var pan: Float { get { return bus.pan } set { bus.pan = newValue } }

  /**
  init:bus:

  - parameter i: Instrument
  - parameter b: AudioUnitElement
  */
  init(bus b: Bus, track: MusicTrack) {
    bus = b
    musicTrack = track
    color = Color.allCases[Int(bus.element) % 10]
  }

  /**
  addNoteForNode:

  - parameter node: MIDINode
  */
  func addNoteForNode(node: MIDINode) throws {
    let timestamp = TrackManager.playing ? TrackManager.currentTime + 0.1 : TrackManager.currentTime
    try MusicTrackNewMIDINoteEvent(musicTrack, timestamp, &node.note) ➤ "\(location()) Failed to add new note event"
    if !TrackManager.playing { try TrackManager.start() }
  }

}


func ==(lhs: Track, rhs: Track) -> Bool { return lhs.bus == rhs.bus }
